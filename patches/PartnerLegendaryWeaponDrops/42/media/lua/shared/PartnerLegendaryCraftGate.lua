-- Called only if the blocked assembly recipe is evaluated by B42 crafting.
-- No update loop; original recipe resources and repair recipes are unchanged.
PartnerLegendaryCraftGate=PartnerLegendaryCraftGate or {}
function PartnerLegendaryCraftGate.AlwaysFalse(item,character)
    return false
end
