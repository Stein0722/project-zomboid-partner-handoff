require "PZAPI/ModOptions"

if not PartnerLightweightBallistics or not PZAPI or not PZAPI.ModOptions then
    return
end

local PLB = PartnerLightweightBallistics
local function tr(key)
    return getText("UI_PLB_" .. key)
end

local options = PZAPI.ModOptions:create(
    "PartnerLightweightBallistics",
    tr("ModName")
)

options:addTitle(tr("Title_Balance"))
local preset = options:addComboBox("Preset", tr("Preset"), tr("Preset_Tooltip"))
preset:addItem(tr("Preset_Solo"), true)
preset:addItem(tr("Preset_Multi"), false)
preset:addItem(tr("Preset_Original"), false)
preset:addItem(tr("Preset_Custom"), false)

options:addSeparator()
options:addTitle(tr("Title_Audio"))
local vanillaVolume = options:addSlider(
    "VanillaVolume", tr("VanillaVolume"), 0, 100, 5, 70,
    tr("VanillaVolume_Tooltip")
)
local britaVolume = options:addSlider(
    "BritaVolume", tr("BritaVolume"), 0, 100, 5, 40,
    tr("BritaVolume_Tooltip")
)
local suppressedVolume = options:addSlider(
    "SuppressedVolume", tr("SuppressedVolume"), 0, 100, 5, 25,
    tr("SuppressedVolume_Tooltip")
)

options:addSeparator()
options:addTitle(tr("Title_Custom"))
local customDamage = options:addSlider(
    "CustomDamage", tr("CustomDamage"), 50, 300, 5, 150,
    tr("CustomDamage_Tooltip")
)
local customHitBonus = options:addSlider(
    "CustomHitBonus", tr("CustomHitBonus"), 0, 40, 1, 12,
    tr("CustomHitBonus_Tooltip")
)
local customCritBonus = options:addSlider(
    "CustomCritBonus", tr("CustomCritBonus"), 0, 50, 1, 20,
    tr("CustomCritBonus_Tooltip")
)
local customAimTime = options:addSlider(
    "CustomAimTime", tr("CustomAimTime"), 40, 150, 5, 80,
    tr("CustomAimTime_Tooltip")
)
local customRecoilDelay = options:addSlider(
    "CustomRecoilDelay", tr("CustomRecoilDelay"), 40, 150, 5, 85,
    tr("CustomRecoilDelay_Tooltip")
)

options:addSeparator()
options:addTitle(tr("Title_PenetrationClasses"))
local penetrationOptions = {}
local penetrationOrder = {
    "Handgun", "SMG", "Shotgun", "Rifle", "Sniper", "MachineGun",
    "Bow", "Crossbow", "Slingshot",
}
local penetrationDefaults = {
    Handgun = 0,
    SMG = 0,
    Shotgun = 0,
    Rifle = 1,
    Sniper = 1,
    MachineGun = 1,
    Bow = 0,
    Crossbow = 0,
    Slingshot = 0,
}
for _, kind in ipairs(penetrationOrder) do
    penetrationOptions[kind] = options:addSlider(
        "Penetration_" .. kind,
        tr("Penetration_" .. kind),
        0, 4, 1, penetrationDefaults[kind],
        tr("Penetration_" .. kind .. "_Tooltip")
    )
end

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
        customPenetrationBonus = 0,
    })
    PLB.PenetrationByClass = PLB.PenetrationByClass or {}
    for _, kind in ipairs(penetrationOrder) do
        PLB.PenetrationByClass[kind] = penetrationOptions[kind]:getValue()
    end
    PLB.ApplyAll()
end

options.apply = syncAndApply
Events.OnGameStart.Add(syncAndApply)
