require "PartnerLegend/Core"
local L=PartnerLegend
local lastWeapon
local function safeCall(target,methodName,...)
    if not target then return false,nil end
    local okMethod,method=pcall(function() return target[methodName] end)
    if not okMethod or not method then return false,nil end
    return pcall(method,target,...)
end
local function safeGet(target,methodName)
    local ok,value=safeCall(target,methodName)
    return ok and value or nil
end
local function isWeapon(item)
    if not item then return false end
    if instanceof then
        local ok,result=pcall(instanceof,item,"HandWeapon")
        if ok then return result==true end
    end
    return safeGet(item,"getMinDamage")~=nil and safeGet(item,"getMaxDamage")~=nil
end
local function rawMaxDamage(item,minDamage)
    local effective=tonumber(safeGet(item,"getMaxDamage"))
    if not effective then return nil end
    if safeGet(item,"hasSharpness")~=true then return effective end
    local sharpness=tonumber(safeGet(item,"getSharpnessMultiplier"))
    if not sharpness or sharpness<=0 or not minDamage or effective<=minDamage then
        return effective
    end
    return minDamage+(effective-minDamage)/sharpness
end
local function closeEnough(a,b)
    return a and b and math.abs(a-b)<0.0001
end
local function restore(item)
    if not isWeapon(item) then return end
    local md=safeGet(item,"getModData")
    local saved=md and md.PartnerLegendDamage
    if type(saved)~="table" then return end
    local lo=tonumber(safeGet(item,"getMinDamage"))
    local rawHi=rawMaxDamage(item,lo)
    -- Preserve external mods' later changes instead of overwriting them.
    if closeEnough(lo,tonumber(saved.appliedMin)) then
        safeCall(item,"setMinDamage",saved.baseMin)
    end
    if closeEnough(rawHi,tonumber(saved.appliedMax)) then
        safeCall(item,"setMaxDamage",saved.baseMax)
    end
    md.PartnerLegendDamage=nil
end
local function weaponPerk(item)
    local perk=safeGet(item,"getPerk")
    if not perk then return nil end
    local id=safeGet(perk,"getId")
    return id and tostring(id) or nil
end
local function apply(player,item)
    if not player or not isWeapon(item) then return end
    restore(item)
    local ranged=safeGet(item,"isRanged")==true
    local bonus=L.DamageBonus(player,ranged,weaponPerk(item))
    if bonus<=0 then return end
    local lo=tonumber(safeGet(item,"getMinDamage"))
    local hi=rawMaxDamage(item,lo)
    if not lo or not hi then return end
    local factor=1+bonus/100
    local md=safeGet(item,"getModData")
    if type(md)~="table" then return end
    local saved={
        version=1,baseMin=lo,baseMax=hi,appliedMin=lo*factor,appliedMax=hi*factor
    }
    local okMin=safeCall(item,"setMinDamage",saved.appliedMin)
    local okMax=safeCall(item,"setMaxDamage",saved.appliedMax)
    if not okMin or not okMax then
        -- Never leave a half-applied bonus behind if one Java setter fails.
        safeCall(item,"setMinDamage",lo)
        safeCall(item,"setMaxDamage",hi)
        md.PartnerLegendDamage=nil
        return
    end
    md.PartnerLegendDamage=saved
end
function L.Refresh(player)
    if not player then return end
    local equipped=player:getPrimaryHandItem()
    if lastWeapon and lastWeapon~=equipped then restore(lastWeapon) end
    lastWeapon=equipped
    apply(player,equipped)
end
local function player()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end
local function minute()
    local p=player()
    if not p then return end
    local new=L.Check(p)
    local equipped=p:getPrimaryHandItem()
    if new>0 or equipped~=lastWeapon then L.Refresh(p) end
    if new>0 and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(p,"Partner Legend: +"..tostring(new).." 업적")
    end
end
Events.OnGameStart.Add(function()
    local p=player()
    if p then L.Check(p);L.Refresh(p) end
end)
Events.EveryOneMinute.Add(minute)
Events.OnEquipPrimary.Add(function(character,item)
    if character~=player() then return end
    if lastWeapon and lastWeapon~=item then restore(lastWeapon) end
    lastWeapon=item
    apply(character,item)
end)
if Events.OnPlayerDeath then
    Events.OnPlayerDeath.Add(function(character)
        if character==player() and lastWeapon then
            restore(lastWeapon)
            lastWeapon=nil
        end
    end)
end

-- Small public hooks for compatibility checks and automated contract tests.
L.RestoreWeapon=restore
L.ApplyWeaponBonus=apply
L.ReadRawMaxDamage=rawMaxDamage
