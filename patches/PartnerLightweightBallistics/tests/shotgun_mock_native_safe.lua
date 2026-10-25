-- Run: texlua mock_native_safe.lua <client lua path>
local source=assert(arg[1])
local callbacks={}
local function event(name)
  local e={list={}}
  function e.Add(f) e.list[#e.list+1]=f end
  function e.Fire(...) for _,f in ipairs(e.list) do f(...) end end
  callbacks[name]=e
  return e
end
Events={OnTick=event('tick'),OnWeaponSwingHitPoint=event('fire'),
  OnWeaponHitCharacter=event('hit'),OnGameStart=event('start'),OnEquipPrimary=event('equip')}
getTimestampMs=function()return 10000+callbacks.tickCount*16 end
callbacks.tickCount=0
isServer=function()return false end
isClient=function()return false end
ZombRand=function(n) return math.floor(n*.5) end
instanceof=function(o,t) return t=='IsoZombie' and o and o.kind=='zombie' end
local setterCount=0
local w={maxHit=0,projectiles=0,name='Base.Shotgun'}
function w:isRanged()return true end
function w:getFullType()return self.name end
function w:getAmmoType()return 'Base.ShotgunShells' end
function w:getMaxHitCount()return self.maxHit end
function w:getProjectileCount()return self.projectiles end
function w:setMaxHitCount(v) self.maxHit=v;setterCount=setterCount+1 end
function w:setProjectileCount(v) self.projectiles=v;setterCount=setterCount+1 end
function w:getScriptItem() return {getMaxHitCount=function()return 3 end} end
function w:getMaxRange()return 11 end
function w:getMinDamage()return 1 end
function w:getMaxDamage()return 2 end
function w:getModData()return self.md end
w.md={}
InventoryItemFactory={CreateItem=function(t)
   return {getMaxHitCount=function()return 3 end,getProjectileCount=function()return 9 end}
end}
local victims={}
local player={}
local held=w
function player:getPrimaryHandItem() return held end
function player:getX()return .5 end
function player:getY()return .5 end
function player:getZ()return 0 end
function player:getLookAngleRadians()return 0 end
function player:isLocalPlayer()return true end
function player:getCell()return cell end
function player:getInventory()return {getItems=function()return {size=function()return 1 end,get=function()return w end}end} end
getPlayer=function()return player end
local function zombie(x,y)
  local o={x=x,y=y,hp=10,kind='zombie',hits=0}
  function o:getX()return self.x end
  function o:getY()return self.y end
  function o:getZ()return 0 end
  function o:isDead()return self.hp<=0 end
  function o:isAlive()return self.hp>0 end
  function o:Hit(gun,who,d)
    assert(gun==w and who==player)
    self.hp=self.hp-d;self.hits=self.hits+1
    -- Additive PZ hit event recursion should be blocked.
    Events.OnWeaponHitCharacter.Fire(player,self,w,d)
  end
  victims[#victims+1]=o
  return o
end
local front=zombie(3.0,.5)
local behind=zombie(5.1,.5)
local other=zombie(4.0,2.4)
cell={getGridSquare=function(_,x,y,z)
  if z~=0 or x<0 or x>20 or y< -4 or y>4 then return nil end
  local objects={}
  for _,a in ipairs(victims) do
    if math.floor(a.x)==x and math.floor(a.y)==y then objects[#objects+1]=a end
  end
  return {getMovingObjects=function() return {size=function()return #objects end,
       get=function(_,i)return objects[i+1] end}end}
end}
LosUtil={lineClear=function(_,x0,y0,z0,x1,y1,z1) return 'Clear' end}
getActivatedMods=function()return {contains=function()return false end}end
TextDrawObject=nil
assert(loadfile(source))()
local p=PartnerShotgunProjectiles
-- First load migrates previously suppressed weapon, without equip hooks.
Events.OnGameStart.Fire()
assert(w:getMaxHitCount()==3 and w:getProjectileCount()==9, 'Legacy migration failed')
assert(p.metrics.restored==1, 'Expected one migration, no duplicate changes')
assert(#Events.OnEquipPrimary.list==0,'No equip hooks allowed')
local baseSetters=setterCount
p.config.showPellets=false
p.config.enabled=true
Events.OnWeaponSwingHitPoint.Fire(player,w)
assert(#p.shots==1)
assert(front.hits==0 and behind.hits==0,'Custom damage must wait for vanilla hit')
-- Native hit then bonus hit exactly once, no damage to primary target.
Events.OnWeaponHitCharacter.Fire(player,front,w,1.4)
Events.OnWeaponHitCharacter.Fire(player,front,w,1.4)
for i=1,5 do callbacks.tickCount=i;Events.OnTick.Fire() end
assert(front.hits==0, 'Primary native zombie double-hit!')
assert(behind.hits==1, 'Expected one follow-through hit behind native hit, found '..behind.hits)
assert(other.hits==0,'Off-axis victim was hit')
assert(p.metrics.bonusHits==1,'Missing confirmed bonus hit')
assert(setterCount==baseSetters,'Healthy weapon modified during fire/tick')
-- No vanilla hit => no added damage.
local oldHits=behind.hits
Events.OnWeaponSwingHitPoint.Fire(player,w)
for i=6,29 do callbacks.tickCount=i;Events.OnTick.Fire() end
assert(behind.hits==oldHits,'Damage without confirmed native hit')
-- Another weapon equip while projectile active must NOT cancel native shot.
Events.OnWeaponSwingHitPoint.Fire(player,w)
held=nil
Events.OnEquipPrimary.Fire()
assert(#p.shots>=1,'Unexpected clear on weapon change')
for i=30,52 do callbacks.tickCount=i;Events.OnTick.Fire() end
assert(setterCount==baseSetters,'Equip/unequip changed gun properties')
-- Normal gun should remain untouched by migration.
assert(p.Migrate(w)==true and setterCount==baseSetters)
-- A wall between the native target and rear victim must prevent bonus damage.
held=w
local rearBefore=behind.hits
LosUtil.lineClear=function()return 'Blocked' end
Events.OnWeaponSwingHitPoint.Fire(player,w)
Events.OnWeaponHitCharacter.Fire(player,front,w,1.4)
for i=53,62 do callbacks.tickCount=i;Events.OnTick.Fire() end
assert(behind.hits==rearBefore, 'Wall should prevent bonus damage')
LosUtil.lineClear=function()return 'Clear' end
-- Test the fallback hit event if native character callback is silent.
Events.OnWeaponSwingHitPoint.Fire(player,w)
Events.OnWeaponHitXp = Events.OnWeaponHitXp or {Fire=function()end}
local prev=behind.hits
p.NativeHit(player,front,w,1.4)
for i=63,74 do callbacks.tickCount=i;Events.OnTick.Fire() end
assert(behind.hits==prev+1, 'Alternative native hit observation should enable follow-through')
-- Target moves out of the beam before the deferred collision: no damage.
behind.y=2.8
prev=behind.hits
Events.OnWeaponSwingHitPoint.Fire(player,w)
p.NativeHit(player,front,w,1.4)
for i=75,85 do callbacks.tickCount=i;Events.OnTick.Fire() end
assert(behind.hits==prev, 'Moved rear target should not be hit using stale position')
behind.y=.5
-- Ammo profile changes must not affect native damage / hitcount.
local oldGetAmmo=w.getAmmoType
w.getAmmoType=function()return 'Base.Slug' end
assert(p.ResolveProfile(w).count==1, 'Slug is a single visual projectile')
w.getAmmoType=function()return 'Base.Birdshot' end
assert(p.ResolveProfile(w).pierce==1, 'Birdshot has no extra penetration')
w.getAmmoType=oldGetAmmo
assert(w:getMaxHitCount()==3 and w:getProjectileCount()==9)
print('PASS v0.3: migration; confirmed-only; no duplicate primary; walls; moving targets; slug and birdshot; no equip setters; no-hit safe fallback')
