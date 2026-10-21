require "PartnerMasteryExtension/Shared"
require "BeyondTen/SkillUI"

local PME = PartnerMasteryExtension
local BT = BeyondTen

local function rounded(value)
    return math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
end

local function drawExtensionCell(progressBar, x, cellSize, fill)
    local r, g, b = 0.72, 0.45, 1.0
    fill = BT.Clamp(fill, 0, 1)
    if fill > 0 then
        progressBar:drawTextureScaled(
            progressBar.SkillUnitFilled, x, 0, cellSize * fill, cellSize, 1, r, g, b)
    end
    progressBar:drawTextureScaled(
        progressBar.SkillUnitBorder, x, 0, cellSize, cellSize, 1, r, g, b)
end

local function updateExtensionTooltip(progressBar, selectedIndex)
    local level, currentXP, requiredXP = PME.GetLevelProgress(progressBar.char, progressBar.perk)
    local targetLevel = selectedIndex + 1
    local levelWord = xpSystemText and xpSystemText.lvl or "Level"
    local message = progressBar.perk:getName() .. " " .. levelWord .. " " .. tostring(targetLevel)

    if targetLevel <= level then
        message = message .. " <LINE> " .. (xpSystemText and xpSystemText.unlocked or "Unlocked")
    elseif targetLevel == level + 1 then
        message = message .. " <LINE> "
            .. getText("IGUI_XP_tooltipxp", rounded(currentXP), rounded(requiredXP))
    else
        message = message .. " <LINE> " .. (xpSystemText and xpSystemText.locked or "Locked")
    end

    progressBar.message = message
        .. " <LINE><LINE> <RGB:0.72,0.45,1> " .. getText("UI_PME_Mastery")
        .. " <LINE> " .. getText("UI_PME_StorageOnly")
end

local function installUIExtension()
    if not PME._installed or PME._skillUIInstalled then return end
    if type(ISSkillProgressBar) ~= "table"
        or type(ISSkillProgressBar.new) ~= "function"
        or type(ISSkillProgressBar.renderPerkRect) ~= "function" then
        return
    end

    local originalNew = ISSkillProgressBar.new
    local originalRenderPerkRect = ISSkillProgressBar.renderPerkRect
    local originalOnMouseMove = ISSkillProgressBar.onMouseMove

    function ISSkillProgressBar:new(x, y, width, height, playerNum, perk, parent)
        local progressBar = originalNew(self, x, y, width, height, playerNum, perk, parent)
        local pitch = tonumber(progressBar.BeyondTenCellPitch) or progressBar:getHeight()
        progressBar.PartnerMasteryBaseWidth = progressBar:getWidth()
        progressBar.PartnerMasteryCellPitch = pitch
        progressBar:setWidth(progressBar.PartnerMasteryBaseWidth + pitch * PME.EXTRA_LEVELS)
        return progressBar
    end

    function ISSkillProgressBar:renderPerkRect()
        originalRenderPerkRect(self)

        local level, currentXP, requiredXP = PME.GetLevelProgress(self.char, self.perk)
        local cellSize = self:getHeight()
        local pitch = tonumber(self.PartnerMasteryCellPitch)
            or tonumber(self.BeyondTenCellPitch)
            or cellSize
        local firstX = BT.MAX_LEVEL * pitch
        local completed = math.max(0, level - BT.MAX_LEVEL)
        local partial = 0
        if level >= BT.MAX_LEVEL and level < PME.MAX_LEVEL and requiredXP > 0 then
            partial = BT.Clamp(currentXP / requiredXP, 0, 1)
        end

        for slot = 1, PME.EXTRA_LEVELS do
            local fill = 0
            if slot <= completed then
                fill = 1
            elseif slot == completed + 1 then
                fill = partial
            end
            drawExtensionCell(self, firstX + (slot - 1) * pitch, cellSize, fill)
        end
    end

    function ISSkillProgressBar:onMouseMove(dx, dy)
        if not self:isMouseOver() then
            self:onMouseMoveOutside(dx, dy)
            return
        end
        local pitch = tonumber(self.PartnerMasteryCellPitch)
            or tonumber(self.BeyondTenCellPitch)
            or self:getHeight()
        local selectedIndex = math.floor(self:getMouseX() / pitch)
        if selectedIndex >= BT.MAX_LEVEL and selectedIndex < PME.MAX_LEVEL then
            updateExtensionTooltip(self, selectedIndex)
            return
        end
        return originalOnMouseMove(self, dx, dy)
    end

    PME._skillUIInstalled = true
    print("[PartnerMasteryExtension] 20-slot skill UI installed")
end

installUIExtension()
