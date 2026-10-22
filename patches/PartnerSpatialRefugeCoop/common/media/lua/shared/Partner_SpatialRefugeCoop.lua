-- Partner Shared Spatial Refuge + Personal Wallet
-- Project Zomboid 42.21 coop compatibility layer.

local PATCH_TAG = "[PartnerSpatialRefugeCoop]"
local STATE_TABLE = "PartnerSpatialRefugeCoopState"
local PERSONAL_BALANCE_KEY = "PartnerMSRPersonalCoreBalance"
local PERSONAL_WALLET_VERSION_KEY = "PartnerMSRPersonalWalletVersion"
local PERSONAL_WALLET_VERSION = 1
local ORIGINAL_SHARED_WALLET_TABLE = "MSR_ShopSharedWallet"
local ORIGINAL_SHARED_BALANCE_KEY = "MSR_MagicalCoreBalance"
local PURCHASE_PRICE_MULTIPLIER = 2.0

-- Skill Book Expansion uses the same five-book slipcase system as B42 vanilla.
-- Custom products have explicit final costs for the 2x economy.
local EXPANDED_SKILL_BOOK_SETS = {
    { id = "axe", name = "UI_Shop_BookAxeSet", item = "SkillBookExpansionB42.BookAxeSet" },
    { id = "blunt", name = "UI_Shop_BookBluntSet", item = "SkillBookExpansionB42.BookBluntSet" },
    { id = "small_blunt", name = "UI_Shop_BookSmallBluntSet", item = "SkillBookExpansionB42.BookSmallBluntSet" },
    { id = "small_blade", name = "UI_Shop_BookSmallBladeSet", item = "SkillBookExpansionB42.BookSmallBladeSet" },
    { id = "spear", name = "UI_Shop_BookSpearSet", item = "SkillBookExpansionB42.BookSpearSet" },
    { id = "sprinting", name = "UI_Shop_BookSprintingSet", item = "SkillBookExpansionB42.BookSprintingSet" },
    { id = "nimble", name = "UI_Shop_BookNimbleSet", item = "SkillBookExpansionB42.BookNimbleSet" },
    { id = "sneaking", name = "UI_Shop_BookSneakingSet", item = "SkillBookExpansionB42.BookSneakingSet" },
    { id = "lightfooted", name = "UI_Shop_BookLightfootedSet", item = "SkillBookExpansionB42.BookLightfootedSet" },
    { id = "strength", name = "UI_Shop_BookStrengthSet", item = "SkillBookExpansionB42.BookStrengthSet" },
    { id = "fitness", name = "UI_Shop_BookFitnessSet", item = "SkillBookExpansionB42.BookFitnessSet" },
}

-- B42.21 vanilla jewelry and watches that the original shop does not accept.
-- Existing sell entries are checked at runtime, so a later Workshop update can
-- add any of these without causing duplicate Sell All rewards.
local GENERAL_ACCESSORY_TYPES = {
    "Base.Bracelet_LeftFriendshipTINT",
    "Base.Bracelet_RightFriendshipTINT",
    "Base.Earring_BirdSkull",
    "Base.Earring_BoarTusk",
    "Base.Earring_Dangly_Ruby",
    "Base.Earring_Pearl",
    "Base.Earring_Stone_Emerald",
    "Base.Necklace_BoarTusk",
    "Base.Necklace_BoarTusk_Multi",
    "Base.Necklace_Choker",
    "Base.Necklace_Choker_Amber",
    "Base.Necklace_Choker_Bone",
    "Base.Necklace_Choker_Diamond",
    "Base.Necklace_DogTag",
    "Base.Necklace_DogTag_Female",
    "Base.Necklace_DogTag_Male",
    "Base.Necklace_SkullMammal",
    "Base.Necklace_SkullMammal_Multi",
    "Base.Necklace_SkullSmall",
    "Base.Necklace_SkullSmall_Multi",
    "Base.Necklace_Teeth",
    "Base.NecklaceLong_Amber",
    "Base.NecklaceLong_SkullMammal",
    "Base.NecklaceLong_SkullMammal_Multi",
    "Base.NecklaceLong_SkullSmall",
    "Base.NecklaceLong_SkullSmall_Multi",
    "Base.NecklaceLong_Teeth",
    "Base.WristWatch_Left_ClassicBlack",
    "Base.WristWatch_Right_ClassicBlack",
    "Base.WristWatch_Left_ClassicBrown",
    "Base.WristWatch_Right_ClassicBrown",
    "Base.WristWatch_Left_ClassicMilitary",
    "Base.WristWatch_Right_ClassicMilitary",
    "Base.WristWatch_Left_DigitalBlack",
    "Base.WristWatch_Right_DigitalBlack",
    "Base.WristWatch_Left_DigitalRed",
    "Base.WristWatch_Right_DigitalRed",
    "Base.WristWatch_Left_DigitalDress",
    "Base.WristWatch_Right_DigitalDress",
}

local PREMIUM_ACCESSORY_TYPES = {
    "Base.Ring_Left_MiddleFinger_Signet",
    "Base.Ring_Left_RingFinger_Signet",
    "Base.Ring_Right_MiddleFinger_Signet",
    "Base.Ring_Right_RingFinger_Signet",
    "Base.WristWatch_Left_ClassicGold",
    "Base.WristWatch_Right_ClassicGold",
    "Base.WristWatch_Left_Expensive",
    "Base.WristWatch_Right_Expensive",
}

-- B42.21 vanilla eyewear. This includes prescription/cosmetic variants,
-- goggles, eye patches, monocles, and novelty glasses so none of the small
-- face-slot loot becomes unsellable clutter.
local EYEWEAR_TYPES = {
    "Base.Glasses",
    "Base.Glasses_Prescription",
    "Base.Glasses_Aviators",
    "Base.Glasses_Prescription_Aviators",
    "Base.Glasses_Normal",
    "Base.Glasses_Cosmetic_Normal",
    "Base.Glasses_Reading",
    "Base.Glasses_SafetyGoggles",
    "Base.Glasses_Shooting",
    "Base.Glasses_Prescription_Shooting",
    "Base.Glasses_SkiGoggles",
    "Base.Glasses_Sun",
    "Base.Glasses_Prescription_Sun",
    "Base.Glasses_SwimmingGoggles",
    "Base.Glasses_Eyepatch_Left",
    "Base.Glasses_Eyepatch_Right",
    "Base.Glasses_CatsEye",
    "Base.Glasses_CatsEye_Sun",
    "Base.Glasses_Cosmetic_CatsEye",
    "Base.Glasses_Prescription_CatsEye_Sun",
    "Base.Glasses_Normal_HornRimmed",
    "Base.Glasses_Cosmetic_Normal_HornRimmed",
    "Base.Glasses_JackieO",
    "Base.Glasses_Prescription_JackieO",
    "Base.Glasses_Macho",
    "Base.Glasses_Round_Normal",
    "Base.Glasses_Round_Shades",
    "Base.Glasses_Cosmetic_Round_Normal",
    "Base.Glasses_Prescription_Round_Shades",
    "Base.Glasses_70s_Gold",
    "Base.Glasses_Cosmetic_70s_Gold",
    "Base.Glasses_Round_HoloSkulls",
    "Base.Glasses_OldWeldingGoggles",
    "Base.Glasses_HalfMoon",
    "Base.Glasses_Cosmetic_HalfMoon",
    "Base.Glasses_MonocleLeft",
    "Base.Glasses_MonocleRight",
    "Base.Glasses_Cosmetic_MonocleLeft",
    "Base.Glasses_Cosmetic_MonocleRight",
    "Base.Glasses_SunCheap",
    "Base.Glasses_3dGlasses",
    "Base.Glasses_Groucho",
    "Base.Glasses_Venetian",
    "Base.Glasses_NewWave",
    "Base.Glasses_Novelty_Xray",
}

-- Every B42.21 vanilla item assigned to the underwear top/bottom slots.
-- ScriptManager validation below skips an entry cleanly if the game removes
-- or renames it in a later build.
local UNDERWEAR_TYPES = {
    "Base.AthleticCup",
    "Base.BoobTube",
    "Base.BoobTubeSmall",
    "Base.Bra_Strapless_Black",
    "Base.Bra_Strapless_RedSpots",
    "Base.Bra_Strapless_White",
    "Base.Bra_Straps_Black",
    "Base.Bra_Straps_White",
    "Base.Underpants_Black",
    "Base.Underpants_RedSpots",
    "Base.Underpants_White",
    "Base.Boxers_Hearts",
    "Base.Boxers_Silk_Black",
    "Base.Boxers_Silk_Red",
    "Base.Boxers_RedStripes",
    "Base.Boxers_White",
    "Base.Briefs_White",
    "Base.Briefs_AnimalPrints",
    "Base.Briefs_SmallTrunks_Black",
    "Base.Briefs_SmallTrunks_Blue",
    "Base.Briefs_SmallTrunks_Red",
    "Base.Briefs_SmallTrunks_WhiteTINT",
    "Base.Corset_Black",
    "Base.Corset_Red",
    "Base.Corset",
    "Base.Corset_Medical",
    "Base.Bra_Strapless_AnimalPrint",
    "Base.Bra_Straps_AnimalPrint",
    "Base.Bra_Straps_FrillyBlack",
    "Base.Bra_Strapless_FrillyBlack",
    "Base.Bra_Straps_FrillyPink",
    "Base.Bra_Strapless_FrillyPink",
    "Base.Bra_Straps_FrillyRed",
    "Base.Bra_Strapless_FrillyRed",
    "Base.Underpants_AnimalPrint",
    "Base.FrillyUnderpants_Black",
    "Base.FrillyUnderpants_Pink",
    "Base.FrillyUnderpants_Red",
    "Base.Briefs_Burlap",
    "Base.Briefs_Denim",
    "Base.Briefs_Garbage",
    "Base.Briefs_Hide",
    "Base.Briefs_Rag",
    "Base.Briefs_Tarp",
    "Base.Bra_Strapless_Hide",
    "Base.Bra_Straps_Hide",
    "Base.Underpants_Hide",
    "Base.StockingsBlack",
    "Base.StockingsBlackTrans",
    "Base.StockingsBlackSemiTrans",
    "Base.StockingsWhite",
    "Base.TightsBlack",
    "Base.TightsBlackTrans",
    "Base.TightsBlackSemiTrans",
    "Base.TightsFishnets",
}

local WALLET_TYPES = {
    "Base.Wallet",
    "Base.Wallet_Female",
    "Base.Wallet_Male",
    "Base.Wallet_Hide",
}

local CREDIT_CARD_TYPES = {
    "Base.CreditCard",
    "Base.CreditCard_Stolen",
}

local ID_CARD_TYPES = {
    "Base.IDcard",
    "Base.IDcard_Stolen",
    "Base.IDcard_Blank",
    "Base.IDcard_Female",
    "Base.IDcard_Male",
}

local function runningAsServer()
    return type(isServer) == "function" and isServer()
end

local function runningAsPureClient()
    return type(isClient) == "function" and isClient() and not runningAsServer()
end

local function shallowCopy(source)
    local result = {}
    if source then
        for key, value in pairs(source) do
            result[key] = value
        end
    end
    return result
end

local function refreshSharedRefugeClient(player)
    if not runningAsPureClient() then return end
    player = player or (getPlayer and getPlayer())
    if not player then return end

    if MSR and type(MSR.InvalidateBoundsCache) == "function" then
        pcall(function() MSR.InvalidateBoundsCache(player) end)
    end
    if MSR and MSR.EffectSystem and type(MSR.EffectSystem.markDirty) == "function" then
        pcall(function() MSR.EffectSystem.markDirty(player) end)
    end
    if MSR and type(MSR.InvalidateRelicContainerCache) == "function" then
        pcall(function() MSR.InvalidateRelicContainerCache() end)
    end

    -- Keep an already-open upgrade window in sync with an upgrade bought by
    -- the other player.  The window is optional, so every call is guarded.
    local window = rawget(_G, "MSR_UpgradeWindow")
    if window and window.instance then
        pcall(function() window.instance:refreshUpgradeList() end)
        pcall(function() window.instance:refreshCurrentUpgrade() end)
    end
end

local function getPatchState()
    if not ModData or type(ModData.getOrCreate) ~= "function" then return nil end
    local ok, state = pcall(function() return ModData.getOrCreate(STATE_TABLE) end)
    return ok and state or nil
end

local function chooseSharedRefuge(Data, registry)
    if not registry then return nil, nil end

    local state = getPatchState()
    if state and state.ownerUsername and registry[state.ownerUsername] then
        return state.ownerUsername, registry[state.ownerUsername]
    end

    local bestName, bestData, bestSlot
    for username, refugeData in pairs(registry) do
        if type(refugeData) == "table" then
            local slot = nil
            if Data.GetRefugeSlotFromCoordinates then
                slot = Data.GetRefugeSlotFromCoordinates(refugeData.centerX, refugeData.centerY)
            end
            slot = tonumber(slot) or 2147483647

            if not bestData or slot < bestSlot or
                    (slot == bestSlot and tostring(username) < tostring(bestName)) then
                bestName = username
                bestData = refugeData
                bestSlot = slot
            end
        end
    end

    if bestData and state then
        state.ownerUsername = bestName
        state.ownerRefugeId = bestData.refugeId
        if runningAsServer() and ModData.transmit then
            pcall(function() ModData.transmit(STATE_TABLE) end)
        end
        print(PATCH_TAG .. " shared refuge owner=" .. tostring(bestName) ..
            " slot=" .. tostring(bestSlot))
    end

    return bestName, bestData
end

local function installSharedRefugePatch()
    if not MSR or not MSR.Data then return false end
    local Data = MSR.Data
    if Data._partnerSharedRefugeInstalled then return true end
    if type(Data.GetRefugeDataByUsername) ~= "function" or
            type(Data.HandleModDataResponse) ~= "function" then
        return false
    end

    local originalGetRefugeDataByUsername = Data.GetRefugeDataByUsername
    local originalHandleModDataResponse = Data.HandleModDataResponse

    -- Server authority: every player resolves to the first allocated refuge slot.
    -- Existing secondary refuges are left untouched as a reversible safety measure.
    Data.GetRefugeDataByUsername = function(username)
        if runningAsServer() then
            local registry = Data.GetRefugeRegistry and Data.GetRefugeRegistry() or nil
            local _, sharedRefuge = chooseSharedRefuge(Data, registry)
            if sharedRefuge then return sharedRefuge end
        end
        return originalGetRefugeDataByUsername(username)
    end

    -- The base mod rejects another owner's refuge packet.  Give each client a
    -- local view bearing its own username while preserving the shared refugeId,
    -- coordinates, tier and upgrade table sent by the server.
    Data.HandleModDataResponse = function(args, player)
        if runningAsPureClient() and args and args.refugeData then
            player = player or (getPlayer and getPlayer())
            local username = player and player:getUsername() or nil
            if username and args.refugeData.username ~= username then
                local adaptedArgs = shallowCopy(args)
                local adaptedRefuge = shallowCopy(args.refugeData)
                adaptedRefuge.partnerSharedOwner = args.refugeData.username
                adaptedRefuge.username = username
                adaptedArgs.refugeData = adaptedRefuge
                local result = originalHandleModDataResponse(adaptedArgs, player)
                refreshSharedRefugeClient(player)
                return result
            end
        end
        local result = originalHandleModDataResponse(args, player)
        refreshSharedRefugeClient(player)
        return result
    end

    Data._partnerSharedRefugeInstalled = true
    print(PATCH_TAG .. " shared refuge and shared upgrades enabled")
    return true
end

local function installSharedUpgradeBroadcast()
    if not runningAsServer() or not MSR_Server or
            type(MSR_Server.HandleFeatureUpgradeRequest) ~= "function" then
        return not runningAsServer()
    end
    if MSR_Server._partnerSharedUpgradeBroadcastInstalled then return true end

    local originalHandler = MSR_Server.HandleFeatureUpgradeRequest
    MSR_Server.HandleFeatureUpgradeRequest = function(player, args)
        local upgradeId = args and args.upgradeId
        local beforeLevel = nil
        if player and upgradeId and MSR and MSR.UpgradeData and
                type(MSR.UpgradeData.getPlayerUpgradeLevel) == "function" then
            beforeLevel = MSR.UpgradeData.getPlayerUpgradeLevel(player, upgradeId)
        end

        local result = originalHandler(player, args)

        local afterLevel = nil
        if player and upgradeId and MSR and MSR.UpgradeData and
                type(MSR.UpgradeData.getPlayerUpgradeLevel) == "function" then
            afterLevel = MSR.UpgradeData.getPlayerUpgradeLevel(player, upgradeId)
        end

        -- Broadcast only after an authoritative level increase.  Do not send
        -- FeatureUpgradeComplete to bystanders: that command finalizes the
        -- purchaser's transaction.  ModDataResponse is the safe snapshot-only
        -- command and our client wrapper adapts the shared owner's username.
        if afterLevel and (not beforeLevel or afterLevel > beforeLevel) and
                MSR.Data and type(MSR.Data.GetRefugeData) == "function" and
                type(MSR.Data.SerializeRefugeData) == "function" then
            local refugeData = MSR.Data.GetRefugeData(player)
            local snapshot = MSR.Data.SerializeRefugeData(refugeData)
            local players = getOnlinePlayers and getOnlinePlayers() or nil
            if snapshot and players then
                for i = 0, players:size() - 1 do
                    local target = players:get(i)
                    if target then
                        sendServerCommand(target, MSR.Config.COMMAND_NAMESPACE,
                            MSR.Config.COMMANDS.MODDATA_RESPONSE, {
                                refugeData = snapshot,
                                partnerSharedUpgrade = upgradeId,
                                partnerSharedLevel = afterLevel
                            })
                    end
                end
                print(PATCH_TAG .. " shared upgrade synchronized: " ..
                    tostring(upgradeId) .. " level=" .. tostring(afterLevel))
            end
        end

        return result
    end

    MSR_Server._partnerSharedUpgradeBroadcastInstalled = true
    print(PATCH_TAG .. " shared upgrade broadcast enabled")
    return true
end

local function getPlayerModData(player)
    if not player or type(player.getModData) ~= "function" then return nil end
    local ok, data = pcall(function() return player:getModData() end)
    return ok and data or nil
end

local function transmitPlayerModData(player)
    if player and type(player.transmitModData) == "function" then
        pcall(function() player:transmitModData() end)
    end
end

local function getMigrationSeed()
    local state = getPatchState()
    if not state then return 0 end
    if state.personalWalletSeed == nil then
        local shared = ModData.getOrCreate(ORIGINAL_SHARED_WALLET_TABLE)
        state.personalWalletSeed = math.max(0,
            math.floor(tonumber(shared and shared[ORIGINAL_SHARED_BALANCE_KEY]) or 0))
        state.personalWalletMigrationVersion = PERSONAL_WALLET_VERSION
        if runningAsServer() and ModData.transmit then
            pcall(function() ModData.transmit(STATE_TABLE) end)
        end
        print(PATCH_TAG .. " captured shared-wallet migration seed=" ..
            tostring(state.personalWalletSeed))
    end
    return math.max(0, math.floor(tonumber(state.personalWalletSeed) or 0))
end

-- Trait reshaping is a separate shop currency path, not a normal catalog purchase.
-- Apply the new 200-cores-per-point rate on both client and authoritative host.
local function installTraitEconomyPatch()
    pcall(require, "MSR_ReshapeData")
    if MSR and MSR.ReshapeData then
        MSR.ReshapeData.CORE_PER_TRAIT_POINT = 200
        return true
    end
    return false
end

local function installPersonalWalletPatch()
    if not MSR or not MSR.ShopData then return false end
    local ShopData = MSR.ShopData
    if ShopData._partnerPersonalWalletInstalled then return true end

    local function ensurePersonalWallet(player)
        if runningAsPureClient() then
            return math.max(0, math.floor(tonumber(ShopData._clientCoreBalance) or 0))
        end
        local data = getPlayerModData(player)
        if not data then return 0 end

        if tonumber(data[PERSONAL_WALLET_VERSION_KEY]) ~= PERSONAL_WALLET_VERSION or
                data[PERSONAL_BALANCE_KEY] == nil then
            local legacyPersonal = tonumber(data[ORIGINAL_SHARED_BALANCE_KEY])
            local startingBalance = legacyPersonal
            if startingBalance == nil then startingBalance = getMigrationSeed() end
            data[PERSONAL_BALANCE_KEY] = math.max(0, math.floor(tonumber(startingBalance) or 0))
            data[PERSONAL_WALLET_VERSION_KEY] = PERSONAL_WALLET_VERSION
            transmitPlayerModData(player)
            print(PATCH_TAG .. " personal wallet initialized for " ..
                tostring(player:getUsername()) .. " balance=" ..
                tostring(data[PERSONAL_BALANCE_KEY]))
        end

        return math.max(0, math.floor(tonumber(data[PERSONAL_BALANCE_KEY]) or 0))
    end

    local function setPersonalBalance(player, balance)
        if not player or runningAsPureClient() then return false end
        local data = getPlayerModData(player)
        if not data then return false end
        ensurePersonalWallet(player)
        data[PERSONAL_BALANCE_KEY] = math.max(0, math.floor(tonumber(balance) or 0))
        data[PERSONAL_WALLET_VERSION_KEY] = PERSONAL_WALLET_VERSION
        transmitPlayerModData(player)
        return true
    end

    ShopData.ensureCoreWallet = ensurePersonalWallet

    ShopData.setCoreBalance = function(player, balance)
        return setPersonalBalance(player, balance)
    end

    ShopData.getCoreBalance = function(player)
        if runningAsPureClient() and ShopData._clientCoreBalance ~= nil then
            return math.max(0, math.floor(tonumber(ShopData._clientCoreBalance) or 0))
        end
        return ensurePersonalWallet(player)
    end

    ShopData.addCores = function(player, count)
        if runningAsPureClient() then return false end
        local amount = math.max(0, math.floor(tonumber(count) or 0))
        if amount <= 0 then return true end
        return setPersonalBalance(player, ensurePersonalWallet(player) + amount)
    end

    ShopData.trySpendCores = function(player, count)
        if runningAsPureClient() then return false end
        local amount = math.max(0, math.floor(tonumber(count) or 0))
        local balance = ensurePersonalWallet(player)
        if amount > balance then return false end
        return setPersonalBalance(player, balance - amount)
    end

    ShopData._partnerPersonalWalletInstalled = true
    print(PATCH_TAG .. " per-player shop wallets enabled")
    return true
end

local function installShopCatalogPatch()
    if not MSR or not MSR.ShopData then return false end
    local ShopData = MSR.ShopData
    if ShopData._partnerCatalogHookInstalled then return true end
    if type(ShopData.initialize) ~= "function" then return false end

    local function isItemValid(fullType)
        if not ScriptManager or not ScriptManager.instance then return true end
        return ScriptManager.instance:getItem(fullType) ~= nil
    end

    local function applyCatalogChanges()
        if ShopData._partnerCatalogInstalled then return true end
        if not ShopData._initialized or not ShopData._items or not ShopData._categories then
            return false
        end

        -- Raise only items that players buy from the normal shop. Sell rewards,
        -- lottery entries/costs, rotation refresh costs, and refuge upgrades are
        -- deliberately left unchanged. Rotation discounts inherit these prices.
        local purchasePriceCount = 0
        for _, shopItem in pairs(ShopData._items) do
            local basePrice = tonumber(shopItem and shopItem.price)
            if shopItem and not shopItem.isSell and shopItem.category ~= "lottery"
                and basePrice and basePrice > 0 then
                shopItem.price = math.ceil(basePrice * PURCHASE_PRICE_MULTIPLIER)
                purchasePriceCount = purchasePriceCount + 1
            end
        end

        local moneyBundle = ShopData._items.sell_money_bundle
        if moneyBundle then moneyBundle.price = 50 end

        local stockCertificate = ShopData._items.sell_stock_certificate
        if stockCertificate then stockCertificate.price = 200 end

        local alreadySellable = {}
        for _, existing in pairs(ShopData._items) do
            if existing and existing.isSell and existing.items then
                for _, itemData in ipairs(existing.items) do
                    if itemData and itemData.type then
                        alreadySellable[itemData.type] = true
                    end
                end
            end
        end

        local function addSellEntry(id, name, description, icon, price, itemTypes)
            if ShopData._items[id] then return 0 end
            local validItems = {}
            for _, fullType in ipairs(itemTypes) do
                if not alreadySellable[fullType] and isItemValid(fullType) then
                    table.insert(validItems, { type = fullType, count = 1 })
                    alreadySellable[fullType] = true
                end
            end
            if #validItems == 0 then return 0 end

            ShopData._items[id] = {
                id = id,
                name = name,
                description = description,
                icon = icon,
                category = "sell",
                price = price,
                isSell = true,
                sellAny = true,
                items = validItems,
            }

            ShopData._categories.sell = ShopData._categories.sell or {}
            table.insert(ShopData._categories.sell, id)
            return #validItems
        end

        local function addPurchaseEntry(id, name, description, icon, category, price, items)
            if ShopData._items[id] then return false end
            local validItems = {}
            for _, itemData in ipairs(items) do
                if itemData and itemData.type and isItemValid(itemData.type) then
                    table.insert(validItems, {
                        type = itemData.type,
                        count = math.max(1, math.floor(tonumber(itemData.count) or 1)),
                    })
                end
            end
            if #validItems == 0 then return false end

            ShopData._items[id] = {
                id = id,
                name = name,
                description = description,
                icon = icon,
                category = category,
                price = price,
                items = validItems,
            }
            ShopData._categories[category] = ShopData._categories[category] or {}
            table.insert(ShopData._categories[category], id)
            return true
        end

        local generalCount = addSellEntry(
            "sell_partner_general_accessories",
            "UI_Shop_SellOtherAccessories",
            "UI_Shop_SellOtherAccessories_Desc",
            "Item_Watch_Black",
            1,
            GENERAL_ACCESSORY_TYPES
        )
        local premiumCount = addSellEntry(
            "sell_partner_premium_accessories",
            "UI_Shop_SellPremiumAccessories",
            "UI_Shop_SellPremiumAccessories_Desc",
            "Item_Watch_Expensive",
            2,
            PREMIUM_ACCESSORY_TYPES
        )
        local eyewearCount = addSellEntry(
            "sell_partner_eyewear",
            "UI_Shop_SellEyewear",
            "UI_Shop_SellEyewear_Desc",
            "Item_GlassesBlack",
            1,
            EYEWEAR_TYPES
        )
        local underwearCount = addSellEntry(
            "sell_partner_underwear",
            "UI_Shop_SellUnderwear",
            "UI_Shop_SellUnderwear_Desc",
            "Item_PantiesGeneric",
            1,
            UNDERWEAR_TYPES
        )
        local walletCount = addSellEntry(
            "sell_partner_wallets",
            "UI_Shop_SellWallets",
            "UI_Shop_SellWallets_Desc",
            "Item_Wallet_01",
            1,
            WALLET_TYPES
        )
        local creditCardCount = addSellEntry(
            "sell_partner_credit_cards",
            "UI_Shop_SellCreditCards",
            "UI_Shop_SellCreditCards_Desc",
            "Item_CreditCard",
            3,
            CREDIT_CARD_TYPES
        )
        local idCardCount = addSellEntry(
            "sell_partner_id_cards",
            "UI_Shop_SellIDCards",
            "UI_Shop_SellIDCards_Desc",
            "Item_IDcard",
            1,
            ID_CARD_TYPES
        )

        local customPurchaseCount = 0
        for _, bookSet in ipairs(EXPANDED_SKILL_BOOK_SETS) do
            if addPurchaseEntry(
                "partner_books_" .. bookSet.id,
                bookSet.name,
                bookSet.name .. "_Desc",
                "Item_BookSlipcase",
                "books",
                200,
                {
                    { type = bookSet.item, count = 1 },
                }
            ) then
                customPurchaseCount = customPurchaseCount + 1
            end
        end

        if addPurchaseEntry(
            "partner_legendary_weapon_draw",
            "UI_Shop_PartnerLegendaryWeaponDraw",
            "UI_Shop_PartnerLegendaryWeaponDraw_Desc",
            "Item_Katana",
            "weapons",
            10000,
            {
                { type = "Base.PartnerLegendaryDrawToken", count = 1 },
            }
        ) then
            customPurchaseCount = customPurchaseCount + 1
        end
        if addPurchaseEntry(
            "partner_repair_all_weapons",
            "UI_Shop_PartnerRepairAllWeapons",
            "UI_Shop_PartnerRepairAllWeapons_Desc",
            "Item_DuctTape",
            "weapons",
            4000,
            {
                { type = "Base.PartnerRepairWeaponsToken", count = 1 },
            }
        ) then
            customPurchaseCount = customPurchaseCount + 1
        end

        if addPurchaseEntry(
            "partner_respirator_starter_kit",
            "UI_Shop_RespiratorStarterKit",
            "UI_Shop_RespiratorStarterKit_Desc",
            "Item_Respirator_wFilter",
            "medical",
            200,
            {
                { type = "Base.Hat_BuildersRespirator_nofilter", count = 1 },
                { type = "Base.RespiratorFilters", count = 4 },
            }
        ) then
            customPurchaseCount = customPurchaseCount + 1
        end
        if addPurchaseEntry(
            "partner_respirator_filter_pack",
            "UI_Shop_RespiratorFilterPack",
            "UI_Shop_RespiratorFilterPack_Desc",
            "Item_AirFilters",
            "medical",
            120,
            {
                { type = "Base.RespiratorFilters", count = 5 },
            }
        ) then
            customPurchaseCount = customPurchaseCount + 1
        end

        for _, itemIds in pairs(ShopData._categories) do
            table.sort(itemIds, function(a, b)
                local itemA = ShopData._items[a] or {}
                local itemB = ShopData._items[b] or {}
                local priceA, priceB = tonumber(itemA.price) or 0, tonumber(itemB.price) or 0
                if priceA == priceB then return tostring(a) < tostring(b) end
                return priceA < priceB
            end)
        end

        ShopData._partnerCatalogInstalled = true
        print(PATCH_TAG .. " purchase prices x" .. tostring(PURCHASE_PRICE_MULTIPLIER) ..
            " applied=" .. tostring(purchasePriceCount) ..
            "; fixed-price purchase bundles added=" .. tostring(customPurchaseCount) ..
            "; vanilla sellable items added=" ..
            tostring(generalCount + premiumCount + eyewearCount + underwearCount +
                walletCount + creditCardCount + idCardCount))
        return true
    end

    local originalInitialize = ShopData.initialize
    ShopData.initialize = function(...)
        originalInitialize(...)
        applyCatalogChanges()
    end
    ShopData._partnerCatalogHookInstalled = true

    -- The shop may already be initialized if another mod opened or queried it.
    applyCatalogChanges()
    print(PATCH_TAG .. " shop catalog compatibility hook enabled")
    return true
end

local function installAll()
    installTraitEconomyPatch()
    local refugeReady = installSharedRefugePatch()
    local walletReady = installPersonalWalletPatch()
    local broadcastReady = installSharedUpgradeBroadcast()
    local catalogReady = installShopCatalogPatch()
    return refugeReady and walletReady and broadcastReady and catalogReady
end

installAll()

if Events then
    if Events.OnServerStarted then Events.OnServerStarted.Add(installAll) end
    if Events.OnGameStart then Events.OnGameStart.Add(installAll) end
    if Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(function() installAll() end)
    end
    if Events.OnTick then
        local installAttempts = 0
        local function retryInstall()
            installAttempts = installAttempts + 1
            if installAll() or installAttempts >= 300 then
                Events.OnTick.Remove(retryInstall)
            end
        end
        Events.OnTick.Add(retryInstall)
    end
end

