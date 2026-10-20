require "BeyondTen/Shared"
require "SkillJournal_Core"

PartnerBeyondTenSkillJournalBridge = PartnerBeyondTenSkillJournalBridge or {}
local Bridge = PartnerBeyondTenSkillJournalBridge
local BT = BeyondTen

Bridge.VERSION = "1.0.1"
Bridge.DATA_KEY = "PartnerBeyondTenSkillJournalBridge"
Bridge.SCHEMA_VERSION = 1

local EPSILON = 0.0001

local function log(message)
    print("[PartnerBeyondTenSkillJournalBridge] " .. tostring(message))
end

local function finiteNumber(value)
    value = tonumber(value)
    if value == nil or not BT.IsFinite(value) then return nil end
    return value
end

local function allowedPerk(perkID)
    if type(perkID) ~= "string" then return nil end
    local perk = BT.ResolvePerk(perkID)
    if not perk or not BT.IsTrainablePerk(perk) then return nil end
    if SkillJournal.skipPhysicalEnabled()
        and type(SkillJournal.isPhysicalPerk) == "function"
        and SkillJournal.isPhysicalPerk(perkID) then
        return nil
    end
    return perk
end

local function sanitizedXP(perk, value)
    value = finiteNumber(value)
    if value == nil or value <= 0 then return nil end
    local maximum = BT.GetTotalMasteryCost(perk, BT.MAX_LEVEL)
    return BT.Clamp(value, 0, maximum)
end

local function bridgeData(item)
    if not item or type(SkillJournal.getItemData) ~= "function" then return nil end
    local journalData = SkillJournal.getItemData(item)
    local data = journalData and journalData[Bridge.DATA_KEY]
    if type(data) ~= "table" or tonumber(data.schema) ~= Bridge.SCHEMA_VERSION then return nil end
    if type(data.xp) ~= "table" then return nil end
    return data
end

function Bridge.RecordMastery(player, item, journalData)
    if not player or not item or type(journalData) ~= "table" then return 0 end

    local previous = journalData[Bridge.DATA_KEY]
    local previousXP = type(previous) == "table" and previous.xp or nil
    local exported = BT.ExportXP(player)
    local recorded = {}
    local count = 0

    local function keepHighest(perkID, rawValue)
        local perk = allowedPerk(perkID)
        local value = perk and sanitizedXP(perk, rawValue) or nil
        if value and value > (recorded[perkID] or 0) then
            if recorded[perkID] == nil then count = count + 1 end
            recorded[perkID] = value
        end
    end

    if type(previousXP) == "table" then
        for perkID, value in pairs(previousXP) do keepHighest(perkID, value) end
    end
    if type(exported) == "table" then
        for perkID, value in pairs(exported) do keepHighest(perkID, value) end
    end

    journalData[Bridge.DATA_KEY] = {
        schema = Bridge.SCHEMA_VERSION,
        bridgeVersion = Bridge.VERSION,
        beyondTenVersion = tostring(BT.VERSION or "unknown"),
        xp = recorded,
    }

    log("recorded mastery XP for " .. tostring(count) .. " skill(s)")
    return count
end

local function syncServerPerk(player, perk, oldLevel, newLevel)
    if type(isServer) ~= "function" or not isServer() then return end
    if BeyondTenServer and type(BeyondTenServer.SendPerkSync) == "function" then
        BeyondTenServer.SendPerkSync(player, perk, oldLevel, newLevel)
    end
end

local function isAuthority()
    return type(isClient) ~= "function" or isClient() ~= true
end

-- Work out which vanilla skills this read is intended to carry across level 10.
-- Beyond Ten temporarily parks their raw XP at the level-9 total, so checking the
-- displayed native level only after Skill Journal finishes can miss that crossing.
function Bridge.PlanNativeGates(player, item, claimedBefore)
    local planned = {}
    if not player or not item or claimedBefore or not isAuthority() then return planned end

    local data = bridgeData(item)
    if not data or type(SkillJournal.targetXP) ~= "function"
        or type(BT.GetNativeCapXP) ~= "function" then return planned end

    local fraction = tonumber(SkillJournal.recoveryFraction()) or 0
    fraction = BT.Clamp(fraction, 0, 1)
    if fraction <= 0 then return planned end

    local xpOK, xpSystem = pcall(function() return player:getXp() end)
    if not xpOK or not xpSystem then return planned end

    for perkID, rawSaved in pairs(data.xp) do
        local perk = allowedPerk(perkID)
        local saved = perk and sanitizedXP(perk, rawSaved) or nil
        if saved then
            local targetOK, target = pcall(SkillJournal.targetXP, player, item, perkID)
            local currentOK, current = pcall(function() return xpSystem:getXP(perk) end)
            local cap = finiteNumber(BT.GetNativeCapXP(perk))
            target = targetOK and finiteNumber(target) or nil
            current = currentOK and finiteNumber(current) or nil
            if target and current and cap and cap > 0 then
                local intended = current + math.max(0, target - current) * fraction
                if intended >= cap - EPSILON then planned[perkID] = true end
            end
        end
    end
    return planned
end

local function nativeGateReady(player, perk, planned)
    if BT.GetNativeLevel(player, perk) >= BT.NATIVE_MAX_LEVEL then return true end
    if not planned or not isAuthority() then return false end

    -- Only repair a gate that actually reached Beyond Ten's level-9 reservoir.
    -- This cannot promote an ordinary partially restored skill from below level 9.
    local xpOK, xpSystem = pcall(function() return player:getXp() end)
    if not xpOK or not xpSystem or type(BT.GetReservoirXP) ~= "function" then return false end
    local rawOK, rawXP = pcall(function() return xpSystem:getXP(perk) end)
    local reservoir = finiteNumber(BT.GetReservoirXP(perk))
    rawXP = rawOK and finiteNumber(rawXP) or nil
    if not rawXP or not reservoir or rawXP < reservoir - EPSILON then return false end

    local setOK = pcall(function()
        xpSystem:setXPToLevel(perk, BT.NATIVE_MAX_LEVEL)
    end)
    return setOK
end

function Bridge.RestoreMastery(player, item, reportedHours, result, claimedBefore, nativeGatePlan)
    if not player or not item or claimedBefore then return 0 end

    local data = bridgeData(item)
    if not data then return 0 end

    local fraction = tonumber(SkillJournal.recoveryFraction()) or 0
    fraction = BT.Clamp(fraction, 0, 1)
    if fraction <= 0 then return 0 end

    local targets = {}
    local beforeXP = {}
    local oldLevels = {}
    local hasTargets = false

    for perkID, rawSaved in pairs(data.xp) do
        local perk = allowedPerk(perkID)
        local saved = perk and sanitizedXP(perk, rawSaved) or nil

        -- Mastery must stay behind the native level-10 gate. The base Skill Journal
        -- restore runs first, so a full recovery can open this gate in the same read.
        local plannedGate = nativeGatePlan and nativeGatePlan[perkID] == true
        if saved and nativeGateReady(player, perk, plannedGate) then
            local current = math.max(0, finiteNumber(BT.GetStoredXP(player, perk)) or 0)
            if saved > current + EPSILON then
                local target = current + ((saved - current) * fraction)
                target = BT.Clamp(target, current, saved)
                if target > current + EPSILON then
                    targets[perkID] = target
                    beforeXP[perkID] = current
                    oldLevels[perkID] = BT.GetEffectiveLevel(player, perk)
                    hasTargets = true
                end
            end
        end
    end

    if not hasTargets then return 0 end
    BT.ImportXP(player, targets, false)

    local restored = 0
    for perkID, _target in pairs(targets) do
        local perk = BT.ResolvePerk(perkID)
        local actual = perk and (finiteNumber(BT.GetStoredXP(player, perk)) or 0) or 0
        if perk and actual > (beforeXP[perkID] or 0) + EPSILON then
            restored = restored + 1
            syncServerPerk(player, perk, oldLevels[perkID], BT.GetEffectiveLevel(player, perk))
        end
    end

    if restored > 0 then
        result = result or {}
        result.xpAwarded = true
        result.partnerBeyondTenMastery = restored
        SkillJournal.markClaimed(player, item, reportedHours)
        log("restored mastery XP for " .. tostring(restored) .. " skill(s)")
    end

    return restored
end

function Bridge.HasMasteryToRecover(player, item)
    if not player or not item then return false end
    if SkillJournal.hasClaimed(player, item) then return false end

    local fraction = tonumber(SkillJournal.recoveryFraction()) or 0
    if fraction <= 0 then return false end

    local data = bridgeData(item)
    if not data then return false end

    for perkID, rawSaved in pairs(data.xp) do
        local perk = allowedPerk(perkID)
        local saved = perk and sanitizedXP(perk, rawSaved) or nil
        if saved and BT.GetNativeLevel(player, perk) >= BT.NATIVE_MAX_LEVEL
            and saved > BT.GetStoredXP(player, perk) + EPSILON then
            return true
        end
    end
    return false
end

local function install()
    if Bridge._installed then return end
    if type(BT) ~= "table" or tonumber(BT.API_VERSION) ~= 1 then
        log("unsupported Beyond Ten API; bridge not installed")
        return
    end
    if type(SkillJournal) ~= "table"
        or type(SkillJournal.snapshot) ~= "function"
        or type(SkillJournal.restore) ~= "function"
        or type(SkillJournal.hasAnythingToRecover) ~= "function" then
        log("Skill Journal API is unavailable; bridge not installed")
        return
    end

    local originalSnapshot = SkillJournal.snapshot
    local originalRestore = SkillJournal.restore
    local originalHasAnythingToRecover = SkillJournal.hasAnythingToRecover

    function SkillJournal.snapshot(player, item)
        local data = originalSnapshot(player, item)
        local ok, err = pcall(Bridge.RecordMastery, player, item, data)
        if not ok then log("record failed; base journal entry was kept -- " .. tostring(err)) end
        return data
    end

    function SkillJournal.restore(player, item, reportedHours)
        local claimedBefore = false
        local claimOK, claimValue = pcall(SkillJournal.hasClaimed, player, item, reportedHours)
        if claimOK then claimedBefore = claimValue == true end

        local nativeGatePlan = Bridge.PlanNativeGates(player, item, claimedBefore)

        local result = originalRestore(player, item, reportedHours)
        result = result or { skills = {}, kills = nil, recipes = {} }

        local ok, err = pcall(Bridge.RestoreMastery,
            player, item, reportedHours, result, claimedBefore, nativeGatePlan)
        if not ok then log("restore failed; base journal restore was kept -- " .. tostring(err)) end
        return result
    end

    function SkillJournal.hasAnythingToRecover(player, item)
        if originalHasAnythingToRecover(player, item) then return true end
        local ok, value = pcall(Bridge.HasMasteryToRecover, player, item)
        if not ok then
            log("recovery preview failed -- " .. tostring(value))
            return false
        end
        return value == true
    end

    Bridge._installed = true
    log("installed v" .. Bridge.VERSION .. " for Beyond Ten " .. tostring(BT.VERSION or "unknown"))
end

install()

