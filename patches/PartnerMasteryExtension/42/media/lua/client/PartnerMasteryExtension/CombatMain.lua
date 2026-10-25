require "PartnerMasteryExtension/CombatConfig"
require "PartnerMasteryExtension/CombatLogic"
local P=PartnerMasteryExtensionCombat
local cfg=P.Config
if isClient and isClient() then return end -- SP-only; no MP authority code

local function get(obj,method,...)
    if not obj then return nil end
    local args={...}
    local unpackArgs=table.unpack or unpack
    local ok,v=pcall(function() return obj[method](obj,unpackArgs(args)) end)
    if ok then return v end
end
local function set(obj,method,...)
    if not obj then return false end
    local args={...}
    local unpackArgs=table.unpack or unpack
    local ok=pcall(function() obj[method](obj,unpackArgs(args)) end)
    return ok
end
local function num(n)
    local ok,v=pcall(function() return tonumber(tostring(n)) end)
    return ok and v or nil
end
local function localPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end
local function isZombie(z)
    if not z then return false end
    if instanceof then
        local ok,v=pcall(instanceof,z,"IsoZombie")
        if ok then return v==true end
    end
    return get(z,"isZombie")==true
end
local function perkId(item)
    local perk=get(item,"getPerk")
    if perk==nil then return nil end
    local raw=get(perk,"getId")
    return P.PerkName(raw or perk)
end
local function isMelee(item)
    if not item or get(item,"isRanged")~=false then return false end
    return P.MELEE[perkId(item) or ""]==true
end
local function skill(player,id)
    if not player or not id then return 0 end
    local pme=PartnerMasteryExtension
    if not (pme and type(pme.GetEffectiveLevel)=='function') then return 0 end
    if not (Perks and type(Perks.FromString)=='function') then return 0 end
    local ok,perk=pcall(Perks.FromString,id)
    if (not ok or perk==nil or (Perks.MAX and perk==Perks.MAX)) and id=='LongBlunt' then
        ok,perk=pcall(Perks.FromString,'Blunt')
    end
    if (not ok or perk==nil or (Perks.MAX and perk==Perks.MAX)) and id=='Blunt' then
        ok,perk=pcall(Perks.FromString,'LongBlunt')
    end
    if not ok or not perk or (Perks.MAX and perk==Perks.MAX) then return 0 end
    local good,value=pcall(pme.GetEffectiveLevel,player,perk)
    return good and math.max(0,num(value) or 0) or 0
end
local testNotices={repair=0,shockwave=0,penetration=0}
local diagnosticCounts={}
local function diag(key,msg)
    if not (cfg.testMode and cfg.diagnostics) then return end
    local limit=math.max(1, math.floor(tonumber(cfg.diagnosticLimit) or 6))
    local n=diagnosticCounts[key] or 0
    if n>=limit then return end
    diagnosticCounts[key]=n+1
    print('[PartnerMasteryExtensionCombat][DIAG] '..key..' :: '..tostring(msg)..' ('..(n+1)..'/'..limit..')')
end
local function itemName(item)
    if not item then return 'nil' end
    return tostring(get(item,'getFullType') or 'unknown')
end
local function announce(key,message)
    if not cfg.testMode or not cfg.testAnnouncements then return end
    local n=testNotices[key] or 0
    if n<5 then
        testNotices[key]=n+1
        print('[PartnerMasteryExtensionCombat][TEST] '..message..' ('..(n+1)..'/5)')
    end
end
local function roll(chance)
    if chance<=0 then return false end
    if chance>=1 then return true end
    return ZombRand and ZombRand(1000000) < math.floor(chance*1000000+0.5) or false
end

-- Attack-local state: one roll per completed swing, not per hit target.
local state={weapon=nil,active=false,sequence=0,seen=nil,waveTriggered=false,meleeSkill=0,maintenance=0,
    sources=nil,confirmed=0,repairHits=0,waveHits=0,lastFinish=nil}
local restorePen
local tempPen=setmetatable({}, {__mode="k"})
local function restoreOne(item)
    if not item then return end
    local md=get(item,"getModData")
    local saved=md and md.PartnerCombatTemporaryPenetration
    if not saved then return end
    if num(get(item,"getMaxHitCount"))==num(saved.applied) then
        set(item,"setMaxHitCount",num(saved.base))
    elseif cfg.debug then
        print("[PartnerMasteryExtensionCombat] MaxHitCount was overwritten by another mod; leaving its value unchanged")
    end
    -- Restore piercing independently. A third-party MaxHitCount rewrite should
    -- not leave our temporary penetrating-bullets flag latched forever.
    if get(item,"isPiercingBullets")==true and saved.piercing~=true then
        set(item,"setPiercingBullets",false)
    end
    md.PartnerCombatTemporaryPenetration=nil
    tempPen[item]=nil
end
restorePen=restoreOne

local function attackBegin(player,item)
    if player~=localPlayer() or not item then return end
    if not cfg.enabled then restoreOne(item); return end
    if state.weapon and state.weapon~=item then restoreOne(state.weapon) end
    restoreOne(item) -- does not allow previous gun rolls to stack
    state.weapon=item
    state.active=true
    state.seen=setmetatable({}, {__mode="k"})
    state.waveTriggered=false
    state.sequence=state.sequence+1
    state.meleeSkill=0
    state.maintenance=0
    state.sources={character=0,zombie=0,xp=0}
    state.confirmed=0
    state.repairHits=0
    state.waveHits=0
    state.lastFinish=nil
    if isMelee(item) then
        if cfg.shockwave then state.meleeSkill=skill(player,perkId(item)) end
        if cfg.indomitable then state.maintenance=skill(player,"Maintenance") end
    end
    if get(item,"isRanged")==false then
        local p=perkId(item)
        if cfg.diagnostics then diag('swing-melee',itemName(item)..' perk='..tostring(p)..' eligible='..tostring(isMelee(item))) end
    end
    if get(item,"isRanged")~=true or not cfg.overpenetration then return end
    -- Optional bridge: VTB owns ballistics in Viewpoint first/third person.
    -- This check runs before touching the weapon's temporary native hit cap.
    local bridge=PartnerViewpointBallisticsBridge
    if bridge and type(bridge.IsExternalBallistics)=='function' and bridge.IsExternalBallistics() then
        return
    end
    if (num(get(item,"getProjectileCount")) or 1)>1 then return end
    local mode=string.lower(tostring(get(item,"getFireMode") or ""))
    local possibilities=string.lower(tostring(get(item,"getFireModePossibilities") or ""))
    local automatic=mode:find("auto",1,true)~=nil or possibilities:find("auto",1,true)~=nil
    -- PLB 1.2.0 knows the exact class of each supported firearm. Do not
    -- bypass its special/ammo exclusion list or guess rifles as pistols.
    local plb=PartnerLightweightBallistics
    if not (plb and type(plb.GetRangedClass)=="function") then return end
    local okClass,plbClass=pcall(plb.GetRangedClass,item)
    if not okClass or not plbClass then return end
    local category=P.ClassifyWeapon(get(item,"getFullType"),get(item,"getAmmoType"),automatic,get(item,"isTwoHandWeapon")==true,plbClass)
    local chance,extra=P.PenetrationPlan(skill(player,"Aiming"),category)
    if not roll(chance) or extra<1 then return end
    local base=num(get(item,"getMaxHitCount"))
    -- A default MaxHitcount of 1000 is a sentinel, not 1000 real targets.
    if not base or base<1 or base>64 then return end
    -- Do not remove any class penetration already configured by the stable PLB.
    -- A high-proc test must not turn a rifle into a 20-target instant wipe.
    -- Always keep hard safety caps, including when ModOptions multiplies extras.
    local maxTotal=math.max(1,math.floor(tonumber(cfg.maxTotalHitCount) or 24))
    local maxExtra=math.max(0,math.floor(tonumber(cfg.maxExtraPenetrations) or 20))
    extra=math.max(0,math.min(extra,maxExtra,maxTotal-base))
    if extra==0 then return end
    local piercing=get(item,"isPiercingBullets")==true
    if not set(item,"setMaxHitCount",base+extra) then return end
    if not set(item,"setPiercingBullets",true) then
        set(item,"setMaxHitCount",base)
        return
    end
    local md=get(item,"getModData")
    if type(md)~="table" then
        set(item,"setMaxHitCount",base)
        set(item,"setPiercingBullets",piercing)
        return
    end
    md.PartnerCombatTemporaryPenetration={base=base,applied=base+extra,piercing=piercing}
    tempPen[item]=true
    if cfg.debug then print("[PartnerMasteryExtensionCombat] penetration "..category.." +"..extra) end
    announce('penetration','overpenetration '..tostring(category)..' + '..tostring(extra)..' temporary targets')
end

local function recoverCondition(item,level)
    if not cfg.enabled or not cfg.indomitable then return false end
    local chance=P.IndomitableChance(level)
    if chance<=0 or not roll(chance) then return false end
    local condition=num(get(item,"getCondition"))
    local maximum=num(get(item,"getConditionMax"))
    if not condition or not maximum then
        diag('repair-condition-api','getCondition='..tostring(condition)..' getConditionMax='..tostring(maximum))
        return false
    end
    if condition<=0 or condition>=maximum then
        diag('repair-not-needed','condition='..condition..' maximum='..maximum)
        return false
    end
    local nextValue=math.min(maximum,condition+1)
    if set(item,"setCondition",nextValue) then
        state.repairHits=state.repairHits+1
        if cfg.debug then print("[PartnerMasteryExtensionCombat] condition "..condition.." -> "..nextValue) end
        announce('repair','indomitable weapon condition '..tostring(condition)..' -> '..tostring(nextValue))
        return true
    end
    diag('repair-set-failed','setCondition failed on '..itemName(item))
    return false
end

-- Block damage through walls/closed doors: verify EACH square transition
-- using B42 IsoGridSquare:isBlockedTo. Unknown collision => no extra hit.
-- These checks run ONLY after a confirmed melee hit and once per swing.
-- Radius is centered on that hit target, not the attacker.
local function clearWavePath(cell,z,x,y,tx,ty)
    local dx,dy=tx-x,ty-y
    local distance=math.sqrt(dx*dx+dy*dy)
    local steps=math.max(1,math.ceil(distance*3))
    local prev=get(cell,"getGridSquare",math.floor(x),math.floor(y),math.floor(z))
    if not prev then return false end
    for j=1,steps do
        local t=j/steps
        local nextSq=get(cell,"getGridSquare",math.floor(x+dx*t),math.floor(y+dy*t),math.floor(z))
        if not nextSq then return false end
        if nextSq~=prev then
            local checked,blocked=pcall(function() return prev:isBlockedTo(nextSq) end)
            if not checked or blocked~=false then return false end
        end
        prev=nextSq
    end
    return true
end
local failingSplash=false
local splashReentrant=false
local function shockwave(player,center,weapon,rawDamage,level)
    if not cfg.enabled or not cfg.shockwave or failingSplash or splashReentrant or state.waveTriggered then return end
    local chance,radius,fraction=P.ShockwavePlan(level)
    if radius<=0 or fraction<=0 or not roll(chance) then return end
    -- At most one propagated splash per attack to avoid event recursion/storms.
    state.waveTriggered=true
    local cell=getCell and getCell() or nil
    local x,y,z=num(get(center,"getX")),num(get(center,"getY")),num(get(center,"getZ"))
    local damage=num(rawDamage)
    if not cell or not x or not y or not z or not damage or damage<=0 then
        diag('splash-invalid-params','cell='..tostring(cell~=nil)..' xyz='..tostring(x)..','..tostring(y)..','..tostring(z)..' damage='..tostring(damage))
        return
    end
    local spread=math.ceil(radius)
    local processed=setmetatable({}, {__mode="k"})
    local count=0
    local examined=0
    local wallBlocked=0
    local inCircle=0
    splashReentrant=true
    for sx=math.floor(x)-spread,math.floor(x)+spread do
        for sy=math.floor(y)-spread,math.floor(y)+spread do
            local square=get(cell,"getGridSquare",sx,sy,math.floor(z))
            local zombies=get(square,"getMovingObjects")
            local countInSquare=num(get(zombies,"size")) or 0
            for i=0,countInSquare-1 do
                examined=examined+1
                -- Hard upper bound: very dense hordes must not stall one frame.
                if examined>(cfg.maxSplashCandidates or 256) or count>=(cfg.maxSplashVictims or 16) then
                    splashReentrant=false
                    if cfg.debug then print("[PartnerMasteryExtensionCombat] splash search capped") end
                    return
                end
                local target=get(zombies,"get",i)
                if target~=center and not processed[target] and isZombie(target)
                    and get(target,"isDead")~=true then
                    processed[target]=true
                    local zx,zy=num(get(target,"getX")),num(get(target,"getY"))
                    if zx and zy and P.InSplashCircle(x,y,zx,zy,radius) then
                        inCircle=inCircle+1
                        if clearWavePath(cell,z,x,y,zx,zy) then
                            -- Splash-origin victims must not trigger another passive on a later event.
                            if state.seen then state.seen[target]=true end
                            local ok,err=pcall(function()
                                target:Hit(weapon,player,damage*fraction,false,1.0,false)
                            end)
                            if not ok then
                                failingSplash=true -- fail closed: no spam / no repeated invalid native hits
                                diag('splash-hit-error',tostring(err))
                                print("[PartnerMasteryExtensionCombat] splash native Hit() rejected; splash disabled until next restart")
                                splashReentrant=false
                                return
                            end
                            count=count+1
                        else
                            wallBlocked=wallBlocked+1
                        end
                    end
                end
            end
        end
    end
    splashReentrant=false
    state.waveHits=state.waveHits+count
    if count==0 then
        diag('splash-no-target','insideRadius='..tostring(inCircle)..' blocked='..tostring(wallBlocked)..' examined='..tostring(examined))
    end
    if cfg.debug and count>0 then print("[PartnerMasteryExtensionCombat] shockwave targets="..count) end
    announce('shockwave','splash triggered, additional targets='..tostring(count))
end

-- All hit event sources converge here; one zombie per swing is counted once.
-- Character is primary (exact damage), XP is alternate (exact damage),
-- OnHitZombie is a diagnostic/fallback (no damage argument in B42).
local function onHitFrom(source,attacker,target,weapon,damage)
    if not cfg.enabled or attacker~=localPlayer() then return end
    if state.sources then state.sources[source]=(state.sources[source] or 0)+1 end
    if cfg.diagnostics then diag('event-'..source,'active='..tostring(state.active)..' weapon='..itemName(weapon)) end
    if splashReentrant then return end
    if not state.active then
        diag('hit-inactive',source..' no matching active attack; attack might have ended or OnWeaponSwing was skipped')
        return
    end
    if not isZombie(target) then
        diag('hit-not-zombie',source)
        return
    end
    if weapon~=state.weapon then
        diag('hit-weapon-mismatch',source..' hit='..itemName(weapon)..' swing='..itemName(state.weapon))
        return
    end
    local perk=perkId(weapon)
    if not isMelee(weapon) then
        diag('hit-not-melee',source..' item='..itemName(weapon)..' perk='..tostring(perk)..' ranged='..tostring(get(weapon,'isRanged')))
        return
    end
    if not state.seen then state.seen=setmetatable({}, {__mode='k'}) end
    if state.seen[target] then
        diag('hit-duplicate',source..' target already handled this swing')
        return
    end
    state.seen[target]=true
    state.confirmed=state.confirmed+1
    local effectiveDamage=num(damage)
    if source=='zombie' and (effectiveDamage==nil or effectiveDamage<=0) then
        -- Fallback is conservative, NOT exact engine damage.
        -- OnHitZombie provides no damage argument, but still confirms a real hit.
        if cfg.allowEstimatedFallbackDamage then
            effectiveDamage=num(get(weapon,'getMinDamage')) or 0
            diag('hit-fallback-damage','using weapon getMinDamage='..tostring(effectiveDamage)..' (estimated)')
        end
    end
    if cfg.diagnostics then diag('hit-accepted',source..' '..itemName(weapon)..' damage='..tostring(effectiveDamage)) end
    recoverCondition(weapon,state.maintenance)
    if effectiveDamage and effectiveDamage>0 then
        shockwave(attacker,target,weapon,effectiveDamage,state.meleeSkill)
    else
        diag('splash-no-damage',source..' damage not available; repair can still trigger')
    end
end
local function onHitCharacter(attacker,target,weapon,damage)
    onHitFrom('character',attacker,target,weapon,damage)
end
local function onHitZombie(zombie,attacker,_bodyPart,weapon)
    onHitFrom('zombie',attacker,zombie,weapon,nil)
end
local function onWeaponHitXp(attacker,weapon,target,damage,_hitcount)
    onHitFrom('xp',attacker,target,weapon,damage)
end

local function attackFinished(player,weapon)
    if player~=localPlayer() then return end
    if weapon then restoreOne(weapon) end
    if state.weapon and state.weapon~=weapon then restoreOne(state.weapon) end
    if state.active and state.weapon and isMelee(state.weapon) then
        local src=state.sources or {}
        if cfg.diagnostics then diag('swing-summary','weapon='..itemName(state.weapon)..' char='..tostring(src.character or 0)
            ..' onHitZombie='..tostring(src.zombie or 0)..' xp='..tostring(src.xp or 0)
            ..' accepted='..tostring(state.confirmed)..' repaired='..tostring(state.repairHits)
            ..' splashVictims='..tostring(state.waveHits)) end
    end
    state.active=false
    state.seen=nil
    state.waveTriggered=false
end
local function equipped(player,item)
    if player~=localPlayer() then return end
    if state.weapon and state.weapon~=item then restoreOne(state.weapon) end
    if item then restoreOne(item) end
    state.weapon=item
    state.active=false
    state.seen=nil
    state.waveTriggered=false
end
local function restoreAfterRestart()
    local player=localPlayer()
    if not player then return end
    local item=get(player,"getPrimaryHandItem")
    if item then restoreOne(item) end
    state.weapon=item
    state.active=false
    state.seen=nil
    state.waveTriggered=false
    -- Most crashes cannot save mid-attack; also sweep inventory for recorded temp flags.
    local inventory=get(player,"getInventory")
    local items=get(inventory,"getItems")
    local n=num(get(items,"size")) or 0
    for i=0,n-1 do restoreOne(get(items,"get",i)) end
end

if Events and Events.OnWeaponSwing then Events.OnWeaponSwing.Add(attackBegin)
else diag('hook-missing','OnWeaponSwing not available') end
if Events and Events.OnWeaponHitCharacter then Events.OnWeaponHitCharacter.Add(onHitCharacter)
else diag('hook-missing','OnWeaponHitCharacter not available') end
if Events and Events.OnHitZombie then Events.OnHitZombie.Add(onHitZombie)
else diag('hook-missing','OnHitZombie not available') end
if Events and Events.OnWeaponHitXp then Events.OnWeaponHitXp.Add(onWeaponHitXp)
else diag('hook-missing','OnWeaponHitXp not available') end
if Events and Events.OnPlayerAttackFinished then Events.OnPlayerAttackFinished.Add(attackFinished) end
if Events and Events.OnEquipPrimary then Events.OnEquipPrimary.Add(equipped) end
if Events and Events.OnGameStart then Events.OnGameStart.Add(restoreAfterRestart) end
print("[PartnerMasteryExtensionCombat] v"..P.VERSION.." loaded. repair="..tostring(cfg.indomitable)
 .." splash="..tostring(cfg.shockwave).." penetration="..tostring(cfg.overpenetration))
if cfg.diagnostics then print('[PartnerMasteryExtensionCombat][DIAG] event hooks: swing='..tostring(Events and Events.OnWeaponSwing~=nil)
    ..' hitChar='..tostring(Events and Events.OnWeaponHitCharacter~=nil)
    ..' hitZombie='..tostring(Events and Events.OnHitZombie~=nil)
    ..' hitXp='..tostring(Events and Events.OnWeaponHitXp~=nil)) end
