-- Partner fix for My Spatial Refuge automatic core pickup on B42.21 MP.
--
-- OnZombieDead can run after the dead zombie has already lost its square.
-- MSR_InventoryAuthority.moveItem then moves the core successfully, but
-- GameServer.sendRemoveItemFromContainer dereferences that missing square and
-- throws.  Keep the authoritative move and destination sync, while skipping
-- only the impossible removal packet for that stale zombie/corpse container.

require "MSR_InventoryAuthority"

local PATCH_TAG = "[PartnerSpatialRefugeCoop]"
local CORE_ITEM = MSR and MSR.Config and MSR.Config.CORE_ITEM or "Base.MagicalCore"
local InventoryAuthority = MSR and MSR.InventoryAuthority or nil

if not InventoryAuthority or type(InventoryAuthority.moveItem) ~= "function" then
    print(PATCH_TAG .. " core pickup sync fix could not find MSR.InventoryAuthority")
    return
end

if InventoryAuthority._partnerStaleCorpseSyncFixInstalled then
    return
end

local originalMoveItem = InventoryAuthority.moveItem
local skippedRemovalNoticeShown = false

-- A core can be inside a bag. Walk outward and report whether the source is
-- one of the player's own containers. Current MSR calls moveItem only from
-- automatic core pickup, but this guard keeps future player-to-player moves
-- on the original fully synchronized path.
local function belongsToPlayer(container, player)
    local current = container
    for _ = 1, 16 do
        if not current then return false end

        local okContaining, containingItem = pcall(function()
            return current:getContainingItem()
        end)
        if okContaining and containingItem then
            local okOuter, outerContainer = pcall(function()
                return containingItem:getContainer()
            end)
            if not okOuter or not outerContainer or outerContainer == current then
                return false
            end
            current = outerContainer
        else
            local okParent, parent = pcall(function() return current:getParent() end)
            return okParent and parent == player
        end
    end
    return false
end

local function isPartnerAutomaticPickupType(fullType)
    if fullType == CORE_ITEM then return true end
    local partnerLoot = MSR and MSR.PartnerAutomaticSellLoot or nil
    return partnerLoot and type(partnerLoot.isManagedLootType) == "function" and
        partnerLoot.isManagedLootType(fullType) == true
end

local function isAutomaticPickupSource(player, sourceContainer, item)
    if not player or not sourceContainer or not item then return false end
    local okType, fullType = pcall(function() return item:getFullType() end)
    if not okType or not isPartnerAutomaticPickupType(fullType) then return false end
    return not belongsToPlayer(sourceContainer, player)
end

local function moveWithoutStaleSourcePacket(player, sourceContainer, destinationContainer, item)
    if not MSR or not MSR.Env or not MSR.Env.hasServerAuthority or
            not MSR.Env.hasServerAuthority() then
        return false
    end
    if not sourceContainer or not destinationContainer or not item then return false end
    if sourceContainer == destinationContainer then return sourceContainer:contains(item) end
    if not sourceContainer:contains(item) then return false end
    if not destinationContainer:hasRoomFor(player, item) then return false end

    sourceContainer:DoRemoveItem(item)
    local added = destinationContainer:AddItem(item)
    if not added then
        sourceContainer:AddItem(item)
        return false
    end

    -- The stale source no longer has a valid world address, so a removal
    -- packet cannot be constructed. The destination is still synchronized.
    if MSR.Env.needsClientSync and MSR.Env.needsClientSync() and
            sendAddItemToContainer then
        local syncOk, syncError = pcall(function()
            sendAddItemToContainer(destinationContainer, item)
        end)
        if not syncOk then
            print(PATCH_TAG .. " automatic-pickup destination sync failed: " .. tostring(syncError))
        end
    end

    if not skippedRemovalNoticeShown then
        skippedRemovalNoticeShown = true
        print(PATCH_TAG .. " safely skipped one stale corpse automatic-pickup removal packet")
    end
    return true
end

InventoryAuthority.moveItem = function(player, sourceContainer, destinationContainer, item)
    -- B42.21's OnZombieDead may clear the zombie square before MSR sends the
    -- source-removal packet.  The old owner-type test no longer catches every
    -- form of that container.  MSR currently uses moveItem only for automatic
    -- MagicalCore and Partner sell-item pickup, so identify those narrow
    -- corpse-to-player transactions directly.
    if isAutomaticPickupSource(player, sourceContainer, item) then
        return moveWithoutStaleSourcePacket(player, sourceContainer, destinationContainer, item)
    end
    return originalMoveItem(player, sourceContainer, destinationContainer, item)
end

InventoryAuthority._partnerStaleCorpseSyncFixInstalled = true
print(PATCH_TAG .. " automatic corpse pickup stale-source sync fix enabled")
