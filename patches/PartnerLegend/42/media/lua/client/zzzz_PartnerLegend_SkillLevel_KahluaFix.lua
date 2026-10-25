-- Compatibility hotfix for B42.21 Kahlua java.lang.Double returned by mastery APIs.
-- Isolated override: do not replace legacy Core.lua, perks, mastery XP, or saved records.
require "PartnerLegend/Core"
local L = PartnerLegend
if not L or type(L.SkillLevel) ~= "function" or L._partnerKahluaSkillLevelFixed then
    return
end

local function numberValue(value)
    if value == nil then return nil end
    local ok, result = pcall(function() return tonumber(tostring(value)) end)
    if ok then return result end
    return nil
end
local function extensionLevel(ext, player, perk)
    if not ext or type(ext.GetEffectiveLevel) ~= "function" then return nil end
    local ok, value = pcall(ext.GetEffectiveLevel, player, perk)
    if not ok then return nil end
    return numberValue(value)
end

L.SkillLevel = function(player, id)
    if not player or not Perks or not Perks.FromString then return 0 end
    local perk = Perks.FromString(id)
    if not perk or (Perks.MAX and perk == Perks.MAX) then return 0 end
    local level = extensionLevel(PartnerMasteryExtension, player, perk)
    if level == nil then level = extensionLevel(BeyondTen, player, perk) end
    if level == nil then
        local ok, value = pcall(function() return player:getPerkLevel(perk) end)
        if ok then level = numberValue(value) end
    end
    return math.max(0, level or 0)
end
L._partnerKahluaSkillLevelFixed = true
print("[PartnerLegend] Kahlua java.lang.Double mastery conversion protected")
