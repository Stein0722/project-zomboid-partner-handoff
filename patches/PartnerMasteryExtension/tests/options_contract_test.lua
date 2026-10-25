local optionsPath = assert(arg[1], "options path required")

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local configured = nil
local combatConfigured = nil
PartnerMasteryExtension = {
    DEFAULT_BONUS_EFFICIENCY = 50,
    Configure = function(values) configured = values.bonusEfficiency end,
}
PartnerMasteryExtensionCombat = {
    ApplySettings = function(values) combatConfigured = values end,
}

local registered = {}
local created = nil
PZAPI = {
    ModOptions = {
        create = function(_self, id, name)
            local instance = {
                id = id,
                name = name,
                sliders = {},
                addTitle = function() end,
                addSlider = function(self, key, _label, minimum, maximum, step, default, _tooltip)
                    local slider = { value = default }
                    function slider:getValue() return self.value end
                    self.sliders[key] = {
                        control = slider,
                        minimum = minimum,
                        maximum = maximum,
                        step = step,
                    }
                    return slider
                end,
            }
            created = instance
            return instance
        end,
    },
}

Events = {
    OnGameStart = {
        Add = function(callback) registered[#registered + 1] = callback end,
    },
}

function getText(key) return key end

local originalRequire = require
require = function(_name) return true end
dofile(optionsPath)
require = originalRequire

assertEqual(created.id, "PartnerMasteryExtension", "stable settings id")
assertEqual(created.sliders.BonusEfficiency.minimum, 0, "minimum efficiency")
assertEqual(created.sliders.BonusEfficiency.maximum, 150, "maximum efficiency")
assertEqual(created.sliders.BonusEfficiency.step, 5, "efficiency step")
assertEqual(#registered, 1, "one game-start sync")

registered[1]()
assertEqual(configured, 50, "default is applied at game start")
assertEqual(combatConfigured.enabled, true, "combat defaults are applied at game start")

created.sliders.BonusEfficiency.control.value = 125
created.apply()
assertEqual(configured, 125, "settings apply updates runtime value")
assertEqual(combatConfigured.overpenetration, true, "combat settings remain enabled")

print("PARTNER_MASTERY_OPTIONS_CONTRACT_TEST_OK")
