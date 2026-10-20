-- Partner shop performance guard + Spatial Well upgrade.
-- Keeps Workshop files untouched so updates remain reversible.

require "MSR_ShopData"
require "MSR_UpgradeData"
require "MSR_UpgradeLogic"
require "MSR_SpatialWell"

local TAG = "[PartnerShopPerfWellUpgrade]"
local WELL_UPGRADE_ID = "partner_spatial_well"
local SELL_CACHE_MS = 750

local WELL_LEVELS = {
    [1] = { dailyLiters = 50, capacityLiters = 500, coreCost = 200 },
    [2] = { dailyLiters = 200, capacityLiters = 1500, coreCost = 500 },
    [3] = { dailyLiters = 1000, capacityLiters = 3000, coreCost = 1000 },
}

local function nowMilliseconds()
    if getTimestampMs then
        local ok, value = pcall(getTimestampMs)
        if ok and type(value) == "number" then return value end
    end
    if os and os.clock then return math.floor(os.clock() * 1000) end
    return 0
end

local function playerCacheKey(player)
    if player and player.getUsername then
        local ok, username = pcall(function() return player:getUsername() end)
        if ok and username then return tostring(username) end
    end
    return tostring(player)
end

local function countSellTransactionsSinglePass(player, shopItem)
    if not player or not shopItem or not shopItem.isSell or type(shopItem.items) ~= "table" then
        return 0
    end

    local requiredByType = {}
    for _, itemData in ipairs(shopItem.items) do
        if itemData and itemData.type then
            local needed = math.max(1, math.floor(tonumber(itemData.count) or 1))
            requiredByType[itemData.type] = needed
        end
    end

    local counts = {}
    for itemType in pairs(requiredByType) do counts[itemType] = 0 end

    local inventories = MSR.ShopData.getAllInventories(player)
    for _, inventory in ipairs(inventories or {}) do
        local items = inventory and inventory.getItems and inventory:getItems() or nil
        if items then
            for index = 0, items:size() - 1 do
                local inventoryItem = items:get(index)
                local fullType = inventoryItem and inventoryItem:getFullType() or nil
                if fullType and requiredByType[fullType]
                        and not MSR.ShopData.isProtectedFromSale(player, inventoryItem) then
                    counts[fullType] = (counts[fullType] or 0) + 1
                end
            end
        end
    end

    if shopItem.sellAny then
        local total = 0
        for itemType, needed in pairs(requiredByType) do
            total = total + math.floor((counts[itemType] or 0) / needed)
        end
        return total
    end

    local minimum = nil
    for itemType, needed in pairs(requiredByType) do
        local possible = math.floor((counts[itemType] or 0) / needed)
        minimum = minimum and math.min(minimum, possible) or possible
    end
    return minimum or 0
end

local function installShopPerformancePatch()
    local ShopData = MSR and MSR.ShopData
    if not ShopData or type(ShopData.canPurchase) ~= "function" then return false end
    if ShopData._partnerSellPerformanceInstalled then return true end

    local originalCanPurchase = ShopData.canPurchase
    local availabilityCache = {}

    local function invalidate(player, itemId)
        if not player then
            availabilityCache = {}
            return
        end
        local key = playerCacheKey(player)
        if not itemId then
            availabilityCache[key] = nil
        elseif availabilityCache[key] then
            availabilityCache[key][itemId] = nil
        end
    end

    ShopData.calculateSellCount = function(player, shopItem)
        return countSellTransactionsSinglePass(player, shopItem)
    end

    ShopData.canPurchase = function(player, itemId)
        local shopItem = ShopData.getItem(itemId)
        if not shopItem or not shopItem.isSell then
            return originalCanPurchase(player, itemId)
        end

        local key = playerCacheKey(player)
        local perPlayer = availabilityCache[key]
        if not perPlayer then
            perPlayer = {}
            availabilityCache[key] = perPlayer
        end

        local now = nowMilliseconds()
        local cached = perPlayer[itemId]
        if cached and now < cached.expiresAt then
            return cached.allowed, cached.reason
        end

        local allowed = countSellTransactionsSinglePass(player, shopItem) > 0
        local reason = allowed and nil or
            (getText("UI_Shop_NotEnoughItemsExchange") or "Not enough items to exchange")
        perPlayer[itemId] = {
            allowed = allowed,
            reason = reason,
            expiresAt = now + SELL_CACHE_MS,
        }
        return allowed, reason
    end

    local originalDoSellMultiple = ShopData.doSellMultiple
    if type(originalDoSellMultiple) == "function" then
        ShopData.doSellMultiple = function(player, shopItem, times)
            local sold = originalDoSellMultiple(player, shopItem, times)
            invalidate(player)
            return sold
        end
    end

    -- Single-player sales add the reward directly instead of calling
    -- doSellMultiple, so wallet changes also invalidate the short-lived cache.
    local originalAddCores = ShopData.addCores
    if type(originalAddCores) == "function" then
        ShopData.addCores = function(player, count)
            local result = originalAddCores(player, count)
            invalidate(player)
            return result
        end
    end

    ShopData.invalidatePartnerSellCache = invalidate
    ShopData._partnerSellPerformanceInstalled = true
    print(TAG .. " single-pass sell checks and 750ms UI cache enabled")
    return true
end

local function getWellLevel(refugeData)
    local upgrades = refugeData and refugeData.upgrades
    local level = upgrades and tonumber(upgrades[WELL_UPGRADE_ID]) or 0
    return math.max(0, math.min(3, math.floor(level or 0)))
end

local function getWellLevelData(refugeData)
    return WELL_LEVELS[getWellLevel(refugeData)]
end

local function getFluidCapacity(fluidContainer)
    if not fluidContainer or not fluidContainer.getCapacity then return nil end
    local ok, capacity = pcall(function() return fluidContainer:getCapacity() end)
    if ok then return tonumber(capacity) end
    return nil
end

local function syncWell(well)
    if not well then return end
    if MSR.UpgradeLogic and MSR.UpgradeLogic.syncObjectToClients then
        MSR.UpgradeLogic.syncObjectToClients(well, true)
    elseif well.transmitModData then
        well:transmitModData()
    end
    if well.sync then pcall(function() well:sync() end) end
end

local function applyWellCapacity(refugeData, well)
    local levelData = getWellLevelData(refugeData)
    if not levelData then return true end
    if MSR.Env and MSR.Env.hasServerAuthority and not MSR.Env.hasServerAuthority() then
        return true
    end

    well = well or (MSR.SpatialWell and MSR.SpatialWell.Find and MSR.SpatialWell.Find(refugeData))
    local fluidContainer = well and well.getFluidContainer and well:getFluidContainer() or nil
    if not fluidContainer then return false, "Spatial Well fluid container is unavailable" end

    local currentCapacity = getFluidCapacity(fluidContainer)
    if currentCapacity and currentCapacity >= levelData.capacityLiters then return true end

    local ok, err = pcall(function() fluidContainer:setCapacity(levelData.capacityLiters) end)
    if not ok then return false, tostring(err) end

    local md = well:getModData()
    md.partnerSpatialWellUpgradeLevel = getWellLevel(refugeData)
    md.partnerSpatialWellCapacityLiters = levelData.capacityLiters
    md.partnerSpatialWellDailyLiters = levelData.dailyLiters
    syncWell(well)
    return true
end

local function installWellUpgradeDefinition()
    local UpgradeData = MSR and MSR.UpgradeData
    if not UpgradeData or type(UpgradeData.initialize) ~= "function" then return false end

    UpgradeData.initialize()
    if not UpgradeData._upgrades or not UpgradeData._categories then return false end

    if not UpgradeData._upgrades[WELL_UPGRADE_ID] then
        UpgradeData._upgrades[WELL_UPGRADE_ID] = {
            id = WELL_UPGRADE_ID,
            name = "UI_Upgrade_PartnerSpatialWell",
            icon = "Item_BucketEmpty",
            category = "shelter",
            maxLevel = 3,
            dependencies = {},
            levels = {
                [1] = {
                    description = "UI_Upgrade_PartnerSpatialWell_L1",
                    requirements = { { type = "Base.MagicalCore", count = 200 } },
                },
                [2] = {
                    description = "UI_Upgrade_PartnerSpatialWell_L2",
                    requirements = { { type = "Base.MagicalCore", count = 500 } },
                },
                [3] = {
                    description = "UI_Upgrade_PartnerSpatialWell_L3",
                    requirements = { { type = "Base.MagicalCore", count = 1000 } },
                },
            },
        }
        UpgradeData._categories.shelter = UpgradeData._categories.shelter or {}
        table.insert(UpgradeData._categories.shelter, WELL_UPGRADE_ID)
        table.sort(UpgradeData._categories.shelter)
        print(TAG .. " Spatial Well upgrade added to shelter category")
    end

    if not UpgradeData._partnerWellExactCostInstalled then
        local originalGetRequirements = UpgradeData.getNextLevelRequirements
        UpgradeData.getNextLevelRequirements = function(player, upgradeId)
            if upgradeId == WELL_UPGRADE_ID then
                local currentLevel = UpgradeData.getPlayerUpgradeLevel(player, WELL_UPGRADE_ID)
                local levelData = WELL_LEVELS[currentLevel + 1]
                if not levelData then return nil end
                return { { type = "Base.MagicalCore", count = levelData.coreCost } }
            end
            return originalGetRequirements(player, upgradeId)
        end
        UpgradeData._partnerWellExactCostInstalled = true
    end

    if not UpgradeData._partnerWellUnlockInstalled then
        local originalIsUnlocked = UpgradeData.isUpgradeUnlocked
        UpgradeData.isUpgradeUnlocked = function(player, upgradeId)
            if upgradeId == WELL_UPGRADE_ID then
                local playerObj = MSR.resolvePlayer and MSR.resolvePlayer(player) or player
                local refugeData = playerObj and MSR.Data and MSR.Data.GetRefugeData and
                    MSR.Data.GetRefugeData(playerObj) or nil
                return refugeData ~= nil and MSR.SpatialWell.IsBuilt(refugeData)
            end
            return originalIsUnlocked(player, upgradeId)
        end
        UpgradeData._partnerWellUnlockInstalled = true
    end

    return true
end

local function getWellForPlayer(player)
    local playerObj = MSR.resolvePlayer and MSR.resolvePlayer(player) or player
    local refugeData = playerObj and MSR.Data and MSR.Data.GetRefugeData and
        MSR.Data.GetRefugeData(playerObj) or nil
    if not refugeData or not MSR.SpatialWell.IsBuilt(refugeData) then
        return nil, nil, nil, "Build the Spatial Well first"
    end

    local well = MSR.SpatialWell.EnsureForRefuge(refugeData)
    if not well then well = MSR.SpatialWell.Find(refugeData) end
    local fluidContainer = well and well.getFluidContainer and well:getFluidContainer() or nil
    if not fluidContainer then return refugeData, well, nil, "Spatial Well is unavailable" end
    return refugeData, well, fluidContainer, nil
end

local function installWellUpgradeHandler()
    local UpgradeLogic = MSR and MSR.UpgradeLogic
    if not UpgradeLogic or type(UpgradeLogic.registerHandler) ~= "function" then return false end
    if UpgradeLogic.hasHandler and UpgradeLogic.hasHandler(WELL_UPGRADE_ID) then return true end

    UpgradeLogic.registerHandler(WELL_UPGRADE_ID, {
        validate = function(player, targetLevel)
            if not WELL_LEVELS[targetLevel] then return false, "Invalid Spatial Well level" end
            local _, _, fluidContainer, err = getWellForPlayer(player)
            if not fluidContainer then return false, err end
            return true, nil
        end,

        prepare = function(player, targetLevel)
            local refugeData, well, fluidContainer, err = getWellForPlayer(player)
            if not fluidContainer then return false, err end
            return {
                upgradeId = WELL_UPGRADE_ID,
                targetLevel = targetLevel,
                previousLevel = MSR.UpgradeData.getPlayerUpgradeLevel(player, WELL_UPGRADE_ID),
                previousCapacity = getFluidCapacity(fluidContainer),
                refugeData = refugeData,
                well = well,
                fluidContainer = fluidContainer,
            }
        end,

        commit = function(player, targetLevel, operation)
            local levelData = WELL_LEVELS[targetLevel]
            if not levelData or not operation or not operation.fluidContainer then
                return false, "Spatial Well upgrade state is unavailable"
            end

            local oldCapacity = operation.previousCapacity
            if not oldCapacity or oldCapacity < levelData.capacityLiters then
                local capacityOk, capacityError = pcall(function()
                    operation.fluidContainer:setCapacity(levelData.capacityLiters)
                end)
                if not capacityOk then return false, tostring(capacityError) end

                local appliedCapacity = getFluidCapacity(operation.fluidContainer)
                if appliedCapacity and appliedCapacity < levelData.capacityLiters then
                    if oldCapacity then
                        pcall(function() operation.fluidContainer:setCapacity(oldCapacity) end)
                    end
                    return false, "Spatial Well capacity did not update"
                end
            end

            if not MSR.UpgradeData.setPlayerUpgradeLevel(player, WELL_UPGRADE_ID, targetLevel) then
                if oldCapacity then
                    pcall(function() operation.fluidContainer:setCapacity(oldCapacity) end)
                end
                return false, "Failed to save Spatial Well upgrade level"
            end

            local md = operation.well:getModData()
            md.partnerSpatialWellUpgradeLevel = targetLevel
            md.partnerSpatialWellCapacityLiters = levelData.capacityLiters
            md.partnerSpatialWellDailyLiters = levelData.dailyLiters
            syncWell(operation.well)
            return true, {
                capacityLiters = levelData.capacityLiters,
                dailyLiters = levelData.dailyLiters,
            }
        end,

        reconcile = function(player, _targetLevel, operation)
            local refugeData = operation and operation.refugeData
            if not refugeData then
                refugeData = MSR.Data and MSR.Data.GetRefugeData and MSR.Data.GetRefugeData(player) or nil
            end
            if not refugeData then return false, "Refuge data is unavailable" end
            return applyWellCapacity(refugeData, operation and operation.well or nil)
        end,
    })

    return true
end

local function installWellRuntimePatch()
    local SpatialWell = MSR and MSR.SpatialWell
    local Config = MSR and MSR.Config
    if not SpatialWell or not Config or not Config.SPATIAL_WELL then return false end
    if SpatialWell._partnerUpgradeRuntimeInstalled then return true end
    if type(SpatialWell.EnsureForRefuge) ~= "function" or type(SpatialWell.ProcessRefill) ~= "function" then
        return false
    end

    local originalEnsureForRefuge = SpatialWell.EnsureForRefuge
    SpatialWell.EnsureForRefuge = function(refugeData)
        local well = originalEnsureForRefuge(refugeData)
        if well and getWellLevel(refugeData) > 0 then
            local ok, err = applyWellCapacity(refugeData, well)
            if not ok then print(TAG .. " capacity reconcile failed: " .. tostring(err)) end
        end
        return well
    end

    local originalProcessRefill = SpatialWell.ProcessRefill
    SpatialWell.ProcessRefill = function(refugeData)
        local levelData = getWellLevelData(refugeData)
        if not levelData then return originalProcessRefill(refugeData) end

        local previousRate = Config.SPATIAL_WELL.REFILL_PER_HOUR
        Config.SPATIAL_WELL.REFILL_PER_HOUR = levelData.dailyLiters / 24
        local ok, result, extra = pcall(originalProcessRefill, refugeData)
        Config.SPATIAL_WELL.REFILL_PER_HOUR = previousRate
        if not ok then error(result) end
        return result, extra
    end

    SpatialWell._partnerUpgradeRuntimeInstalled = true
    print(TAG .. " Spatial Well capacity/refill runtime enabled")
    return true
end

local function installAll()
    local shopReady = installShopPerformancePatch()
    local definitionReady = installWellUpgradeDefinition()
    local handlerReady = installWellUpgradeHandler()
    local runtimeReady = installWellRuntimePatch()
    return shopReady and definitionReady and handlerReady and runtimeReady
end

installAll()

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(installAll) end
    if Events.OnServerStarted then Events.OnServerStarted.Add(installAll) end
    if Events.OnTick then
        local attempts = 0
        local function retryInstall()
            attempts = attempts + 1
            if installAll() or attempts >= 300 then Events.OnTick.Remove(retryInstall) end
        end
        Events.OnTick.Add(retryInstall)
    end
end

