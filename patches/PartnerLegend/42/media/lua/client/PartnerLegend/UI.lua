require "PartnerLegend/Core"
require "ISUI/ISRichTextPanel"
require "ISUI/ISCollapsableWindow"
local L=PartnerLegend
local window
local function openAchievements()
    local p=getSpecificPlayer and getSpecificPlayer(0)
    if not p then return end
    L.Check(p)
    local d=L.GetData(p)
    local kills,days=L.Stats(p)
    local title=L.BestTitle(p)
    local lines={"<H1>"..L.Text("UI_PL_WindowTitle","Partner Legend")
            .."<LINE><TEXT>"..title.."<LINE>",
        L.Text("UI_PL_Kills","Kills").." "..tostring(kills).." / "
            ..L.Text("UI_PL_Survival","Survival").." "..tostring(days)
            ..L.Text("UI_PL_DaySuffix"," days").."<LINE><LINE>",
        "<H2>"..L.Text("UI_PL_Titles","Titles").."<LINE>"}
    for i,t in ipairs(L.TITLES) do
        lines[#lines+1]=(d.titles[i]
            and L.Text("UI_PL_Unlocked","[Unlocked] ")
            or L.Text("UI_PL_Locked","[Locked] "))
            ..L.GetTitleName(t).." - "..tostring(L.Required("kills",t[1]))
            ..L.Text("UI_PL_KillSuffix"," kills").."<LINE>"
    end
    lines[#lines+1]="<LINE><H2>"..L.Text("UI_PL_Medals","Medals").."<LINE>"
    for _,m in ipairs(L.MEDALS) do
        local unit=m.kind=="kills" and L.Text("UI_PL_KillSuffix"," kills")
            or m.kind=="days" and L.Text("UI_PL_DaySuffix"," days")
            or L.Text("UI_PL_LevelSuffix"," level")
        lines[#lines+1]=(d.medals[m.id]
            and L.Text("UI_PL_Unlocked","[Unlocked] ")
            or L.Text("UI_PL_Locked","[Locked] "))
            ..L.GetMedalName(m).." - "..tostring(L.Required(m.kind,m.target))..unit
            .." (+"..tostring(L.GetMedalBonus(m)).."%)<LINE>"
    end
    lines[#lines+1]="<LINE>"..L.Text("UI_PL_Footer",
        "F8: close / Adjust damage rewards in Mod Options")
    if window then window:removeFromUIManager();window=nil end
    local panel=ISRichTextPanel:new(0,0,530,520)
    panel:initialise()
    panel.autosetheight=false
    panel.clip=true
    window=panel:wrapInCollapsableWindow(L.Text("UI_PL_WindowTitle","Partner Legend"),false)
    window:setX(math.max(0,(getCore():getScreenWidth()-550)/2))
    window:setY(math.max(0,(getCore():getScreenHeight()-560)/2))
    window:addToUIManager()
    panel:setY(24)
    panel:setWidth(window:getWidth()-16)
    panel:setHeight(window:getHeight()-32)
    panel:addScrollBars()
    panel:setText(table.concat(lines))
    panel:paginate()
end
Events.OnKeyPressed.Add(function(key)
    if not Keyboard or key~=Keyboard.KEY_F8 then return end
    if window and window:isVisible() then
        window:removeFromUIManager();window=nil
    else
        openAchievements()
    end
end)
