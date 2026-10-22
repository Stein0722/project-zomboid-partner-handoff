-- Run from repository root:
--   lua patches/PartnerLegendaryWeaponDrops/tests/independent_drop_test.lua <repo-root>
local root=assert(arg[1],"repository root required"):gsub("\\","/")
local handlers={}
local function event() return {Add=function(fn) handlers[#handlers+1]=fn end} end
Events={OnFillContainer=event(),OnGameStart=event(),OnLoad=event(),OnServerStarted=event()}
SandboxVars={PartnerLegendaryDrops={Enabled=true,ContainerChanceDenominator=10000,SuppressOriginalSources=false}}
isClient=function() return false end
local valid={
    ["P4Excalibar.P4Excalibar"]=true,
    ["LTW.LegendaryTacticalSword"]=true,
    ["LK.LegendaryKatanaBlack"]=true,
}
getScriptManager=function() return {
    FindItem=function(_,name) return valid[name] and {} or nil end
} end
local rolls={}
ZombRand=function(n)
    assert(n==10000,"expected exact per-item chance denominator")
    return table.remove(rolls,1) or 1
end
local spawned={}
local container={AddItem=function(_,name) spawned[#spawned+1]=name;return {} end}
assert(loadfile(root.."/patches/PartnerLegendaryWeaponDrops/42/media/lua/server/Items/PartnerLegendaryWeaponDrops.lua"))()
-- First, select the registered per-container handler.
local cb=handlers[1]
assert(type(cb)=="function","OnFillContainer handler not registered")
-- Three registered item types, three independent rolls. Two may hit in one chest.
rolls={0,2,0}
cb("bedroom","wardrobe",container)
assert(#spawned==2,"independent rolls should allow two legendary drops per container")
assert(spawned[1]~=spawned[2],"unexpected same item from distinct rolls")
-- No successful item: zero drops.
spawned={};rolls={1,1,1}
cb("bedroom","wardrobe",container)
assert(#spawned==0,"unsuccessful independent rolls yielded drop")
print("Independent legendary drop test passed")
