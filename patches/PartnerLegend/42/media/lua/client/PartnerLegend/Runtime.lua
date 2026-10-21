require "PartnerLegend/Core"
local L=PartnerLegend
local lastWeapon
local function isWeapon(item)
    return item and type(item.getMinDamage)=="function"
        and type(item.getMaxDamage)=="function"
        and type(item.setMinDamage)=="function"
        and type(item.setMaxDamage)=="function"
end
local function restore(item)
    if not isWeapon(item) then return end
    local md=item:getModData()
    local saved=md and md.PartnerLegendDamage
    if type(saved)~="table" then return end
    local lo,hi=tonumber(item:getMinDamage()),tonumber(item:getMaxDamage())
    -- Preserve external mods' later changes instead of overwriting them.
    if lo and saved.appliedMin and math.abs(lo-saved.appliedMin)<0.0001 then
        item:setMinDamage(saved.baseMin)
    end
    if hi and saved.appliedMax and math.abs(hi-saved.appliedMax)<0.0001 then
        item:setMaxDamage(saved.baseMax)
    end
    md.PartnerLegendDamage=nil
end
local function weaponPerk(item)
    if type(item.getPerk)~="function" then return nil end
    local perk=item:getPerk()
    return perk and perk.getId and tostring(perk:getId()) or nil
end
local function apply(player,item)
    if not player or not isWeapon(item) then return end
    restore(item)
    local ranged=item.isRanged and item:isRanged() or false
    local bonus=L.DamageBonus(player,ranged,weaponPerk(item))
    if bonus<=0 then return end
    local lo,hi=tonumber(item:getMinDamage()),tonumber(item:getMaxDamage())
    if not lo or not hi then return end
    local factor=1+bonus/100
    local md=item:getModData()
    md.PartnerLegendDamage={
        baseMin=lo,baseMax=hi,appliedMin=lo*factor,appliedMax=hi*factor
    }
    item:setMinDamage(lo*factor)
    item:setMaxDamage(hi*factor)
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
