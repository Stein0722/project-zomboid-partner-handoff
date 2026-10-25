-- Run from repository root:
--   lua patches/PartnerLegendaryWeaponDrops/tests/independent_drop_test.lua <repo-root>
local root=assert(arg[1],"repository root required"):gsub("\\","/")
local handlers={}
local function event() return {Add=function(fn) handlers[#handlers+1]=fn end} end
Events={
    OnFillContainer=event(),OnZombieDead=event(),OnGameStart=event(),
    OnLoad=event(),OnServerStarted=event(),EveryOneMinute=event(),
}
SandboxVars={PartnerLegendaryDrops={Enabled=true,ContainerChanceDenominatorV2=10000,SuppressOriginalSources=false}}
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
local expectedNs={}
ZombRand=function(n)
    local expected=table.remove(expectedNs,1)
    assert(n==expected,"unexpected random range: "..tostring(n).." ~= "..tostring(expected))
    return table.remove(rolls,1) or 1
end
local spawned={}
local container={AddItem=function(_,name) spawned[#spawned+1]=name;return {} end}
assert(loadfile(root.."/patches/PartnerLegendaryWeaponDrops/42/media/lua/server/Items/PartnerLegendaryWeaponDrops.lua"))()
-- First, select the registered per-container handler.
local cb=handlers[1]
assert(type(cb)=="function","OnFillContainer handler not registered")
-- The rare-event skip chooses the first hit; later entries keep independent 1/N rolls.
-- This sequence yields the first and third weapon in one chest.
expectedNs={1000000000,10000,10000};rolls={0,2,0}
cb("bedroom","wardrobe",container)
assert(#spawned==2,"independent rolls should allow two legendary drops per container")
assert(spawned[1]~=spawned[2],"unexpected same item from distinct rolls")
-- Fast-path rejection: no successful item and no per-entry loop.
spawned={};expectedNs={1000000000};rolls={999999999}
cb("bedroom","wardrobe",container)
assert(#spawned==0,"unsuccessful independent rolls yielded drop")
print("Independent legendary drop test passed")
