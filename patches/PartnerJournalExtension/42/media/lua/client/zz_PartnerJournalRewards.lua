-- Partner Journal rewards v0.4: single-player B42.21.
-- Only our Partner-owned badges receive rewards. Original Journal medals are records only.
-- Retroactive checks do not play dozens of achievement sounds on first install.
-- Each claim is durable in ModData, and earlier v0.3 rewards are migrated to avoid double pay.
require "PartnerLegend/Core"
pcall(require,"dSAG/dSAG_Medals")
local L=PartnerLegend
local R={}
PartnerJournalRewards=R
local NEW_KEY="PartnerJournalRewardV4"
local OLD_KEY="PartnerJournalRewardV3"
local payout={
    pl_days_7=300,pl_days_30=1500,pl_days_100=5000,
    pl_days_365=15000,pl_days_1000=30000,
    pl_kill_10000=2000,pl_kill_50000=4000,
    pl_kill_500000=10000,pl_kill_1000000=15000,
    pl_aim_10=300,pl_aim_15=700,pl_aim_20=1500,
    title_100=100,title_1000=400,title_5000=700,title_10000=0,
    title_25000=2000,title_50000=0,title_75000=2500,
    title_100000=5000,title_150000=4000,title_250000=7500,
    title_500000=0,title_1000000=0,
    pl_combo_melee=3000,pl_combo_ranged=3000,pl_combo_self=2500,
    pl_combo_engineer=2500,pl_combo_undying=4000,pl_combo_armory=3000,
}
local profPrice={Cooking=700,Woodwork=700,Electricity=700,Mechanics=700,
    Doctor=700,Tailoring=700,Farming=700,Fishing=700,Trapping=700,
    PlantScavenging=700,Reloading=1000,Maintenance=1000,
    Fitness=1000,Strength=1000}
local professions={
    Cooking="요리의 달인",Woodwork="목공의 달인",Electricity="전기의 달인",
    Mechanics="정비의 달인",Doctor="응급처치의 달인",Tailoring="재봉의 달인",
    Farming="농사의 달인",Fishing="낚시의 달인",Trapping="덫의 달인",
    PlantScavenging="채집의 달인",Reloading="재장전의 달인",
    Maintenance="무기 관리의 달인",Fitness="지구력의 달인",Strength="근력의 달인",
}
local compositeName={melee="수라의 경지",ranged="탄도의 지배자",
    self="자급자족의 달인",engineer="종말의 기술자",
    undying="죽음을 거부한 자",armory="탄약의 연금술사"}
for id,value in pairs(profPrice) do payout["pl_prof_"..id.."_10"]=value end
for _,perk in ipairs(L.MELEE_PERKS) do
    for _,rank in ipairs({10,15,20}) do
        payout["pl_skill_"..perk[1].."_"..rank]=rank==10 and 300 or rank==15 and 700 or 1500
    end
end
local aliases={
    pl_days_7={"week1"},pl_days_30={"month1"},pl_days_365={"year1"},
    pl_days_1000={"days1000"},pl_kill_10000={"kills10k"},
    title_100={"kills100"},title_1000={"kills1k"},
    title_100000={"kills100k"},pl_kill_500000={"title_500000"},
    pl_kill_1000000={"title_1000000"},
}
-- All item rewards are ALREADY defined by installed mods. No new items or recipes.
-- The sealed cases will unpack via the originating mods' existing recipes.
local prizes={
    pl_days_365={{"Base.PartnerLegendaryDrawToken",1}},
    pl_days_1000={{"LK.LegendaryDaishoCaseSealed",1}},
    pl_kill_50000={{"LTW.LegendaryTacticalKnifeCaseSealed",1}},
    title_100000={{"LTW.LegendaryTacticalSwordCaseSealed",1}},
    title_250000={{"Base.PartnerLegendaryDrawToken",1}},
    pl_kill_500000={{"Base.PartnerLegendaryDrawToken",1}},
    pl_kill_1000000={{"LK.LegendaryDaishoCaseSealed",1},{"Base.PartnerLegendaryDrawToken",1}},
}
local PROTECTED_OLD_SPECIAL={pl_days_365="year1",pl_days_1000="days1000"}
local function player() return getSpecificPlayer and getSpecificPlayer(0) or nil end
local function getStore(p)
    if not p then return nil end
    local md=p:getModData()
    if type(md[NEW_KEY])~="table" then
        md[NEW_KEY]={claimed={},items={},migrated=false,firstAudit=false}
    end
    local d=md[NEW_KEY]
    d.claimed=d.claimed or {};d.items=d.items or {}
    if not d.migrated then
        local old=md[OLD_KEY]
        if type(old)=="table" then
            for key in pairs(payout) do
                if type(old.claimed)=="table" then
                    if old.claimed[key] then d.claimed[key]=true end
                    for _,alias in ipairs(aliases[key] or {}) do
                        if old.claimed[alias] then d.claimed[key]=true end
                    end
                end
            end
            if type(old.special)=="table" then
                -- Preserve previously issued draw tokens, including old Journal-only keys.
                if old.special.year1 or old.special.pl_days_365 then
                    d.items["pl_days_365|Base.PartnerLegendaryDrawToken"]=1
                end
                if old.special.title_250000 then
                    d.items["title_250000|Base.PartnerLegendaryDrawToken"]=1
                end
                if old.special.title_500000 or old.special.pl_kill_500000 then
                    d.items["pl_kill_500000|Base.PartnerLegendaryDrawToken"]=1
                end
                if old.special.title_1000000 or old.special.pl_kill_1000000 then
                    d.items["pl_kill_1000000|Base.PartnerLegendaryDrawToken"]=1
                end
            end
        end
        d.migrated=true
    end
    return d
end
local function nameFor(id)
    local key="UI_dSAG_medal_"..id
    local name=L.Text(key,nil)
    if name and name~=key then return name end
    local titleNum=id:match("^title_(%d+)$")
    if titleNum then
        for _,def in ipairs(L.TITLES) do
            if tostring(def[1])==titleNum then return L.GetTitleName(def) end
        end
    end
    local prof=id:match("^pl_prof_(.+)_10$")
    if prof then return professions[prof] or id end
    local combo=id:match("^pl_combo_(.+)$")
    if combo then return compositeName[combo] or id end
    return id
end
local function money(p,amount)
    if amount<=0 then return true end
    if not MSR or not MSR.ShopData then pcall(require,"MSR_ShopData") end
    local fn=MSR and MSR.ShopData and MSR.ShopData.addCores
    if type(fn)~="function" then return false end
    local ok,result=pcall(fn,p,amount)
    return ok and result~=false
end
local function issueItems(p,id,data)
    local entries=prizes[id]
    if not entries then return end
    local inv=p:getInventory()
    local manager=getScriptManager and getScriptManager()
    if not inv or not manager then return end
    for _,entry in ipairs(entries) do
        local itemId,count=entry[1],entry[2]
        local key=id.."|"..itemId
        local issued=tonumber(data.items[key]) or 0
        if manager:FindItem(itemId) then
            for n=issued+1,count do
                local ok,item=pcall(function() return inv:AddItem(itemId) end)
                if not ok or not item then break end
                data.items[key]=n -- per-item progress saved; never double issue on retry.
            end
        end
    end
end
local function notify(id)
    if L.Celebration and L.Celebration.Enqueue then
        L.Celebration.Enqueue(id,nameFor(id))
    end
end
local function claim(p,id,announce)
    local amount=payout[id]
    if amount==nil then return false end -- This excludes ALL original Journal awards.
    local data=getStore(p);if not data then return false end
    if not data.claimed[id] then
        if not money(p,amount) then return false end
        data.claimed[id]=true
        if announce then notify(id) end
        print("[PartnerRewards] Partner achievement "..id.." cores="..tostring(amount))
    end
    issueItems(p,id,data)
    return true
end
local function audit(p,announce)
    if not p or p:isDead() then return end
    local store=getStore(p)
    if not store then return end
    local allowAnnounce=announce and store.firstAudit
    -- Native Journal achievements stay in its UI but NEVER trigger payout.
    -- Only Partner-specific IDs are processed.
    L.Check(p)
    local d=L.GetData(p)
    for id in pairs(d.medals or {}) do claim(p,"pl_"..id,allowAnnounce) end
    if L.SkillLevel(p,"Aiming")>=10 then claim(p,"pl_aim_10",allowAnnounce) end
    local kills=select(1,L.Stats(p))
    for _,def in ipairs(L.TITLES) do
        if kills>=L.Required("kills",def[1]) then
            claim(p,"title_"..tostring(def[1]),allowAnnounce)
        end
    end
    -- Profession and composite thresholds rely on established perk API, no scans.
    local journalOwned=p:getModData().dSAG_medals or {}
    for id in pairs(journalOwned) do
        if id:sub(1,8)=="pl_prof_" or id:sub(1,9)=="pl_combo_" then
            claim(p,id,allowAnnounce)
        end
    end
    if type(L.PartnerJournalLevel)=="function" then
        for key in pairs(profPrice) do
            if L.PartnerJournalLevel(p,key)>=10 then
                claim(p,"pl_prof_"..key.."_10",allowAnnounce)
            end
        end
    end
    if type(L.PartnerJournalComposites)=="table" then
        for id,check in pairs(L.PartnerJournalComposites) do
            if check(p) then claim(p,"pl_combo_"..id,allowAnnounce) end
        end
    end
    store.firstAudit=true
end
-- Avoid auditing every in-game minute (which can be a few real seconds).
-- Fresh awards are paid immediately by the event-driven realtime scanner;
-- the existing native Journal rollover wrapper still handles its own awards.
-- A slow retry audit is kept for temporarily unavailable shop/item APIs.
local attached=false
local lastAuditedPlayer=nil
local lastAuditHour=nil
local function install()
    local p=player()
    if not p then return end
    if not attached and dSAG and type(dSAG.checkMedals)=="function" then
        local previous=dSAG.checkMedals
        dSAG.checkMedals=function(character,md,record)
            local fresh=previous(character,md,record)
            if type(fresh)=="table" then
                local d=getStore(character)
                for _,id in ipairs(fresh) do
                    if payout[id]~=nil then claim(character,id,d and d.firstAudit) end
                end
            end
            return fresh
        end
        attached=true
        print("[PartnerRewards] v0.4 Partner-only payout attached")
    end
    local hour=tonumber(p:getHoursSurvived()) or 0
    if lastAuditedPlayer~=p or lastAuditHour==nil or hour<lastAuditHour
        or hour-lastAuditHour>=0.25 then  -- 15 in-game minutes
        audit(p,true)
        lastAuditedPlayer=p
        lastAuditHour=hour
    end
end
Events.OnGameStart.Add(install)
Events.EveryOneMinute.Add(install)
-- Tiered survival fatigue: highest attained Partner medal only.
local lastFatigue=nil
local function fatigueCut(p)
    local d=L.GetData(p)
    if not d then return 0 end
    local m=d.medals
    if m.days_1000 then return 0.12 end
    if m.days_365 then return 0.10 end
    if m.days_100 then return 0.07 end
    if m.days_30 then return 0.05 end
    return 0
end
local function characterStat(p,key)
    if not CharacterStat or not CharacterStat[key] then return nil,nil,nil end
    local s=p:getStats()
    if not s then return nil,nil,nil end
    local ok,val=pcall(s.get,s,CharacterStat[key])
    if not ok or type(val)~="number" then return nil,nil,nil end
    return s,CharacterStat[key],val
end
local lastLife={}
local function adjustStat(p,key,rate,mode)
    if rate<=0 then return end
    local stats,enum,now=characterStat(p,key)
    if not stats then return end
    local was=lastLife[key]
    if was then
        local delta=now-was
        local valid=(mode=="rising" and delta>0 and delta<0.05)
            or (mode=="recovering" and delta>0 and delta<0.1)
        if valid then
            local new=math.max(0,math.min(1,now-delta*rate))
            if mode=="recovering" then new=math.min(1,now+delta*rate) end
            pcall(stats.set,stats,enum,new)
            now=new
        end
    end
    lastLife[key]=now
end
Events.EveryOneMinute.Add(function()
    local p=player()
    if not p or p:isDead() then lastLife={};return end
    local fatigue=fatigueCut(p)
    -- Highest survival tier, never additive. Other Partner lifetime effects are small.
    adjustStat(p,"FATIGUE",fatigue,"rising")
    local md=p:getModData();local medals=md.dSAG_medals or {}
    if medals.pl_prof_Cooking_10 then adjustStat(p,"HUNGER",0.03,"rising") end
    if medals.pl_prof_PlantScavenging_10 then adjustStat(p,"THIRST",0.03,"rising") end
    if medals.pl_prof_Fitness_10 then adjustStat(p,"ENDURANCE",0.02,"recovering") end
    if medals.pl_combo_self then
        adjustStat(p,"HUNGER",0.02,"rising")
        adjustStat(p,"THIRST",0.02,"rising")
    end
end)
L.GetSurvivalFatigueBonus=fatigueCut
-- Melee stamina cost reimbursement after actual swing, not every frame.
local pending=nil
local registered=false
local function settle(attacker)
    if not pending or pending.player~=attacker then return end
    local now=getTimestampMs and getTimestampMs() or 0
    if now-pending.at<250 then return end
    local request=pending;pending=nil
    if registered and Events.OnPlayerUpdate then Events.OnPlayerUpdate.Remove(settle);registered=false end
    if attacker:isDead() then return end
    local stats,enum,current=characterStat(attacker,"ENDURANCE")
    if not stats then return end
    local spent=request.before-current
    if spent>0 and spent<0.25 then
        pcall(stats.set,stats,enum,math.min(1,current+spent*request.rate))
    end
end
if Events.OnWeaponSwing and Events.OnPlayerUpdate and Events.OnPlayerUpdate.Remove then
    Events.OnWeaponSwing.Add(function(attacker,weapon)
        if attacker~=player() or not weapon or attacker:isDead() or pending then return end
        local ok,isRanged=pcall(weapon.isRanged,weapon)
        if not ok or isRanged then return end
        local kills=select(1,L.Stats(attacker))
        local rate=kills>=10000 and 0.10 or kills>=1000 and 0.05 or 0
        if rate==0 then return end
        local _,_,before=characterStat(attacker,"ENDURANCE")
        if not before then return end
        pending={player=attacker,at=getTimestampMs and getTimestampMs() or 0,
            before=before,rate=rate}
        Events.OnPlayerUpdate.Add(settle)
        registered=true
    end)
end
-- 100 kills +3% melee damage, plus Strength10 +2% (both capped by original L.Settings).
if not L._PartnerV4DamageWrapped then
    L._PartnerV4DamageWrapped=true
    local previous=L.DamageBonus
    L.DamageBonus=function(p,ranged,perkId)
        local amount=previous(p,ranged,perkId)
        if not p or ranged then return amount end
        local k=select(1,L.Stats(p))
        if k>=100 then amount=amount+3 end
        if (p:getModData().dSAG_medals or {}).pl_prof_Strength_10 then amount=amount+2 end
        return math.min(L.Settings.damageCap or 20,amount)
    end
end
L.PartnerRewardCore=payout
L.PartnerRewardClaim=claim
L.PartnerRewardAudit=audit
L.PartnerRewardName=nameFor
L.PartnerRewardVersion=NEW_KEY
print("[PartnerRewards] v0.4 loaded; original Journal medals are read-only")
