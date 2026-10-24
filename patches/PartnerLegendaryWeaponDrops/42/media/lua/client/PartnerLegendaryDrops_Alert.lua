-- Only runs after a rare generated loot event. Never scans the world.
local function popup()
    local player=getPlayer and getPlayer() or nil
    if not player then return end
    if HaloTextHelper then
        local color=HaloTextHelper.getColorWhite and HaloTextHelper.getColorWhite() or nil
        local ok=pcall(function()HaloTextHelper.addText(player,'...!','',color)end)
        if not ok then pcall(function()HaloTextHelper.addText(player,'...!',color)end) end
    end
    local sounds=getSoundManager and getSoundManager()
    if sounds then
        local ok,handle=pcall(function()return sounds:PlaySound('Kanteishi',false,0)end)
        if ok and handle then pcall(function()handle:setVolume(0.7)end)
        else pcall(function()sounds:PlaySound('GainExperienceLevel',false,0)end)end
    end
end
PartnerLegendaryDropsNotify=popup
Events.OnServerCommand.Add(function(module,command,args)
    if module=='PartnerLegendaryDrops' and command=='NearbyLegendary' then popup() end
end)
