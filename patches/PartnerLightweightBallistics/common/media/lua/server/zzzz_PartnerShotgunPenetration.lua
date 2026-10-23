-- B42 resolves shotgun pellet spread before MaxHitCount/PiercingBullets.
-- Those fields can limit already-selected pellet targets, but they cannot add
-- a zombie behind the first target. This event-only supplement handles that
-- shotgun-specific gap without OnTick, projectile objects or global searches.
local PLB = PartnerLightweightBallistics
if not PLB or PLB._partnerShotgunPenetrationInstalled then
    return
end
PLB._partnerShotgunPenetrationInstalled = true

local busy = false

local function safe(object, method, ...)
    if not object then
        return nil
    end
    local fn = object[method]
    if not fn then
        return nil
    end
    local ok, value = pcall(fn, object, ...)
    if ok then
        return value
    end
    return nil
end

local function isLivingZombie(object)
    return object
        and instanceof(object, "IsoZombie")
        and safe(object, "isDead") ~= true
end

local function hasClearLine(cell, fromX, fromY, z, toX, toY)
    if not LosUtil or not LosUtil.lineClear then
        return true
    end
    local ok, result = pcall(
        LosUtil.lineClear,
        cell,
        math.floor(fromX), math.floor(fromY), math.floor(z),
        math.floor(toX), math.floor(toY), math.floor(z),
        false
    )
    if not ok then
        return true
    end
    local text = string.lower(tostring(result or ""))
    return text:find("blocked", 1, true) == nil
        and text:find("closeddoor", 1, true) == nil
end

local function nativeHitTargets(owner)
    local result = {}
    local hitList = safe(owner, "getHitInfoList")
    if not hitList then
        return result
    end
    local ok, count = pcall(function() return hitList:size() end)
    if not ok then
        return result
    end
    for i = 0, count - 1 do
        local info = hitList:get(i)
        local object = safe(info, "getObject")
        if object then
            result[object] = true
        end
    end
    return result
end

local function collectBehindTargets(owner, firstTarget, weapon, limit)
    local ownerX = tonumber(safe(owner, "getX")) or 0
    local ownerY = tonumber(safe(owner, "getY")) or 0
    local ownerZ = tonumber(safe(owner, "getZ")) or 0
    local targetX = tonumber(safe(firstTarget, "getX")) or ownerX
    local targetY = tonumber(safe(firstTarget, "getY")) or ownerY
    local dx = targetX - ownerX
    local dy = targetY - ownerY
    local firstDistance = math.sqrt(dx * dx + dy * dy)
    if firstDistance < 0.1 then
        return {}
    end

    local dirX = dx / firstDistance
    local dirY = dy / firstDistance
    local maxRange = tonumber(safe(weapon, "getMaxRange", owner)) or 10
    if maxRange <= firstDistance + 0.2 then
        return {}
    end

    local cell = safe(owner, "getCell") or (getCell and getCell())
    if not cell then
        return {}
    end

    local nativeTargets = nativeHitTargets(owner)
    nativeTargets[firstTarget] = true
    local visitedSquares = {}
    local candidates = {}
    local seen = {}
    local step = firstDistance + 0.35

    while step <= maxRange + 0.25 do
        local centerX = ownerX + dirX * step
        local centerY = ownerY + dirY * step
        local squareX = math.floor(centerX)
        local squareY = math.floor(centerY)
        for oy = -1, 1 do
            for ox = -1, 1 do
                local sx = squareX + ox
                local sy = squareY + oy
                local squareKey = tostring(sx) .. ":" .. tostring(sy)
                if not visitedSquares[squareKey] then
                    visitedSquares[squareKey] = true
                    local square = cell:getGridSquare(sx, sy, math.floor(ownerZ))
                    local movers = square and square:getMovingObjects()
                    if movers then
                        for i = 0, movers:size() - 1 do
                            local zombie = movers:get(i)
                            if isLivingZombie(zombie)
                                and not nativeTargets[zombie]
                                and not seen[zombie] then
                                local zx = tonumber(safe(zombie, "getX")) or sx + 0.5
                                local zy = tonumber(safe(zombie, "getY")) or sy + 0.5
                                local zz = tonumber(safe(zombie, "getZ")) or ownerZ
                                local relX = zx - ownerX
                                local relY = zy - ownerY
                                local forward = relX * dirX + relY * dirY
                                local lateral = math.abs(relX * dirY - relY * dirX)
                                if math.abs(zz - ownerZ) < 0.5
                                    and forward > firstDistance + 0.15
                                    and forward <= maxRange + 0.25
                                    and lateral <= 0.45
                                    and hasClearLine(cell, targetX, targetY, ownerZ, zx, zy) then
                                    seen[zombie] = true
                                    candidates[#candidates + 1] = {
                                        zombie = zombie,
                                        distance = forward,
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
        step = step + 0.5
    end

    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    local result = {}
    for i = 1, math.min(limit, #candidates) do
        result[#result + 1] = candidates[i].zombie
    end
    return result
end

local function onWeaponHitXp(owner, weapon, hitObject, damage)
    if busy or not owner or not weapon or not isLivingZombie(hitObject) then
        return
    end
    if safe(weapon, "isRanged") ~= true or safe(weapon, "isRangeFalloff") ~= true then
        return
    end
    if not PLB.GetRangedClass or PLB.GetRangedClass(weapon) ~= "Shotgun" then
        return
    end

    local extra = math.floor(tonumber(
        PLB.PenetrationByClass and PLB.PenetrationByClass.Shotgun
    ) or 0)
    if extra <= 0 then
        return
    end
    if extra > 4 then
        extra = 4
    end

    local baseDamage = tonumber(damage) or 0
    if baseDamage <= 0 then
        return
    end

    local targets = collectBehindTargets(owner, hitObject, weapon, extra)
    if #targets == 0 then
        return
    end

    busy = true
    local successful = 0
    for i = 1, #targets do
        -- Each body absorbs some pellet energy, so later targets receive less.
        local passedDamage = baseDamage * (0.85 ^ i)
        local ok = pcall(targets[i].Hit, targets[i], weapon, owner, passedDamage, false, 2.0)
        if ok then
            successful = successful + 1
        end
    end
    busy = false

    if successful > 0 then
        print(string.format(
            "[PartnerLightweightBallistics] shotgun passthrough hit %d additional target(s).",
            successful
        ))
    end
end

Events.OnWeaponHitXp.Add(onWeaponHitXp)
