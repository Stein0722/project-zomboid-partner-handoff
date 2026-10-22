require "PartnerLegend/Core"
pcall(require,"PZAPI/ModOptions")
if not PZAPI or not PZAPI.ModOptions then return end
local L=PartnerLegend
local options=PZAPI.ModOptions:create("PartnerLegend",getText("UI_PL_Name"))
options:addTitle(getText("UI_PL_Settings"))
local rewards=options:addSlider("RewardEfficiency",getText("UI_PL_Reward"),0,200,5,100)
local cap=options:addSlider("DamageCap",getText("UI_PL_Cap"),0,100,1,20)
local kills=options:addSlider("KillRequirement",getText("UI_PL_KillReq"),25,300,5,100)
local days=options:addSlider("DayRequirement",getText("UI_PL_DayReq"),25,300,5,100)
options:addSeparator()
options:addTitle(getText("UI_PL_GroupSettings"))
local survival=options:addSlider("SurvivalEfficiency",getText("UI_PL_SurvivalReward"),0,200,5,100)
local skill=options:addSlider("SkillEfficiency",getText("UI_PL_SkillReward"),0,200,5,100)
local combat=options:addSlider("CombatEfficiency",getText("UI_PL_CombatReward"),0,200,5,100)
options:addSeparator()
options:addTitle(getText("UI_PL_MedalSettings"))
local medalOptions={}
for _,m in ipairs(L.MEDALS) do
    medalOptions[m.id]=options:addSlider(
        "Medal_"..m.id,L.GetMedalName(m).." (%)",0,20,0.5,m.bonus
    )
end
local function sync()
    local medalBonuses={}
    for id,option in pairs(medalOptions) do medalBonuses[id]=option:getValue() end
    L.Configure({
        rewardEfficiency=rewards:getValue(),damageCap=cap:getValue(),
        killRequirement=kills:getValue(),dayRequirement=days:getValue(),
        survivalEfficiency=survival:getValue(),skillEfficiency=skill:getValue(),
        combatEfficiency=combat:getValue(),medalBonuses=medalBonuses
    })
    local p=getSpecificPlayer and getSpecificPlayer(0)
    if p then L.Check(p);if L.Refresh then L.Refresh(p) end end
end
options.apply=sync
Events.OnGameStart.Add(sync)
