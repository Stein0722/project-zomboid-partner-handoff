require "PartnerLegend/Core"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"

local L=PartnerLegend
local window
local panel
local selected=1
local tab="titles"
local buttons={}
local function player()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end
local function label(key,fallback)
    return L.Text("UI_PL_"..key,fallback)
end
local function paint()
    local p=player()
    if not p or not panel then return end
    L.Check(p)
    local d=L.GetData(p)
    local kills,days=L.Stats(p)
    local t=L.TITLES[selected]
    local threshold=L.Required("kills",t[1])
    local unlocked=d.titles[selected]==true
    local equipped,equippedIndex=L.BestTitle(p)
    local state=unlocked and label("Unlocked","Unlocked") or label("Locked","Locked")
    local rows={
        "<LINE><LINE><LINE><H1>"..label("WindowTitle","Partner Legend").."<LINE><LINE>",
        label("Kills","Kills")..": "..tostring(kills).." / "..label("Survival","Survival")..": "..tostring(days).."<LINE>",
        label("Equipped","Equipped")..": "..equipped.."<LINE><LINE>",
        "<H2>"..label("Selected","Selected").."  "..selected.." / "..#L.TITLES.."<LINE>",
        L.GetTitleName(t).."<LINE>",
        state.." - "..tostring(threshold)..label("KillSuffix"," kills").."<LINE><LINE>",
    }
    if tab=="effects" then
        rows[#rows+1]=label("EffectTab","Aura settings").."<LINE>"
        rows[#rows+1]=label("AuraPending","Visual aura renderer is not installed yet.").."<LINE>"
        rows[#rows+1]=label("AuraPreference","Saved aura preference")..": "..
            (L.AuraPreference(p,selected) and label("Enabled","ON") or label("Disabled","OFF")).."<LINE>"
        rows[#rows+1]=label("AuraDisclaimer","This setting does not yet display an aura.").."<LINE>"
    else
        rows[#rows+1]=label("TitleMode","Selection mode")..": "..
            (d.titleMode=="auto" and label("ModeAuto","Auto") or
            d.titleMode=="manual" and label("ModeManual","Manual") or label("ModeNone","None")).."<LINE>"
        rows[#rows+1]=label("TitleHint","Select an unlocked title, then equip it.").."<LINE>"
    end
    panel:setText(table.concat(rows))
    panel:paginate()
    for name,button in pairs(buttons) do
        if button then
            local common=(name=="previous" or name=="next" or name=="tabTitles" or name=="tabEffects")
            local effect=(name=="aura")
            button:setVisible(common or (tab=="effects" and effect) or
                (tab=="titles" and not effect and not common))
        end
    end
    if buttons.equip then buttons.equip:setEnable(unlocked) end
    if buttons.aura then buttons.aura:setEnable(unlocked) end
end
local function addButton(id,x,y,w,text,handler)
    local b=ISButton:new(x,y,w,25,text,panel,function() handler();paint() end)
    b:initialise()
    panel:addChild(b)
    buttons[id]=b
end
local function openTitles()
    local p=player()
    if not p then return end
    if window then window:removeFromUIManager();window=nil end
    panel=ISRichTextPanel:new(0,0,540,400)
    panel:initialise()
    panel.autosetheight=false
    panel.clip=true
    window=panel:wrapInCollapsableWindow(label("WindowTitle","Partner Legend"),false)
    window:setX(math.max(0,(getCore():getScreenWidth()-560)/2))
    window:setY(math.max(0,(getCore():getScreenHeight()-470)/2))
    window:addToUIManager()
    panel:setY(24)
    panel:setWidth(window:getWidth()-16)
    panel:setHeight(window:getHeight()-32)
    buttons={}
    addButton("tabTitles",10,10,110,label("TabTitles","Titles"),function() tab="titles" end)
    addButton("tabEffects",128,10,120,label("TabEffects","Effects"),function() tab="effects" end)
    addButton("previous",10,325,82,label("Previous","Previous"),function()
        selected=selected>1 and selected-1 or #L.TITLES
    end)
    addButton("next",98,325,82,label("Next","Next"),function()
        selected=selected<#L.TITLES and selected+1 or 1
    end)
    addButton("equip",188,325,82,label("Equip","Equip"),function() L.EquipTitle(p,selected) end)
    addButton("clear",276,325,82,label("Unequip","Unequip"),function() L.SetTitleMode(p,"none") end)
    addButton("auto",364,325,82,label("Auto","Auto"),function() L.SetTitleMode(p,"auto") end)
    addButton("aura",188,325,260,label("AuraToggle","Toggle aura preference"),function()
        L.ToggleAuraPreference(p,selected)
    end)
    paint()
end
Events.OnKeyPressed.Add(function(key)
    if not Keyboard or key~=Keyboard.KEY_F8 then return end
    if window and window:isVisible() then
        window:removeFromUIManager()
        window=nil
        panel=nil
    else
        openTitles()
    end
end)
