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
    local lines={"<H1>Partner Legend<LINE><TEXT>"..title.."<LINE>",
        "처치 "..tostring(kills).." / 생존 "..tostring(days).."일<LINE><LINE>",
        "<H2>칭호<LINE>"}
    for i,t in ipairs(L.TITLES) do
        lines[#lines+1]=(d.titles[i] and "[획득] " or "[미획득] ")
            ..t[2].." - "..tostring(L.Required("kills",t[1])).."킬<LINE>"
    end
    lines[#lines+1]="<LINE><H2>훈장<LINE>"
    for _,m in ipairs(L.MEDALS) do
        local unit=m.kind=="kills" and "킬" or m.kind=="days" and "일" or "레벨"
        lines[#lines+1]=(d.medals[m.id] and "[획득] " or "[미획득] ")
            ..m.name.." - "..tostring(L.Required(m.kind,m.target))..unit
            .." (+"..tostring(m.bonus).."%)<LINE>"
    end
    lines[#lines+1]="<LINE>F8: 닫기 / 피해 보상은 게임 모드 설정에서 조절"
    if window then window:removeFromUIManager();window=nil end
    local panel=ISRichTextPanel:new(0,0,530,520)
    panel:initialise()
    panel.autosetheight=false
    panel.clip=true
    window=panel:wrapInCollapsableWindow("Partner Legend",false)
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
