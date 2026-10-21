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
local function sync()
    L.Configure({
        rewardEfficiency=rewards:getValue(),damageCap=cap:getValue(),
        killRequirement=kills:getValue(),dayRequirement=days:getValue()
    })
    local p=getSpecificPlayer and getSpecificPlayer(0)
    if p then L.Check(p);if L.Refresh then L.Refresh(p) end end
end
options.apply=sync
Events.OnGameStart.Add(sync)
