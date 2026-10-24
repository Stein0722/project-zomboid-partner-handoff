-- Partner realtime achievements v0.4.6 (Build 42.21 / single player).
-- This is NOT the native Daily Report Journal rollover check.
-- Hot loop: timestamp gate only, then 1-second integer kill poll.
-- Only scan pending milestones, and only the category that may have changed.
-- No zombie iteration, inventory scan, projectile event, or additional timers.
require "PartnerLegend/Core"
pcall(require, "dSAG/dSAG_Medals")
local L=PartnerLegend
local J=dSAG
if not L or not J or type(J.medalDefs)~="table" then
    print("[PartnerLiveAchievements] missing prerequisites; disabled")
    return
end
if J._PartnerLiveAchievementsV046 then return end
J._PartnerLiveAchievementsV046=true

local QUICK_MS=1000   -- actual milliseconds, not in-game minutes
local SKILL_MS=5000   -- catch extended Beyond Ten levels without native LevelPerk
local busy=false
local initialized=false
local attachedPlayer=nil
local pending=nil
local previousKills=nil
local previousDay=nil
local nextKillTarget=nil
local previousRequirement=nil
local nextQuick=0
local nextSkills=0

local function currentPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end
local function dayOf(p)
    return math.floor(math.max(0,tonumber(p:getHoursSurvived()) or 0)/24)+1
end
local function titleName(id)
    if L.PartnerRewardName then return L.PartnerRewardName(id) end
    local key="UI_dSAG_medal_"..id
    return L.Text and L.Text(key,id) or id
end
local function categorize(id)
    if id:sub(1,8)=="pl_days_" then return "days" end
    if id:sub(1,8)=="pl_kill_" then return "kills" end
    if id=="pl_combo_melee" or id=="pl_combo_ranged" then return "killSkill" end
    if id=="pl_combo_undying" then return "daySkill" end
    return "skills"
end
local function matches(kind, mode)
    return mode=="all" or
        (mode=="kill" and (kind=="kills" or kind=="killSkill")) or
        (mode=="day" and (kind=="days" or kind=="daySkill")) or
        (mode=="skill" and (kind=="skills" or kind=="killSkill" or kind=="daySkill"))
end
local function setupPending(p)
    local md=p:getModData()
    if not md then return false end
    if type(md.dSAG_medals)~="table" then md.dSAG_medals={} end
    local earned=md.dSAG_medals
    pending={}
    for _,def in ipairs(J.medalDefs) do
        local id=def.id
        if type(id)=="string" and id:sub(1,3)=="pl_"
            and type(def.check)=="function" and not earned[id] then
            pending[#pending+1]={id=id,kind=categorize(id),check=def.check}
        end
    end
    attachedPlayer=p
    return true
end

-- Compute the next threshold ONLY on initialization/threshold crossing/5s wake.
-- Most kills never reach a threshold; they do not require any medal evaluation.
local function nextThreshold(kills)
    local nextValue=nil
    local function consider(target)
        local amount=tonumber(target)
        if amount and amount>kills and (not nextValue or amount<nextValue) then
            nextValue=amount
        end
    end
    for _,def in ipairs(L.TITLES or {}) do
        consider(L.Required("kills",def[1]))
    end
    for _,m in ipairs(L.MEDALS or {}) do
        if m.kind=="kills" then consider(L.Required("kills",m.target)) end
    end
    -- Composite Partner badges have literal thresholds rather than L.Required.
    consider(100000)
    consider(250000)
    return nextValue
end
local function scan(p,mode,announce)
    if busy or not p or p:isDead() then return end
    busy=true
    local md=p:getModData()
    if not md then busy=false;return end
    if not pending or attachedPlayer~=p then
        if not setupPending(p) then busy=false;return end
    end
    local earned=md.dSAG_medals
    local day=dayOf(p)
    local ctx={player=p,record={day=day},day=day,modData=md,md=md}
    local remaining={}
    local fresh={}
    for _,entry in ipairs(pending) do
        local id=entry.id
        if not earned[id] then
            if matches(entry.kind,mode) then
                local ok,passed=pcall(entry.check,ctx)
                if ok and passed==true then
                    earned[id]=day
                    fresh[#fresh+1]=id
                else
                    remaining[#remaining+1]=entry
                end
            else
                remaining[#remaining+1]=entry
            end
        end
    end
    pending=remaining
    -- Audit only on startup, genuinely fresh Partner medals or an actual
    -- title-kill/day threshold. Repeated ordinary kills never audit payouts.
    if mode=="all" or mode=="kill" or mode=="day" or #fresh>0 then
        if type(L.PartnerRewardAudit)=="function" then
            L.PartnerRewardAudit(p,announce and initialized)
        elseif announce and initialized and L.Celebration and L.Celebration.Enqueue then
            -- Only freshly earned medals, never every achievement earned today.
            for _,id in ipairs(fresh) do
                L.Celebration.Enqueue(id,titleName(id))
            end
        end
    end
    initialized=true
    busy=false
end
local function reset(p)
    initialized=false
    attachedPlayer=nil
    pending=nil
    previousKills=nil
    previousDay=nil
    nextKillTarget=nil
    previousRequirement=nil
    nextQuick=0
    nextSkills=0
    if not p or p:isDead() then return end
    previousKills=tonumber(p:getZombieKills()) or 0
    previousDay=dayOf(p)
    previousRequirement=L.Settings and L.Settings.killRequirement or 100
    scan(p,"all",false) -- retroactive achievements stay silent
    nextKillTarget=nextThreshold(previousKills)
end
local function onPlayerUpdate(p)
    -- Keep hot path tiny: one timestamp call, one comparison per player update.
    if not p or p~=currentPlayer() then return end
    local ms=getTimestampMs and getTimestampMs() or 0
    if ms<nextQuick then return end
    nextQuick=ms+QUICK_MS
    if p:isDead() then return end
    if p~=attachedPlayer then reset(p) end
    local kills=tonumber(p:getZombieKills()) or 0
    if previousKills==nil then previousKills=kills end
    if kills<previousKills or (nextKillTarget and kills>=nextKillTarget) then
        scan(p,"kill",true)
        nextKillTarget=nextThreshold(kills)
    end
    previousKills=kills
    if ms>=nextSkills then
        nextSkills=ms+SKILL_MS
        local day=dayOf(p)
        if day~=previousDay then
            previousDay=day
            scan(p,"day",true)
        end
        -- Requirement slider changes must not postpone threshold unlocks.
        local requirement=L.Settings and L.Settings.killRequirement or 100
        if requirement~=previousRequirement then
            previousRequirement=requirement
            scan(p,"kill",true)
        end
        nextKillTarget=nextThreshold(kills)
        -- Pending skill medals only; never native Daily Journal definitions.
        if pending and #pending>0 then scan(p,"skill",true) end
    end
end
local function onLevel(p)
    if p~=currentPlayer() or p:isDead() then return end
    if p~=attachedPlayer then reset(p) end
    scan(p,"skill",true)
end
Events.OnGameStart.Add(function() reset(currentPlayer()) end)
if Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(onPlayerUpdate) end
if Events.LevelPerk then Events.LevelPerk.Add(onLevel) end
if Events.OnPlayerDeath then
    Events.OnPlayerDeath.Add(function(p)
        if p==currentPlayer() then
            attachedPlayer=nil
            pending=nil
            initialized=false
            previousKills=nil
            nextKillTarget=nil
        end
    end)
end
print("[PartnerLiveAchievements] v0.4.6: 1s kill gate, 5s pending skill check, native daily intact")
