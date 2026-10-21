require "PartnerMasteryExtension/Shared"
require "PZAPI/ModOptions"

if not PartnerMasteryExtension or not PZAPI or not PZAPI.ModOptions then
    return
end

local PME = PartnerMasteryExtension
local function tr(key)
    return getText(key)
end

local options = PZAPI.ModOptions:create(
    "PartnerMasteryExtension",
    tr("UI_PME_ModName")
)

options:addTitle(tr("UI_PME_Title_Settings"))
local bonusEfficiency = options:addSlider(
    "BonusEfficiency",
    tr("UI_PME_BonusEfficiency"),
    0,
    150,
    5,
    PME.DEFAULT_BONUS_EFFICIENCY,
    tr("UI_PME_BonusEfficiency_Tooltip")
)

local function syncSettings()
    PME.Configure({
        bonusEfficiency = bonusEfficiency:getValue(),
    })
end

options.apply = syncSettings
Events.OnGameStart.Add(syncSettings)
