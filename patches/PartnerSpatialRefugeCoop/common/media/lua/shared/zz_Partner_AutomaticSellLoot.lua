-- Partner automatic sell-loot upgrade and shared settings API.
-- Extends automatic_core_pickup to levels 4-5 without editing Workshop files.

require "00_core/00_MSR"
require "MSR_UpgradeData"
require "MSR_ShopData"

local TAG = "[PartnerAutomaticSellLoot]"
local UPGRADE_ID = (MSR.Config and MSR.Config.UPGRADES and
    MSR.Config.UPGRADES.AUTOMATIC_CORE_PICKUP) or "automatic_core_pickup"
local SETTINGS_KEY = "partnerAutoLootSettings"
local COMMAND_MODULE = "PartnerSpatialRefugeCoop"

local GROUP_DEFINITIONS = {
    -- Level 4: underwear, including the stockings/tights already accepted by
    -- the Partner shop catalog.
    { id = "sell_partner_underwear", requiredLevel = 4 },

    -- Level 5: money, certificates, jewelry, watches and small valuables.
    { id = "sell_money", requiredLevel = 5 },
    { id = "sell_money_bundle", requiredLevel = 5 },
    { id = "sell_stock_certificate", requiredLevel = 5 },
    { id = "sell_silver_jewelry", requiredLevel = 5 },
    { id = "sell_gold_jewelry", requiredLevel = 5 },
    { id = "sell_partner_general_accessories", requiredLevel = 5 },
    { id = "sell_partner_premium_accessories", requiredLevel = 5 },
    { id = "sell_partner_eyewear", requiredLevel = 5 },
    { id = "sell_partner_wallets", requiredLevel = 5 },
    { id = "sell_partner_credit_cards", requiredLevel = 5 },
    { id = "sell_partner_id_cards", requiredLevel = 5 },
}

local GROUP_BY_ID = {}
for _, definition in ipairs(GROUP_DEFINITIONS) do
    GROUP_BY_ID[definition.id] = definition
end

MSR.PartnerAutomaticSellLoot = MSR.PartnerAutomaticSellLoot or {}
local API = MSR.PartnerAutomaticSellLoot
API.UPGRADE_ID = UPGRADE_ID
API.SETTINGS_KEY = SETTINGS_KEY
API.COMMAND_MODULE = COMMAND_MODULE
API.GROUP_DEFINITIONS = GROUP_DEFINITIONS
API.GROUP_BY_ID = GROUP_BY_ID
API.typeToGroup = API.typeToGroup or {}

local function resolvePlayer(player)
    if MSR.resolvePlayer then return MSR.resolvePlayer(player) end
    if type(player) == "number" and getSpecificPlayer then return getSpecificPlayer(player) end
    return player
end

function API.getGroupRequiredLevel(groupId)
    local definition = GROUP_BY_ID[groupId]
    return definition and definition.requiredLevel or nil
end

function API.isKnownGroup(groupId)
    return type(groupId) == "string" and GROUP_BY_ID[groupId] ~= nil
end

function API.getPlayerUpgradeLevel(player)
    player = resolvePlayer(player)
    if not player or not MSR.UpgradeData then return 0 end
    return tonumber(MSR.UpgradeData.getPlayerUpgradeLevel(player, UPGRADE_ID)) or 0
end

function API.getRefugeData(player)
    player = resolvePlayer(player)
    if not player or not MSR.Data or not MSR.Data.GetRefugeData then return nil end
    return MSR.Data.GetRefugeData(player)
end

local function getSettingsTable(refugeData, create)
    if not refugeData then return nil end
    if not refugeData.customizations and create then refugeData.customizations = {} end
    local customizations = refugeData.customizations
    if not customizations then return nil end
    if not customizations[SETTINGS_KEY] and create then customizations[SETTINGS_KEY] = {} end
    return customizations[SETTINGS_KEY]
end

-- Missing values intentionally mean ON, so upgrading immediately enables the
-- new feature and old saves need no migration pass.
function API.isGroupEnabled(player, groupId)
    if not API.isKnownGroup(groupId) then return false end
    local settings = getSettingsTable(API.getRefugeData(player), false)
    if not settings or settings[groupId] == nil then return true end
    return settings[groupId] == true
end

function API.applySettingLocal(player, groupId, enabled)
    if not API.isKnownGroup(groupId) then return false end
    local refugeData = API.getRefugeData(player)
    local settings = getSettingsTable(refugeData, true)
    if not settings then return false end
    settings[groupId] = enabled == true
    return true, refugeData
end

function API.isGroupUnlocked(player, groupId)
    local requiredLevel = API.getGroupRequiredLevel(groupId)
    return requiredLevel ~= nil and API.getPlayerUpgradeLevel(player) >= requiredLevel
end

function API.requestSetting(player, groupId, enabled)
    player = resolvePlayer(player)
    if not player or not API.isKnownGroup(groupId) then return false end
    enabled = enabled == true

    if API.getPlayerUpgradeLevel(player) < API.getGroupRequiredLevel(groupId) then
        return false
    end

    if isClient and isClient() then
        sendClientCommand(COMMAND_MODULE, "SetAutoLoot", {
            groupId = groupId,
            enabled = enabled,
        })
        return true
    end

    local applied, refugeData = API.applySettingLocal(player, groupId, enabled)
    if not applied then return false end
    if MSR.Data and MSR.Data.SaveRefugeData then
        return MSR.Data.SaveRefugeData(refugeData) == true
    end
    return true
end

function API.requestToggle(player, groupId)
    return API.requestSetting(player, groupId, not API.isGroupEnabled(player, groupId))
end

function API.rebuildItemRegistry()
    local ShopData = MSR and MSR.ShopData
    if not ShopData then return false end
    if ShopData.initialize then ShopData.initialize() end

    local typeToGroup = {}
    local itemTypeCount = 0
    for _, definition in ipairs(GROUP_DEFINITIONS) do
        local shopItem = ShopData._items and ShopData._items[definition.id] or nil
        if shopItem and shopItem.isSell and type(shopItem.items) == "table" then
            for _, itemData in ipairs(shopItem.items) do
                if itemData and type(itemData.type) == "string" then
                    typeToGroup[itemData.type] = definition.id
                    itemTypeCount = itemTypeCount + 1
                end
            end
        end
    end

    API.typeToGroup = typeToGroup
    API.itemTypeCount = itemTypeCount
    return itemTypeCount > 0
end

function API.getGroupForItemType(fullType)
    if not fullType then return nil end
    -- B42's Kahlua runtime does not consistently expose Lua's global next().
    -- The registry already records its item count, so use that value to decide
    -- whether it needs rebuilding instead of calling next(table).
    if not API.typeToGroup or (tonumber(API.itemTypeCount) or 0) <= 0 then
        API.rebuildItemRegistry()
    end
    return API.typeToGroup and API.typeToGroup[fullType] or nil
end

function API.isManagedLootType(fullType)
    return API.getGroupForItemType(fullType) ~= nil
end

local function applyUpgradeDefinition()
    local UpgradeData = MSR and MSR.UpgradeData
    if not UpgradeData or not UpgradeData._upgrades then return false end
    local upgrade = UpgradeData._upgrades[UPGRADE_ID]
    if not upgrade then return false end

    upgrade.maxLevel = 5
    upgrade.levels = upgrade.levels or {}

    -- B42.21 sometimes fails to match Base.Speaker variants in upgrade
    -- inventories. Keep level 3's original core cost, but remove only the
    -- speaker requirement as requested.
    local level3 = upgrade.levels[3] or upgrade.levels["3"]
    if level3 then
        level3.requirements = { { type = "Base.MagicalCore", count = 36 } }
    end

    upgrade.levels[4] = {
        description = "UI_Upgrade_AutomaticCorePickup_L4",
        effects = { corePickupRadius = 2.0 },
        requirements = { { type = "Base.MagicalCore", count = 500 } },
    }
    upgrade.levels[5] = {
        description = "UI_Upgrade_AutomaticCorePickup_L5",
        effects = { corePickupRadius = 2.0 },
        requirements = { { type = "Base.MagicalCore", count = 1000 } },
    }
    return true
end

local function installUpgradePatch()
    local UpgradeData = MSR and MSR.UpgradeData
    if not UpgradeData or type(UpgradeData.initialize) ~= "function" then return false end

    if not UpgradeData._partnerAutomaticSellLootInitializeInstalled then
        local originalInitialize = UpgradeData.initialize
        UpgradeData.initialize = function(...)
            local result = originalInitialize(...)
            applyUpgradeDefinition()
            return result
        end
        UpgradeData._partnerAutomaticSellLootInitializeInstalled = true
    end

    UpgradeData.initialize()
    if not applyUpgradeDefinition() then return false end

    if not UpgradeData._partnerAutomaticSellLootExactCostInstalled then
        local originalGetRequirements = UpgradeData.getNextLevelRequirements
        UpgradeData.getNextLevelRequirements = function(player, upgradeId)
            if upgradeId == UPGRADE_ID then
                local nextLevel = UpgradeData.getPlayerUpgradeLevel(player, UPGRADE_ID) + 1
                if nextLevel == 4 then
                    return { { type = "Base.MagicalCore", count = 500 } }
                elseif nextLevel == 5 then
                    return { { type = "Base.MagicalCore", count = 1000 } }
                end
            end
            return originalGetRequirements(player, upgradeId)
        end
        UpgradeData._partnerAutomaticSellLootExactCostInstalled = true
    end

    return true
end

local function installAll()
    local upgradeReady = installUpgradePatch()
    local registryReady = API.rebuildItemRegistry()
    if upgradeReady and registryReady and not API._installedNoticeShown then
        API._installedNoticeShown = true
        print(TAG .. " levels 4-5 and " .. tostring(API.itemTypeCount or 0) ..
            " sellable item types enabled")
    end
    return upgradeReady and registryReady
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

return API
