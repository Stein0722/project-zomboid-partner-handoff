require "BeyondTen/Shared"

PartnerMasteryExtension = PartnerMasteryExtension or {}
local PME = PartnerMasteryExtension
local BT = BeyondTen

PME.VERSION = "0.1.0"
PME.API_VERSION = 1
PME.MAX_LEVEL = 20
PME.BONUS_MAX_LEVEL = 15
PME.EXTRA_LEVELS = PME.MAX_LEVEL - PME.BONUS_MAX_LEVEL
PME.SUPPORTED_BEYOND_TEN = "1.3.4"
PME.SINGLE_PLAYER_ONLY = true

local unpackValues = table.unpack or unpack

local function packValues(...)
    return { n = select("#", ...), ... }
end

local function log(message)
    print("[PartnerMasteryExtension] " .. tostring(message))
end

-- Beyond Ten uses BT.MAX_LEVEL both for storage capacity and for gameplay
-- bonuses. Leaving it at 20 permanently would also grant full-strength ranks
-- 16-20. This helper raises the ceiling only for one synchronous storage or
-- display calculation, then restores 15 even when the callback fails.
local function withExtendedMaximum(callback, ...)
    local previousMaximum = BT.MAX_LEVEL
    BT.MAX_LEVEL = PME.MAX_LEVEL
    local results = packValues(pcall(callback, ...))
    BT.MAX_LEVEL = previousMaximum
    if not results[1] then error(results[2]) end
    return unpackValues(results, 2, results.n)
end

local function ensureExtendedCostCache(perk)
    -- Beyond Ten memoises its cost table. A table first built for level 15 has
    -- no entries for 16-20, so rebuild it once when that stale shape is seen.
    if BT.GetMasteryCost(perk, PME.MAX_LEVEL) <= 0 then
        BT.InvalidatePerkCaches()
    end
end

function PME.IsSupported()
    return type(BT) == "table"
        and tonumber(BT.API_VERSION) == 1
        and tostring(BT.VERSION or "") == PME.SUPPORTED_BEYOND_TEN
        and tonumber(BT.NATIVE_MAX_LEVEL) == 10
        and tonumber(BT.MAX_LEVEL) == PME.BONUS_MAX_LEVEL
end

function PME.GetMaximumStoredXP(perkOrId)
    local perk = BT.ResolvePerk(perkOrId)
    if not perk or not BT.IsTrainablePerk(perk) then return 0 end
    return withExtendedMaximum(function()
        ensureExtendedCostCache(perk)
        return BT.GetTotalMasteryCost(perk, PME.MAX_LEVEL)
    end)
end

function PME.GetEffectiveLevel(character, perkOrId)
    local perk = BT.ResolvePerk(perkOrId)
    if not character or not perk then return 0 end
    return withExtendedMaximum(function()
        ensureExtendedCostCache(perk)
        return BT.GetEffectiveLevel(character, perk)
    end)
end

function PME.GetLevelProgress(character, perkOrId)
    local perk = BT.ResolvePerk(perkOrId)
    if not character or not perk then return 0, 0, 0 end
    return withExtendedMaximum(function()
        ensureExtendedCostCache(perk)
        return BT.GetLevelProgress(character, perk)
    end)
end

function PME.GetExtensionXP(character, perkOrId)
    local perk = BT.ResolvePerk(perkOrId)
    if not character or not perk then return 0 end
    local baseMaximum = BT.GetTotalMasteryCost(perk, PME.BONUS_MAX_LEVEL)
    return math.max(0, BT.GetStoredXP(character, perk) - baseMaximum)
end

local function installStorageExtension()
    if not PME.IsSupported() then
        log("unsupported Beyond Ten state; expected 1.3.4 API 1 with level 15 cap")
        return false
    end

    local state = PME._setStoredXPWrapper
    if state and BT.SetStoredXP == state.wrapper then return true end

    local original = BT.SetStoredXP
    if type(original) ~= "function" then
        log("Beyond Ten SetStoredXP API is unavailable")
        return false
    end

    local wrapper = function(character, perkOrId, value)
        local perk = BT.ResolvePerk(perkOrId)
        if not character or not perk or not BT.IsTrainablePerk(perk) then
            return original(character, perkOrId, value)
        end
        return withExtendedMaximum(function()
            ensureExtendedCostCache(perk)
            return original(character, perk, value)
        end)
    end

    PME._setStoredXPWrapper = {
        original = original,
        wrapper = wrapper,
    }
    BT.SetStoredXP = wrapper
    PME._installed = true
    log("installed v" .. PME.VERSION .. " (single-player, levels 16-20 store XP only)")
    return true
end

installStorageExtension()
