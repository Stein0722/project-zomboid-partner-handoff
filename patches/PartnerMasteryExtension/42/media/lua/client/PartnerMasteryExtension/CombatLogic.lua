-- Standalone, pure calculation functions. No game event registration here.
PartnerMasteryExtensionCombat = PartnerMasteryExtensionCombat or {}
local P = PartnerMasteryExtensionCombat
P.VERSION = "0.3.0-balanced-integrated"

P.MELEE = {
    Axe = true, Blunt = true, LongBlunt = true, SmallBlunt = true,
    LongBlade = true, SmallBlade = true, Spear = true,
}

-- Some B42/third-party weapon perks arrive as Java enums; others as strings.
-- Accept only known perk suffixes, never classify a bare unarmed/nil perk.
function P.PerkName(value)
    if value==nil then return nil end
    local valueString=tostring(value)
    if P.MELEE[valueString] then return valueString end
    local suffix=valueString:match('([%w_]+)$')
    if suffix and P.MELEE[suffix] then return suffix end
    return suffix
end

function P.LevelTier(level)
    local config = P.Config
    if config and config.testMode == true and config.forceTier20 == true then return 20 end
    level = tonumber(tostring(level or 0)) or 0
    return level >= 20 and 20 or level >= 15 and 15 or 0
end

function P.ShockwavePlan(level)
    local tier=P.LevelTier(level)
    local c=P.Config
    if tier==20 then
        return (c.shockwave20BP or 500)/10000,
            (c.shockwaveRadius20Tenths or 30)/10,
            (c.shockwaveDamage20Pct or 30)/100
    end
    if tier==15 then
        return (c.shockwave15BP or 100)/10000,
            (c.shockwaveRadius15Tenths or 15)/10,
            (c.shockwaveDamage15Pct or 15)/100
    end
    return 0,0,0
end
function P.IndomitableChance(level)
    local tier=P.LevelTier(level)
    local c=P.Config
    if tier==20 then return (c.indomitable20BP or 100)/10000 end
    if tier==15 then return (c.indomitable15BP or 25)/10000 end
    return 0
end

-- Every entry: level20 proc (%), level15 extra targets, level20 extra targets.
P.PENETRATION = {
    AntiMateriel = {10, 6, 20},
    BoltAction   = { 7, 4, 12},
    DMR          = { 4, 3,  8},
    Assault      = { 2, 2,  6},
    MachineGun   = { 1, 3, 10},
    HandgunSMG   = { 1, 1,  3},
}
function P.PenetrationPlan(level,kind)
    local entry=P.PENETRATION[kind]
    local tier=P.LevelTier(level)
    if not entry or tier==0 then return 0,0 end
    local c=P.Config
    local baseBP=(c.penChance20BP and c.penChance20BP[kind]) or entry[1]*100
    -- Level 15 uses exactly one-third of the chosen level-20 probability.
    local chance=baseBP/(tier==15 and 30000 or 10000)
    local baseExtra=tier==15 and entry[2] or entry[3]
    local scale=tier==15 and c.penExtraScale15 or c.penExtraScale20
    local extra=math.floor(baseExtra*(tonumber(scale) or 100)/100+0.5)
    return math.max(0,math.min(1,chance)),math.max(0,extra)
end

-- Warcraft/LoL-style 360-degree radial splash centered on the first hit target.
-- Squared distance avoids unnecessary sqrt and covers front, side and rear alike.
function P.InSplashCircle(cx,cy,x,y,radius)
    if type(cx)~="number" or type(cy)~="number" or type(x)~="number"
       or type(y)~="number" or type(radius)~="number" or radius<=0 then
        return false
    end
    local dx,dy=x-cx,y-cy
    return dx*dx+dy*dy <= radius*radius + 0.00000001
end

-- Backwards-compatible geometry helper; player position is now irrelevant.
function P.InWave(_px,_py,cx,cy,x,y,radius)
    return P.InSplashCircle(cx,cy,x,y,radius)
end

local MG={"m249","m240","m60","m1919","mg42","mg3","rpk","pkm","m134","minigun","lmg","machinegun","fnmag","negev","ultimax","mg4","m2hb"}
local AM={"barrett","m82","m107","m95","tac50","m200","cheytac","bfg50","gepard","osv96","osv_96","50bmg","anti_materiel","antimateriel"}
local BOLT={"mosin","sv98","l96","sako85","m40","m1903","kar98","boltaction","huntingrifle","varmintrifle","msr7"}
local DMR={"dmr","svd","psg1","psg-1","g28","scar20","m14ebr","mk14","wa2000","msg90","svdk","vssk"}
local function matches(id,patterns)
    for i=1,#patterns do if string.find(id,patterns[i],1,true) then return true end end
    return false
end
-- `plbClass` is the authoritative top-level category when PLB 1.2.0 is loaded.
-- Do not silently guess a rifle is a handgun if the two-hand getter is absent.
-- Unknown sniper variants are deliberately skipped until explicitly classified.
function P.ClassifyWeapon(fullType, ammo, isAutomatic, isTwoHand, plbClass)
    local id=string.lower(tostring(fullType or ""))
    local a=string.lower(tostring(ammo or ""))
    if id=="" then return nil end
    if a:find("shell",1,true) or a:find("shotgun",1,true) then return nil end
    if plbClass=="Bow" or plbClass=="Crossbow" or plbClass=="Slingshot"
        or plbClass=="Shotgun" then return nil end
    if plbClass=="MachineGun" then return "MachineGun" end
    if plbClass=="Handgun" or plbClass=="SMG" then return "HandgunSMG" end
    if matches(id,MG) then return "MachineGun" end
    if matches(id,AM) or a:find("50bmg",1,true) then return "AntiMateriel" end
    if matches(id,BOLT) then return "BoltAction" end
    if matches(id,DMR) then return "DMR" end
    if plbClass=="Sniper" then
        -- Safe fallback only for nonautomatic sniper-category rifles.
        -- If semiauto/bolt isn't distinguishable by name, do not guess.
        return nil
    end
    if plbClass=="Rifle" then return isAutomatic and "Assault" or "DMR" end
    -- If no PLB classifier is installed, only identify explicit subtypes.
    if plbClass~=nil then return nil end
    if not isTwoHand then return "HandgunSMG" end
    if a:find("9mm",1,true) or a:find("45acp",1,true)
        or a:find("380",1,true) or a:find("40sw",1,true) then
        return "HandgunSMG"
    end
    return isAutomatic and "Assault" or nil
end
