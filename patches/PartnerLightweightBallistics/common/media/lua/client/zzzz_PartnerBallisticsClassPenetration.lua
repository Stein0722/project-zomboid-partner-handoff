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
    local kind = PLB.GetRangedClass and PLB.GetRangedClass(item) or nil
    if not kind then
        return false
    end

    local extra = math.floor(tonumber(PLB.PenetrationByClass[kind]) or 0)
    if extra < 0 then extra = 0 end
    if extra > 4 then extra = 4 end

    local currentCount = tonumber(safe(item, "getMaxHitCount")) or 1
    local currentPiercing = safe(item, "isPiercingBullets") == true
    local data = safe(item, "getModData")
    if not data then
        return false
    end

    local state = data.PartnerPLBPenetration
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
    local okCount = pcall(function() item:setMaxHitCount(targetCount) end)
    local okPiercing = pcall(function() item:setPiercingBullets(targetPiercing) end)
    if not okCount or not okPiercing then
        return false
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

local beforeInventory = PLB.ApplyPlayerInventory
if type(beforeInventory) == "function" then
    PLB.ApplyPlayerInventory = function(player)
        local result = beforeInventory(player)
        local inventory = safe(player, "getInventory")

        local function visit(container, depth)
            if not container or depth > 8 then
                return 0
            end
            local items = safe(container, "getItems")
            if not items then
                return 0
            end
            local ok, count = pcall(function() return items:size() end)
            if not ok then
                return 0
            end
            local changed = 0
            for i = 0, count - 1 do
                local obj = items:get(i)
                if tuneWeapon(obj) then
                    changed = changed + 1
                end
                local child = safe(obj, "getInventory")
                if child then
                    changed = changed + visit(child, depth + 1)
                end
            end
            return changed
        end

        local changed = visit(inventory, 0)
        if changed > 0 then
            print(string.format("[PartnerLightweightBallistics] class penetration refreshed on %d ranged weapon(s).", changed))
        end
        return result
    end
end

-- Registered after the original handlers: preset tuning runs first, then this
-- independent class bonus. It therefore works in every preset.
Events.OnEquipPrimary.Add(function(_, item) tuneWeapon(item) end)
Events.OnEquipSecondary.Add(function(_, item) tuneWeapon(item) end)
