-- Partner Journal Extension v0.4: Partner-owned achievements appear in the Journal.
-- The original Daily Report Journal medal definitions and payouts are left untouched.
-- 30 previous Partner milestones, 14 profession masteries and 6 composite challenges.
-- No OnTick, no inventory/zombie scans.
pcall(require,"dSAG/dSAG_Medals")
pcall(require,"PartnerLegend/Core")
local journal=dSAG
local legend=PartnerLegend
if not journal or type(journal.medalDefs)~="table" or not legend then
    print("[PartnerJournalExtension] prerequisites not loaded")
    return
end
if journal._partnerLegendExtended then return end
journal._partnerLegendExtended=true
local seen={}
for _,definition in ipairs(journal.medalDefs) do seen[definition.id]=true end
local function add(id,test)
    if seen[id] then return end
    seen[id]=true
    journal.medalDefs[#journal.medalDefs+1]={id=id,check=test}
end
local ALIASES={
    Woodwork={"Woodwork","Carpentry"},
    Doctor={"Doctor","FirstAid"},
    PlantScavenging={"PlantScavenging","Foraging"},
}
local function level(p,key)
    if not p then return 0 end
    local names=ALIASES[key] or {key}
    for _,name in ipairs(names) do
        local amount=legend.SkillLevel(p,name)
        if amount>0 then return amount end
    end
    return 0
end
local professions={"Cooking","Woodwork","Electricity","Mechanics","Doctor",
    "Tailoring","Farming","Fishing","Trapping","PlantScavenging",
    "Reloading","Maintenance","Fitness","Strength"}
local function longestMelee(p)
    local m=0
    for _,def in ipairs(legend.MELEE_PERKS) do
        m=math.max(m,legend.SkillLevel(p,def[1]))
    end
    return m
end
local COMPOSITES={
    melee=function(p) return select(1,legend.Stats(p))>=100000 and longestMelee(p)>=20 end,
    ranged=function(p) return select(1,legend.Stats(p))>=250000 and level(p,"Aiming")>=20 end,
    self=function(p) return level(p,"Cooking")>=10 and level(p,"PlantScavenging")>=10 end,
    engineer=function(p) return level(p,"Woodwork")>=10 and level(p,"Mechanics")>=10 end,
    undying=function(p) return select(2,legend.Stats(p))>=365 and level(p,"Doctor")>=10 end,
    armory=function(p) return level(p,"Reloading")>=20 and level(p,"Maintenance")>=20 end,
}
for _,medal in ipairs(legend.MEDALS) do
    local m=medal
    add("pl_"..m.id,function(ctx)
        local p=ctx.player
        if not p then return false end
        local value
        if m.kind=="kills" then value=select(1,legend.Stats(p))
        elseif m.kind=="days" then value=select(2,legend.Stats(p))
        else value=level(p,m.perk) end
        return value>=legend.Required(m.kind,m.target)
    end)
end
add("pl_aim_10",function(ctx) return level(ctx.player,"Aiming")>=10 end)
for _,name in ipairs(professions) do
    local k=name
    add("pl_prof_"..k.."_10",function(ctx) return level(ctx.player,k)>=10 end)
end
for id,test in pairs(COMPOSITES) do
    local check=test
    add("pl_combo_"..id,function(ctx) return ctx.player~=nil and check(ctx.player) end)
end
-- Reuse these pure evaluators for silent retroactive reward audits.
legend.PartnerJournalProfessions=professions
legend.PartnerJournalLevel=level
legend.PartnerJournalComposites=COMPOSITES
print("[PartnerJournalExtension] 50 Partner medals integrated in Daily Report Journal")
