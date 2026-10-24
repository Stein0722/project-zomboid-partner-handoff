-- Exact premium item prices after the original Partner x2 shop multiplier.
-- No tick/per-frame callbacks and no edits to base ShopData purchase operations.
require "MSR_ShopData"
local PREMIUM = {
    mod_dabaojian = 11000,           -- Taido / Base.dabaojian
    mod_legendary_wakizashi = 11000, -- LK.LegendaryWakizashiGrey
    mod_legendary_katana = 11000,    -- LK.LegendaryKatanaGrey
}
local function tune()
    local data = MSR and MSR.ShopData
    if not data or not data._items then return end
    for id, price in pairs(PREMIUM) do
        local item = data._items[id]
        if item and not item.isSell and tonumber(item.price) ~= price then
            item.price = price
        end
    end
end
local data = MSR and MSR.ShopData
if data and type(data.initialize) == 'function' and not data._partnerPremiumPriceHook then
    local previous = data.initialize
    data.initialize = function(...)
        local a,b,c = previous(...)
        tune()
        return a,b,c
    end
    data._partnerPremiumPriceHook = true
end
if Events.OnGameStart then Events.OnGameStart.Add(tune) end
if Events.OnServerStarted then Events.OnServerStarted.Add(tune) end
