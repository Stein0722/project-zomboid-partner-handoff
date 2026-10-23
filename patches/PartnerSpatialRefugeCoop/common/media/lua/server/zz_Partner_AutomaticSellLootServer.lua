-- Server-authoritative corpse auto-loot for Partner shop sell categories.

require "zz_Partner_AutomaticSellLoot"
require "MSR_InventoryAuthority"
local UpgradeEvents = require "MSR_UpgradeEvents"

local TAG = "[PartnerAutomaticSellLootServer]"
local API = MSR.PartnerAutomaticSellLoot
local InventoryAuthority = MSR.InventoryAuthority
local COMMAND_MODULE = API.COMMAND_MODULE
local OWNER_KEY = "PartnerAutomaticSellLootOwner"
local PROTECTED_UNTIL_KEY = "PartnerAutomaticSellLootProtectedUntil"
local OWNER_PROTECTION_SECONDS = 30
local MIN_SCAN_INTERVAL_MS = 500
local MAX_SCAN_RADIUS = 2

local scanStateByPlayer = setmetatable({}, { __mode = "k" })

local function getPlayerLabel(player)
    if not player then return "unknown" end
    local username = player:getUsername()
    if username and username ~= "" then return username end
    return tostring(player:getOnlineID())
end

local function getPickupRadius(player, level)
    level = level or API.getPlayerUpgradeLevel(player)
    if level <= 0 then return 0 end
    local effects = MSR.UpgradeData.getLevelEffects(API.UPGRADE_ID, level)
    return tonumber(effects and effects.corePickupRadius) or 0
end

local function isObjectInRange(object, player, radius)
    if not object or not player or object:getZ() ~= player:getZ() then return false end
    local dx = object:getX() - player:getX()
    local dy = object:getY() - player:getY()
    return dx * dx + dy * dy <= radius * radius
end

local function canCollectFromCorpse(player, corpse, now)
    local modData = corpse and corpse:getModData() or nil
    local owner = modData and modData[OWNER_KEY] or nil
    local protectedUntil = modData and tonumber(modData[PROTECTED_UNTIL_KEY]) or 0
    if not owner or protectedUntil <= now then return true end
    return player:getUsername() == owner
end

local function reserveCorpse(player, corpse)
    if not player or not corpse then return end
    local username = player:getUsername()
    if not username or username == "" then return end
    local modData = corpse:getModData()
    modData[OWNER_KEY] = username
    modData[PROTECTED_UNTIL_KEY] = getTimestamp() + OWNER_PROTECTION_SECONDS
end

local function addDestinationCandidate(player, item, containerItem, seenItems, sameType, other)
    if not containerItem or seenItems[containerItem] then return end
    seenItems[containerItem] = true
    if not instanceof(containerItem, "InventoryContainer") then return end
    local container = containerItem:getInventory()
    if not container or not container:hasRoomFor(player, item) then return end

    local fullType = item:getFullType()
    local destinations = container:containsType(fullType) and sameType or other
    destinations[#destinations + 1] = container
end

local function buildDestinationPlan(player, item)
    local sameType = {}
    local other = {}
    local seenItems = {}

    addDestinationCandidate(player, item, player:getClothingItem_Back(), seenItems, sameType, other)

    local wornItems = player:getWornItems()
    local wornCount = wornItems and wornItems:size() or 0
    for index = 0, wornCount - 1 do
        local wornItem = wornItems:get(index)
        addDestinationCandidate(player, item, wornItem and wornItem:getItem() or nil,
            seenItems, sameType, other)
    end

    addDestinationCandidate(player, item, player:getPrimaryHandItem(), seenItems, sameType, other)
    addDestinationCandidate(player, item, player:getSecondaryHandItem(), seenItems, sameType, other)

    for index = 1, #other do sameType[#sameType + 1] = other[index] end

    local rootInventory = player:getInventory()
    if rootInventory and rootInventory:hasRoomFor(player, item) then
        sameType[#sameType + 1] = rootInventory
    end
    return sameType
end

local function buildEnabledGroups(player, level)
    local enabledGroups = {}
    for _, definition in ipairs(API.GROUP_DEFINITIONS) do
        if level >= definition.requiredLevel and API.isGroupEnabled(player, definition.id) then
            enabledGroups[definition.id] = true
        end
    end
    return enabledGroups
end

local function collectEligibleItems(container, enabledGroups, output)
    if not container then return output end
    output = output or {}
    local items = container:getItems()
    if not items then return output end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            local fullType = item:getFullType()
            local groupId = API.getGroupForItemType(fullType)
            if groupId and enabledGroups[groupId] then
                output[#output + 1] = item
            elseif instanceof(item, "InventoryContainer") then
                collectEligibleItems(item:getInventory(), enabledGroups, output)
            end
        end
    end
    return output
end

local function transferItems(player, items)
    local moved = 0
    for _, item in ipairs(items or {}) do
        local sourceContainer = item and item:getContainer() or nil
        if sourceContainer then
            local destinations = buildDestinationPlan(player, item)
            for _, destination in ipairs(destinations) do
                if sourceContainer ~= destination and
                        InventoryAuthority.moveItem(player, sourceContainer, destination, item) then
                    moved = moved + 1
                    break
                end
            end
        end
    end
    return moved
end

local function showPickupFeedback(player, count)
    if count <= 0 or not HaloTextHelper then return end
    local text = getText("UI_PartnerAutoLootPickup", count) or ("Auto loot +" .. tostring(count))
    HaloTextHelper.addText(player, "[col=137,232,148]" .. text .. "[/]", "[br/]")
end

local function collectFromCorpse(player, corpse, rootContainer, level, enabledGroups)
    if not player or not corpse or not rootContainer or level < 4 then return 0, 0 end
    enabledGroups = enabledGroups or buildEnabledGroups(player, level)
    local eligibleItems = collectEligibleItems(rootContainer, enabledGroups, {})
    local eligibleCount = #eligibleItems
    if eligibleCount == 0 then return 0, 0 end
    if not canCollectFromCorpse(player, corpse, getTimestamp()) then return 0, eligibleCount end
    return transferItems(player, eligibleItems), eligibleCount
end

local function onZombieDead(zombie)
    if not zombie then return end
    local killer = zombie:getAttackedBy()
    if not killer or not instanceof(killer, "IsoPlayer") or killer:getVehicle() then return end

    local level = API.getPlayerUpgradeLevel(killer)
    if level < 4 then return end
    local radius = getPickupRadius(killer, level)
    if radius <= 0 or not isObjectInRange(zombie, killer, radius) then return end

    local rootContainer = zombie:getInventory()
    if not rootContainer then return end
    local moved, eligibleCount = collectFromCorpse(killer, zombie, rootContainer, level)
    if moved > 0 then
        showPickupFeedback(killer, moved)
        print(TAG .. " collected=" .. tostring(moved) .. " player=" .. getPlayerLabel(killer))
    end
    if moved < eligibleCount then reserveCorpse(killer, zombie) end
end

local function collectNearby(player, level, radius, square)
    square = square or player:getCurrentSquare()
    local cell = getCell()
    if not square or not cell then return 0 end

    local centerX = square:getX()
    local centerY = square:getY()
    local centerZ = square:getZ()
    local scanRadius = math.min(MAX_SCAN_RADIUS, math.max(1, math.ceil(radius)))
    local moved = 0
    local enabledGroups = buildEnabledGroups(player, level)

    for offsetX = -scanRadius, scanRadius do
        for offsetY = -scanRadius, scanRadius do
            local nearbySquare = cell:getGridSquare(centerX + offsetX, centerY + offsetY, centerZ)
            local corpses = nearbySquare and nearbySquare:getDeadBodys() or nil
            local corpseCount = corpses and corpses:size() or 0
            for index = 0, corpseCount - 1 do
                local corpse = corpses:get(index)
                if corpse and isObjectInRange(corpse, player, radius) then
                    local rootContainer = corpse:getContainer()
                    local corpseMoved = collectFromCorpse(
                        player, corpse, rootContainer, level, enabledGroups
                    )
                    moved = moved + corpseMoved
                end
            end
        end
    end
    return moved
end

local function onPlayerMove(player)
    if not player or player:isDead() or player:getVehicle() then return end
    local level = API.getPlayerUpgradeLevel(player)
    if level < 4 then return end

    local square = player:getCurrentSquare()
    if not square then return end
    local state = scanStateByPlayer[player]
    if not state then
        state = {}
        scanStateByPlayer[player] = state
    end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    if state.x == x and state.y == y and state.z == z then return end
    local now = getTimestampMs()
    if state.scannedAt and now - state.scannedAt < MIN_SCAN_INTERVAL_MS then return end

    state.x, state.y, state.z, state.scannedAt = x, y, z, now
    local radius = getPickupRadius(player, level)
    if radius <= 0 then return end
    local moved = collectNearby(player, level, radius, square)
    if moved > 0 then showPickupFeedback(player, moved) end
end

local function broadcastSetting(groupId, enabled)
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then return end
    for index = 0, players:size() - 1 do
        local target = players:get(index)
        if target then
            sendServerCommand(target, COMMAND_MODULE, "AutoLootSettingChanged", {
                groupId = groupId,
                enabled = enabled == true,
            })
        end
    end
end

local function resolveServerPlayer(playerRef)
    if playerRef and type(playerRef) ~= "number" and playerRef.getUsername then return playerRef end
    if getOnlinePlayer then return getOnlinePlayer(playerRef) end
    return nil
end

local function onClientCommand(module, command, playerRef, args)
    if module ~= COMMAND_MODULE or command ~= "SetAutoLoot" then return end
    local player = resolveServerPlayer(playerRef)
    local groupId = args and args.groupId or nil
    local enabled = args and args.enabled == true or false
    if not player or not API.isKnownGroup(groupId) then return end
    if API.getPlayerUpgradeLevel(player) < API.getGroupRequiredLevel(groupId) then return end

    local applied, refugeData = API.applySettingLocal(player, groupId, enabled)
    if not applied or not refugeData then return end
    if not MSR.Data.SaveRefugeData(refugeData) then return end
    broadcastSetting(groupId, enabled)
    print(TAG .. " setting " .. groupId .. "=" .. tostring(enabled) ..
        " by " .. getPlayerLabel(player))
end

local function onUpgradeLevelChanged(player, upgradeId)
    if upgradeId == API.UPGRADE_ID and player then scanStateByPlayer[player] = nil end
end

API.rebuildItemRegistry()
UpgradeEvents.OnLevelChanged.Add(onUpgradeLevelChanged)
Events.OnZombieDead.Add(onZombieDead)
Events.OnPlayerMove.Add(onPlayerMove)
Events.OnClientCommand.Add(onClientCommand)
if Events.OnServerStarted then Events.OnServerStarted.Add(API.rebuildItemRegistry) end

print(TAG .. " server-authoritative corpse auto-loot enabled")
