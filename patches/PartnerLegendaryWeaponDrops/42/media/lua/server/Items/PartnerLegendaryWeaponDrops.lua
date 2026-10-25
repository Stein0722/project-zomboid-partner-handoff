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

-- v1.3.2: 89 weapons + 3 source-confirmed sealed cases.
-- Zombie inventory: ONE aggregate 1/10000 roll per newly filled inventory,
-- then ONE reward drawn from the complete weighted pool (weapons:cases = 3:1
-- per individual entry). Base container odds are unchanged (per item); Lucky x1.10.
-- Event-driven only (OnFillContainer, OnZombieDead); zero OnTick/zombie scans.
-- SP Lucky gives +10% relative chance to both zombie and container rolls.
-- Positive detection is cached for the rest of the running session.
local TAG = '[PartnerLegendaryDrops]'
local availableWeapons, availableCases = {}, {}
-- Avoid a second roll if another mod re-emits OnFillContainer for the same
-- zombie inventory during this session. Weak keys avoid retaining containers.
local rolledZombieInventories = setmetatable({}, { __mode = 'k' })
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
-- B42.21 character trait API: getCharacterTraits():getKnownTraits(),
-- then player:hasTrait(CharacterTrait). Older string APIs are fallbacks only.
-- Cache positive Lucky detection permanently for this running SP session.
-- When absent, retry once per in-game minute to support acquired traits.
local luckyActive = false
local luckyPlayerReady = false

local function luckyName(trait)
    if trait == nil then return false end
    local name = trait
    if type(trait) ~= 'string' then
        local ok, result = pcall(function() return trait:getName() end)
        name = ok and result or tostring(trait)
    end
    local key = string.lower(tostring(name or ''))
    return key == 'lucky' or key:match('^[%w_%-]+:lucky$') ~= nil
end

local function playerHasLucky(player)
    if not player then return false end
    local ok, traits = pcall(function() return player:getCharacterTraits() end)
    if ok and traits then
        local valid, known = pcall(function() return traits:getKnownTraits() end)
        if valid and known then
            local countOk, size = pcall(function() return known:size() end)
            if countOk and size then
                for i=0,math.min(size,512)-1 do
                    local got, trait = pcall(function() return known:get(i) end)
                    if got and luckyName(trait) then
                        local tested, has = pcall(function() return player:hasTrait(trait) end)
                        if tested and has then return true end
                    end
                end
            end
        end
    end
    -- Some old trait mods and migrated saves expose legacy string APIs.
    -- Fail closed on an API error, never treat the trait's name alone as owned.
    local legacy, found = pcall(function() return player:HasTrait('Lucky') end)
    if legacy and found then return true end
    local listOk, list = pcall(function() return player:getTraits() end)
    if listOk and list then
        local hasOk, has = pcall(function() return list:contains('Lucky') end)
        if hasOk and has then return true end
    end
    return false
end

local function refreshLucky()
    if luckyActive then return end
    local player = getPlayer and getPlayer() or nil
    if not player then return end
    luckyPlayerReady = true
    if playerHasLucky(player) then
        luckyActive = true
        print(TAG .. ' Lucky confirmed: zombie and world-container legendary chances x1.10 (cached for session)')
    end
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
-- Ordinary containers retain the existing independent-per-entry policy.
-- Lucky affects *each* weapon or case draw by a RELATIVE x1.10, not a flat
-- +10 percentage points; the fast geometric skip avoids looping 89 entries
-- on the overwhelmingly common no-reward result.
-- Non-Lucky RNG path remains byte-for-byte the old logic and probabilities.
local function rollPool(container,pool,denominator)
    local n=#pool
    if n==0 then return 0 end
    local first=1
    if denominator>1 then
        local p = luckyActive and math.min(1, 1.1 / denominator) or (1 / denominator)
        local q=1-p
        local anyChance=1-(q^n)
        local r=ZombRand(1000000000)/1000000000
        if r>=anyChance then return 0 end
        if q>0 then
            first=math.ceil(math.log(1-r)/math.log(q))
            if first<1 then first=1 end
            if first>n then first=n end
        end
    end
    local found=0
    for i=first,n do
        local passed=i==first
        if not passed then
            if luckyActive then
                -- Same 1e9-grid Bernoulli method as Lucky zombie roll.
                local threshold=math.min(1000000000,1100000000/denominator)
                passed=ZombRand(1000000000)<threshold
            else
                passed=ZombRand(denominator)==0
            end
        end
        if passed then
            local ok,item=pcall(container.AddItem,container,pool[i])
            if ok and item then found=found+1 end
        end
    end
    return found
end
-- One Bernoulli trial controls ALL legendary zombie rewards combined.
-- The selection is conditional on success: weapon entries have weight 3,
-- sealed-case entries weight 1. No second roll for a sealed case.
local function rollSingleZombieReward(container,denominator)
    local weaponSlots = #availableWeapons * 3
    local slots = weaponSlots + #availableCases
    if slots == 0 then return 0 end
    local succeeded
    if luckyActive then
        -- Relative +10%, not +10 percentage points. For default 10000:
        -- exact 0.000110 = 1/9090.909...; max probability is 100%.
        local threshold = math.min(1000000000, 1100000000 / denominator)
        succeeded = ZombRand(1000000000) < threshold
    else
        -- Preserve the exact original integer RNG path for non-Lucky players.
        succeeded = ZombRand(denominator) == 0
    end
    if not succeeded then return 0 end
    local pick = ZombRand(slots) -- 0 .. slots-1
    local itemId
    if pick < weaponSlots then
        itemId = availableWeapons[math.floor(pick / 3) + 1]
    else
        itemId = availableCases[pick - weaponSlots + 1]
    end
    local ok,item = pcall(container.AddItem,container,itemId)
    if not ok or not item then
        print(string.format('%s WARN: zombie reward could not be added: %s',TAG,tostring(itemId)))
        return 0
    end
    print(string.format('%s zombie reward selected: %s (base 1/%d overall, lucky=%s)',TAG,itemId,denominator,tostring(luckyActive)))
    return 1
end

local function onFill(room,typeName,container)
    if not enabled() or not container then return end
    if #availableWeapons==0 and #availableCases==0 then rebuildPool() end
    local zombie=isZombieInventory(typeName,container)
    if zombie then
        if rolledZombieInventories[container] then return end
        rolledZombieInventories[container] = true
    end
    local c=config()
    -- V3 key intentionally differs from the old per-weapon V2 setting:
    -- existing saves with ZombieChanceDenominator=50000 should migrate to
    -- the new aggregate default rather than silently retaining 1/50000.
    local configuredDenominator
    if zombie then
        configuredDenominator = c and c.ZombieTotalChanceDenominatorV3
    else
        configuredDenominator = c and c.ContainerChanceDenominatorV2
    end
    local den=positive(configuredDenominator,zombie and 10000 or 30000)
    local count
    if zombie then
        -- In a normal SP session the player exists before loot generation.
        -- If OnGameStart happened unusually early, resolve the player once.
        if not luckyPlayerReady and not luckyActive then refreshLucky() end
        count=rollSingleZombieReward(container,den)
    else
        -- If the player loaded before the initial check, resolve Lucky here.
        if not luckyPlayerReady and not luckyActive then refreshLucky() end
        -- Preserve each container entry's base odds and its sealed-case rarity.
        count=rollPool(container,availableWeapons,den)
        count=count+rollPool(container,availableCases,den*3)
    end
    if count==0 then return end
    print(string.format('%s %d legendary item(s), zombie=%s, mode=%s, denominator=%d',TAG,count,tostring(zombie),zombie and 'single-total' or 'per-entry',den))
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
    refreshLucky()
end
if not isClient() then
    Events.OnFillContainer.Add(onFill)
    Events.OnZombieDead.Add(onZombieDead)
    Events.OnGameStart.Add(onReady)
    Events.OnLoad.Add(onReady)
    if Events.EveryOneMinute then Events.EveryOneMinute.Add(refreshLucky) end
    if Events.OnServerStarted then Events.OnServerStarted.Add(onReady) end
end
