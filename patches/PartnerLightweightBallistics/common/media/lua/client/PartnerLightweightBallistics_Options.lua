require "PZAPI/ModOptions"

if not PartnerLightweightBallistics or not PZAPI or not PZAPI.ModOptions then
    return
end

local PLB = PartnerLightweightBallistics
local function tr(key)
    return getText(key)
end

local options = PZAPI.ModOptions:create(
    "PartnerLightweightBallistics",
    tr("UI_PLB_ModName")
)

options:addTitle(tr("UI_PLB_Title_Balance"))
local preset = options:addComboBox(
    "Preset",
    tr("UI_PLB_Preset"),
    tr("UI_PLB_Preset_Tooltip")
)
preset:addItem(tr("UI_PLB_Preset_Solo"), true)
preset:addItem(tr("UI_PLB_Preset_Multi"), false)
preset:addItem(tr("UI_PLB_Preset_Original"), false)
preset:addItem(tr("UI_PLB_Preset_Custom"), false)

options:addSeparator()
options:addTitle(tr("UI_PLB_Title_Audio"))
local vanillaVolume = options:addSlider(
    "VanillaVolume", tr("UI_PLB_VanillaVolume"), 0, 100, 5, 70,
    tr("UI_PLB_VanillaVolume_Tooltip")
)
local britaVolume = options:addSlider(
    "BritaVolume", tr("UI_PLB_BritaVolume"), 0, 100, 5, 40,
    tr("UI_PLB_BritaVolume_Tooltip")
)
local suppressedVolume = options:addSlider(
    "SuppressedVolume", tr("UI_PLB_SuppressedVolume"), 0, 100, 5, 25,
    tr("UI_PLB_SuppressedVolume_Tooltip")
)

options:addSeparator()
options:addTitle(tr("UI_PLB_Title_Custom"))
local customDamage = options:addSlider(
    "CustomDamage", tr("UI_PLB_CustomDamage"), 50, 300, 5, 150,
    tr("UI_PLB_CustomDamage_Tooltip")
)
local customHitBonus = options:addSlider(
    "CustomHitBonus", tr("UI_PLB_CustomHitBonus"), 0, 40, 1, 12,
    tr("UI_PLB_CustomHitBonus_Tooltip")
)
local customCritBonus = options:addSlider(
    "CustomCritBonus", tr("UI_PLB_CustomCritBonus"), 0, 50, 1, 20,
    tr("UI_PLB_CustomCritBonus_Tooltip")
)
local customAimTime = options:addSlider(
    "CustomAimTime", tr("UI_PLB_CustomAimTime"), 40, 150, 5, 80,
    tr("UI_PLB_CustomAimTime_Tooltip")
)
local customRecoilDelay = options:addSlider(
    "CustomRecoilDelay", tr("UI_PLB_CustomRecoilDelay"), 40, 150, 5, 85,
    tr("UI_PLB_CustomRecoilDelay_Tooltip")
)
local customPenetration = options:addSlider(
    "CustomPenetration", tr("UI_PLB_CustomPenetration"), 0, 4, 1, 1,
    tr("UI_PLB_CustomPenetration_Tooltip")
)

local function syncAndApply()
    PLB.Configure({
        preset = preset:getValue(),
        vanillaVolume = vanillaVolume:getValue(),
        britaVolume = britaVolume:getValue(),
        suppressedVolume = suppressedVolume:getValue(),
        customDamage = customDamage:getValue(),
        customHitBonus = customHitBonus:getValue(),
        customCritBonus = customCritBonus:getValue(),
        customAimTime = customAimTime:getValue(),
        customRecoilDelay = customRecoilDelay:getValue(),
        customPenetrationBonus = customPenetration:getValue(),
    })
    PLB.ApplyAll()
end

options.apply = syncAndApply
Events.OnGameStart.Add(syncAndApply)

