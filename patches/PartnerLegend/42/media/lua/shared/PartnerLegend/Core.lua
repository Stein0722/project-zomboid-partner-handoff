PartnerLegend = PartnerLegend or {}
local L = PartnerLegend
L.VERSION = "0.1.1"
L.DATA_KEY = "PartnerLegend_v1"
L.TITLES = {
    {100,"첫 번째 피"},{1000,"좀비 사냥꾼"},{5000,"무리의 사냥꾼"},
    {10000,"베테랑 학살자"},{25000,"군단의 악몽"},{50000,"죽음의 집행자"},
    {100000,"인간 병기"},{250000,"종말의 집행자"},{500000,"재앙의 종결자"},
    {1000000,"인류의 구원자"},{2000000,"멸절자"},{5000000,"최후의 심판자"}
}
L.MELEE_PERKS = {
    {"Axe","도끼"},{"LongBlunt","긴둔기"},{"SmallBlunt","짧은둔기"},
    {"LongBlade","장검"},{"SmallBlade","단검"},{"Spear","창"}
}
-- Each medal awards percentage points of damage, not a full multiplier.
L.MEDALS = {}
local function medal(id,name,kind,target,scope,bonus,perk,group)
    L.MEDALS[#L.MEDALS+1] = {
        id=id,name=name,kind=kind,target=target,scope=scope,bonus=bonus,perk=perk,
        group=group or kind
    }
end
medal("days_7","생존 본능","days",7,"melee",1,nil,"survival")
medal("days_30","강인한 생존자","days",30,"ranged",1,nil,"survival")
medal("days_100","백전노장","days",100,"all",2,nil,"survival")
medal("days_365","불굴의 의지","days",365,"all",3,nil,"survival")
medal("days_1000","살아있는 전설","days",1000,"all",5,nil,"survival")
for _,p in ipairs(L.MELEE_PERKS) do
    medal("skill_"..p[1].."_10",p[2].." 입문자","skill",10,"perk",1,p[1],"skill")
    medal("skill_"..p[1].."_15",p[2].." 달인","skill",15,"perk",3,p[1],"skill")
    medal("skill_"..p[1].."_20",p[2].." 극의","skill",20,"perk",5,p[1],"skill")
end
medal("aim_15","사격 전문가","skill",15,"ranged",3,"Aiming","skill")
medal("aim_20","전설의 사수","skill",20,"ranged",5,"Aiming","skill")
medal("kill_10000","좀비 학살자","kills",10000,"all",1,nil,"combat")
medal("kill_50000","죽음의 군단","kills",50000,"all",2,nil,"combat")
medal("kill_500000","재앙의 종결","kills",500000,"all",3,nil,"combat")
medal("kill_1000000","인류의 구원","kills",1000000,"none",0,nil,"combat")
L.Settings = {
    rewardEfficiency=100,damageCap=20,killRequirement=100,dayRequirement=100,
    survivalEfficiency=100,skillEfficiency=100,combatEfficiency=100,
    medalBonuses={}
}
local function clamp(n,lo,hi)
    return math.max(lo,math.min(hi,tonumber(n) or lo))
end
function L.Configure(values)
    if type(values)~="table" then return end
    local limits = {
        rewardEfficiency={0,200},damageCap={0,100},
        killRequirement={25,300},dayRequirement={25,300},
        survivalEfficiency={0,200},skillEfficiency={0,200},combatEfficiency={0,200}
    }
    for k,v in pairs(limits) do
        if values[k]~=nil then L.Settings[k]=clamp(values[k],v[1],v[2]) end
    end
    if type(values.medalBonuses)=="table" then
        for _,m in ipairs(L.MEDALS) do
            if values.medalBonuses[m.id]~=nil then
                L.Settings.medalBonuses[m.id]=clamp(values.medalBonuses[m.id],0,20)
            end
        end
    end
end
function L.GetMedalBonus(medalDef)
    if not medalDef then return 0 end
    local custom=L.Settings.medalBonuses[medalDef.id]
    if custom~=nil then return tonumber(custom) or 0 end
    return tonumber(medalDef.bonus) or 0
end
function L.GetGroupEfficiency(group)
    local key=tostring(group or "").."Efficiency"
    return clamp(L.Settings[key] or 100,0,200)/100
end
function L.Required(kind,target)
    local pct=kind=="kills" and L.Settings.killRequirement
        or kind=="days" and L.Settings.dayRequirement or 100
    return math.max(1,math.ceil(target*pct/100))
end
function L.GetData(player)
    if not player then return nil end
    local md=player:getModData()
    if type(md[L.DATA_KEY])~="table" then
        md[L.DATA_KEY]={titles={},medals={},initialized=false}
    end
    local data=md[L.DATA_KEY]
    if type(data.titles)~="table" then data.titles={} end
    if type(data.medals)~="table" then data.medals={} end
    return data
end
function L.SkillLevel(player,id)
    if not player or not Perks or not Perks.FromString then return 0 end
    local perk=Perks.FromString(id)
    if not perk or (Perks.MAX and perk==Perks.MAX) then return 0 end
    local ext=PartnerMasteryExtension
    if ext and type(ext.GetEffectiveLevel)=="function" then
        return tonumber(ext.GetEffectiveLevel(player,perk)) or 0
    end
    local bt=BeyondTen
    if bt and type(bt.GetEffectiveLevel)=="function" then
        return tonumber(bt.GetEffectiveLevel(player,perk)) or 0
    end
    return tonumber(player:getPerkLevel(perk)) or 0
end
function L.Stats(player)
    if not player then return 0,0 end
    local kills=math.max(0,math.floor(tonumber(player:getZombieKills()) or 0))
    local days=math.max(0,math.floor((tonumber(player:getHoursSurvived()) or 0)/24))
    return kills,days
end
function L.BestTitle(player)
    local d=L.GetData(player)
    if not d then return "생존자",0 end
    local latest=0
    for i=1,#L.TITLES do if d.titles[i] then latest=i end end
    if latest==0 then return "생존자",0 end
    return L.TITLES[latest][2],latest
end
function L.Check(player)
    local d=L.GetData(player)
    if not d then return 0 end
    local kills,days=L.Stats(player)
    local retro=not d.initialized
    local fresh=0
    for i,t in ipairs(L.TITLES) do
        if not d.titles[i] and kills>=L.Required("kills",t[1]) then
            d.titles[i]=true
            fresh=fresh+1
        end
    end
    local levels={}
    for _,m in ipairs(L.MEDALS) do
        if not d.medals[m.id] then
            local current=0
            if m.kind=="kills" then current=kills
            elseif m.kind=="days" then current=days
            else
                if levels[m.perk]==nil then
                    levels[m.perk]=L.SkillLevel(player,m.perk)
                end
                current=levels[m.perk]
            end
            if current>=L.Required(m.kind,m.target) then
                -- Retroactive unlocks have no known historical calendar date.
                d.medals[m.id]=retro and {legacy=true} or {day=days}
                fresh=fresh+1
            end
        end
    end
    d.initialized=true
    return retro and 0 or fresh
end
function L.DamageBonus(player,ranged,perkID)
    local d=L.GetData(player)
    if not d then return 0 end
    local sum=0
    for _,m in ipairs(L.MEDALS) do
        if d.medals[m.id] and (
            m.scope=="all" or
            (m.scope=="melee" and not ranged) or
            (m.scope=="ranged" and ranged) or
            (m.scope=="perk" and not ranged and m.perk==perkID)
        ) then
            sum=sum+L.GetMedalBonus(m)*L.GetGroupEfficiency(m.group)
        end
    end
    return math.min(L.Settings.damageCap,sum*L.Settings.rewardEfficiency/100)
end
