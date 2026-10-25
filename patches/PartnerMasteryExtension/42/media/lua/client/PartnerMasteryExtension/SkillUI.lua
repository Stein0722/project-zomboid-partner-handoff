-- Partner Mastery Extension v0.4 display patch (Beyond Ten 1.3.4).
-- Changes player-facing 16-20 tooltip wording only; preserves the actual modifiers.
require "PartnerMasteryExtension/Shared"
require "BeyondTen/SkillUI"
local PME=PartnerMasteryExtension
local BT=BeyondTen
local function rounded(value) return math.floor((tonumber(value) or 0)*100+0.5)/100 end
local function drawExtensionCell(bar,x,size,fill)
    local r,g,b=0.72,0.45,1.0
    fill=BT.Clamp(fill,0,1)
    if fill>0 then
        bar:drawTextureScaled(bar.SkillUnitFilled,x,0,size*fill,size,1,r,g,b)
    end
    bar:drawTextureScaled(bar.SkillUnitBorder,x,0,size,size,1,r,g,b)
end
local function getLocal(key,fallback)
    if not getText then return fallback end
    local str=getText(key)
    if str and str~=key then return str end
    return fallback
end
local function updateExtensionTooltip(bar,selectedIndex)
    -- Display only. Original XP, level, and Beyond Ten rank formulas are untouched.
    local level,currentXP,requiredXP=PME.GetLevelProgress(bar.char,bar.perk)
    local target=selectedIndex+1
    local word=xpSystemText and xpSystemText.lvl or "Level"
    local text=bar.perk:getName().." "..word.." "..tostring(target)
    if target<=level then
        text=text.." <LINE> "..(xpSystemText and xpSystemText.unlocked or "Unlocked")
    elseif target==level+1 then
        text=text.." <LINE> "..getText("IGUI_XP_tooltipxp",rounded(currentXP),rounded(requiredXP))
    else
        text=text.." <LINE> "..(xpSystemText and xpSystemText.locked or "Locked")
    end

    local rate=math.floor(PME.GetBonusEfficiency()*100+0.5)
    text=text.." <LINE><LINE> <RGB:0.79,0.64,1> "
        ..getLocal("UI_PME_Mastery","Additional mastery (16-20)")
        .." <LINE> "..getLocal("UI_PME_PerLevel","Each level grants ")
        ..tostring(rate).."%"..getLocal("UI_PME_PerLevelSuffix"," of the normal bonus.")
    bar.message=text
end
local function install()
    if not PME._installed or PME._skillUIInstalled then return end
    if type(ISSkillProgressBar)~="table" or type(ISSkillProgressBar.new)~="function"
        or type(ISSkillProgressBar.renderPerkRect)~="function" then return end
    local oldNew=ISSkillProgressBar.new
    local oldDraw=ISSkillProgressBar.renderPerkRect
    local oldMouse=ISSkillProgressBar.onMouseMove
    function ISSkillProgressBar:new(x,y,width,height,playerNum,perk,parent)
        local bar=oldNew(self,x,y,width,height,playerNum,perk,parent)
        local pitch=tonumber(bar.BeyondTenCellPitch) or bar:getHeight()
        bar.PartnerMasteryBaseWidth=bar:getWidth()
        bar.PartnerMasteryCellPitch=pitch
        bar:setWidth(bar.PartnerMasteryBaseWidth+pitch*PME.EXTRA_LEVELS)
        return bar
    end
    function ISSkillProgressBar:renderPerkRect()
        oldDraw(self)
        local level,currentXP,requiredXP=PME.GetLevelProgress(self.char,self.perk)
        local size=self:getHeight()
        local pitch=tonumber(self.PartnerMasteryCellPitch) or tonumber(self.BeyondTenCellPitch) or size
        local firstX=BT.MAX_LEVEL*pitch
        local completed=math.max(0,level-BT.MAX_LEVEL)
        local partial=0
        if level>=BT.MAX_LEVEL and level<PME.MAX_LEVEL and requiredXP>0 then
            partial=BT.Clamp(currentXP/requiredXP,0,1)
        end
        for slot=1,PME.EXTRA_LEVELS do
            local fill=0
            if slot<=completed then fill=1
            elseif slot==completed+1 then fill=partial end
            drawExtensionCell(self,firstX+(slot-1)*pitch,size,fill)
        end
    end
    function ISSkillProgressBar:onMouseMove(dx,dy)
        if not self:isMouseOver() then
            self:onMouseMoveOutside(dx,dy)
            return
        end
        local pitch=tonumber(self.PartnerMasteryCellPitch) or tonumber(self.BeyondTenCellPitch) or self:getHeight()
        local idx=math.floor(self:getMouseX()/pitch)
        if idx>=BT.MAX_LEVEL and idx<PME.MAX_LEVEL then
            updateExtensionTooltip(self,idx)
            return
        end
        return oldMouse(self,dx,dy)
    end
    PME._skillUIInstalled=true
    print("[PartnerMasteryExtension] localized 16-20 mastery details active")
end
install()
