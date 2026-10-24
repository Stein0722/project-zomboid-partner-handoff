local WEAPON_POOL = {
    "P4Excalibar.P4Excalibar",
    "P4Excalibar.P4TrueExcalibar",
    "P4Excalibar.P4TrueExcalibarF",
    "P4Excalibar.P4TrueExcalibarW",
    "P4Excalibar.P4TrueExcalibarE",
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
    "Base.Buster",
    "Base.Masamune",
    "Base.MythrilRod",
    "Base.Cerberus",
    "Base.BarretGatlingGun",
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
local SEALED_CASE_POOL = {
    "LTW.LegendaryTacticalSwordCaseSealed",
    "LTW.LegendaryTacticalKnifeCaseSealed",
    "LK.LegendaryDaishoCaseSealed",
}

-- v1.2.0: 89 weapons + 3 source-confirmed sealed cases.
-- Event driven only (OnFillContainer, OnZombieDead); zero OnTick/zombie scans.
-- Each eligible item independently rolls 1/30000 for ordinary containers,
-- 1/50000 for zombie inventories; sealed case odds are intentionally rarer.
local TAG = '[PartnerLegendaryDrops]'
local availableWeapons, availableCases = {}, {}
local function config() return SandboxVars and SandboxVars.PartnerLegendaryDrops or nil end
local function positive(value, default)
    local result = math.floor(tonumber(value) or default)
    if result < 1 then return 1 end
    return result
end
local function enabled()
    local c = config()
    return not c or c.Enabled ~= false
end
local function rebuildPool()
    availableWeapons, availableCases = {}, {}
    local manager = getScriptManager and getScriptManager() or nil
    if not manager then return end
    for _,id in ipairs(WEAPON_POOL) do
        local ok,item = pcall(manager.FindItem,manager,id)
        if ok and item then availableWeapons[#availableWeapons+1]=id end
    end
    for _,id in ipairs(SEALED_CASE_POOL) do
        local ok,item=pcall(manager.FindItem,manager,id)
        if ok and item then availableCases[#availableCases+1]=id end
    end
    print(string.format('%s active weapons=%d/%d, sealed cases=%d/%d',TAG,#availableWeapons,#WEAPON_POOL,#availableCases,#SEALED_CASE_POOL))
end
local function suppressFinalFantasy()
    local c=config()
    if c and c.SuppressOriginalSources == false then return end
    local originals=SandboxVars and SandboxVars.BustMasamuneRewards
    if originals then originals.EnableZombieDrops=false; originals.EnableKillRewards=false end
end
local function asSquare(container)
    if not container then return nil end
    local ok,p=pcall(function()return container:getParent()end)
    if ok and p then
        local has,sq=pcall(function()return p:getSquare()end)
        if has and sq then return sq end
    end
    ok,p=pcall(function()return container:getSourceGrid()end)
    if ok and p then return p end
    return nil
end
local function findNearbyPlayer(square)
    if not square then return nil end
    local function near(player)
        if not player then return false end
        local ok,pSquare=pcall(function()return player:getSquare()end)
        if not ok or not pSquare then return false end
        return math.abs(pSquare:getX()-square:getX())<=12 and math.abs(pSquare:getY()-square:getY())<=12 and pSquare:getZ()==square:getZ()
    end
    if isServer() and getOnlinePlayers then
        local players=getOnlinePlayers()
        if players then
            for i=0,players:size()-1 do local p=players:get(i);if near(p) then return p end end
        end
    end
    local p=getPlayer and getPlayer() or nil
    if near(p) then return p end
end
local function alert(player)
    if not player then return end
    if isServer() and sendServerCommand then
        sendServerCommand(player,'PartnerLegendaryDrops','NearbyLegendary',{})
    else
        -- SP: the client event below owns visible UI; server script may run in same VM.
        if PartnerLegendaryDropsNotify then PartnerLegendaryDropsNotify() end
    end
end
local function isZombieInventory(typeName,container)
    local key=string.lower(tostring(typeName or ''))
    if key=='inventorymale' or key=='inventoryfemale' or key=='inventoryzombie' then return true end
    local ok,parent=pcall(function()return container:getParent()end)
    if ok and parent and instanceof then
        local match,isZ=pcall(instanceof,parent,'IsoZombie')
        if match and isZ then return true end
    end
    return false
end
-- Exact independent Bernoulli odds with rare-event fast path:
-- most containers/zombies use a single random draw per pool, not 89+3 rolls.
-- The first successful slot is sampled from the conditional geometric law;
-- all later slots retain their independent 1/N probability.
local function rollPool(container,pool,denominator)
    local n=#pool
    if n==0 then return 0 end
    local first=1
    if denominator>1 then
        local q=1-1/denominator
        local anyChance=1-(q^n)
        local r=ZombRand(1000000000)/1000000000
        if r>=anyChance then return 0 end
        first=math.ceil(math.log(1-r)/math.log(q))
        if first<1 then first=1 end
        if first>n then first=n end
    end
    local found=0
    for i=first,n do
        if i==first or ZombRand(denominator)==0 then
            local ok,item=pcall(container.AddItem,container,pool[i])
            if ok and item then found=found+1 end
        end
    end
    return found
end
local function onFill(room,typeName,container)
    if not enabled() or not container then return end
    -- B42 can also dispatch procedural ItemPickerContainer objects here.
    -- They are distribution definitions, not live inventories, and do not
    -- provide getParent/AddItem.  Ignore them before touching the container.
    if not instanceof or not instanceof(container,"ItemContainer") then return end
    if #availableWeapons==0 and #availableCases==0 then rebuildPool() end
    local zombie=isZombieInventory(typeName,container)
    local c=config()
    local den=positive(c and (zombie and c.ZombieChanceDenominator or c.ContainerChanceDenominatorV2),zombie and 50000 or 30000)
    local count=rollPool(container,availableWeapons,den)
    -- Sealed packages are more valuable than a single weapon: one-third chance.
    count=count+rollPool(container,availableCases,den*3)
    if count==0 then return end
    print(string.format('%s %d legendary item(s), zombie=%s, chance 1/%d',TAG,count,tostring(zombie),den))
    local square=asSquare(container)
    if zombie then
        -- OnFillContainer can run for a corpse *after* OnZombieDead, so notify
        -- immediately when newly generated zombie loot is near a player.
        alert(findNearbyPlayer(square))
        local ok,parent=pcall(function()return container:getParent()end)
        if ok and parent and parent.getModData then
            local valid,data=pcall(function()return parent:getModData()end)
            if valid and data then data.PartnerLegendaryPendingAlert=true end
        end
    else
        -- Only on rare successful creation, not continuous nearby scans.
        alert(findNearbyPlayer(square))
    end
end
local function onZombieDead(zombie)
    if not zombie or not zombie.getModData then return end
    local ok,data=pcall(function()return zombie:getModData()end)
    if not ok or not data or not data.PartnerLegendaryPendingAlert then return end
    data.PartnerLegendaryPendingAlert=nil
    local sq=zombie:getSquare()
    alert(findNearbyPlayer(sq))
end
local function onReady()
    rebuildPool()
    suppressFinalFantasy()
end
if not isClient() then
    Events.OnFillContainer.Add(onFill)
    Events.OnZombieDead.Add(onZombieDead)
    Events.OnGameStart.Add(onReady)
    Events.OnLoad.Add(onReady)
    if Events.OnServerStarted then Events.OnServerStarted.Add(onReady) end
end
