-- Partner Legend v0.3 — client-only achievement celebration.
-- Uses user's supplied font baked into PNGs. No font binaries distributed.
-- No UIElement is created: drawing CANNOT intercept mouse input.
-- Sound is a local UI sound, never a world sound or zombie attractor.
require "PartnerLegend/Core"
local L=PartnerLegend
local C={}
L.Celebration=C
local queue,active={},nil
local lastStart=0
local DURATION=4700
local MAX_QUEUE=5
local iconPath="media/ui/PLAch_"
local motes=nil
local goldMotes=nil
local lineAccent=nil
local function now() return getTimestampMs and getTimestampMs() or 0 end
local function playSound()
    local manager=getSoundManager and getSoundManager()
    if manager and manager.playUISound then
        local ok,err=pcall(function() manager:playUISound("PartnerLegendAchievement") end)
        if not ok then print("[PartnerLegend] UI achievement sound unavailable: "..tostring(err)) end
    end
end
local function startNext()
    if #queue==0 then active=nil;return end
    active=table.remove(queue,1)
    active.t=now()
    active.texture=getTexture(iconPath..active.id..".png") or getTexture(iconPath.."default.png")
    motes=motes or getTexture("media/ui/PLAura_mote.png")
    goldMotes=goldMotes or getTexture("media/ui/PLAch_GoldMote.png")
    lineAccent=lineAccent or getTexture("media/ui/PLAch_LineAccent.png")
    lastStart=active.t
    playSound()
end
function C.Enqueue(id,name)
    if not id or (not name) then return end
    if #queue>=MAX_QUEUE then return end
    queue[#queue+1]={id=tostring(id),name=tostring(name)}
    if not active then startNext() end
end
function C.IsPlaying() return active~=nil end
function C.Clear() queue={};active=nil end
local function draw()
    if not active then return end
    local elapsed=now()-active.t
    if elapsed>=DURATION then startNext();return end
    if not UIManager or not UIManager.DrawTexture then return end
    local core=getCore and getCore()
    if not core then return end
    local sw=core:getScreenWidth()
    local fraction=elapsed/DURATION
    local fadeIn=math.min(1,elapsed/420)
    local fadeOut=math.min(1,(DURATION-elapsed)/800)
    local alpha=math.min(fadeIn,fadeOut)
    local w,h=700,115
    local x=(sw-w)/2
    local y=22+9*math.sin(math.min(1,fraction)*math.pi)
    if active.texture then
        UIManager.DrawTexture(active.texture,x,y,w,h,alpha*0.96)
        -- Gold accent overlay brightens only the original symmetrical side
        -- strokes; all achievement lettering and the underlying PNG remain.
        if lineAccent then
            UIManager.DrawTexture(lineAccent,x,y,w,h,alpha*0.92)
        end
    end
    if motes then
        -- Three clearly visible UI-only confetti bursts (20 motes per wave).
        -- 60 is an upper bound, not 60 active all the time. Rendering exists
        -- only while the 4.7-second banner is shown: no world emitters, light,
        -- zombie queries or new gameplay polling / timer events are created.
        local t=elapsed*0.001
        for i=1,60 do
            local wave=math.floor((i-1)/20)
            local slot=((i-1)%20)+1
            local delay=0.15+wave*1.06+((slot*7)%11)*0.045
            local progress=(t-delay)/1.62
            if progress>=0 and progress<1 then
                -- Motes launch at both sides of the banner and fan upward.
                local side=(slot%2==0) and 1 or -1
                local radial=60+(slot%5)*31
                local spread=side*(35+((slot*13)%91))*progress
                local sway=math.sin(t*(2.0+slot%3)*0.65+slot)*5*progress
                local mx=sw/2+side*radial+spread+sway
                local rise=57+((slot*19)%80)
                local my=y+84+((slot*17)%29)-rise*progress-9*progress*progress
                local size=4.4+(slot%4)*1.25
                local opacity=alpha*math.min(1,progress*7)
                    *math.pow(1-progress,0.72)*0.94
                local sprite=(slot%4==0 and goldMotes) or motes
                if sprite then
                    UIManager.DrawTexture(sprite,mx-size/2,my-size/2,size,size,opacity)
                end
            end
        end
    end
end
if Events.OnPreUIDraw then Events.OnPreUIDraw.Add(draw) end
if Events.OnPlayerDeath then
    Events.OnPlayerDeath.Add(function(p)
        if p==getSpecificPlayer(0) then C.Clear() end
    end)
end
L._CelebrationV03=true
