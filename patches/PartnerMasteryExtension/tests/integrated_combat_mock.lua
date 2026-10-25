local root='./PartnerMasteryExtension/42/media/lua/client/'
package.path=root..'?.lua;'..root..'?/?.lua;'..package.path
local function event() local e={handlers={}};function e.Add(fn)table.insert(e.handlers,fn)end;function e:fire(...)for _,fn in ipairs(self.handlers) do fn(...) end end;return e end
Events={OnWeaponSwing=event(),OnWeaponHitCharacter=event(),OnHitZombie=event(),OnWeaponHitXp=event(),OnPlayerAttackFinished=event(),OnEquipPrimary=event(),OnGameStart=event()}
local p={skills={}};getSpecificPlayer=function()return p end
isClient=function()return false end
instanceof=function(o,id)return id=='IsoZombie' and o.zombie==true end
Perks={MAX={}};function Perks.FromString(id) return {getId=function()return id end,raw=id} end
PartnerMasteryExtension={GetEffectiveLevel=function(player,perk) return player.skills[perk.raw] or 0 end}
PartnerLightweightBallistics={GetRangedClass=function(_,weapon) return 'Handgun' end}
ZombRand=function(n)return 0 end -- Any nonzero proc chance passes (deterministic)
local squares={};local cell={}
function cell:getGridSquare(x,y,z)
 if z~=0 then return nil end
 local key=x..','..y;local sq=squares[key]
 if not sq then
  sq={items={}}
  function sq:getMovingObjects()local a=self.items;return {size=function()return #a end,get=function(_,i)return a[i+1] end} end
  function sq:isBlockedTo(other)return false end
  squares[key]=sq
 end
 return sq
end
getCell=function()return cell end
local function zombie(x,y)
 local z={zombie=true,x=x,y=y,z=0,hits=0,damage=0}
 function z:getX()return self.x end;function z:getY()return self.y end;function z:getZ()return self.z end
 function z:isDead()return false end
 function z:Hit(whoWeapon,whoPlayer,hitDamage)
  self.hits=self.hits+1;self.damage=self.damage+hitDamage
  Events.OnWeaponHitCharacter:fire(whoPlayer,self,whoWeapon,hitDamage)
 end
 table.insert(cell:getGridSquare(math.floor(x),math.floor(y),0).items,z)
 return z
end
local center=zombie(0,0);local near=zombie(1,0);local far=zombie(4,0)
local bat={ranged=false,condition=2,maximum=10,perk='Blunt',md={}}
function bat:isRanged() return self.ranged end
function bat:getFullType()return 'Base.BaseballBat' end
function bat:getPerk()return {getId=function()return self.perk end} end
function bat:getCondition()return self.condition end
function bat:getConditionMax()return self.maximum end
function bat:setCondition(x)self.condition=x end
function bat:getMinDamage()return 2 end
function bat:getModData()return self.md end
function p:getPrimaryHandItem()return bat end
function p:getInventory()return {getItems=function()return {size=function()return 0 end}end} end
require('PartnerMasteryExtension/CombatMain')
local C=PartnerMasteryExtensionCombat
assert(C.Config.testMode==false and C.Config.forceTier20==false)
local chance,radius,damage=C.ShockwavePlan(14)
assert(chance==0 and radius==0 and damage==0 and C.IndomitableChance(14)==0)
local c15,r15,d15=C.ShockwavePlan(15)
assert(c15==0.01 and r15==1.5 and d15==0.15)
local c20,r20,d20=C.ShockwavePlan(20)
assert(c20==0.05 and r20==3 and d20==0.30)
assert(C.IndomitableChance(15)==0.0025 and C.IndomitableChance(20)==0.01)
local q1,e1=C.PenetrationPlan(15,'AntiMateriel')
local q2,e2=C.PenetrationPlan(20,'AntiMateriel')
assert(math.abs(q1-0.1/3)<1e-9 and e1==6 and q2==0.10 and e2==20)
-- Level14 no effect
p.skills.Blunt=14;p.skills.Maintenance=14
Events.OnWeaponSwing:fire(p,bat);Events.OnWeaponHitCharacter:fire(p,center,bat,10);Events.OnPlayerAttackFinished:fire(p,bat)
assert(bat.condition==2 and near.hits==0)
-- Level15 and 20 proc via deterministic RNG
p.skills.Blunt=15;p.skills.Maintenance=15
Events.OnWeaponSwing:fire(p,bat);Events.OnWeaponHitCharacter:fire(p,center,bat,10);Events.OnPlayerAttackFinished:fire(p,bat)
assert(bat.condition==3 and near.hits==1 and math.abs(near.damage-1.5)<1e-9)
p.skills.Blunt=20;p.skills.Maintenance=20
Events.OnWeaponSwing:fire(p,bat);Events.OnWeaponHitCharacter:fire(p,center,bat,10)
Events.OnHitZombie:fire(center,p,'Torso',bat)
Events.OnPlayerAttackFinished:fire(p,bat)
assert(bat.condition==4 and near.hits==2 and math.abs(near.damage-4.5)<1e-9)
assert(far.hits==0)
-- options live update (100%, radius up to 5, disable repair) and release
C.ApplySettings({indomitable=false,shockwave20BP=10000,shockwaveRadius20Tenths=10,shockwaveDamage20Pct=100})
Events.OnWeaponSwing:fire(p,bat);Events.OnWeaponHitCharacter:fire(p,center,bat,10);Events.OnPlayerAttackFinished:fire(p,bat)
assert(bat.condition==4 and near.hits==3 and near.damage==14.5)
C.ApplySettings({shockwave=false})
Events.OnWeaponSwing:fire(p,bat);Events.OnWeaponHitCharacter:fire(p,center,bat,10);Events.OnPlayerAttackFinished:fire(p,bat)
assert(near.hits==3)
-- eligible handgun level 20 penetration; unchanged at lower level, restored after attack
local gun={ranged=true, maxhit=3, piercing=false,md={}}
function gun:isRanged()return true end;function gun:getFullType()return 'Base.Pistol' end
function gun:getAmmoType()return 'Base.9mm' end;function gun:getFireMode()return 'single' end
function gun:getFireModePossibilities()return '' end
function gun:isTwoHandWeapon()return false end;function gun:getProjectileCount()return 1 end
function gun:getMaxHitCount()return self.maxhit end;function gun:setMaxHitCount(v)self.maxhit=v end
function gun:isPiercingBullets()return self.piercing end;function gun:setPiercingBullets(v)self.piercing=v end
function gun:getModData()return self.md end
p.skills.Aiming=20
Events.OnWeaponSwing:fire(p,gun)
assert(gun.maxhit==6 and gun.piercing==true)
Events.OnPlayerAttackFinished:fire(p,gun)
assert(gun.maxhit==3 and gun.piercing==false)
p.skills.Aiming=14
Events.OnWeaponSwing:fire(p,gun)
assert(gun.maxhit==3)
Events.OnPlayerAttackFinished:fire(p,gun)
C.ApplySettings({penChance20BP={HandgunSMG=0}})
p.skills.Aiming=20
Events.OnWeaponSwing:fire(p,gun)
assert(gun.maxhit==3)
Events.OnPlayerAttackFinished:fire(p,gun)
-- Optional Viewpoint bridge must keep native penetration OFF in FPS/TPS,
-- then restore original behaviour when camera returns to isometric.
C.ApplySettings({penChance20BP={HandgunSMG=10000}})
p.skills.Aiming=20
PartnerViewpointBallisticsBridge={IsExternalBallistics=function() return true end}
Events.OnWeaponSwing:fire(p,gun)
assert(gun.maxhit==3 and gun.piercing==false, 'VTB 3D must not receive native overpenetration')
Events.OnPlayerAttackFinished:fire(p,gun)
PartnerViewpointBallisticsBridge.IsExternalBallistics=function() return false end
Events.OnWeaponSwing:fire(p,gun)
assert(gun.maxhit==6 and gun.piercing==true, 'isometric should restore mastery overpen')
Events.OnPlayerAttackFinished:fire(p,gun)
assert(gun.maxhit==3 and gun.piercing==false)
print('INTEGRATED PASS: 14/15/20 level gates, native radial splash, damage, durability, dedupe, live options, gun restore')
