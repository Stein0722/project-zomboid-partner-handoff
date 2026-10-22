-- Partner Extreme-Rare Legendary Weapon Drops
-- Server-authoritative: one roll per newly generated world container.

local WEAPON_POOL = {
    -- Excalibar: finished weapons only (quest components and broken variants excluded)
    "P4Excalibar.P4Excalibar",
    "P4Excalibar.P4TrueExcalibar",
    "P4Excalibar.P4TrueExcalibarF",
    "P4Excalibar.P4TrueExcalibarW",
    "P4Excalibar.P4TrueExcalibarE",

    -- Xixi's Weapon Pack (50 weapons; sheath/belt items excluded)
    "Base.AndurilSword",
    "Base.AngryThunderLance",
    "Base.Bahamut",
    "Base.BlueRoseSword",
    "Base.BlueSteelMachete",
    "Base.CardCaptorSakuraCrowbar",
    "Base.CarrotNightSticks",
    "Base.ChanShiZhe",
    "Base.ClaymoreSword",
    "Base.CuteRabbitKnife",
    "Base.DarkRepulsor",
    "Base.DivinepunishmentKnife",
    "Base.ErrataKatana",
    "Base.Excalibur",
    "Base.FeiyuzhuohuaMachete",
    "Base.ForestShamanPrayer",
    "Base.FuxiaoYanlingMachete",
    "Base.GlintofClouds",
    "Base.HandandahalfSwordClassic",
    "Base.HexagramGiantSwordHammer",
    "Base.HonglingAxe",
    "Base.HymnofWindandFlower",
    "Base.IridescentGalaxy",
    "Base.Izanami",
    "Base.JeannedArcSword",
    "Base.JudgmentScythe",
    "Base.LauraIceAxe",
    "Base.LumberingAxeold",
    "Base.MirageHalberd",
    "Base.NebulaButterflyKnife",
    "Base.NightFalcon",
    "Base.NightSkySword",
    "Base.NocturnalEdge",
    "Base.OrpheusCradle",
    "Base.PoeticMelody",
    "Base.PurplestarBaseballBat",
    "Base.RainbowWave",
    "Base.RanLing",
    "Base.RanLingKnife",
    "Base.Rwbyliandao",
    "Base.SpaaerShovelShovel",
    "Base.StabbingEmbersLance",
    "Base.StarryThunder",
    "Base.SurfingTunes",
    "Base.TacticalHatchetX",
    "Base.Taidao",
    "Base.TianLaiJiBan",
    "Base.VillageSword",
    "Base.XixiCaliburn",
    "Base.XunXueHandAxe",

    -- Final Fantasy Weapons
    "Base.Buster",
    "Base.Masamune",
    "Base.MythrilRod",
    "Base.Cerberus",
    "Base.BarretGatlingGun",

    -- Lightweight v0.2: 29 new finished weapons, no craft parts/cases.
    "LTW.LegendaryTacticalSword",
    "LTW.LegendaryTacticalTomahawk",
    "LTW.LegendaryTacticalAxe",
    "LTW.LegendaryTacticalCrowbar",
    "LTW.LegendaryTacticalBat",
    "LTW.LegendaryTacticalHammer",
    "LTW.LegendaryTacticalKnife",
    "LTW.LegendaryTacticalSledgehammer",
    "LTW.LegendaryTacticalSpear",
    "LK.LegendaryKatanaBlack",
    "LK.LegendaryKatanaBlue",
    "LK.LegendaryKatanaBrown",
    "LK.LegendaryKatanaGreen",
    "LK.LegendaryKatanaGrey",
    "LK.LegendaryKatanaOrange",
    "LK.LegendaryKatanaPink",
    "LK.LegendaryKatanaPurple",
    "LK.LegendaryKatanaRed",
    "LK.LegendaryKatanaWhite",
    "LK.LegendaryWakizashiBlack",
    "LK.LegendaryWakizashiBlue",
    "LK.LegendaryWakizashiBrown",
    "LK.LegendaryWakizashiGreen",
    "LK.LegendaryWakizashiGrey",
    "LK.LegendaryWakizashiOrange",
    "LK.LegendaryWakizashiPink",
    "LK.LegendaryWakizashiPurple",
    "LK.LegendaryWakizashiRed",
    "LK.LegendaryWakizashiWhite",
}

local availablePool = nil

local function settings()
    return SandboxVars and SandboxVars.PartnerLegendaryDrops
end

local function rebuildAvailablePool()
    availablePool = {}
    local manager = getScriptManager and getScriptManager() or nil
    if not manager then return end

    for _, fullType in ipairs(WEAPON_POOL) do
        local ok, scriptItem = pcall(function()
            return manager:FindItem(fullType)
        end)
        if ok and scriptItem then
            table.insert(availablePool, fullType)
        end
    end

    print(string.format(
        "[PartnerLegendaryDrops] Validated %d/%d rare weapons.",
        #availablePool,
        #WEAPON_POOL
    ))
end

local function suppressFinalFantasySources()
    local cfg = settings()
    if not cfg or cfg.SuppressOriginalSources == false then return end
    if not SandboxVars or not SandboxVars.BustMasamuneRewards then return end

    local original = SandboxVars.BustMasamuneRewards
    original.EnableZombieDrops = false
    original.EnableKillRewards = false
end

local function onFillContainer(roomName, containerType, container)
    local cfg = settings()
    if not cfg or cfg.Enabled == false or not container then return end

    local denominator = math.floor(tonumber(cfg.ContainerChanceDenominator) or 10000)
    if denominator < 1 then denominator = 1 end
    if ZombRand(denominator) ~= 0 then return end

    if not availablePool then rebuildAvailablePool() end
    if #availablePool == 0 then return end

    local fullType = availablePool[ZombRand(#availablePool) + 1]
    local item = container:AddItem(fullType)
    if item then
        print(string.format(
            "[PartnerLegendaryDrops] Rare find: %s (room=%s, container=%s, 1/%d)",
            fullType,
            tostring(roomName),
            tostring(containerType),
            denominator
        ))
    end
end

local function onWorldReady()
    rebuildAvailablePool()
    suppressFinalFantasySources()
end

if not isClient() then
    Events.OnFillContainer.Add(onFillContainer)
    Events.OnGameStart.Add(onWorldReady)
    Events.OnLoad.Add(onWorldReady)
    Events.OnServerStarted.Add(onWorldReady)
end

