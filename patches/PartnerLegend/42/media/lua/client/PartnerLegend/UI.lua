-- Partner Legend v0.3 — title codex. Single-window, mouse-safe, no full-screen overlay.
require "PartnerLegend/Core"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

local L = PartnerLegend
local W = ISCollapsableWindow:derive("PartnerLegendCodex")
local instance, selected, tab = nil, 1, "titles"

-- Preserve equipped title when migrating from v0.2's 'automatic' mode.
-- Newly unlocked higher titles will never silently replace the user's choice.
if not L._PartnerManualTitleMigration then
    L._PartnerManualTitleMigration = true
    local oldGetData = L.GetData
    L.GetData = function(p)
        local d = oldGetData(p)
        if d and d.titleMode == "auto" then
            local kills = select(1, L.Stats(p))
            local highest
            for _, def in ipairs(L.TITLES) do
                if kills >= L.Required("kills", def[1]) then highest = def[1] end
            end
            d.titleMode = highest and "manual" or "none"
            d.equippedTitleThreshold = highest
        end
        return d
    end
end

local STORIES = {
    [100] = {"\236\178\152\236\157\140\236\151\144\235\138\148 \236\130\180\236\149\132\235\130\168\234\184\176 \236\156\132\237\149\180 \236\139\184\236\155\160\235\139\164.", "\234\183\184 \236\178\171 \235\178\136\236\167\184 \236\132\160\237\131\157\236\157\128 \235\143\140\236\149\132\234\176\136 \234\184\184\236\157\132 \236\167\128\236\155\160\235\139\164."},
    [1000] = {"\235\145\144\235\160\164\236\155\128\236\157\180 \236\130\172\235\157\188\236\167\132 \234\178\131\236\157\128 \236\149\132\235\139\136\236\151\136\235\139\164.", "\234\183\184\236\160\128 \235\145\144\235\160\164\236\155\128 \236\134\141\236\151\144\236\132\156 \236\155\128\236\167\129\236\157\180\235\138\148 \235\178\149\236\157\132 \235\176\176\236\155\160\235\139\164."},
    [5000] = {"\235\172\180\235\166\172 \234\176\128\236\154\180\235\141\176 \237\153\128\235\161\156 \236\132\156\236\132\156 \236\130\180\236\149\132\235\130\168\236\149\152\235\139\164.", "\236\136\171\236\158\144\235\161\156\235\138\148 \236\132\164\235\170\133\237\149\160 \236\136\152 \236\151\134\235\138\148 \234\176\144\234\176\129\236\157\132 \236\150\187\236\151\136\235\139\164."},
    [10000] = {"\234\183\184\234\176\128 \236\167\128\235\130\152\234\176\132 \234\177\176\235\166\172\236\151\144\235\138\148 \235\176\156\236\134\140\235\166\172\234\176\128 \235\169\142\236\151\136\235\139\164.", "\236\185\168\235\172\181\236\157\128 \236\138\164\236\138\164\235\161\156 \236\150\187\236\150\180\235\130\184 \237\143\137\237\153\148\236\152\128\235\139\164."},
    [25000] = {"\234\181\176\235\139\168\236\157\152 \234\183\156\235\170\168\235\138\148 \236\157\152\235\175\184\235\165\188 \236\158\131\236\151\136\235\139\164.", "\236\152\164\237\158\136\235\160\164 \234\181\176\235\139\168\236\157\180 \237\149\156 \236\130\172\235\158\140\236\157\132 \235\145\144\235\160\164\236\155\140\237\150\136\235\139\164."},
    [50000] = {"\235\129\157\236\151\134\236\157\180 \235\176\152\235\179\181\235\144\156 \236\131\157\236\130\172\236\157\152 \236\132\160\237\131\157.", "\234\183\184\236\157\152 \236\134\144\235\129\157\236\151\144\235\138\148 \235\167\157\236\132\164\236\158\132\236\157\180 \235\130\168\236\167\128 \236\149\138\236\149\152\235\139\164."},
    [75000] = {"\236\160\132\237\136\172\235\138\148 \235\141\148 \236\157\180\236\131\129 \236\139\156\237\151\152\236\157\180 \236\149\132\235\139\136\236\151\136\235\139\164.", "\234\183\184\234\176\128 \235\176\156\236\157\132 \235\148\155\235\138\148 \234\179\179\235\167\136\235\139\164 \236\160\132\237\153\169\236\157\180 \235\139\172\235\157\188\236\161\140\235\139\164."},
    [100000] = {"\236\157\184\234\176\132\236\157\152 \237\149\156\234\179\132\235\138\148 \236\150\180\235\148\148\234\185\140\236\167\128\236\157\184\234\176\128.", "\234\183\184\235\138\148 \235\140\128\235\139\181 \235\140\128\236\139\160 \234\183\184 \237\149\156\234\179\132\235\165\188 \235\132\152\236\150\180\236\132\176\235\139\164."},
    [150000] = {"\236\162\133\235\167\144\236\157\152 \235\176\169\237\150\165\236\157\132 \235\176\148\234\190\188 \235\176\156\234\177\184\236\157\140.", "\236\167\128\235\143\132\236\151\144\235\138\148 \234\183\184\236\157\152 \236\151\172\236\160\149\236\157\180 \236\131\136\234\178\168\236\161\140\235\139\164."},
    [250000] = {"\236\132\184\236\131\129\236\157\180 \234\183\184\235\165\188 \234\181\172\237\149\156 \236\160\129\236\157\128 \236\151\134\236\151\136\235\139\164.", "\237\149\152\236\167\128\235\167\140 \234\183\184\234\176\128 \236\167\128\235\130\152\234\176\132 \236\132\184\236\131\129\236\157\128 \236\161\176\234\184\136\236\148\169 \234\181\172\236\155\144\235\176\155\236\149\152\235\139\164."},
    [500000] = {"\235\170\168\235\147\160 \234\178\131\236\157\132 \236\158\131\236\157\128 \236\132\184\236\131\129\236\151\144\236\132\156\235\143\132", "\234\183\184\235\138\148 \236\167\128\236\188\156\236\149\188 \237\149\160 \234\178\131\236\157\132 \237\143\172\234\184\176\237\149\152\236\167\128 \236\149\138\236\149\152\235\139\164."},
    [1000000] = {"\236\163\189\236\157\140\236\157\128 \235\136\132\234\181\172\236\151\144\234\178\140\235\130\152 \234\179\181\237\143\137\237\150\136\235\139\164.", "\235\139\168 \237\149\156 \236\130\172\235\158\140\236\157\132 \236\160\156\236\153\184\237\149\152\234\179\160."},
}
local function p0() return getSpecificPlayer and getSpecificPlayer(0) or nil end
local function word(key, fallback) return L.Text("UI_PL_" .. key, fallback) end
local function setupChoice(p)
    L.Check(p)
    local _,idx=L.BestTitle(p)
    if idx>0 then selected=idx end
end
local function refreshEffect()
    if L.AuraRenderer and L.AuraRenderer.Refresh then L.AuraRenderer.Refresh() end
end
local function addButton(owner,id,x,y,w,text,callback)
    local b=ISButton:new(x,y,w,26,text,owner,function()
        callback();refreshEffect();owner:refresh()
    end)
    b:initialise();owner:addChild(b);owner.buttons[id]=b
    return b
end
function W:new()
    local w,h=720,388
    local x=math.max(0,(getCore():getScreenWidth()-w)/2)
    local y=math.max(0,(getCore():getScreenHeight()-h)/2)
    local o=ISCollapsableWindow:new(x,y,w,h)
    setmetatable(o,self);self.__index=self
    o.resizable=false;o.pin=true;o.isCollapsed=false
    o.backgroundColor={r=0.045,g=0.05,b=0.063,a=0.96}
    o.borderColor={r=0.43,g=0.35,b=0.18,a=1}
    o.title="\237\140\140\237\138\184\235\132\136 \235\160\136\236\160\132\235\147\156 \226\128\148 \236\185\173\237\152\184 \235\143\132\234\176\144"
    o.buttons={}
    o.preview={}
    return o
end
-- The codex is a manual F8 dialog, not an auto-hiding inventory panel.
-- Some B42 UI paths mutate ISCollapsableWindow.pin / isCollapsed even after
-- createChildren; disable auto-collapse on THIS subclass only.
local function keepExpanded(self)
    local wasCollapsed=self.isCollapsed
    self.pin=true
    self.isCollapsed=false
    self.collapseCounter=0
    if wasCollapsed and self.clearMaxDrawHeight then
        self:clearMaxDrawHeight()
    end
    if self.pinButton then self.pinButton:setVisible(false) end
    if self.collapseButton then self.collapseButton:setVisible(false) end
end

function W:collapse()
    keepExpanded(self)
end
function W:uncollapse()
    keepExpanded(self)
end
function W:onMouseMoveOutside(dx,dy)
    -- Preserve title-bar dragging, but deliberately omit base auto-collapse.
    self.mouseOver=false
    if self.moving then
        self:setX(self.x+dx)
        self:setY(self.y+dy)
        self:bringToTop()
    end
    keepExpanded(self)
end
function W:prerender()
    keepExpanded(self)
    ISCollapsableWindow.prerender(self)
end

function W:createChildren()
    ISCollapsableWindow.createChildren(self)
    -- A codex is a persistent document window, not an inventory auto-hide pane.
    -- Hide the inherited collapse/pin controls; the close button and F8 still work.
    self.pin = true
    self.isCollapsed = false
    self.collapseCounter = 0
    if self.clearMaxDrawHeight then self:clearMaxDrawHeight() end
    if self.pinButton then self.pinButton:setVisible(false) end
    if self.collapseButton then self.collapseButton:setVisible(false) end
    addButton(self,"titles",16,33,104,"\236\185\173\237\152\184 \235\143\132\234\176\144",function()tab="titles" end)
    addButton(self,"effects",127,33,106,"\236\157\180\237\142\153\237\138\184",function()tab="effects" end)
    addButton(self,"choice",16,125,304,"\236\185\173\237\152\184 \235\170\169\235\161\157 \226\150\188",function()
        self.list:setVisible(not self.list:isVisible())
    end)
    self.list=ISScrollingListBox:new(16,154,318,194)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight=27
    self.list.font=UIFont.Small
    self.list:setOnMouseDownFunction(self,function(owner,item)
        -- B42 list callbacks may pass the item payload (number) directly,
        -- rather than the full list entry. Accept both representations.
        local index=type(item)=="table" and tonumber(item.item) or tonumber(item)
        if index and L.TITLES[index] then
            selected=index
            owner.list:setVisible(false)
            owner:refresh()
        end
    end)
    self:addChild(self.list)
    for i,def in ipairs(L.TITLES) do
        local name=L.GetTitleName(def)
        self.list:addItem(name.." \226\128\148 "..tostring(def[1]).."\237\130\172",i)
    end
    self.list:setVisible(false)
    addButton(self,"equip",16,346,98,"\236\185\173\237\152\184 \236\158\165\236\176\169",function()
        local p=p0();if p then L.EquipTitle(p,selected) end
    end)
    addButton(self,"none",122,346,98,"\236\185\173\237\152\184 \237\149\180\236\160\156",function()
        local p=p0();if p then L.SetTitleMode(p,"none") end
    end)
    addButton(self,"aura",16,346,204,"\236\152\164\236\152\164\235\157\188 \236\188\156\234\184\176",function()
        local p=p0();if p then L.ToggleAuraPreference(p,selected) end
    end)
    addButton(self,"preview",230,346,173,"\236\182\149\237\149\152 \236\151\176\236\182\156 \235\175\184\235\166\172\235\179\180\234\184\176",function()
        if L.Celebration and L.Celebration.Enqueue then
            -- UI demonstration only: never grants cores or medals.
            L.Celebration.Enqueue("pl_days_100","\235\176\177\236\160\132\235\133\184\236\158\165")
        end
    end)
    self:refresh()
end
function W:refresh()
    local p=p0();if not p then return end
    L.Check(p)
    local d=L.GetData(p)
    local t=L.TITLES[selected]
    local name,index=L.BestTitle(p)
    local unlocked=d.titles[selected]==true
    self.preview={kills=select(1,L.Stats(p)),selected=selected,
        threshold=t[1],name=L.GetTitleName(t),equipped=name,
        equippedIndex=index,unlocked=unlocked,story=STORIES[t[1]],
        aura=unlocked and L.AuraPreference(p,selected)}
    for i=1,#self.list.items do
        if self.list.setItemTextColorRGBA then
            if d.titles[i] then
                self.list:setItemTextColorRGBA(i,0.94,0.95,0.98,1)
            else
                self.list:setItemTextColorRGBA(i,0.50,0.53,0.57,1)
            end
        end
    end
    self.buttons.equip:setEnable(unlocked)
    self.buttons.aura:setEnable(unlocked)
    self.buttons.aura:setTitle(self.preview.aura and "\236\152\164\236\152\164\235\157\188 \235\129\132\234\184\176" or "\236\152\164\236\152\164\235\157\188 \236\188\156\234\184\176")
    self.buttons.choice:setTitle(self.preview.name.."  \226\150\188")
    local effect=(tab=="effects")
    self.buttons.aura:setVisible(effect)
    self.buttons.preview:setVisible(effect)
    self.buttons.equip:setVisible(not effect)
    self.buttons.none:setVisible(not effect)
end
function W:render()
    ISCollapsableWindow.render(self)
    local s=self.preview
    if not s or not s.name then return end
    local function line(text,x,y,col,font)
        local c=col or {0.91,0.92,0.94}
        self:drawText(tostring(text),x,y,c[1],c[2],c[3],1,font or UIFont.Small)
    end
    local muted={0.67,0.72,0.77}
    local gold={0.99,0.79,0.36}
    line("\235\136\132\236\160\129 \236\178\152\236\185\152: "..tostring(s.kills),19,74,muted)
    line("\237\152\132\236\158\172 \236\158\165\236\176\169: "..(s.equippedIndex>0 and s.equipped or "\236\151\134\236\157\140"),19,96)
    if not self.list:isVisible() then
        line(s.unlocked and "[\237\154\141\235\147\157\237\149\156 \236\185\173\237\152\184]" or "[\235\175\184\237\154\141\235\147\157 \194\183 \236\151\180\235\158\140 \234\176\128\235\138\165]",19,164,
             s.unlocked and gold or muted)
        line("\236\154\148\234\181\172 \236\178\152\236\185\152: "..tostring(s.threshold).."\237\130\172",19,190,muted)
        line(s.equippedIndex==selected and "\237\152\132\236\158\172 \236\158\165\236\176\169 \236\164\145" or
            (s.unlocked and "\236\158\165\236\176\169\237\149\160 \236\136\152 \236\158\136\236\138\181\235\139\136\235\139\164" or "\235\139\172\236\132\177 \236\160\132\236\151\144\235\138\148 \236\158\165\236\176\169\237\149\160 \236\136\152 \236\151\134\236\138\181\235\139\136\235\139\164"),19,218)
        if tab=="effects" then
            line("\236\132\160\237\131\157 \236\185\173\237\152\184 \236\152\164\236\152\164\235\157\188: "..(s.aura and "ON" or "OFF"),19,265,gold)
        end
    end
    -- Right column is for independent, short title lore.
    self:drawRect(350,78,1,236,0.65,0.38,0.31,0.22)
    line("\236\185\173\237\152\184\236\157\152 \236\157\152\235\175\184",374,80,gold,UIFont.Medium)
    line(s.name,374,122,{0.96,0.90,0.73},UIFont.Medium)
    local story=s.story or {"\236\138\164\236\138\164\235\161\156 \236\150\187\236\150\180\235\130\184 \236\131\157\236\161\180\236\157\152 \234\184\176\235\161\157.",""}
    line(story[1],374,171)
    line(story[2],374,198)
    line(tab=="effects" and "\236\152\164\236\152\164\235\157\188\235\138\148 \236\185\173\237\152\184\236\153\128 \235\179\132\234\176\156\235\161\156 \236\132\164\236\160\149\237\149\169\235\139\136\235\139\164." or
        "\237\149\156 \235\178\136 \236\158\165\236\176\169\237\149\152\235\169\180 \236\131\136 \236\185\173\237\152\184\235\165\188 \236\150\187\236\150\180\235\143\132 \236\156\160\236\167\128\235\144\169\235\139\136\235\139\164.",374,282,muted)
end
local function open()
    if instance and instance:isVisible() then
        instance:removeFromUIManager();instance=nil;return
    end
    if instance then instance:removeFromUIManager() end
    local p=p0();if not p then return end
    setupChoice(p)
    instance=W:new();instance:initialise();instance:instantiate()
    instance:addToUIManager();instance:bringToTop();instance:refresh()
end
Events.OnKeyPressed.Add(function(key)
    if Keyboard and key==Keyboard.KEY_F8 then open() end
end)
L.TitleStory=STORIES
L.OpenTitleCodex=open
L._F8v03=true
