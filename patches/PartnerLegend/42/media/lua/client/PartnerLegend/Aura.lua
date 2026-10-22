-- Partner Legend v0.2.1 — lightweight title aura
-- No zombie scans, OnTick, world light sources or custom external dependencies.
-- The invisible ISPanel only renders while F8 aura preference is ON.
require "PartnerLegend/Core"
require "ISUI/ISPanel"

local L=PartnerLegend
local A={}
L.AuraRenderer=A
local Overlay=ISPanel:derive("PartnerLegendAuraOverlay")
local panel=nil
local active=false
local colour={0.35,0.68,1.0}
local sparks=0
local style=0
local texture=nil
local segments=18
local TWOPI=math.pi*2

local function drawSegment(self,cx,cy,rx,ry,angle1,angle2,width,r,g,b,alpha)
    local x1=cx+rx*math.cos(angle1)
    local y1=cy+ry*math.sin(angle1)
    local x2=cx+rx*math.cos(angle2)
    local y2=cy+ry*math.sin(angle2)
    local dx,dy=x2-x1,y2-y1
    local mag=math.sqrt(dx*dx+dy*dy)
    if mag<0.01 then return end
    local nx,ny=-dy*width/mag,dx*width/mag
    self:drawTextureAllPoint(texture,
        x1-nx,y1-ny, x2-nx,y2-ny,
        x2+nx,y2+ny, x1+nx,y1+ny,
        r,g,b,alpha)
end

function Overlay:new(playerIndex)
    local inst=ISPanel:new(0,0,getCore():getScreenWidth(),getCore():getScreenHeight())
    setmetatable(inst,self)
    self.__index=self
    inst.playerIndex=playerIndex
    inst:noBackground()
    inst.drawBorder=false
    if inst.setRenderThisPlayerOnly then
        inst:setRenderThisPlayerOnly(playerIndex)
    end
    return inst
end
function Overlay:initialise()
    ISPanel.initialise(self)
end
function Overlay:onMouseDown()
    return false
end
function Overlay:onRightMouseDown()
    return false
end
function Overlay:render()
    if not active or not texture then return end
    local p=getSpecificPlayer and getSpecificPlayer(self.playerIndex)
    if not p or p:isDead() then return end
    if p:getVehicle() then return end

    local core=getCore()
    local sw,sh=core:getScreenWidth(),core:getScreenHeight()
    if self.width~=sw then self:setWidth(sw) end
    if self.height~=sh then self:setHeight(sh) end

    local x,y,z=p:getX(),p:getY(),p:getZ()
    local px=x+0.5
    local py=y+0.5
    local left=getPlayerScreenLeft(self.playerIndex)
    local top=getPlayerScreenTop(self.playerIndex)
    local cx=isoToScreenX(self.playerIndex,px,py,z)-left
    local cy=isoToScreenY(self.playerIndex,px,py,z)-top
    local diff=math.abs(isoToScreenX(self.playerIndex,px+1,py,z)-
        isoToScreenX(self.playerIndex,px,py,z))
    local rx=math.max(21,math.min(126,diff*1.55))
    local ry=rx*0.48
    if cx < -rx or cx > sw+rx or cy < -ry or cy > sh+ry then return end

    local time=(getTimestampMs and getTimestampMs() or 0)/1000
    local pulse=0.66+0.18*math.sin(time*2.5)
    local r,g,b=colour[1],colour[2],colour[3]
    -- At most 36 low-alpha quads for the aura + 2-8 particles.
    for i=0,segments-1 do
        local a1=TWOPI*i/segments
        local a2=TWOPI*(i+1)/segments
        drawSegment(self,cx,cy,rx,ry,a1,a2,2.5,r,g,b,0.18*pulse)
        drawSegment(self,cx,cy,rx,ry,a1,a2,1.05,r,g,b,0.63*pulse)
    end
    for i=1,sparks do
        local a=time*(0.35+0.06*(i%3))+(i*TWOPI/sparks)
        local mx=cx+rx*math.cos(a)
        local my=cy+ry*math.sin(a)-2-math.abs(math.sin(time*1.5+i))*7
        local size=1.5+(i%3)*0.55
        self:drawTextureAllPoint(texture,
            mx-size,my-size,mx+size,my-size,
            mx+size,my+size,mx-size,my+size,
            math.min(1,r+0.2),math.min(1,g+0.2),math.min(1,b+0.2),0.65)
    end
end

local function ensureOverlay()
    if panel then return true end
    if not getTexture or not getCore then return false end
    texture=getTexture("media/white.png")
    if not texture then
        print("[PartnerLegendAura] missing media/white.png, effect disabled")
        return false
    end
    panel=Overlay:new(0)
    panel:initialise()
    panel:addToUIManager()
    panel:setVisible(false)
    return true
end
local function colourFor(titleThreshold)
    if titleThreshold>=1000000 then
        return {0.74,0.48,1.0},8,5
    elseif titleThreshold>=500000 then
        return {0.64,0.56,1.0},7,4
    elseif titleThreshold>=250000 then
        return {1.0,0.77,0.26},6,3
    elseif titleThreshold>=100000 then
        return {1.0,0.25,0.34},5,2
    elseif titleThreshold>=50000 then
        return {0.3,0.9,0.85},4,1
    elseif titleThreshold>=10000 then
        return {0.22,0.6,1.0},3,1
    else
        return {0.7,0.8,0.95},2,0
    end
end

function A.Refresh()
    local p=getSpecificPlayer and getSpecificPlayer(0)
    if not p or p:isDead() then
        active=false
        if panel then panel:setVisible(false) end
        return
    end
    local _,index=L.BestTitle(p)
    local want=index>0 and L.AuraPreference(p,index)
    if not want then
        active=false
        if panel then panel:setVisible(false) end
        return
    end
    if not ensureOverlay() then return end
    local threshold=L.TITLES[index][1]
    colour,sparks,style=colourFor(threshold)
    active=true
    panel:setVisible(true)
end
function A.IsActive()
    return active
end
Events.OnGameStart.Add(A.Refresh)
-- Refresh title unlock state once per in-game minute; no per-frame stats query.
Events.EveryOneMinute.Add(A.Refresh)
Events.OnPlayerDeath.Add(function(p)
    if p==getSpecificPlayer(0) then
        active=false
        if panel then panel:setVisible(false) end
    end
end)
