-- Compatibility name for My Spatial Refuge Shop Extension.
-- My Spatial Refuge B42.21 exposes this API as MSR.Basement from
-- MSR_Basement.lua, while the shop extension still requires the older
-- MSR_BasementGeneration module name.
local basement = nil

if MSR and MSR.Basement then
    basement = MSR.Basement
else
    local ok, loaded = pcall(require, "MSR_Basement")
    if ok then
        basement = loaded or (MSR and MSR.Basement)
    end
end

if MSR and basement then
    MSR.BasementGeneration = MSR.BasementGeneration or basement
end

return MSR and MSR.BasementGeneration or basement
