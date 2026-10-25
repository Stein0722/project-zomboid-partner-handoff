-- v1.3.0 unified UI. Preserve the original PartnerLightweightBallistics
-- option registry and keys to keep existing balance and audio preferences.
local ok=pcall(require,'PZAPI/ModOptions')
if not ok or not PZAPI or not PZAPI.ModOptions then
    print('[PartnerBallistics] ModOptions not found; safe default settings retained')
    return
end
local PLB=PartnerLightweightBallistics
local PSP=PartnerShotgunProjectiles
if not PLB or not PSP then
    print('[PartnerBallistics] Core not available when UI initialized')
    return
end
local function tr(key)
    return getText('UI_PLB_'..key)
end
local options=PZAPI.ModOptions:create('PartnerLightweightBallistics',tr('ModName'))

options:addTitle(tr('Title_Balance'))
local preset=options:addComboBox('Preset',tr('Preset'),tr('Preset_Tooltip'))
preset:addItem(tr('Preset_Solo'),true)
preset:addItem(tr('Preset_Multi'),false)
preset:addItem(tr('Preset_Original'),false)
preset:addItem(tr('Preset_Custom'),false)

options:addSeparator()
options:addTitle(tr('Title_Audio'))
local vanillaVolume=options:addSlider('VanillaVolume',tr('VanillaVolume'),0,100,5,70,tr('VanillaVolume_Tooltip'))
local britaVolume=options:addSlider('BritaVolume',tr('BritaVolume'),0,100,5,40,tr('BritaVolume_Tooltip'))
local suppressedVolume=options:addSlider('SuppressedVolume',tr('SuppressedVolume'),0,100,5,25,tr('SuppressedVolume_Tooltip'))

options:addSeparator()
options:addTitle(tr('Title_Custom'))
local customDamage=options:addSlider('CustomDamage',tr('CustomDamage'),50,300,5,150,tr('CustomDamage_Tooltip'))
local customHitBonus=options:addSlider('CustomHitBonus',tr('CustomHitBonus'),0,40,1,12,tr('CustomHitBonus_Tooltip'))
local customCritBonus=options:addSlider('CustomCritBonus',tr('CustomCritBonus'),0,50,1,20,tr('CustomCritBonus_Tooltip'))
local customAimTime=options:addSlider('CustomAimTime',tr('CustomAimTime'),40,150,5,80,tr('CustomAimTime_Tooltip'))
local customRecoilDelay=options:addSlider('CustomRecoilDelay',tr('CustomRecoilDelay'),40,150,5,85,tr('CustomRecoilDelay_Tooltip'))

options:addSeparator()
options:addTitle(tr('Title_PenetrationClasses'))
local penetrationOptions={}
local penetrationOrder={'Handgun','SMG','Rifle','Sniper','MachineGun','Bow','Crossbow','Slingshot'}
local penetrationDefaults={Handgun=0,SMG=0,Rifle=1,Sniper=1,MachineGun=1,Bow=0,Crossbow=0,Slingshot=0}
for _,kind in ipairs(penetrationOrder) do
    penetrationOptions[kind]=options:addSlider('Penetration_'..kind,
        tr('Penetration_'..kind),0,4,1,penetrationDefaults[kind],
        tr('Penetration_'..kind..'_Tooltip'))
end

options:addSeparator()
options:addTitle(tr('Title_Shotgun'))
local sgEnabled=options:addTickBox('ShotgunEnabled',tr('ShotgunEnabled'),true,tr('ShotgunEnabled_Tooltip'))
local sgShow=options:addTickBox('ShotgunShowPellets',tr('ShotgunShowPellets'),true,tr('ShotgunShowPellets_Tooltip'))
local sgPellets=options:addSlider('ShotgunPellets',tr('ShotgunPellets'),1,20,1,12,tr('ShotgunPellets_Tooltip'))
local sgPierce=options:addSlider('ShotgunPenetration',tr('ShotgunPenetration'),1,2,1,2,tr('ShotgunPenetration_Tooltip'))
local sgSpread=options:addSlider('ShotgunSpread',tr('ShotgunSpread'),3,40,1,20,tr('ShotgunSpread_Tooltip'))
-- Screenshot of the previously working v0.3.0 used 85%, so retain that
-- user-tested default when old standalone preferences cannot be imported.
local sgDamage=options:addSlider('ShotgunDamage',tr('ShotgunDamage'),20,100,5,85,tr('ShotgunDamage_Tooltip'))
local sgDebug=options:addTickBox('ShotgunDebug',tr('ShotgunDebug'),false,tr('ShotgunDebug_Tooltip'))

local function asBoolean(v)
    return v==true or v==1 or v=='1' or v=='true' or v=='TRUE'
end
local function apply()
    PSP.config.enabled=asBoolean(sgEnabled:getValue())
    PSP.config.showPellets=asBoolean(sgShow:getValue())
    PSP.config.pellets=tonumber(sgPellets:getValue()) or 12
    PSP.config.penetration=tonumber(sgPierce:getValue()) or 2
    PSP.config.spread=tonumber(sgSpread:getValue()) or 20
    PSP.config.damageScale=(tonumber(sgDamage:getValue()) or 85)/100
    PSP.config.debug=asBoolean(sgDebug:getValue())
    if not PSP.config.enabled and PSP.Reset then PSP.Reset() end

    PLB.Configure({
        preset=preset:getValue(), vanillaVolume=vanillaVolume:getValue(),
        britaVolume=britaVolume:getValue(), suppressedVolume=suppressedVolume:getValue(),
        customDamage=customDamage:getValue(), customHitBonus=customHitBonus:getValue(),
        customCritBonus=customCritBonus:getValue(),customAimTime=customAimTime:getValue(),
        customRecoilDelay=customRecoilDelay:getValue(),customPenetrationBonus=0,
    })
    PLB.PenetrationByClass=PLB.PenetrationByClass or {}
    PLB.PenetrationByClass.Shotgun=0 -- independent follow-through only, never stack
    for _,kind in ipairs(penetrationOrder) do
        PLB.PenetrationByClass[kind]=penetrationOptions[kind]:getValue()
    end
    PLB.ApplyAll()
    print(string.format('[PartnerBallistics] unified options applied: preset=%s shotgun=%s penetration=%d visual=%s',
        tostring(preset:getValue()),tostring(PSP.config.enabled),PSP.config.penetration,
        tostring(PSP.config.showPellets)))
end
options.apply=apply
Events.OnGameStart.Add(apply)
