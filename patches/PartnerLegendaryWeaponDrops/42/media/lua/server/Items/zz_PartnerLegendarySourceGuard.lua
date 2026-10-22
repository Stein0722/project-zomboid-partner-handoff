-- Partner Legendary Source Guard for optional LTW and LK packs (B42.21).
-- One-time cleanup of static loot tables only. Never scans live zombies or containers.
-- Crafting, recolouring and repair are intentionally NOT changed by this phase.

local function enabled()
    local cfg=SandboxVars and SandboxVars.PartnerLegendaryDrops
    return cfg and cfg.Enabled~=false and cfg.SuppressOriginalSources~=false
end

local blocked={}
for _,typeName in ipairs({
    "LTW.LegendaryTacticalSword", "LTW.LegendaryTacticalTomahawk",
    "LTW.LegendaryTacticalAxe", "LTW.LegendaryTacticalCrowbar",
    "LTW.LegendaryTacticalBat", "LTW.LegendaryTacticalHammer",
    "LTW.LegendaryTacticalKnife", "LTW.LegendaryTacticalSledgehammer",
    "LTW.LegendaryTacticalSpear",
    "LTW.LegendaryTacticalSwordCaseSealed",
    "LTW.LegendaryTacticalKnifeCaseSealed",
    "LK.LegendaryDaishoCaseSealed",
}) do blocked[typeName]=true end

local colors={"Black","Blue","Brown","Green","Grey","Orange","Pink","Purple","Red","White"}
for _,color in ipairs(colors) do
    blocked["LK.LegendaryKatana"..color]=true
    blocked["LK.LegendaryWakizashi"..color]=true
end

local function removeAllOriginalLoot(root,visited)
    if type(root)~="table" or visited[root] then return 0 end
    visited[root]=true
    local removed=0
    local items=rawget(root,"items")
    if type(items)=="table" then
        for i=#items-1,1,-2 do
            if blocked[items[i]] then
                table.remove(items,i+1) -- numeric loot weight
                table.remove(items,i)   -- item full type
                removed=removed+1
            end
        end
    end
    for key,child in pairs(root) do
        if key~="items" and type(child)=="table" then
            removed=removed+removeAllOriginalLoot(child,visited)
        end
    end
    return removed
end

local completed=false
local function run()
    if completed or not enabled() then return end
    -- These tables were populated by the source mod's distribution scripts.
    local roots={}
    if ProceduralDistributions and ProceduralDistributions.list then
        roots[#roots+1]=ProceduralDistributions.list
    end
    if SuburbsDistributions then roots[#roots+1]=SuburbsDistributions end
    if VehicleDistributions then roots[#roots+1]=VehicleDistributions end
    local visited,removed={},0
    for _,root in ipairs(roots) do
        removed=removed+removeAllOriginalLoot(root,visited)
    end
    -- Also guard sandbox settings on worlds with source scripts that read them later.
    if SandboxVars.LTWO then
        local opt=SandboxVars.LTWO
        opt.WeaponsZombies=0
        for _,name in ipairs({"Sword","Knife","Tomahawk","Axe","Crowbar","Bat",
                              "Hammer","Sledgehammer","Spear"}) do
            opt[name.."Rare"]=0
            opt[name.."Common"]=0
        end
    end
    if SandboxVars.LKO then
        local opt=SandboxVars.LKO
        opt.KatanaZombies=0
        opt.WakizashiZombies=0
        opt.DaishoCommon=0
        opt.DaishoRare=0
    end
    completed=true
    print("[PartnerLegendaryDrops] removed "..removed.." LTW/LK original loot entries")
end

if not isClient() then
    Events.OnGameStart.Add(run)
    Events.OnLoad.Add(run)
    if Events.OnServerStarted then Events.OnServerStarted.Add(run) end
end
