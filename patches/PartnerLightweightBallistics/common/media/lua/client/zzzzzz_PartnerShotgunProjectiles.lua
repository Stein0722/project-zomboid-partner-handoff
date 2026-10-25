-- Partner Shotgun Projectiles 0.3.0: native-aim-safe follow-through architecture.
-- This is NOT a complete replacement of Build 42's firearm ballistics.
-- Vanilla controls aim, primary hits, XP, ammo, attachments and equipment.
-- Bonus piercing requires a REAL vanilla zombie hit. No native weapon fields are suppressed.
if isServer and isServer() then return end
if PartnerShotgunProjectiles then return end

local PSP = {
    VERSION='0.3.0',
    config={enabled=true, showPellets=true, pellets=12, penetration=2, spread=20,
            damageScale=0.70, debug=false},
    shots={}, tickNumber=0, active=true, _logOnce={}, _renderer=nil,
    _inBonusHit=false, _recentHits={}, _lastEquipWeapon=nil, _lastFireLogged=false,
    metrics={fired=0,nativeHits=0,bonusHits=0,bonusDamage=0,restored=0},
}
PartnerShotgunProjectiles=PSP
local TAG='[PartnerShotgunProjectiles]'
local function log(s) print(TAG..' '..tostring(s)) end
local function once(k,s) if not PSP._logOnce[k] then PSP._logOnce[k]=true;log(s) end end
local function call(o,m,...)
    if o==nil then return nil end
    local ok,fn=pcall(function() return o[m] end)
    if not ok or not fn then return nil end
    local success,result=pcall(fn,o,...)
    if success then return result end
    return nil
end
local function set(o,m,value) return o and pcall(function() o[m](o,value) end) or false end
local function clamp(v,a,b) return math.min(b,math.max(a,v)) end
local function nowMs() return getTimestampMs and getTimestampMs() or nil end
local function alive(z)
    return z and instanceof and instanceof(z,'IsoZombie') and
        call(z,'isDead')~=true and call(z,'isAlive')~=false
end
local function key(w)
    local a=call(w,'getAmmoType')
    return string.lower(tostring(a and (call(a,'getItemKey') or a) or ''))
end
local nativeTypes={['base.shotgun']=true,['base.doublebarrelshotgun']=true,
    ['base.sawnoffshotgun']=true,['base.sawnoffdoublebarrelshotgun']=true}
local function shotgun(w)
    if call(w,'isRanged')~=true then return false end
    local name=string.lower(tostring(call(w,'getFullType') or ''))
    local ammo=key(w)
    if ammo:find('grenade',1,true) or ammo:find('rocket',1,true) then return false end
    if nativeTypes[name] then return true end
    local plb=PartnerLightweightBallistics
    if plb and type(plb.GetRangedClass)=='function' then
        local ok,kind=pcall(plb.GetRangedClass,w)
        if ok and kind=='Shotgun' then return true end
        if ok and (kind=='Pistol' or kind=='Rifle' or kind=='SMG') then return false end
    end
    return name:find('shotgun',1,true)~=nil or name:find('mossberg',1,true)~=nil
        or name:find('saiga12',1,true)~=nil or ammo:find('shotgunshell',1,true)~=nil
        or ammo:find('12gauge',1,true)~=nil or ammo:find('12ga',1,true)~=nil
        or ammo:find('buckshot',1,true)~=nil or ammo:find('slug',1,true)~=nil
end
PSP.IsShotgun=shotgun

-- Repair persistent zeroed values from 0.2.2/0.2.3. NEVER touch healthy guns.
-- A fresh template is used only once per damaged instance; if missing, fail closed.
local function migrate(w)
    if not w or not shotgun(w) then return false end
    local oldCount=tonumber(call(w,'getMaxHitCount'))
    local oldProjectiles=tonumber(call(w,'getProjectileCount'))
    local md=call(w,'getModData')
    local legacy=md and md.PSPNativeV020
    local broken=(oldCount~=nil and oldCount<=0) or
        (oldProjectiles~=nil and oldProjectiles<=0) or type(legacy)=='table'
    if not broken then return true end
    local script=call(w,'getScriptItem')
    local original=script and tonumber(call(script,'getMaxHitCount')) or nil
    local fresh=nil
    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        local ok,item=pcall(InventoryItemFactory.CreateItem,tostring(call(w,'getFullType') or ''))
        if ok then fresh=item end
    end
    local maxCount=type(legacy)=='table' and tonumber(legacy.maxHitCount) or nil
    local projCount=type(legacy)=='table' and tonumber(legacy.projectileCount) or nil
    maxCount=maxCount and maxCount>0 and maxCount or (original and original>0 and original or tonumber(call(fresh,'getMaxHitCount')))
    projCount=projCount and projCount>0 and projCount or tonumber(call(fresh,'getProjectileCount'))
    if oldCount and oldCount<=0 and maxCount and maxCount>0 then set(w,'setMaxHitCount',math.floor(maxCount)) end
    if oldProjectiles and oldProjectiles<=0 and projCount and projCount>0 then set(w,'setProjectileCount',math.floor(projCount)) end
    -- Two other properties that v0.2.2 may have suppressed; legacy snapshots only.
    if type(legacy)=='table' then
        if legacy.treeDamage~=nil and call(w,'getTreeDamage')==0 then set(w,'setTreeDamage',legacy.treeDamage) end
        if legacy.doorDamage~=nil and call(w,'getDoorDamage')==0 then set(w,'setDoorDamage',legacy.doorDamage) end
        if legacy.rangeFalloff~=nil and call(w,'isRangeFalloff')==true then set(w,'setRangeFalloff',legacy.rangeFalloff) end
        md.PSPNativeV020=nil
    end
    if (tonumber(call(w,'getMaxHitCount')) or 0)<=0 or
        (tonumber(call(w,'getProjectileCount')) or 0)<=0 then
        once('migrationFailed:'..tostring(call(w,'getFullType')),
            'SAFE WARNING: saved shotgun hit values are zero and template recovery unavailable; disable beta and inspect weapon')
        return false
    end
    PSP.metrics.restored=PSP.metrics.restored+1
    log('MIGRATED stale v0.2.x weapon suppression for '..tostring(call(w,'getFullType')))
    return true
end
PSP.Migrate=migrate

-- Distinct ammunition and gun geometry profiles, no per-frame profile lookups.
local function profile(w)
    local name=string.lower(tostring(call(w,'getFullType') or ''))
    local ammo=key(w)
    local p={kind='buckshot',count=9,spread=9,pierce=2,bonusRatio=.28,victims=2}
    if ammo:find('slug',1,true) then
        p.kind='slug';p.count=1;p.spread=.8;p.pierce=2;p.bonusRatio=.38;p.victims=1
    elseif ammo:find('bird',1,true) or ammo:find('smallshot',1,true) then
        p.kind='birdshot';p.count=14;p.spread=14;p.pierce=1;p.bonusRatio=.09;p.victims=1
    elseif ammo:find('000',1,true) then
        p.kind='000buck';p.count=8;p.spread=8;p.bonusRatio=.30
    end
    if name:find('sawn',1,true) or name:find('sawnoff',1,true) or name:find('shorty',1,true) then
        p.spread=p.spread*1.75;p.model='sawn-off'
    elseif name:find('double',1,true) then
        p.spread=p.spread*1.15;p.model='double'
    elseif name:find('saiga',1,true) or name:find('mossberg',1,true) or name:find('tactical',1,true) then
        p.spread=p.spread*.9;p.model='tactical'
    else p.model='standard' end
    p.count=math.min(p.count,math.floor(clamp(tonumber(PSP.config.pellets) or 12,1,20)))
    p.spread=math.min(p.spread,clamp(tonumber(PSP.config.spread) or 20,3,40))
    p.pierce=math.min(p.pierce,math.floor(clamp(tonumber(PSP.config.penetration) or 2,1,4)))
    return p
end
PSP.ResolveProfile=profile
local function rnd()
    if ZombRand then return ZombRand(1000000)/1000000 end
    return math.random()
end
local function jitter(span)
    return (rnd()+rnd()+rnd()+rnd()-2)*0.5*math.rad(span/2)
end
local function lineClear(cell,x0,y0,x1,y1,z)
    if not LosUtil or not LosUtil.lineClear then return false end
    local ok,result=pcall(LosUtil.lineClear,cell,math.floor(x0),math.floor(y0),z,
        math.floor(x1),math.floor(y1),z,false)
    if not ok or not result then return false end
    local flag=tostring(result):match('([%w]+)$') or ''
    return flag=='Clear' or flag=='ClearThroughOpenDoor'
end
PSP.LineClear=lineClear

local function display(ray)
    if not PSP.config.showPellets or not PSP.active then return end
    if not (TextDrawObject and ISCoordConversion and getCore) then return end
    if not PSP._renderer then
        local ok,d=pcall(function()
            local r=TextDrawObject.new()
            r:setDefaultColors(1,1,1,1);r:setOutlineColors(0,0,0,0)
            r:setAllowAnyImage(true)
            r:ReadString(UIFont.Small,'[img=media/ui/PartnerShotgunProjectiles/Pellet.png]',-1)
            return r
        end)
        if not ok then once('sprite','Pellet visual unavailable; collision remains native');return end
        PSP._renderer=d
    end
    local s=ray.shot
    pcall(function()
        local xx,yy=ISCoordConversion.ToScreen(s.x+ray.dx*ray.distance,s.y+ray.dy*ray.distance,s.z+.38)
        local zoom=getCore():getZoom(0)
        if zoom and zoom>0 then xx=xx/zoom;yy=yy/zoom end
        PSP._renderer:AddBatchedDraw(xx-5,yy-5,true)
    end)
end

-- Native-impact-triggered, additive follow-through only. Never modify first-hit victims.
-- Collide against CURRENT zombie positions rather than a cached 'future hit' snapshot.
local function scanBehind(shot,contact)
    if not alive(contact.z) then
        -- Dead by vanilla is valid. We still use the contact coordinates from the event.
        if not contact.x or not contact.y then return {} end
    end
    local tx,ty=contact.x,contact.y
    local ux,uy=tx-shot.x,ty-shot.y
    local length=math.sqrt(ux*ux+uy*uy)
    if length<.05 then return {} end
    ux,uy=ux/length,uy/length
    local range=shot.range
    if range<=length+.38 then return {} end
    local ex,ey=shot.x+ux*range,shot.y+uy*range
    local extent=1+math.tan(math.rad(shot.profile.spread/2))*(range-length)
    local xmin,xmax=math.floor(math.min(tx,ex)-extent),math.floor(math.max(tx,ex)+extent)
    local ymin,ymax=math.floor(math.min(ty,ey)-extent),math.floor(math.max(ty,ey)+extent)
    -- Refuse very large spatial scans; never freeze the main thread in a horde.
    if (xmax-xmin+1)*(ymax-ymin+1)>192 then
        once('scanCap','SAFE SKIP: penetration scan grid too large')
        return {}
    end
    local seen,out={},{}
    for y=ymin,ymax do for x=xmin,xmax do
        local sq=call(shot.cell,'getGridSquare',x,y,shot.z)
        local mo=call(sq,'getMovingObjects')
        local n=math.min(tonumber(call(mo,'size')) or 0,200)
        for j=0,n-1 do
            local z=call(mo,'get',j)
            if alive(z) and not seen[z] and not shot.native[z] and not shot.bonus[z] then
                seen[z]=true
                local zx,zy,zz=tonumber(call(z,'getX')),tonumber(call(z,'getY')),tonumber(call(z,'getZ'))
                if zx and zy and zz and math.abs(zz-shot.z)<.5 then
                    local ax,ay=zx-tx,zy-ty
                    local forward=ax*ux+ay*uy
                    if forward>.5 and forward<range-length and lineClear(shot.cell,tx,ty,zx,zy,shot.z) then
                        local perp=math.abs(ax*uy-ay*ux)
                        local width=.42+forward*math.tan(math.rad(shot.profile.spread/2))*.55
                        if perp<=width then
                            -- Preserve the actual per-shell random pellet pattern: a second
                            -- zombie must lie on at least one ray that also crossed the
                            -- confirmed vanilla target. This check is only a handful of
                            -- multiplications; it does not rescan the world per pellet.
                            local crossed=0
                            for _,offset in ipairs(shot.offsets) do
                                local c,si=math.cos(offset),math.sin(offset)
                                local dx,dy=ux*c-uy*si,uy*c+ux*si
                                local primaryPerp=math.abs((tx-shot.x)*dy-(ty-shot.y)*dx)
                                local secondPerp=math.abs((zx-shot.x)*dy-(zy-shot.y)*dx)
                                if primaryPerp<=.43 and secondPerp<=.43 then
                                    crossed=crossed+1
                                end
                            end
                            if crossed>0 then
                                out[#out+1]={z=z,x=zx,y=zy,forward=forward,
                                    perp=perp,crossed=crossed}
                            end
                        end
                    end
                end
            end
        end
    end end
    table.sort(out,function(a,b)return a.forward<b.forward end)
    return out
end
local function processFollowThrough(shot)
    if shot.processed or not shot.confirmed then return end
    shot.processed=true
    if shot.profile.pierce<=1 or not PSP.config.enabled or not PSP.active or PSP.suspended then return end
    if not LosUtil or not LosUtil.lineClear then
        once('noLos','SAFE SKIP: line-of-sight API unavailable')
        return
    end
    local granted=0
    for _,contact in ipairs(shot.contacts) do
        if granted>=shot.profile.victims then break end
        local result=scanBehind(shot,contact)
        local minD,maxD=tonumber(call(shot.weapon,'getMinDamage')) or .5,
            tonumber(call(shot.weapon,'getMaxDamage')) or 1.5
        local average=math.max(.1,(minD+maxD)*.5)
        local nativeD=math.max(.01,tonumber(contact.damage) or average)
        local budget=math.min(average*.65,nativeD*.45)*clamp(PSP.config.damageScale or .7,.1,1.0)
        for _,v in ipairs(result) do
            if granted>=shot.profile.victims or budget<=.01 then break end
            if not shot.native[v.z] and not shot.bonus[v.z] and alive(v.z) then
                -- Conservative: only targets behind a CONFIRMED vanilla primary hit.
                local attenuation=clamp(1-v.forward/(shot.range+.01),.25,.85)
                local d=math.min(budget,average*shot.profile.bonusRatio*attenuation)
                if d>.02 then
                    PSP._inBonusHit=true
                    local ok=pcall(function() v.z:Hit(shot.weapon,shot.player,d,false,2.0) end)
                    PSP._inBonusHit=false
                    if not ok then
                        once('hitFail','SAFE STOP bonus damage: IsoZombie.Hit API incompatible')
                        PSP.active=false;return
                    end
                    shot.bonus[v.z]=true
                    budget=budget-d;granted=granted+1
                    PSP.metrics.bonusHits=PSP.metrics.bonusHits+1
                    PSP.metrics.bonusDamage=PSP.metrics.bonusDamage+d
                end
            end
        end
    end
    if PSP.config.debug then
        log('SHOT COMPLETE '..shot.profile.kind..' native='..#shot.contacts..' bonus='..granted)
    end
end

local function nativeHit(attacker,target,w,damage)
    if PSP._inBonusHit or not PSP.config.enabled or not PSP.active or PSP.suspended then return end
    if not (w and shotgun(w) and alive(target) or
        w and shotgun(w) and target and instanceof and instanceof(target,'IsoZombie')) then return end
    local player=getPlayer and getPlayer()
    if attacker~=player then return end
    PSP.metrics.nativeHits=PSP.metrics.nativeHits+1
    local event={weapon=w,z=target,x=tonumber(call(target,'getX')),
                 y=tonumber(call(target,'getY')), damage=damage,tick=PSP.tickNumber}
    -- Native projectile callbacks can occur either side of the fire event.
    for i=#PSP.shots,1,-1 do
        local shot=PSP.shots[i]
        if shot.weapon==w and PSP.tickNumber-shot.firedTick<=140 then
            if shot.bonus[target] then return end -- exclude callbacks from our own previous hit
            if not shot.native[target] then
                shot.native[target]=true
                shot.contacts[#shot.contacts+1]=event
                shot.confirmed=true;shot.lastContactTick=PSP.tickNumber
            end
            return
        end
    end
    PSP._recentHits[#PSP._recentHits+1]=event
    if #PSP._recentHits>24 then table.remove(PSP._recentHits,1) end
end
PSP.NativeHit=nativeHit

local function fire(player,w)
    if not PSP.config.enabled or not PSP.active or PSP.suspended or not player or not w or not shotgun(w) then return end
    if call(player,'isLocalPlayer')~=true then return end
    -- On a pre-v0.3.0 contaminated save, recover ONLY the current weapon once.
    if not migrate(w) then return end
    local x,y,z=tonumber(call(player,'getX')),tonumber(call(player,'getY')),tonumber(call(player,'getZ'))
    local facing=tonumber(call(player,'getLookAngleRadians'))
    local cell=call(player,'getCell') or (getCell and getCell())
    if not (x and y and z and facing and cell) then
        once('positionMissing','Shot tracer unavailable: player position/cell missing')
        return
    end
    local p=profile(w)
    local range=clamp(tonumber(call(w,'getMaxRange',player)) or 11.2,1,11.2)
    local shot={weapon=w,player=player,profile=p,x=x,y=y,z=math.floor(z),cell=cell,
        range=range,firedTick=PSP.tickNumber,native={},contacts={},bonus={},confirmed=false,
        processed=false,lastContactTick=-1000,rays={},offsets={},born=nowMs()}
    for i=1,p.count do
        local offset=jitter(p.spread)
        shot.offsets[#shot.offsets+1]=offset
        local theta=facing+offset
        shot.rays[#shot.rays+1]={shot=shot,dx=math.cos(theta),dy=math.sin(theta),distance=0}
    end
    -- Reconcile callbacks which fired before OnWeaponSwingHitPoint.
    for i=#PSP._recentHits,1,-1 do
        local event=PSP._recentHits[i]
        if PSP.tickNumber-event.tick>18 then
            table.remove(PSP._recentHits,i)
        elseif event.weapon==w and PSP.tickNumber-event.tick<=3 and not shot.native[event.z] then
            shot.native[event.z]=true;shot.contacts[#shot.contacts+1]=event
            shot.confirmed=true;shot.lastContactTick=PSP.tickNumber
            table.remove(PSP._recentHits,i)
        end
    end
    PSP.shots[#PSP.shots+1]=shot
    if #PSP.shots>6 then table.remove(PSP.shots,1) end
    PSP.metrics.fired=PSP.metrics.fired+1
    if not PSP._lastFireLogged or PSP.config.debug then
        log('FIRE '..tostring(call(w,'getFullType'))..' ammo='..key(w)
            ..' kind='..p.kind..' visualPellets='..p.count..' aim=VANILLA safeMode=ON')
        PSP._lastFireLogged=true
    end
end
PSP.Fire=fire

local lastMs=nil
local function tick()
    PSP.tickNumber=PSP.tickNumber+1
    if #PSP.shots==0 then lastMs=nil;return end
    local t=nowMs();local dt=1/60
    if t and lastMs and t>lastMs then dt=clamp((t-lastMs)/1000,1/400,.05) end
    lastMs=t
    local step=math.max(.45,140*dt)
    for i=#PSP.shots,1,-1 do
        local shot=PSP.shots[i]
        local age=PSP.tickNumber-shot.firedTick
        if PSP.config.showPellets then
            for _,ray in ipairs(shot.rays) do
                ray.distance=math.min(shot.range,ray.distance+step)
                if ray.distance<shot.range then display(ray) end
            end
        end
        -- Two ticks after the last native hit: allow other pellets' vanilla hits to register.
        -- Give the vanilla B42 projectiles time to finish before any additional hit.
        -- Use REAL elapsed time, not just a tick count (400 FPS would otherwise
        -- shorten the grace period to a few milliseconds).
        local elapsed=t and shot.born and t-shot.born or nil
        local nativeGrace=elapsed and elapsed>=80 or (not elapsed and age>=8)
        if shot.confirmed and nativeGrace and PSP.tickNumber-shot.lastContactTick>=3 then
            processFollowThrough(shot)
        end
        if (elapsed and elapsed>=320) or (not elapsed and age>=140) then
            if not shot.confirmed then
                once('noImpactObserved','No vanilla shotgun impact observed for a shell; zero bonus damage (misses are normal)')
                if PSP.config.debug then
                    log('SHOT native-hit event absent; no additional damage (safe fail-closed)')
                end
            end
            if shot.confirmed and not shot.processed then processFollowThrough(shot) end
            table.remove(PSP.shots,i)
        end
    end
    for i=#PSP._recentHits,1,-1 do
        if PSP.tickNumber-PSP._recentHits[i].tick>18 then table.remove(PSP._recentHits,i) end
    end
end
PSP.Tick=tick
local function gameStart()
    local player=getPlayer and getPlayer()
    local held=player and call(player,'getPrimaryHandItem')
    if held then migrate(held) end
    -- Recover old beta's item-instance damage in inventory at load, not on equip.
    local inv=player and call(player,'getInventory')
    local list=call(inv,'getItems')
    local n=math.min(tonumber(call(list,'size')) or 0,800)
    for i=0,n-1 do local w=call(list,'get',i); if shotgun(w) then migrate(w) end end
    log('v'..PSP.VERSION..' loaded native-safe; no equip hooks, no weapon suppression; mode='..tostring(PSP.config.enabled))
end
local function shutdown()
    -- No weapon to restore: v0.3.0 never mutates a working weapon's hit stats.
    PSP.shots={};PSP._recentHits={};lastMs=nil
end
PSP.Reset=shutdown
Events.OnTick.Add(tick)
Events.OnWeaponSwingHitPoint.Add(fire)
local hasNativeListener=false
if Events.OnWeaponHitCharacter and Events.OnWeaponHitCharacter.Add then
    Events.OnWeaponHitCharacter.Add(nativeHit)
    hasNativeListener=true
end
-- Some B42 scripts route XP/hit notifications separately. Register this as a
-- redundant, deduplicated observation source; never use it to alter vanilla damage.
if Events.OnWeaponHitXp and Events.OnWeaponHitXp.Add then
    Events.OnWeaponHitXp.Add(function(attacker,weapon,target,damage)
        nativeHit(attacker,target,weapon,damage)
    end)
    hasNativeListener=true
end
if not hasNativeListener then
    once('noNativeEvent','Hit callback unavailable: VISUAL ONLY, vanilla damage untouched')
end
Events.OnGameStart.Add(gameStart)
