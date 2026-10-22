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

local localized = {
    UI_PL_Title_100 = "Localized Title",
    UI_PL_Medal_days_7 = "Localized Medal",
}
getText = function(key) return localized[key] or key end

local levels = { Axe = 20, Aiming = 20 }
PartnerMasteryExtension = {
    GetEffectiveLevel = function(_, p) return levels[p:getId()] or 0 end,
}

assert(loadfile(root .. "/patches/PartnerLegend/42/media/lua/shared/PartnerLegend/Core.lua"))()
local L = PartnerLegend
assert(L.VERSION == "0.2.0", "unexpected version")
assert(#L.TITLES == 12, "title count changed")
assert(#L.MEDALS == 29, "medal count changed")
assert(L.GetTitleName(L.TITLES[1]) == "Localized Title", "title translation failed")
assert(L.GetMedalName(L.MEDALS[1]) == "Localized Medal", "medal translation failed")
assert(L.GetMedalName(L.MEDALS[2]) == "Hardened Survivor", "English fallback failed")

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


-- Title migration/equipment: no old slot may accidentally unlock a new threshold.
assert(L.TITLES[12][1] == 1000000, "final title must require one million kills")
assert(L.TITLES[7][1] == 75000 and L.TITLES[10][1] == 250000)
assert(L.EquipTitle(player,1), "earned title should equip")
local titleName,titleIndex=L.BestTitle(player)
assert(titleIndex==1, "equipped manual title was ignored")
assert(L.ToggleAuraPreference(player,1)==true, "aura preference not saved")
assert(L.AuraPreference(player,1)==true, "aura preference did not round-trip")
assert(L.SetTitleMode(player,"none"), "cannot unequip title")
assert(select(2,L.BestTitle(player))==0, "title did not unequip")
assert(L.SetTitleMode(player,"auto"), "cannot restore automatic title")
assert(select(2,L.BestTitle(player))==6, "auto title should match 50k milestone")

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


-- Weapon-skill 10/20: +2 hit targets, safe rollback after unequip.
weapon.getMaxHitCount=function(self) return self.hitCount or 3 end
weapon.setMaxHitCount=function(self,value) self.hitCount=value end
weapon.isPiercingBullets=function(self) return self.piercing or false end
weapon.setPiercingBullets=function(self,value) self.piercing=value end
weapon.getProjectileCount=function() return 1 end
L.ApplySkillHitBonus(damagePlayer,weapon)
assert(weapon.hitCount==5, "20 melee should add two max targets")
L.RestoreWeapon(weapon)
assert(weapon.hitCount==3, "unequip must restore original max hit")
assert(weaponData.PartnerLegendHits==nil, "hit marker was not cleared")
local rangedData={}
local ranged={
    getModData=function() return rangedData end,
    getMinDamage=function() return 1 end,
    getMaxDamage=function() return 2 end,
    isRanged=function() return true end,
    getProjectileCount=function() return 1 end,
    getMaxHitCount=function(self) return self.hits or 1 end,
    setMaxHitCount=function(self,v) self.hits=v end,
    isPiercingBullets=function(self) return self.piercing or false end,
    setPiercingBullets=function(self,v) self.piercing=v end,
}
L.ApplySkillHitBonus(damagePlayer,ranged)
assert(ranged.hits==3 and ranged.piercing==true, "20 aiming must add +2 and enable piercing")
L.RestoreWeapon(ranged)
assert(ranged.hits==1 and ranged.piercing==false, "ranged state should restore")

print("Partner Legend contract test passed")
