local uiPath = assert(arg[1], "SkillUI.lua path required")

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

BeyondTen = {
    MAX_LEVEL = 15,
    Clamp = function(value, minimum, maximum)
        return math.max(minimum, math.min(maximum, value))
    end,
}

PartnerMasteryExtension = {
    _installed = true,
    MAX_LEVEL = 20,
    EXTRA_LEVELS = 5,
    GetLevelProgress = function(_character, _perk)
        return 16, 50, 100
    end,
    GetBonusEfficiency = function()
        return 0.5
    end,
}

xpSystemText = {
    lvl = "Level",
    unlocked = "Unlocked",
    locked = "Locked",
}

function getText(key, current, required)
    if key == "IGUI_XP_tooltipxp" then return tostring(current) .. "/" .. tostring(required) end
    if key == "UI_PME_Mastery" then return "Partner Mastery" end
    if key == "UI_PME_StorageOnly" then return "Storage only" end
    return key
end

local perk = {}
function perk:getName() return "Long Blunt" end

ISSkillProgressBar = {}
function ISSkillProgressBar:new(_x, _y, _width, _height, _playerNum, value, _parent)
    local result = {
        width = 150,
        height = 8,
        BeyondTenCellPitch = 10,
        char = {},
        perk = value,
        draws = 0,
        mouseX = 150,
        SkillUnitFilled = {},
        SkillUnitBorder = {},
    }
    setmetatable(result, { __index = self })
    function result:getWidth() return self.width end
    function result:setWidth(valueWidth) self.width = valueWidth end
    function result:getHeight() return self.height end
    function result:drawTextureScaled(...) self.draws = self.draws + 1 end
    function result:isMouseOver() return true end
    function result:getMouseX() return self.mouseX end
    function result:onMouseMoveOutside() self.message = nil end
    return result
end
function ISSkillProgressBar:renderPerkRect() self.baseRendered = true end
function ISSkillProgressBar:onMouseMove(_dx, _dy) self.baseMouseMove = true end

local originalRequire = require
require = function(_name) return true end
dofile(uiPath)
require = originalRequire

local bar = ISSkillProgressBar:new(0, 0, 0, 0, 0, perk, {})
assertEqual(bar:getWidth(), 200, "adds five mastery cells")
bar:renderPerkRect()
assertEqual(bar.baseRendered, true, "keeps Beyond Ten base renderer")
assertEqual(bar.draws, 7, "draws completed, partial, and empty extension cells")
bar:onMouseMove(0, 0)
assertEqual(string.find(bar.message, "Partner Mastery", 1, true) ~= nil, true, "shows extension tooltip")
assertEqual(PartnerMasteryExtension._skillUIInstalled, true, "installs UI wrapper once")

print("PARTNER_MASTERY_SKILL_UI_CONTRACT_TEST_OK")
