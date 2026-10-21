local root = assert(arg[1], "repository root is required")
root = root:gsub("\\", "/")

local function assertNear(actual, expected, message)
    assert(math.abs(actual - expected) < 0.0001,
        (message or "values differ") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local perkObjects = {}
local function perk(id)
    if not perkObjects[id] then
        perkObjects[id] = { getId = function() return id end }
    end
    return perkObjects[id]
end

Perks = { MAX = {}, None = {} }
Perks.FromString = function(id) return perk(id) end

local levels = { Axe = 20, Aiming = 20 }
PartnerMasteryExtension = {
    GetEffectiveLevel = function(_, p) return levels[p:getId()] or 0 end,
}

assert(loadfile(root .. "/patches/PartnerLegend/42/media/lua/shared/PartnerLegend/Core.lua"))()
local L = PartnerLegend
assert(L.VERSION == "0.1.1", "unexpected version")
assert(#L.TITLES == 12, "title count changed")
assert(#L.MEDALS == 29, "medal count changed")

local playerData = {}
local player = {
    getModData = function() return playerData end,
    getZombieKills = function() return 50000 end,
    getHoursSurvived = function() return 100 * 24 end,
    getPerkLevel = function(_, p) return levels[p:getId()] or 0 end,
}

assert(L.Check(player) == 0, "retroactive scan must not announce old achievements")
local data = L.GetData(player)
assert(data.titles[6] == true and data.titles[7] == nil, "kill titles unlocked incorrectly")
assert(data.medals.days_100 and data.medals.skill_Axe_20 and data.medals.aim_20,
    "retroactive medals were not unlocked")

local damageData = {
    PartnerLegend_v1 = {
        initialized = true,
        titles = {},
        medals = {
            days_7 = { legacy = true },
            skill_Axe_10 = { legacy = true },
            kill_10000 = { legacy = true },
        },
    },
}
local damagePlayer = {
    getModData = function() return damageData end,
    getPrimaryHandItem = function(self) return self.primary end,
}

L.Configure({
    rewardEfficiency = 100,
    damageCap = 100,
    survivalEfficiency = 150,
    skillEfficiency = 50,
    combatEfficiency = 200,
    medalBonuses = { days_7 = 1, skill_Axe_10 = 4, kill_10000 = 3 },
})
assertNear(L.DamageBonus(damagePlayer, false, "Axe"), 9.5,
    "group and per-medal settings were not combined correctly")

local callbacks = {}
local function event(name)
    return { Add = function(fn) callbacks[name] = fn end }
end
Events = {
    OnGameStart = event("OnGameStart"),
    EveryOneMinute = event("EveryOneMinute"),
    OnEquipPrimary = event("OnEquipPrimary"),
    OnPlayerDeath = event("OnPlayerDeath"),
}
getSpecificPlayer = function() return damagePlayer end
instanceof = function(_, className) return className == "HandWeapon" end
require = function() return true end

local weaponData = {}
local weapon = {
    rawMin = 1,
    rawMax = 5,
    sharpness = 0.5,
    getModData = function() return weaponData end,
    getMinDamage = function(self) return self.rawMin end,
    getMaxDamage = function(self)
        return self.rawMin + (self.rawMax - self.rawMin) * self.sharpness
    end,
    setMinDamage = function(self, value) self.rawMin = value end,
    setMaxDamage = function(self, value) self.rawMax = value end,
    hasSharpness = function() return true end,
    getSharpnessMultiplier = function(self) return self.sharpness end,
    isRanged = function() return false end,
    getPerk = function() return perk("Axe") end,
}
damagePlayer.primary = weapon

assert(loadfile(root .. "/patches/PartnerLegend/42/media/lua/client/PartnerLegend/Runtime.lua"))()
L.ApplyWeaponBonus(damagePlayer, weapon)
assertNear(weapon.rawMin, 1.095, "minimum damage bonus failed")
assertNear(weapon.rawMax, 5.475, "raw maximum damage bonus failed")

-- Applying twice must first restore the raw base; sharpenable weapons must not stack.
L.ApplyWeaponBonus(damagePlayer, weapon)
assertNear(weapon.rawMin, 1.095, "minimum damage stacked")
assertNear(weapon.rawMax, 5.475, "maximum damage stacked")

L.RestoreWeapon(weapon)
assertNear(weapon.rawMin, 1, "minimum damage was not restored")
assertNear(weapon.rawMax, 5, "raw maximum damage was not restored")
assert(weaponData.PartnerLegendDamage == nil, "weapon marker was not cleared")

-- A failed Java setter must roll back the other field and leave no marker.
local brokenData = {}
local brokenWeapon = {
    rawMin = 2,
    rawMax = 6,
    getModData = function() return brokenData end,
    getMinDamage = function(self) return self.rawMin end,
    getMaxDamage = function(self) return self.rawMax end,
    setMinDamage = function(self, value) self.rawMin = value end,
    setMaxDamage = function(self, value)
        if value ~= 6 then error("simulated Java setter failure") end
        self.rawMax = value
    end,
    hasSharpness = function() return false end,
    isRanged = function() return false end,
    getPerk = function() return perk("Axe") end,
}
L.ApplyWeaponBonus(damagePlayer, brokenWeapon)
assertNear(brokenWeapon.rawMin, 2, "partial application did not roll back minimum damage")
assertNear(brokenWeapon.rawMax, 6, "partial application changed maximum damage")
assert(brokenData.PartnerLegendDamage == nil, "failed application left a weapon marker")

print("Partner Legend contract test passed")
