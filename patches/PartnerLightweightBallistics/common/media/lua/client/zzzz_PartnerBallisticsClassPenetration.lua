-- Category penetration overlay. Event-only: no projectile, attack or OnTick hook.
local PLB = PartnerLightweightBallistics
if not PLB or PLB._partnerClassPenetrationInstalled then
    return
end
PLB._partnerClassPenetrationInstalled = true

PLB.PenetrationByClass = PLB.PenetrationByClass or {
    Handgun = 0,
    SMG = 0,
    Shotgun = 0,
    Rifle = 1,
    Sniper = 1,
    MachineGun = 1,
    Bow = 0,
    Crossbow = 0,
    Slingshot = 0,
}

local function safe(item, method)
    if not item then
        return nil
    end
    local fn = item[method]
    if not fn then
        return nil
    end
    local ok, value = pcall(fn, item)
    if ok then
        return value
    end
    return nil
end

local function sameNumber(a, b)
    a = tonumber(a)
    b = tonumber(b)
    return a ~= nil and b ~= nil and math.abs(a - b) < 0.001
end

local function tuneWeapon(item)
    if PLB.ExternalBallistics then return true end
    local kind = PLB.GetRangedClass and PLB.GetRangedClass(item) or nil
    if not kind then
        return false
    end

    -- Shotgun penetration is now owned by PartnerShotgunProjectiles; retain
    -- vanilla/Brita pellet targeting for the red aim indicator.
    local extra = kind=='Shotgun' and 0 or math.floor(tonumber(PLB.PenetrationByClass[kind]) or 0)
    if extra < 0 then extra = 0 end
    if extra > 4 then extra = 4 end

    local currentCount = tonumber(safe(item, "getMaxHitCount")) or 1
    local currentPiercing = safe(item, "isPiercingBullets") == true
    local data = safe(item, "getModData")
    if not data then
        return false
    end

    local state = data.PartnerPLBPenetration
    if kind=='Shotgun' and type(state)~='table' then
        return true -- no shotgun native class overlay: do not touch gun stats
    end
    local baseCount = currentCount
    local basePiercing = currentPiercing

    -- Reuse our saved baseline only while the weapon still has our previous
    -- result. A change from an attachment or another mod becomes the new base.
    if type(state) == "table"
        and sameNumber(currentCount, state.targetCount)
        and currentPiercing == (state.targetPiercing == true) then
        baseCount = tonumber(state.baseCount) or currentCount
        basePiercing = state.basePiercing == true
    end

    local targetCount = math.min(8, math.max(1, baseCount) + extra)
    local targetPiercing = basePiercing or extra > 0
    -- Short-circuit identical values: no repeated native setter on equip/unequip.
    local okCount,okPiercing = true,true
    if not sameNumber(currentCount,targetCount) then
        okCount = pcall(function() item:setMaxHitCount(targetCount) end)
    end
    if currentPiercing ~= targetPiercing then
        okPiercing = pcall(function() item:setPiercingBullets(targetPiercing) end)
    end
    if not okCount or not okPiercing then return false end
    if kind=='Shotgun' then
        -- Retire the old native shotgun penetration overlay, recovering saved
        -- originals only when the existing old overlay is still recognizable.
        data.PartnerPLBPenetration=nil
        return true
    end
    if type(state)=='table'
       and sameNumber(state.baseCount,baseCount)
       and (state.basePiercing==true)==basePiercing
       and sameNumber(state.targetCount,targetCount)
       and (state.targetPiercing==true)==targetPiercing then
        return true
    end
    data.PartnerPLBPenetration = {
        baseCount = baseCount,
        basePiercing = basePiercing,
        targetCount = targetCount,
        targetPiercing = targetPiercing,
        category = kind,
    }
    return true
end

PLB.ApplyClassPenetration = tuneWeapon

-- No separate inventory sweep or equip listeners: applyInstance() in the
-- shared core invokes PLB.ApplyClassPenetration in the same pass.
