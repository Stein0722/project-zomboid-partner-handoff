-- Partner Journal Extension: append Partner Legend medals to Daily Report Journal.
-- Reuses the original journal's daily achievement evaluation + medal UI.
-- No OnTick, no additional zombie scanning, no duplicated medal tracking.
pcall(require,"dSAG/dSAG_Medals")
pcall(require,"PartnerLegend/Core")
local journal=dSAG
local legend=PartnerLegend
if not journal or type(journal.medalDefs)~="table" or not legend then
    print("[PartnerJournalExtension] Missing Daily Report Journal or Partner Legend")
    return
end
if journal._partnerLegendExtended then return end
journal._partnerLegendExtended=true
local seen={}
for _,def in ipairs(journal.medalDefs) do seen[def.id]=true end
local function install(def)
    if seen[def.id] then return end
    journal.medalDefs[#journal.medalDefs+1]=def
    seen[def.id]=true
end
for _,medal in ipairs(legend.MEDALS) do
    local m=medal
    local id="pl_"..m.id
    install({
        id=id,
        check=function(ctx)
            local player=ctx.player
            if not player then return false end
            local value=0
            if m.kind=="kills" then
                value=select(1,legend.Stats(player))
            elseif m.kind=="days" then
                value=select(2,legend.Stats(player))
            else
                value=legend.SkillLevel(player,m.perk)
            end
            return value>=legend.Required(m.kind,m.target)
        end
    })
end
-- New 10-level aiming milestone: ranged penetration rank I is a planned bonus.
install({
    id="pl_aim_10",
    check=function(ctx)
        return ctx.player and legend.SkillLevel(ctx.player,"Aiming")>=10
    end
})
print("[PartnerJournalExtension] Original Daily Journal medals extended by Partner Legend")
