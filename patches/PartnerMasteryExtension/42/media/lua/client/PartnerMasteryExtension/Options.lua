require "PartnerMasteryExtension/Shared"
require "PZAPI/ModOptions"
require "PartnerMasteryExtension/CombatConfig"

if not PartnerMasteryExtension or not PZAPI or not PZAPI.ModOptions then
    return
end

local PME = PartnerMasteryExtension
local function tr(key)
    return getText(key)
end

local options = PZAPI.ModOptions:create(
    "PartnerMasteryExtension",
    tr("UI_PME_ModName")
)

options:addTitle(tr("UI_PME_Title_Settings"))
local bonusEfficiency = options:addSlider(
    "BonusEfficiency",
    tr("UI_PME_BonusEfficiency"),
    0,
    150,
    5,
    PME.DEFAULT_BONUS_EFFICIENCY,
    tr("UI_PME_BonusEfficiency_Tooltip")
)

-- 15/20 combat specialization controls. Chances use basis points (0.01%).
local C=PartnerMasteryExtensionCombat
local function tick(id,key,default)
    if options.addTickBox then
        return options:addTickBox(id,tr(key),default,tr(key.."_Tip"))
    end
    -- Compatibility with older PZAPI mock layouts; slider 0/1 is equivalent.
    return options:addSlider(id,tr(key),0,1,1,default and 1 or 0,tr(key.."_Tip"))
end
local function slider(id,key,minv,maxv,step,default)
    return options:addSlider(id,tr(key),minv,maxv,step,default,tr(key.."_Tip"))
end
options:addTitle(tr("UI_PME_CombatGeneral"))
local combatEnabled=tick('CombatEnabled','UI_PME_CombatEnabled',true)
local repairEnabled=tick('CombatRepairEnabled','UI_PME_CombatRepairEnabled',true)
local splashEnabled=tick('CombatSplashEnabled','UI_PME_CombatSplashEnabled',true)
local penEnabled=tick('CombatPenEnabled','UI_PME_CombatPenEnabled',true)
options:addTitle(tr('UI_PME_RepairTitle'))
local repair15=slider('RepairChance15','UI_PME_Repair15',0,10000,1,25)
local repair20=slider('RepairChance20','UI_PME_Repair20',0,10000,1,100)
options:addTitle(tr('UI_PME_SplashTitle'))
local splash15=slider('SplashChance15','UI_PME_Splash15',0,10000,25,100)
local splash20=slider('SplashChance20','UI_PME_Splash20',0,10000,25,500)
local radius15=slider('SplashRadius15','UI_PME_Radius15',0,50,1,15)
local radius20=slider('SplashRadius20','UI_PME_Radius20',0,50,1,30)
local damage15=slider('SplashDamage15','UI_PME_Damage15',0,100,1,15)
local damage20=slider('SplashDamage20','UI_PME_Damage20',0,100,1,30)
options:addTitle(tr('UI_PME_PenTitle'))
local penChanceOptions={}
for _,entry in ipairs({
    {'AntiMateriel',1000},{'BoltAction',700},{'DMR',400},{'Assault',200},{'MachineGun',100},{'HandgunSMG',100}
}) do
    local key=entry[1]
    penChanceOptions[key]=slider('PenChance'..key,'UI_PME_Pen'..key,0,10000,25,entry[2])
end
local penExtra15=slider('PenExtraScale15','UI_PME_PenExtra15',0,200,5,100)
local penExtra20=slider('PenExtraScale20','UI_PME_PenExtra20',0,200,5,100)
local function bool(control)
    local v=control:getValue()
    return v==true or v==1 or v=='true'
end
local function syncSettings()
    PME.Configure({bonusEfficiency=bonusEfficiency:getValue()})
    local chance={}
    for key,control in pairs(penChanceOptions) do chance[key]=control:getValue() end
    C.ApplySettings({
        enabled=bool(combatEnabled),indomitable=bool(repairEnabled),
        shockwave=bool(splashEnabled),overpenetration=bool(penEnabled),
        indomitable15BP=repair15:getValue(),indomitable20BP=repair20:getValue(),
        shockwave15BP=splash15:getValue(),shockwave20BP=splash20:getValue(),
        shockwaveRadius15Tenths=radius15:getValue(),shockwaveRadius20Tenths=radius20:getValue(),
        shockwaveDamage15Pct=damage15:getValue(),shockwaveDamage20Pct=damage20:getValue(),
        penChance20BP=chance,penExtraScale15=penExtra15:getValue(),penExtraScale20=penExtra20:getValue(),
    })
end

options.apply = syncSettings
Events.OnGameStart.Add(syncSettings)
