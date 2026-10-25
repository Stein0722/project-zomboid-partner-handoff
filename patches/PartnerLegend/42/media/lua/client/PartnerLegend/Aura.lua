-- Partner Legend v0.2.2: world-aligned, mouse-transparent title aura.
-- NO full-screen ISPanel / UIElement: unlike v0.2.1 this cannot intercept input.
-- Draws at the character's exact world position via the B42 isoToScreen API.
-- Native UIManager.DrawTexture, executed only while the selected aura is ON.
require "PartnerLegend/Core"

local L = PartnerLegend
local A = {}
L.AuraRenderer = A

local PATH = "media/ui/PLAura_"
local COLOURS = {
    pale = "pale", blue = "blue", teal = "teal",
    red = "red", gold = "gold", violet = "violet"
}
local cachedTextures = {}
local enabled = false
local activeTitle = 0
local motes = 0
local ringTexture = nil
local moteTexture = nil
local TWO_PI = math.pi * 2
local warned = false

local function getSprite(name)
    if not cachedTextures[name] then
        cachedTextures[name] = getTexture(PATH .. name .. ".png")
    end
    return cachedTextures[name]
end

local function profile(threshold)
    if threshold >= 1000000 then return COLOURS.violet, 8 end
    if threshold >= 500000 then return COLOURS.violet, 7 end
    if threshold >= 250000 then return COLOURS.gold, 6 end
    if threshold >= 100000 then return COLOURS.red, 5 end
    if threshold >= 50000 then return COLOURS.teal, 4 end
    if threshold >= 10000 then return COLOURS.blue, 3 end
    return COLOURS.pale, 2
end

function A.Refresh()
    enabled = false
    local p = getSpecificPlayer and getSpecificPlayer(0)
    if not p or p:isDead() or not L.BestTitle then return end
    local _, index = L.BestTitle(p)
    if not index or index == 0 or not L.AuraPreference(p, index) then return end
    local def = L.TITLES[index]
    if not def then return end
    local colour, count = profile(def[1])
    ringTexture = getSprite(colour)
    moteTexture = getSprite("mote")
    if not ringTexture then
        if not warned then
            print("[PartnerLegendAura] aura texture not found; check v0.2.2 UI png files")
            warned = true
        end
        return
    end
    activeTitle = def[1]
    motes = count
    enabled = true
end

function A.IsActive()
    return enabled
end

-- Title text is independent of the ring, at the user's requested foot position.
local label, labelColour, labelAvailable = nil, {0.7,0.8,0.95}, false
-- 100% = original Warhaven PNG pixels. The default 65% is near the
-- character's foot width in the user's reference screenshot.
-- The size is independent of world zoom and is only recalculated when
-- the title texture or the slider value changes, never each frame.
local labelSprite=nil
local titleSizePercent = 65
local titleDrawWidth, titleDrawHeight = 0, 0
local function updateTitleDimensions()
    if labelSprite then
        local scale=titleSizePercent/100
        titleDrawWidth=math.max(1,math.floor(labelSprite:getWidth()*scale+0.5))
        titleDrawHeight=math.max(1,math.floor(labelSprite:getHeight()*scale+0.5))
    else
        titleDrawWidth,titleDrawHeight=0,0
    end
end
function A.SetTitleSizePercent(value)
    local n=tonumber(value) or 65
    n=math.max(25,math.min(200,n))
    if titleSizePercent==n then return n end
    titleSizePercent=n
    updateTitleDimensions()
    return n
end
function A.GetTitleSizePercent()
    return titleSizePercent
end
local colourRGB={pale={0.84,0.86,0.92},blue={0.42,0.75,1.0},
 teal={0.33,0.91,0.86},red={1.0,0.43,0.46},gold={1.0,0.79,0.33},
 violet={0.79,0.60,1.0}}
local prevRefresh=A.Refresh
A.Refresh=function()
    prevRefresh()
    label=nil
    labelSprite=nil
    labelAvailable=false
    local p=getSpecificPlayer and getSpecificPlayer(0)
    if not p or p:isDead() then return end
    local name,index=L.BestTitle(p)
    local def=index>0 and L.TITLES[index] or nil
    if def then
        label=name
        labelAvailable=true
        labelSprite=getTexture("media/ui/PLTitle_"..tostring(def[1])..".png")
        local key=profile(def[1])
        labelColour=colourRGB[key] or colourRGB.pale
    end
    updateTitleDimensions()
end

local function render()
    if not enabled and not labelAvailable then return end
    local p=getSpecificPlayer and getSpecificPlayer(0)
    if not p or p:isDead() or p:getVehicle() then return end
    local z=p:getZ()
    local sx=isoToScreenX(0,p:getX(),p:getY(),z)
    local sy=isoToScreenY(0,p:getX(),p:getY(),z)
    if enabled and ringTexture and UIManager and UIManager.DrawTexture then
        -- World-scaled ring remains unchanged, but a title-only display no
        -- longer makes unnecessary getZoom calls each frame.
        local zoom=(getCore() and getCore():getZoom(0)) or 1
        if zoom<=0 then zoom=1 end
        local width,height=110/zoom,58/zoom
        local time=(getTimestampMs and getTimestampMs() or 0)/1000
        local alpha=0.73+0.16*math.sin(time*2)
        UIManager.DrawTexture(ringTexture,sx-width/2,sy-height/2,width,height,alpha)
        if moteTexture and motes>0 then
            for i=1,motes do
                local angle=TWO_PI*(i/motes)+time*(0.28+0.03*(i%3))
                local sparkle=(3.5+i%3)/zoom
                local mx=sx+math.cos(angle)*width*0.4-sparkle/2
                local my=sy+math.sin(angle)*height*0.39-sparkle/2
                    -(3.5/zoom)*math.abs(math.sin(time*1.5+i))
                UIManager.DrawTexture(moteTexture,mx,my,sparkle,sparkle,0.48+0.22*math.sin(time+i)^2)
            end
        end
    end
    -- v0.4.7: fixed screen-pixel size across all zoom levels.
    -- User slider changes titleSizePercent; all texture dimensions are cached.
    -- No per-frame image dimensions queries, slider reads or zoom math.
    if labelAvailable and labelSprite and titleDrawWidth>0 and UIManager and UIManager.DrawTexture then
        local tw,th=titleDrawWidth,titleDrawHeight
        local tx=sx-tw/2
        local ty=sy+5-th/2
        -- A stronger charcoal outline is baked into the supplied PNG texture.
        -- Drawing once avoids shimmer and stays constant regardless of zoom.
        UIManager.DrawTexture(labelSprite,tx,ty,tw,th,1)
    end
end

Events.OnGameStart.Add(A.Refresh)
Events.EveryOneMinute.Add(A.Refresh)
if Events.OnPlayerDeath then
    Events.OnPlayerDeath.Add(function(p)
        if p == getSpecificPlayer(0) then enabled = false end
    end)
end
if Events.OnPreUIDraw then
    Events.OnPreUIDraw.Add(render)
else
    print("[PartnerLegendAura] OnPreUIDraw unavailable; aura disabled safely")
end
