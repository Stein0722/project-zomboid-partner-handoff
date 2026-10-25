-- Partner Viewpoint Ballistics Bridge v0.1.0 TEST. B42.21 singleplayer only.
-- Uses Viewpoint.View.next(), a read-only public Lua function.
-- NOTE: next()=="first" means CURRENTLY isometric,
--       next()=="third" means CURRENTLY first person,
--       next()=="isometric" means CURRENTLY third person.
if isServer and isServer() then return end
PartnerViewpointBallisticsBridge = PartnerViewpointBallisticsBridge or {}
local B=PartnerViewpointBallisticsBridge
B.mode='unknown'
B.currentOwner='unknown'
B.lastApplied=nil
B.checkEveryTicks=10
local ticks=0
local warned={}
local function once(key,msg)
    if warned[key] then return end
    warned[key]=true
    print('[PartnerViewpointBridge][WARN] '..msg)
end
local function cameraMode()
    local v=Viewpoint and Viewpoint.View
    if not v or not v.next then return nil end
    local ok,n=pcall(v.next)
    if not ok then return nil end
    if n=='first' then return 'isometric' end
    if n=='third' then return 'first' end
    if n=='isometric' then return 'third' end
    return nil
end
local function javaReady()
    if not VTB or type(VTB.isAvailable)~='function' then return false end
    local ok,value=pcall(VTB.isAvailable)
    return ok and value==true
end
local function enabled()
    local o=SandboxVars and SandboxVars.VTB
    return not o or o.Enabled~=false
end
local function isoEnabled()
    local o=SandboxVars and SandboxVars.VTB
    return o and o.UseInIsoView==true or false
end
local function owner()
    local mode=cameraMode()
    if not mode then return false,'unavailable' end
    if not javaReady() or not enabled() then return false,mode end
    return mode~='isometric' or isoEnabled(),mode
end
function B.IsExternalBallistics()
    -- Mastery may receive OnWeaponSwing before our bridge callback. Ensure
    -- the PLB equipped-gun fields match the current camera mode first.
    local external=owner()
    if B.lastApplied~=external then B.Sync(false) end
    return external==true
end
function B.GetMode() local _,mode=owner();return mode end
function B.Status()
    local external,mode=owner()
    return '[PartnerViewpointBridge] camera='..tostring(mode)..' owner='..(external and 'TrueBallistics' or 'PartnerLightweightBallistics')
end
function B.Sync(force)
    local plb=PartnerLightweightBallistics
    if not plb or type(plb.SetExternalBallistics)~='function' then
        once('plb','Compatible PLB test build not loaded, no mode switch possible')
        return
    end
    local external,mode=owner()
    if mode=='unavailable' then
        once('camera','Viewpoint public next() unavailable; fail-safe PLB mode')
    end
    if isoEnabled() then
        once('iso','VTB.UseInIsoView=true; switching ALL views to True Ballistics to avoid duplicates. Set false for intended iso PLB')
    end
    B.mode=mode
    B.currentOwner=external and 'VTB' or 'PLB'
    if B.lastApplied==external and not force then return end
    B.lastApplied=external
    plb.SetExternalBallistics(external)
    print(B.Status())
end
local function onTick()
    ticks=ticks+1
    if ticks>=B.checkEveryTicks then ticks=0; B.Sync(false) end
end
local function onSwing(player,weapon)
    if getSpecificPlayer and player==getSpecificPlayer(0) then B.Sync(false) end
end
local function onFinished(player)
    if getSpecificPlayer and player==getSpecificPlayer(0) and B.IsExternalBallistics() then
        local plb=PartnerLightweightBallistics
        if plb and plb.RefreshBridgeWeapon then plb.RefreshBridgeWeapon() end
    end
end
Events.OnTick.Add(onTick)
if Events.OnWeaponSwing then Events.OnWeaponSwing.Add(onSwing) end
if Events.OnPlayerAttackFinished then Events.OnPlayerAttackFinished.Add(onFinished) end
Events.OnGameStart.Add(function() B.lastApplied=nil;B.Sync(true) end)
print('[PartnerViewpointBridge] v0.1.0 loaded; isometric=PLB, Viewpoint FPS/TPS=VTB when VTB Java is ready')
