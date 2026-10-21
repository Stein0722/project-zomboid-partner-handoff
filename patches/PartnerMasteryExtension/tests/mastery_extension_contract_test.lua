local extensionPath = assert(arg[1], "extension path required")

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local perk = { id = "LongBlunt" }
function perk:getId() return self.id end

local stored = 0
local costs = {}
for level = 11, 20 do costs[level] = 100 end

BeyondTen = {
    VERSION = "1.3.4",
    API_VERSION = 1,
    NATIVE_MAX_LEVEL = 10,
    MAX_LEVEL = 15,
}

function BeyondTen.IsFinite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end
function BeyondTen.Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end
function BeyondTen.ResolvePerk(value)
    if value == perk or value == perk.id then return perk end
end
function BeyondTen.IsTrainablePerk(value) return value == perk end
function BeyondTen.InvalidatePerkCaches() end
function BeyondTen.GetMasteryCost(value, level)
    if value ~= perk or level > BeyondTen.MAX_LEVEL then return 0 end
    return costs[level] or 0
end
function BeyondTen.GetTotalMasteryCost(value, level)
    if value ~= perk then return 0 end
    return math.max(0, math.min(level, BeyondTen.MAX_LEVEL) - 10) * 100
end
function BeyondTen.GetStoredXP(_character, value)
    if value ~= perk then return 0 end
    return stored
end
function BeyondTen.GetNativeLevel(_character, value)
    return value == perk and 10 or 0
end
function BeyondTen.GetMasteryState(_character, value)
    if value ~= perk then return 10, 0, 0 end
    local level = 10 + math.floor(stored / 100)
    level = math.min(level, BeyondTen.MAX_LEVEL)
    if level >= BeyondTen.MAX_LEVEL then return level, 0, 0 end
    return level, stored - (level - 10) * 100, 100
end
function BeyondTen.GetEffectiveLevel(character, value)
    if BeyondTen.GetNativeLevel(character, value) < 10 then return 0 end
    return BeyondTen.GetMasteryState(character, value)
end
function BeyondTen.GetLevelProgress(character, value)
    return BeyondTen.GetMasteryState(character, value)
end
function BeyondTen.SetStoredXP(character, value, amount)
    local oldLevel = BeyondTen.GetEffectiveLevel(character, value)
    stored = BeyondTen.Clamp(amount, 0, BeyondTen.GetTotalMasteryCost(value, BeyondTen.MAX_LEVEL))
    local newLevel = BeyondTen.GetEffectiveLevel(character, value)
    return stored, oldLevel, newLevel
end
function BeyondTen.AddStoredXP(character, value, amount)
    local before = stored
    local newValue, oldLevel, newLevel = BeyondTen.SetStoredXP(character, value, before + amount)
    return newValue - before, oldLevel, newLevel, newValue
end

local originalRequire = require
require = function(_name) return true end
dofile(extensionPath)
require = originalRequire

local player = {}
assertEqual(BeyondTen.MAX_LEVEL, 15, "base bonus cap remains 15 after install")

local applied, oldLevel, newLevel = BeyondTen.AddStoredXP(player, perk, 850)
assertEqual(applied, 850, "stores XP past the old level-15 cap")
assertEqual(oldLevel, 10, "extended write reports old level")
assertEqual(newLevel, 18, "extended write reports new level")
assertEqual(stored, 850, "extended XP is retained")
assertEqual(BeyondTen.MAX_LEVEL, 15, "temporary maximum is restored after write")

assertEqual(BeyondTen.GetEffectiveLevel(player, perk), 15, "Beyond Ten bonuses still see level 15")
assertEqual(PartnerMasteryExtension.GetEffectiveLevel(player, perk), 18, "extension UI sees level 18")
assertEqual(PartnerMasteryExtension.GetExtensionXP(player, perk), 350, "extension XP excludes levels 11-15")
assertEqual(PartnerMasteryExtension.GetMaximumStoredXP(perk), 1000, "level-20 storage maximum")
assertEqual(BeyondTen.MAX_LEVEL, 15, "read helper restores bonus cap")

BeyondTen.AddStoredXP(player, perk, 500)
assertEqual(stored, 1000, "storage clamps at level 20")
assertEqual(PartnerMasteryExtension.GetEffectiveLevel(player, perk), 20, "reaches level 20")

BeyondTen.AddStoredXP(player, perk, -250)
assertEqual(stored, 750, "negative XP can lower extension progress")
assertEqual(PartnerMasteryExtension.GetEffectiveLevel(player, perk), 17, "level falls with negative XP")
assertEqual(BeyondTen.GetEffectiveLevel(player, perk), 15, "bonus level remains capped after negative XP")

print("PARTNER_MASTERY_EXTENSION_CONTRACT_TEST_OK")
