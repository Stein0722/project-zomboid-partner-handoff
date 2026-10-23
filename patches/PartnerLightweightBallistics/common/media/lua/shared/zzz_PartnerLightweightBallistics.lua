-- Partner Lightweight Realistic Ballistics v1.2.0
--
-- Performance contract:
--   * no OnTick callback
--   * no per-shot callback
--   * no zombie/world scan
--   * no custom projectile object
--
-- Script definitions are read once at boot. Live weapon instances are
-- refreshed when the player is created, settings are applied, or a weapon is
-- equipped.

if PartnerLightweightBallisticsLoaded then
    return
end
PartnerLightweightBallisticsLoaded = true

local MOD_TAG = "[PartnerLightweightBallistics]"
PartnerLightweightBallistics = PartnerLightweightBallistics or {}
local PLB = PartnerLightweightBallistics

PLB.Settings = PLB.Settings or {
    preset = 1,
    vanillaVolume = 70,
    britaVolume = 40,
    suppressedVolume = 25,
    customDamage = 150,
    customHitBonus = 12,
    customCritBonus = 20,
    customAimTime = 80,
    customRecoilDelay = 85,
    customPenetrationBonus = 1,
}

local profiles = {}
local baselines = {}
local definitionsCaptured = false

local sharedBritaAliases = {
    DoubleBarrelShotgunShoot = "PLB_Brita_DoubleBarrelShotgunShoot",
    JS2000ShotgunShoot = "PLB_Brita_JS2000ShotgunShoot",
    M14Shoot = "PLB_Brita_M14Shoot",
    M16Shoot = "PLB_Brita_M16Shoot",
    M1911Shoot = "PLB_Brita_M1911Shoot",
    M9Shoot = "PLB_Brita_M9Shoot",
    MagnumShoot = "PLB_Brita_MagnumShoot",
    MSR700Shoot = "PLB_Brita_MSR700Shoot",
}

-- BritaCombinedB42 labels these weapons as integrally suppressed, but five
-- definitions either use a normal gunshot or a missing legacy sound. Only the
-- three normal/loud definitions need the same noise reduction used by Brita's
-- detachable-suppressor runtime; the two legacy-sound entries need sound repair.
local integralSuppressorFixes = {
    ["Base.M635SD"] = { swingSound = "SD[1]Shot_9", scaleNoise = true },
    ["Base.Sten_MK2SD"] = { swingSound = "SD[1]Shot_9", scaleNoise = true },
    ["Base.SIX12SD"] = { swingSound = "SD[1]Shot_12g", scaleNoise = true },
    ["Base.ASVAL_Fold"] = { swingSound = "SD[1]Shot_9", scaleNoise = false },
    ["Base.KRISS22_CRB_Fold"] = { swingSound = "SD[1]Shot_22", scaleNoise = false },
}

local function register(items, maxHit, piercing, spread)
    local soloMaxHit = nil
    if maxHit == 2 then
        soloMaxHit = 3
    elseif maxHit == 3 then
        soloMaxHit = 4
    elseif maxHit == 4 then
        soloMaxHit = 6
    end

    for i = 1, #items do
        profiles[items[i]] = {
            multiMaxHit = maxHit,
            soloMaxHit = soloMaxHit,
            piercing = piercing,
            spread = spread,
        }
    end
end

-- Magnum handguns and carbines: limited two-target penetration.
register({
    "Base.Pistol3",
    "Base.Revolver",
    "Base.Revolver_Long",
    "Base.L92_Carbine",
    "Base.Ash",
    "Base.Automag",
    "Base.Colt_Navy_1851",
    "Base.Colt_Service45",
    "Base.DEagle",
    "Base.DEagle_Hawk",
    "Base.DEagle_Long",
    "Base.GP100_2_357",
    "Base.GP100_4_357",
    "Base.GP100_6_357",
    "Base.Judge_45LC",
    "Base.Judge513_45LC",
    "Base.Judge513_Long_45LC",
    "Base.K6S_357",
    "Base.M1936",
    "Base.M29_44",
    "Base.M29_44Carbine",
    "Base.Marlin_1894_357",
    "Base.NEF_Handi_357",
    "Base.NEF_Handi_357_Sawed",
    "Base.NEF_Handi_45LC",
    "Base.NEF_Handi_45LC_Sawed",
    "Base.Revolver_357",
    "Base.Revolver_Long_357",
    "Base.Revolver_Short_357",
    "Base.Rhino_200DS_357",
    "Base.Rhino_40DS_357",
    "Base.Rhino_60DS_357",
    "Base.Ruger_No1_4570",
    "Base.SW_327_357",
    "Base.SW_M500",
    "Base.Thompson_Center_4570",
    "Base.TXS_804_45LC",
    "Base.VSSK",
    "Base.Win_1894",
    "Base.Winchester1866",
    "Base.Winchester1873",
}, 2, true, nil)

-- PDWs: a small penetration advantage without turning ordinary SMGs into rifles.
register({
    "Base.AR57_PDW",
    "Base.AR57_PDW_Fold",
    "Base.AR57_PDW_Long",
    "Base.FN_P90",
    "Base.FN_PS90",
    "Base.MPA57DMG_Carbine",
    "Base.MPA57DMG_Carbine_Fold",
}, 2, true, nil)

-- Vanilla full-power rifle roles that are below the intended baseline.
register({
    "Base.AssaultRifle2",
    "Base.L94_Rifle",
    "Base.SKS",
    "Base.SKS_A26",
    "Base.SKS_Bayo",
    "Base.SKS_PARA",
    "Base.SKS_PARA_Bayo",
}, 2, true, nil)

-- Precision/bolt-action/DMR weapons: three aligned targets maximum.
register({
    "Base.HuntingRifle",
    "Base.MSR7T_Rifle",
    "Base.VarmintRifle",
    "Base.Galil_Sniper",
    "Base.Galil_Sniper_Fold",
    "Base.G28",
    "Base.K14",
    "Base.L96",
    "Base.M14EBR",
    "Base.M14EBR_Fold",
    "Base.M1903",
    "Base.M40",
    "Base.M40A1",
    "Base.M40A2",
    "Base.M40A3",
    "Base.M46_Mauser",
    "Base.MAS36",
    "Base.Mosin",
    "Base.MSG90",
    "Base.OTS_03_SVU",
    "Base.PSG1",
    "Base.Ruger_No1_3006",
    "Base.Ruger_No1_308",
    "Base.Sako85",
    "Base.Savage12",
    "Base.SCAR20",
    "Base.SV_98",
    "Base.SVD",
    "Base.SVDK",
    "Base.Thompson_Center_3006",
    "Base.Thompson_Center_308",
    "Base.Type38",
    "Base.Type99",
    "Base.Viper",
    "Base.WA2000",
    "Base.WA2000_Bipod",
    "Base.Win_1895",
}, 3, true, nil)

-- Anti-materiel rifles: rare, heavy four-target line penetration.
register({
    "Base.BFG50",
    "Base.BOAR",
    "Base.CheyTac50",
    "Base.CheyTac50_Bipod",
    "Base.CheyTac50_Fold",
    "Base.CheyTac50_Fold_Bipod",
    "Base.EDM96",
    "Base.EDM96_Fold",
    "Base.Gepard_M6",
    "Base.Harris50",
    "Base.M82",
    "Base.OSV_96",
    "Base.TAC50",
}, 4, true, nil)

-- Long break-action shotguns: keep their tighter identity, but reduce excessive
-- pellet stacking on a single zombie.
register({
    "Base.DoubleBarrelShotgun",
    "Base.Coachgun",
    "Base.DT11",
    "Base.NEF_Handi_410",
    "Base.ROYAL_SXS",
    "Base.Terminator",
    "Base.Triple_Crown",
}, nil, false, 0.75)

-- Standard full-size shotguns: nine/six/four native pellets are preserved.
-- Only the native spread value changes; sawed-off shotguns (already 1.5-2.0)
-- are intentionally left untouched.
register({
    "Base.Shotgun",
    "Base.JS3T_Shotgun",
    "Base.10855_Silver",
    "Base.A400",
    "Base.AA12",
    "Base.AUTO_5",
    "Base.CAWS",
    "Base.Colt1855",
    "Base.DAO12",
    "Base.DAO12_Fold",
    "Base.Ithaca_M37",
    "Base.Judge_410g",
    "Base.Judge513_410g",
    "Base.Judge513_Long_410g",
    "Base.KS23",
    "Base.KS23_S_Pistol",
    "Base.KSG",
    "Base.KSG25",
    "Base.M1014",
    "Base.M1014_Fold",
    "Base.M1014_Stock",
    "Base.M1014_Wick",
    "Base.M1208",
    "Base.M1212",
    "Base.M1216",
    "Base.M1887",
    "Base.M1897",
    "Base.M870",
    "Base.M870_Breaching_Pistol",
    "Base.M870_CQB",
    "Base.M870_CQB_Fold",
    "Base.M870_Express",
    "Base.M870_MCS",
    "Base.M870_Police",
    "Base.M870_Wingmaster",
    "Base.Moss500_20",
    "Base.MP133",
    "Base.MP133S_Pistol",
    "Base.Origin",
    "Base.R11_87",
    "Base.Saiga12",
    "Base.Saiga12_Long",
    "Base.Saiga12_Tromix",
    "Base.SIX12",
    "Base.SIX12SD",
    "Base.SPAS_15",
    "Base.SPAS12_Fixed",
    "Base.SPAS12_Fold",
    "Base.SPAS12_Stock",
    "Base.TOZ106",
    "Base.TOZ106_Fold",
    "Base.TOZ194_Pistol",
    "Base.TXS_804_410g",
    "Base.USAS_12",
    "Base.UTS15",
    "Base.VIPER_G2",
}, nil, false, 1.15)

local vanillaSounds = {
    "DesertEagleShoot", "DoubleBarrelShotgunShoot", "JS14Shoot",
    "JS2000ShotgunShoot", "L92Shoot", "L94Shoot", "M14Shoot", "M16Shoot",
    "M16ShootFullAuto", "M1911Shoot", "M36Shoot", "M625Shoot", "M9Shoot",
    "MagnumShoot", "MSR700Shoot", "MSR788Shoot",
    "SawnOffDoubleBarrelShotgunShoot", "SawnOffJS2000ShotgunShoot",
    "TrapperCarbineShoot",
}

local britaSounds = {
    "[1]Shot_10g", "[1]Shot_12g", "[1]Shot_20g", "[1]Shot_22",
    "[1]Shot_223", "[1]Shot_3006", "[1]Shot_308", "[1]Shot_357",
    "[1]Shot_38", "[1]Shot_380", "[1]Shot_40mm", "[1]Shot_410g",
    "[1]Shot_44", "[1]Shot_45", "[1]Shot_4570", "[1]Shot_45LC",
    "[1]Shot_4g", "[1]Shot_50", "[1]Shot_50MAG", "[1]Shot_545",
    "[1]Shot_556", "[1]Shot_57", "[1]Shot_762x39", "[1]Shot_762x54r",
    "[1]Shot_9", "[1]Shot_BB177", "[1]Shot_Marlin_01", "[1]Shot_Marlin_02",
    "[1]Shot_PB68", "[1]Shot_Rocket", "[1]Shot_SKS_01", "[1]Shot_SKS_02",
    "[6]Minigun_308", "[6]Minigun_50", "[6]Minigun_556",
    "COMP[1]Shot_10g", "COMP[1]Shot_12g", "COMP[1]Shot_20g",
    "COMP[1]Shot_22", "COMP[1]Shot_223", "COMP[1]Shot_3006",
    "COMP[1]Shot_308", "COMP[1]Shot_357", "COMP[1]Shot_38",
    "COMP[1]Shot_380", "COMP[1]Shot_410g", "COMP[1]Shot_44",
    "COMP[1]Shot_45", "COMP[1]Shot_4570", "COMP[1]Shot_45LC",
    "COMP[1]Shot_4g", "COMP[1]Shot_50", "COMP[1]Shot_50MAG",
    "COMP[1]Shot_545", "COMP[1]Shot_556", "COMP[1]Shot_57",
    "COMP[1]Shot_762x39", "COMP[1]Shot_762x54r", "COMP[1]Shot_9",
    "COMP[1]Shot_Marlin_01", "COMP[1]Shot_Marlin_02", "COMP[1]Shot_SKS_01",
    "PLB_Brita_DoubleBarrelShotgunShoot", "PLB_Brita_JS2000ShotgunShoot",
    "PLB_Brita_M14Shoot", "PLB_Brita_M16Shoot", "PLB_Brita_M1911Shoot",
    "PLB_Brita_M9Shoot", "PLB_Brita_MagnumShoot", "PLB_Brita_MSR700Shoot",
}

local suppressedSounds = {
    "SD[1]Shot_10g", "SD[1]Shot_12g", "SD[1]Shot_20g", "SD[1]Shot_22",
    "SD[1]Shot_223", "SD[1]Shot_3006", "SD[1]Shot_308", "SD[1]Shot_357",
    "SD[1]Shot_38", "SD[1]Shot_380", "SD[1]Shot_40mm", "SD[1]Shot_410g",
    "SD[1]Shot_44", "SD[1]Shot_45", "SD[1]Shot_4570", "SD[1]Shot_45LC",
    "SD[1]Shot_4g", "SD[1]Shot_50", "SD[1]Shot_50MAG", "SD[1]Shot_545",
    "SD[1]Shot_556", "SD[1]Shot_57", "SD[1]Shot_762x39",
    "SD[1]Shot_762x54r", "SD[1]Shot_9", "SD[1]Shot_BB177",
}

local function safeGet(target, methodName)
    if not target then
        return nil
    end
    local okMethod, method = pcall(function() return target[methodName] end)
    if not okMethod or not method then
        return nil
    end
    local ok, value = pcall(method, target)
    if not ok then
        return nil
    end
    return value
end

local function safeCall(target, methodName, ...)
    if not target then
        return false, nil
    end
    local okMethod, method = pcall(function() return target[methodName] end)
    if not okMethod or not method then
        return false, nil
    end
    local ok, value = pcall(method, target, ...)
    return ok, value
end

local function setValue(target, methodName, value)
    if value == nil then
        return true
    end
    local ok = safeCall(target, methodName, value)
    return ok
end

local function clamp(value, low, high)
    value = tonumber(value) or low
    if value < low then return low end
    if value > high then return high end
    return value
end

local function normalizedAmmo(ammo)
    return string.lower(tostring(ammo or "")):gsub("[^%w]", "")
end

local function isTunableRangedAmmo(ammo)
    local key = normalizedAmmo(ammo)
    return key:find("bullet", 1, true) ~= nil
        or key:find("shotgun", 1, true) ~= nil
        or key:find("shell", 1, true) ~= nil
        or key:find("arrow", 1, true) ~= nil
        or key:find("bowammo", 1, true) ~= nil
        or key:find("bolt", 1, true) ~= nil
        or key:find("slingshotammo", 1, true) ~= nil
        or key:find("railgunammo", 1, true) ~= nil
end

local function ammoCategory(ammo)
    local key = normalizedAmmo(ammo)
    if key:find("bolt", 1, true) then
        return "crossbow"
    end
    if key:find("arrow", 1, true) or key:find("bowammo", 1, true) then
        return "bow"
    end
    if key:find("slingshotammo", 1, true) then
        return "slingshot"
    end
    if key:find("railgunammo", 1, true) then
        return "rifleHeavy"
    end
    if key:find("shotgun", 1, true) or key:find("shell", 1, true) then
        return "shotgun"
    end
    if key:find("308", 1, true) or key:find("3030", 1, true)
        or key:find("3006", 1, true) or key:find("762", 1, true)
        or key:find("4570", 1, true) or key:find("50bmg", 1, true) then
        return "rifleHeavy"
    end
    if key:find("556", 1, true) or key:find("223", 1, true)
        or key:find("545", 1, true) then
        return "rifleIntermediate"
    end
    if key:find("357", 1, true) or key:find("44", 1, true)
        or key:find("45", 1, true) or key:find("50mag", 1, true) then
        return "handgunHeavy"
    end
    return "handgun"
end

local function isBritaDefinition(scriptItem)
    local modID = string.lower(tostring(safeGet(scriptItem, "getModID") or ""))
    local path = string.lower(tostring(safeGet(scriptItem, "getFileAbsPath") or ""))
    return modID:find("brita", 1, true) ~= nil
        or path:find("britacombinedb42", 1, true) ~= nil
        or path:find("3777433827", 1, true) ~= nil
end

local function isAutomatic(instance)
    local mode = string.lower(tostring(safeGet(instance, "getFireMode") or ""))
    local modes = string.lower(tostring(safeGet(instance, "getFireModePossibilities") or ""))
    return mode:find("auto", 1, true) ~= nil
        or mode:find("burst", 1, true) ~= nil
        or modes:find("auto", 1, true) ~= nil
        or modes:find("burst", 1, true) ~= nil
end

local machineGunPatterns = {
    "m249", "m240", "m60", "m1919", "mg42", "mg3", "mg36", "rpk",
    "pkm", "m134", "minigun", "lmg", "machinegun", "fnmag", "negev",
    "ultimax", "mg4", "m2hb", "xm214", "gau17", "gau19", "shrike",
    "k3lmg", "g21lmg", "mk43", "rpd", "dshk", "fixed_mg", "k12",
}

local sniperPatterns = {
    "sniper", "huntingrifle", "varmintrifle", "msr7", "mosin", "svd",
    "sv98", "m82", "wa2000", "barrett", "cheytac", "tac50", "l96",
    "sako85", "psg1", "msg90", "scar20", "m14ebr", "m40", "m1903",
    "m46_mauser", "anti_materiel", "dmr", "g28", "vssk", "svdk",
    "osv_96", "bfg50", "gepard_m6", "railgun",
}

local smgPatterns = {
    "smg", "pdw", "mp5", "mp7", "mp9", "p90", "ps90", "uzi",
    "mac10", "mac11", "ump", "kriss", "vector", "vz61", "sten",
    "scorpion", "bizon", "ppsh", "mp40", "thompson", "jatimatic",
    "calico_m900", "model50", "model55", "m2hyde", "bt380", "bt9_",
    "evo_", "kg9", "ar57_pdw",
}

local pistolAmmoPatterns = {
    "9mm", "9x19", "45acp", "380acp", "380auto", "22lr", "57x28",
    "40sw", "10mm", "32acp", "25acp", "357sig",
}

local function matchesAny(value, patterns)
    for i = 1, #patterns do
        if value:find(patterns[i], 1, true) then
            return true
        end
    end
    return false
end

function PLB.GetRangedClass(weapon)
    if not weapon or safeGet(weapon, "isRanged") ~= true then
        return nil
    end

    local fullType = string.lower(tostring(safeGet(weapon, "getFullType") or ""))
    local ammo = normalizedAmmo(safeGet(weapon, "getAmmoType"))
    if fullType == "" then
        return nil
    end
    if not isTunableRangedAmmo(ammo) then
        return nil
    end
    if ammo:find("bolt", 1, true) or fullType:find("crossbow", 1, true) then
        return "Crossbow"
    end
    if ammo:find("arrow", 1, true) or ammo:find("bowammo", 1, true) then
        return "Bow"
    end
    if ammo:find("slingshotammo", 1, true) then
        return "Slingshot"
    end
    if ammo:find("shotgun", 1, true) or ammo:find("shell", 1, true) then
        return "Shotgun"
    end
    if matchesAny(fullType, machineGunPatterns) then
        return "MachineGun"
    end
    if matchesAny(fullType, sniperPatterns) then
        return "Sniper"
    end
    if matchesAny(fullType, smgPatterns) then
        return "SMG"
    end

    local twoHand = safeGet(weapon, "isTwoHandWeapon") == true
    if not twoHand then
        return "Handgun"
    end
    local automatic = isAutomatic(weapon)
    local pistolAmmo = matchesAny(ammo, pistolAmmoPatterns)
    if pistolAmmo and automatic then
        return "SMG"
    end
    if not automatic and (ammo:find("308", 1, true)
        or ammo:find("3006", 1, true) or ammo:find("50bmg", 1, true)
        or ammo:find("railgun", 1, true)) then
        return "Sniper"
    end
    return "Rifle"
end

local function captureDefinitions()
    if definitionsCaptured then
        return true
    end

    local manager = ScriptManager and ScriptManager.instance or nil
    if not manager then
        print(MOD_TAG .. " ScriptManager unavailable; definitions were not captured.")
        return false
    end

    local okItems, allItems = pcall(manager.getAllItems, manager)
    if not okItems or not allItems then
        print(MOD_TAG .. " getAllItems failed; definitions were not captured.")
        return false
    end

    local captured = 0
    local excluded = 0
    local classCounts = {}
    for i = 0, allItems:size() - 1 do
        local scriptItem = allItems:get(i)
        local isRanged = safeGet(scriptItem, "isRanged")
        local ammo = safeGet(scriptItem, "getAmmoType")
        if isRanged and isTunableRangedAmmo(ammo) then
            local okInstance, instance = safeCall(scriptItem, "InstanceItem", nil)
            local fullType = tostring(safeGet(scriptItem, "getFullName") or "")
            if okInstance and instance and fullType ~= "" then
                baselines[fullType] = {
                    minDamage = safeGet(instance, "getMinDamage"),
                    maxDamage = safeGet(instance, "getMaxDamage"),
                    hitChance = safeGet(instance, "getHitChance"),
                    critChance = safeGet(instance, "getCriticalChance"),
                    critMultiplier = safeGet(instance, "getCriticalDamageMultiplier"),
                    aimingTime = safeGet(instance, "getAimingTime"),
                    recoilDelay = safeGet(instance, "getRecoilDelay"),
                    maxHit = safeGet(instance, "getMaxHitCount"),
                    piercing = safeGet(instance, "isPiercingBullets"),
                    spread = safeGet(instance, "getProjectileSpread"),
                    soundRadius = safeGet(instance, "getSoundRadius"),
                    soundVolume = safeGet(instance, "getSoundVolume"),
                    noiseRange = safeGet(instance, "getNoiseRange"),
                    noiseFactor = safeGet(instance, "getNoiseFactor"),
                    soundGain = safeGet(instance, "getSoundGain"),
                    swingSound = safeGet(scriptItem, "getSwingSound"),
                    ammo = ammo,
                    category = ammoCategory(ammo),
                    brita = isBritaDefinition(scriptItem),
                    twoHand = safeGet(instance, "isTwoHandWeapon") == true,
                    automatic = isAutomatic(instance),
                }
                local rangedClass = PLB.GetRangedClass(instance) or "Unclassified"
                classCounts[rangedClass] = (classCounts[rangedClass] or 0) + 1
                captured = captured + 1
            end
        elseif isRanged then
            excluded = excluded + 1
        end
    end

    definitionsCaptured = true
    local orderedClasses = {
        "Handgun", "SMG", "Shotgun", "Rifle", "Sniper", "MachineGun",
        "Bow", "Crossbow", "Slingshot", "Unclassified",
    }
    local classSummary = {}
    for i = 1, #orderedClasses do
        local name = orderedClasses[i]
        classSummary[#classSummary + 1] = name .. "=" .. tostring(classCounts[name] or 0)
    end
    print(string.format(
        "%s audited %d tunable ranged definitions (%s); %d special/explosive ranged definitions safely excluded.",
        MOD_TAG, captured, table.concat(classSummary, ", "), excluded
    ))
    return true
end

local function getSoloBonuses(category)
    if category == "shotgun" then return 1.40, 10, 15 end
    if category == "crossbow" then return 1.55, 12, 20 end
    if category == "bow" then return 1.45, 10, 15 end
    if category == "slingshot" then return 1.20, 8, 10 end
    if category == "rifleHeavy" then return 1.70, 12, 25 end
    if category == "rifleIntermediate" then return 1.65, 12, 20 end
    if category == "handgunHeavy" then return 1.60, 14, 20 end
    return 1.55, 14, 15
end

local function createTuning(fullType, base)
    local tuning = {
        minDamage = base.minDamage,
        maxDamage = base.maxDamage,
        hitChance = base.hitChance,
        critChance = base.critChance,
        critMultiplier = base.critMultiplier,
        aimingTime = base.aimingTime,
        recoilDelay = base.recoilDelay,
        maxHit = base.maxHit,
        piercing = base.piercing,
        spread = base.spread,
        swingSound = base.swingSound,
    }

    local preset = math.floor(clamp(PLB.Settings.preset, 1, 4))
    local profile = profiles[fullType]

    if preset == 1 then
        local damage, hit, crit = getSoloBonuses(base.category)
        tuning.minDamage = (base.minDamage or 0) * damage
        tuning.maxDamage = (base.maxDamage or 0) * damage
        tuning.hitChance = clamp((base.hitChance or 0) + hit, 0, 100)
        tuning.critChance = clamp((base.critChance or 0) + crit, 0, 100)
        tuning.aimingTime = math.max(1, math.floor((base.aimingTime or 1) * 0.80 + 0.5))
        tuning.recoilDelay = math.max(0, math.floor((base.recoilDelay or 0) * 0.85 + 0.5))

        if profile then
            tuning.maxHit = profile.soloMaxHit or base.maxHit
            tuning.piercing = profile.piercing
            tuning.spread = profile.spread or base.spread
        elseif base.category == "rifleHeavy" or base.category == "rifleIntermediate" then
            tuning.maxHit = math.max(base.maxHit or 1, 3)
            tuning.piercing = true
        elseif base.twoHand and base.automatic then
            tuning.maxHit = math.max(base.maxHit or 1, 2)
            tuning.piercing = true
        end
    elseif preset == 2 then
        if profile then
            tuning.maxHit = profile.multiMaxHit or base.maxHit
            tuning.piercing = profile.piercing
            tuning.spread = profile.spread or base.spread
        end
    elseif preset == 4 then
        local damage = clamp(PLB.Settings.customDamage, 50, 300) / 100
        local hit = clamp(PLB.Settings.customHitBonus, 0, 40)
        local crit = clamp(PLB.Settings.customCritBonus, 0, 50)
        local aim = clamp(PLB.Settings.customAimTime, 40, 150) / 100
        local recoil = clamp(PLB.Settings.customRecoilDelay, 40, 150) / 100
        local penetration = math.floor(clamp(PLB.Settings.customPenetrationBonus, 0, 4))

        tuning.minDamage = (base.minDamage or 0) * damage
        tuning.maxDamage = (base.maxDamage or 0) * damage
        tuning.hitChance = clamp((base.hitChance or 0) + hit, 0, 100)
        tuning.critChance = clamp((base.critChance or 0) + crit, 0, 100)
        tuning.aimingTime = math.max(1, math.floor((base.aimingTime or 1) * aim + 0.5))
        tuning.recoilDelay = math.max(0, math.floor((base.recoilDelay or 0) * recoil + 0.5))

        if profile then
            if profile.multiMaxHit then
                tuning.maxHit = math.min(8, profile.multiMaxHit + penetration)
            end
            tuning.piercing = profile.piercing
            tuning.spread = profile.spread or base.spread
        elseif penetration > 0 and (base.category == "rifleHeavy" or base.category == "rifleIntermediate") then
            tuning.maxHit = math.min(8, math.max(base.maxHit or 1, 2 + penetration))
            tuning.piercing = true
        elseif penetration > 0 and base.twoHand and base.automatic then
            tuning.maxHit = math.min(8, math.max(base.maxHit or 1, 1 + penetration))
            tuning.piercing = true
        end
    end

    if base.brita and sharedBritaAliases[tostring(base.swingSound)] then
        tuning.swingSound = sharedBritaAliases[tostring(base.swingSound)]
    end
    return tuning
end

local function applyTuning(target, fullType, isDefinition)
    local base = baselines[fullType]
    if not target or not base then
        return false
    end
    local tuning = createTuning(fullType, base)
    if not isDefinition and base.brita and sharedBritaAliases[tostring(base.swingSound)] then
        local currentSound = tostring(safeGet(target, "getSwingSound") or "")
        local alias = sharedBritaAliases[tostring(base.swingSound)]
        if currentSound ~= tostring(base.swingSound) and currentSound ~= alias then
            -- Brita changes an equipped weapon's SwingSound when a suppressor or
            -- compensator is fitted. Never overwrite that live attachment sound.
            tuning.swingSound = nil
        end
    end
    local ok = true
    ok = setValue(target, "setMinDamage", tuning.minDamage) and ok
    ok = setValue(target, "setMaxDamage", tuning.maxDamage) and ok
    ok = setValue(target, "setHitChance", tuning.hitChance) and ok
    ok = setValue(target, "setCriticalChance", tuning.critChance) and ok
    ok = setValue(target, "setCriticalDamageMultiplier", tuning.critMultiplier) and ok
    ok = setValue(target, "setAimingTime", tuning.aimingTime) and ok
    ok = setValue(target, "setRecoilDelay", tuning.recoilDelay) and ok
    ok = setValue(target, "setMaxHitCount", tuning.maxHit) and ok
    ok = setValue(target, "setPiercingBullets", tuning.piercing) and ok
    ok = setValue(target, "setProjectileSpread", tuning.spread) and ok
    ok = setValue(target, "setSwingSound", tuning.swingSound) and ok
    return ok
end

local function applyIntegralSuppressorFix(target, fullType)
    local fix = integralSuppressorFixes[fullType]
    local base = baselines[fullType]
    if not target or not fix or not base then
        return false
    end

    local essentialOK = setValue(target, "setSwingSound", fix.swingSound)
    if fix.scaleNoise then
        if base.soundRadius ~= nil then
            essentialOK = setValue(target, "setSoundRadius", math.max(1, math.floor(base.soundRadius * 0.30 + 0.5))) and essentialOK
        end
        if base.soundVolume ~= nil then
            essentialOK = setValue(target, "setSoundVolume", math.max(1, math.floor(base.soundVolume * 0.45 + 0.5))) and essentialOK
        end
        -- These setters exist on live HandWeapon instances, but some PZ builds do not
        -- expose every one of them on script Item definitions. Keep them best-effort
        -- so one optional field cannot hide a successful integral-suppressor repair.
        if base.noiseRange ~= nil then
            setValue(target, "setNoiseRange", math.max(1, math.floor(base.noiseRange * 0.30 + 0.5)))
        end
        if base.noiseFactor ~= nil then
            setValue(target, "setNoiseFactor", base.noiseFactor * 0.35)
        end
        if base.soundGain ~= nil then
            setValue(target, "setSoundGain", base.soundGain * 0.55)
        end
    end
    return essentialOK
end

function PLB.ApplyDefinitions()
    if not captureDefinitions() then
        return 0, 0
    end

    -- B42 script Item definitions expose getters but not the HandWeapon setters.
    -- Applying HandWeapon setters to them only produced hundreds of harmless
    -- failures. Live weapon instances are patched on player creation, inventory
    -- refresh and equip, which is the point at which their combat stats matter.
    print(string.format(
        "%s v1.2.0 preset %d: instance patch mode ready. No definition failures, Tick or per-shot hooks.",
        MOD_TAG, PLB.Settings.preset
    ))
    return 0, 0
end

local function applyInstance(item)
    local fullType = tostring(safeGet(item, "getFullType") or "")
    if fullType == "" or not baselines[fullType] then
        return false
    end
    local weaponParts = safeGet(item, "getAllWeaponParts")
    if weaponParts and weaponParts:size() > 0 then
        -- Native/Brita attachments alter weapon-instance stats. The script
        -- definition was already patched before the item loaded, so leave an
        -- attached instance alone instead of erasing its scope/suppressor data.
        return applyIntegralSuppressorFix(item, fullType)
    end
    local applied = applyTuning(item, fullType, false)
    if integralSuppressorFixes[fullType] then
        applied = applyIntegralSuppressorFix(item, fullType) and applied
    end
    return applied
end

local function patchContainer(container, depth)
    if not container or depth > 8 then
        return 0
    end
    local items = safeGet(container, "getItems")
    if not items then
        return 0
    end

    local patched = 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if applyInstance(item) then
            patched = patched + 1
        end
        local child = safeGet(item, "getInventory")
        if child then
            patched = patched + patchContainer(child, depth + 1)
        end
    end
    return patched
end

function PLB.ApplyPlayerInventory(player)
    if not player then
        return 0
    end
    local inventory = safeGet(player, "getInventory")
    if not inventory then
        return 0
    end
    local patched = patchContainer(inventory, 0)
    if patched > 0 then
        print(string.format("%s refreshed %d saved weapon instance(s).", MOD_TAG, patched))
    end
    return patched
end

local function setSoundVolume(soundName, volume)
    if not GameSounds or not GameSounds.getSound then
        return false
    end
    local ok, gameSound = pcall(GameSounds.getSound, soundName)
    if not ok or not gameSound then
        return false
    end
    local okSet = pcall(gameSound.setUserVolume, gameSound, volume)
    if not okSet then
        return false
    end

    -- B42 deliberately returns 1.0 for every individual sound while advanced
    -- sound options are disabled. Read the value back so the log never reports
    -- success while the engine is silently forcing 100 percent.
    local okRead, actual = pcall(gameSound.getUserVolume, gameSound)
    return okRead and math.abs((tonumber(actual) or -1) - volume) < 0.001
end

local function setSoundListVolume(list, volume)
    local changed = 0
    for i = 1, #list do
        if setSoundVolume(list[i], volume) then
            changed = changed + 1
        end
    end
    return changed
end

function PLB.ApplyAudioVolumes()
    local advancedEnabled = false
    if SystemDisabler
        and SystemDisabler.setEnableAdvancedSoundOptions
        and SystemDisabler.getEnableAdvancedSoundOptions then
        local okEnable = pcall(SystemDisabler.setEnableAdvancedSoundOptions, true)
        local okRead, enabled = pcall(SystemDisabler.getEnableAdvancedSoundOptions)
        advancedEnabled = okEnable and okRead and enabled == true
    end

    local vanilla = clamp(PLB.Settings.vanillaVolume, 0, 100) / 100
    local brita = clamp(PLB.Settings.britaVolume, 0, 100) / 100
    local suppressed = clamp(PLB.Settings.suppressedVolume, 0, 100) / 100
    local count = 0
    count = count + setSoundListVolume(vanillaSounds, vanilla)
    count = count + setSoundListVolume(britaSounds, brita)
    count = count + setSoundListVolume(suppressedSounds, suppressed)
    print(string.format(
        "%s audible volume applied: vanilla %d%%, Brita %d%%, suppressed %d%% (%d verified sounds, advanced=%s). Zombie hearing unchanged.",
        MOD_TAG, vanilla * 100, brita * 100, suppressed * 100, count,
        tostring(advancedEnabled)
    ))
    return count
end

function PLB.Configure(settings)
    if type(settings) ~= "table" then
        return
    end
    for key, value in pairs(settings) do
        if PLB.Settings[key] ~= nil and tonumber(value) ~= nil then
            PLB.Settings[key] = tonumber(value)
        end
    end
    PLB.Settings.preset = math.floor(clamp(PLB.Settings.preset, 1, 4))
end

function PLB.ApplyAll()
    PLB.ApplyDefinitions()
    PLB.ApplyAudioVolumes()
    if getSpecificPlayer then
        local ok, player = pcall(getSpecificPlayer, 0)
        if ok and player then
            PLB.ApplyPlayerInventory(player)
        end
    end
end

local function onCreatePlayer(_, player)
    PLB.ApplyPlayerInventory(player)
    PLB.ApplyAudioVolumes()
end

local function onEquip(_, item)
    applyInstance(item)
end

Events.OnGameBoot.Add(PLB.ApplyDefinitions)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnEquipPrimary.Add(onEquip)
Events.OnEquipSecondary.Add(onEquip)

