-- Partner MP Map Fix for Build 42.21
-- MapAllKnown is reported as true by the server but may leave the world map
-- covered in multiplayer.  Rendering unvisited areas directly avoids touching
-- the world, character, or map-symbol save data.

require "ISUI/Maps/ISWorldMap"

local originalShowWorldMap = ISWorldMap.ShowWorldMap

function ISWorldMap.ShowWorldMap(playerNum, centerX, centerY, zoom)
    originalShowWorldMap(playerNum, centerX, centerY, zoom)

    if not ISWorldMap_instance then
        return
    end

    ISWorldMap_instance:setHideUnvisitedAreas(false)
    ISWorldMap_instance:setShowPlayers(true)
    ISWorldMap_instance:setShowRemotePlayers(true)
    ISWorldMap_instance:setShowPlayerNames(true)

    print("[PartnerMPMapFix] Full map and remote player names enabled")
end
