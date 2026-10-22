-- Partner Spatial Refuge shop services.
-- The original shop delivers a lightweight token through its normal SP/MP
-- purchase path. This authoritative handler consumes that token and performs
-- the random reward or repair service on the server (or directly in SP).

if isClient() then return end

require "MSR_ShopData"

local TAG = "[PartnerShopServices]"
local DRAW_TOKEN = "Base.PartnerLegendaryDrawToken"
local REPAIR_TOKEN = "Base.PartnerRepairWeaponsToken"
local DRAW_COST = 10000
local REPAIR_COST = 4000
local DRAW_HISTORY_KEY = "PartnerLegendaryShopDraws"

local WEAPON_POOL = {
    -- Excalibar: completed weapons only.
    "P4Excalibar.P4Excalibar",
    "P4Excalibar.P4TrueExcalibar",
    "P4Excalibar.P4TrueExcalibarF",
    "P4Excalibar.P4TrueExcalibarW",
    "P4Excalibar.P4TrueExcalibarE",

    -- Xixi's Weapon Pack: weapons only; sheath and belt helper items excluded.
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

    -- Final Fantasy VII weapon pack.
    "Base.Buster",
    "Base.Masamune",
    "Base.MythrilRod",
    "Base.Cerberus",
    "Base.BarretGatlingGun",
}

local availablePool = nil
local tickCounter = 0

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

    print(string.format("%s validated %d/%d legendary rewards", TAG, #availablePool, #WEAPON_POOL))
end

local function syncBalance(player)
    if isServer() and sendServerCommand and player and MSR and MSR.ShopData then
        sendServerCommand(player, "MSRShop", "BalanceResult", {
            coreBalance = MSR.ShopData.getCoreBalance(player),
        })
    end
end

local function refund(player, amount)
    if not player or not MSR or not MSR.ShopData then return end
    MSR.ShopData.addCores(player, amount)
    syncBalance(player)
end

local function removeToken(token)
    if not token then return false end
    local container = token:getContainer()
    if not container then return false end

    if container.DoRemoveItem then
        container:DoRemoveItem(token)
    elseif container.Remove then
        container:Remove(token)
    end
    if container.contains and container:contains(token) and container.Remove then
        container:Remove(token)
    end
    if container.contains and container:contains(token) then return false end

    if isServer() and sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, token)
    end
    return true
end

local function getDrawHistory(player)
    local modData = player:getModData()
    local history = modData[DRAW_HISTORY_KEY]
    if type(history) ~= "table" then
        history = {}
        modData[DRAW_HISTORY_KEY] = history
    end
    return history
end

local function saveDrawHistory(player)
    if player and player.transmitModData then
        pcall(function() player:transmitModData() end)
    end
end

local function processLegendaryDraw(player, token)
    if not removeToken(token) then return end
    if not availablePool then rebuildAvailablePool() end

    local history = getDrawHistory(player)
    local remaining = {}
    for _, fullType in ipairs(availablePool or {}) do
        if not history[fullType] then
            table.insert(remaining, fullType)
        end
    end

    if #remaining == 0 then
        refund(player, DRAW_COST)
        player:Say("이미 모든 전설 무기를 뽑았습니다. 10,000코어를 돌려드렸습니다.")
        return
    end

    local fullType = remaining[ZombRand(#remaining) + 1]
    local inventory = player:getInventory()
    local reward = inventory:AddItem(fullType)
    if not reward then
        refund(player, DRAW_COST)
        player:Say("무기를 지급하지 못해 10,000코어를 돌려드렸습니다.")
        return
    end

    if isServer() and sendAddItemToContainer then
        sendAddItemToContainer(inventory, reward)
    end
    history[fullType] = true
    saveDrawHistory(player)
    player:playSound("AddItemInInventory")
    player:Say("전설 무기 획득: " .. tostring(reward:getDisplayName()))
    print(string.format("%s %s drew %s (%d remaining)", TAG,
        tostring(player:getUsername()), fullType, #remaining - 1))
end

local function getDamagedWeapons(inventory)
    if not inventory or not inventory.getAllEvalRecurse then return nil end
    return inventory:getAllEvalRecurse(function(item)
        if not item or not instanceof(item, "HandWeapon") then return false end
        local maximum = tonumber(item:getConditionMax()) or 0
        local current = tonumber(item:getCondition()) or maximum
        return maximum > 0 and current < maximum
    end)
end

local function processRepairService(player, token)
    if not removeToken(token) then return end

    local damaged = getDamagedWeapons(player:getInventory())
    local repaired = 0
    if damaged then
        for i = 0, damaged:size() - 1 do
            local weapon = damaged:get(i)
            if weapon then
                weapon:setCondition(weapon:getConditionMax())
                repaired = repaired + 1
                if isServer() and sendItemStats then
                    sendItemStats(weapon)
                end
            end
        end
    end

    if repaired == 0 then
        refund(player, REPAIR_COST)
        player:Say("수리할 무기가 없어 4,000코어를 돌려드렸습니다.")
        return
    end

    player:playSound("AddItemInInventory")
    player:Say(tostring(repaired) .. "개의 무기를 완전히 수리했습니다.")
    print(string.format("%s %s repaired %d weapons", TAG,
        tostring(player:getUsername()), repaired))
end

local function processPlayer(player)
    if not player or player:isDead() then return end
    local inventory = player:getInventory()
    if not inventory then return end

    local drawToken = inventory:getFirstTypeRecurse(DRAW_TOKEN)
    if drawToken then processLegendaryDraw(player, drawToken) end

    local repairToken = inventory:getFirstTypeRecurse(REPAIR_TOKEN)
    if repairToken then processRepairService(player, repairToken) end
end

local function forEachAuthoritativePlayer(callback)
    if isServer() then
        local players = getOnlinePlayers and getOnlinePlayers() or nil
        if not players then return end
        for i = 0, players:size() - 1 do
            callback(players:get(i))
        end
        return
    end

    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, count - 1 do
        local player = getSpecificPlayer and getSpecificPlayer(i) or nil
        if player then callback(player) end
    end
end

local function onTick()
    tickCounter = tickCounter + 1
    if tickCounter < 30 then return end
    tickCounter = 0
    forEachAuthoritativePlayer(processPlayer)
end

local function onWorldReady()
    availablePool = nil
    rebuildAvailablePool()
end

Events.OnTick.Add(onTick)
Events.OnGameStart.Add(onWorldReady)
Events.OnLoad.Add(onWorldReady)
if Events.OnServerStarted then Events.OnServerStarted.Add(onWorldReady) end

print(TAG .. " loaded")
