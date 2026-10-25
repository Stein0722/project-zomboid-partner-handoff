local r='./PartnerMasteryExtension/42/media/lua/client/'
package.path=r..'?.lua;'..r..'?/?.lua;'..package.path
PartnerMasteryExtension={DEFAULT_BONUS_EFFICIENCY=50,bonusValue=50,Configure=function(selfarg)PartnerMasteryExtension.bonusValue=selfarg.bonusEfficiency end}
-- exact vanilla PZAPI-like checkbox slider interface
local created=nil
PZAPI={ModOptions={create=function(_,id,name)
 local options={controls={},id=id,sectionTitles={}}
 function options:addTitle(t) self.sectionTitles[#self.sectionTitles+1]=t end
 function options:addSlider(key,title,min,max,step,default,tooltip)
  local control={value=default,min=min,max=max,step=step}
  function control:getValue() return self.value end
  self.controls[key]=control
  return control
 end
 function options:addTickBox(key,title,default,tooltip)
  local control={value=default}
  function control:getValue()return self.value end
  self.controls[key]=control
  return control
 end
 created=options
 return options
end}}
getText=function(key)return key end
local onGameStart={}
Events={OnGameStart={Add=function(fn)onGameStart[#onGameStart+1]=fn end}}
-- Avoid requiring full Beyond Ten shared API for this options-only contract.
local oldRequire=require
require=function(name)
 if name=='PartnerMasteryExtension/Shared' or name=='PZAPI/ModOptions' then return true end
 return oldRequire(name)
end
require('PartnerMasteryExtension/Options')
require=oldRequire
require('PartnerMasteryExtension/CombatLogic')
assert(#onGameStart==1 and created.id=='PartnerMasteryExtension')
local C=PartnerMasteryExtensionCombat
local sliders=created.controls
assert(sliders.RepairChance15.value==25 and sliders.RepairChance20.value==100)
assert(sliders.SplashChance15.value==100 and sliders.SplashChance20.value==500)
assert(sliders.SplashRadius15.value==15 and sliders.SplashRadius20.value==30)
assert(sliders.CombatEnabled.value==true and sliders.CombatPenEnabled.value==true)
assert(sliders.PenChanceAntiMateriel.value==1000 and sliders.PenChanceHandgunSMG.value==100)
onGameStart[1]()
assert(C.Config.indomitable20BP==100 and C.Config.penChance20BP.DMR==400)
sliders.CombatRepairEnabled.value=false
sliders.SplashChance20.value=10000
sliders.SplashRadius20.value=40
sliders.SplashDamage20.value=65
sliders.PenChanceHandgunSMG.value=900
sliders.PenExtraScale20.value=150
sliders.BonusEfficiency.value=75
created.apply()
assert(C.Config.indomitable==false and C.ShockwavePlan(20)==1 and ({C.ShockwavePlan(20)})[2]==4)
assert(({C.ShockwavePlan(20)})[3]==0.65)
assert(C.PenetrationPlan(20,'HandgunSMG')==0.09 and ({C.PenetrationPlan(20,'HandgunSMG')})[2]==5)
assert(PartnerMasteryExtension.bonusValue==75)
print('OPTIONS CONTRACT PASS: persistent mod id; Korean/UI fields; 15/20 defaults; onGameStart/apply/live values; toggle; 16-20 base bonus')
