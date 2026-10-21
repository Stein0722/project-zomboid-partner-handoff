local beyondTenSharedPath = assert(arg[1], "Beyond Ten Shared.lua path required")
local extensionPath = assert(arg[2], "extension Shared.lua path required")

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local perk = { id = "LongBlunt" }
function perk:getId() return self.id end
function perk:getParent() return Perks.None end
function perk:getXp9() return 900 end
function perk:getXp10() return 1000 end
function perk:getXpForLevel(level) return level * 100 end
function perk:getTotalXpForLevel(level) return level * 100 end
function perk:isCustom() return false end

Perks = {
    None = { id = "None" },
    MAX = { id = "MAX" },
}
function Perks.FromString(id)
    if id == perk.id then return perk end
    if id == "None" then return Perks.None end
    if id == "MAX" then return Perks.MAX end
end

local perkList = { perk }
function perkList:size() return 1 end
function perkList:get(index) return index == 0 and perk or nil end
PerkFactory = { PerkList = perkList }

local character = { modData = {}, native = 10 }
function character:getModData() return self.modData end
function character:getPerkLevel(value) return value == perk and self.native or 0 end
function character:getXp()
    return {
        getXP = function() return 1000 end,
    }
end

dofile(beyondTenSharedPath)
assertEqual(BeyondTen.VERSION, "1.3.4", "loads installed Beyond Ten source")
assertEqual(BeyondTen.GetTotalMasteryCost(perk, 15), 6500, "original level-15 cost")

local originalRequire = require
require = function(_name) return true end
dofile(extensionPath)
require = originalRequire

local applied, oldLevel, newLevel = BeyondTen.AddStoredXP(character, perk, 15500)
assertEqual(applied, 15500, "actual Beyond Ten API stores full level-20 XP")
assertEqual(oldLevel, 10, "actual API reports old extended level")
assertEqual(newLevel, 20, "actual API reports new extended level")
assertEqual(BeyondTen.GetStoredXP(character, perk), 15500, "actual record keeps extended XP")
assertEqual(BeyondTen.MAX_LEVEL, 15, "actual Beyond Ten cap returns to 15")
assertEqual(BeyondTen.GetEffectiveLevel(character, perk), 15, "actual bonus-facing level remains 15")
assertEqual(PartnerMasteryExtension.GetEffectiveLevel(character, perk), 20, "companion-facing level reaches 20")
assertEqual(BeyondTen.GetMasteryRanks(character, perk), 7.5, "actual core bonuses receive half-strength ranks through level 20")
assertEqual(PartnerMasteryExtension.GetBonusRanks(character, perk), 7.5, "public weighted-rank API")
assertEqual(PartnerMasteryExtension.GetMaximumStoredXP(perk), 15500, "actual level-20 cost")
assertEqual(PartnerMasteryExtension.GetExtensionXP(character, perk), 9000, "actual 16-20 XP segment")

BeyondTen.AddStoredXP(character, perk, -2050)
local level, current, required = PartnerMasteryExtension.GetLevelProgress(character, perk)
assertEqual(level, 18, "negative award lowers actual extended level")
assertEqual(current, 1850, "actual level-19 progress is retained")
assertEqual(required, 1900, "actual level-19 requirement")
assertEqual(BeyondTen.GetEffectiveLevel(character, perk), 15, "bonus-facing level remains capped after loss")
assertEqual(BeyondTen.GetMasteryRanks(character, perk), 6.5, "actual weighted ranks follow the lowered level")

print("BEYOND_TEN_134_INTEGRATION_TEST_OK")
