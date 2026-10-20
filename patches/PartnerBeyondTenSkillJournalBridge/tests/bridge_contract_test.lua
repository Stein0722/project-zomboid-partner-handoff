local bridgePath = assert(arg[1], "bridge path required")

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local perks = {}
local function perk(id)
    local value = { id = id }
    function value:getId() return self.id end
    perks[id] = value
    return value
end

perk("Carpentry")
perk("Fitness")

BeyondTen = {
    VERSION = "1.3.4-test",
    API_VERSION = 1,
    NATIVE_MAX_LEVEL = 10,
    MAX_LEVEL = 15,
}

function BeyondTen.IsFinite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

function BeyondTen.Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function BeyondTen.ResolvePerk(id) return perks[id] end
function BeyondTen.IsTrainablePerk(value) return value ~= nil end
function BeyondTen.GetTotalMasteryCost(_perk, _level) return 500 end
function BeyondTen.GetNativeCapXP(_perk) return 1000 end
function BeyondTen.GetReservoirXP(_perk) return 900 end
function BeyondTen.GetNativeLevel(player, value) return player.native[value:getId()] or 0 end
function BeyondTen.GetStoredXP(player, value) return player.mastery[value:getId()] or 0 end
function BeyondTen.GetEffectiveLevel(player, value)
    local native = BeyondTen.GetNativeLevel(player, value)
    if native < 10 then return native end
    return math.min(15, 10 + math.floor(BeyondTen.GetStoredXP(player, value) / 100))
end
function BeyondTen.ExportXP(player)
    local result = {}
    for id, value in pairs(player.mastery) do result[id] = value end
    return result
end
function BeyondTen.ImportXP(player, values, _replace)
    for id, value in pairs(values) do
        if perks[id] then player.mastery[id] = BeyondTen.Clamp(value, 0, 500) end
    end
end

local recoveryFraction = 1
local skipPhysical = false
local serverMode = false
local syncCount = 0

SkillJournal = {}
function SkillJournal.getItemData(item)
    item.modData.SkillJournal = item.modData.SkillJournal or {}
    return item.modData.SkillJournal
end
function SkillJournal.skipPhysicalEnabled() return skipPhysical end
function SkillJournal.isPhysicalPerk(id) return id == "Fitness" end
function SkillJournal.recoveryFraction() return recoveryFraction end
function SkillJournal.targetXP(_player, item, perkID)
    return (SkillJournal.getItemData(item).xp or {})[perkID] or 0
end
function SkillJournal.hasClaimed(player, _item, _hours) return player.claimed == true end
function SkillJournal.markClaimed(player, _item, _hours) player.claimed = true end
function SkillJournal.snapshot(_player, item)
    local data = SkillJournal.getItemData(item)
    data.xp = data.xp or { Carpentry = 1000 }
    data.effort = data.effort or { Carpentry = 1000 }
    data.entryID = data.entryID or "entry-1"
    return data
end
function SkillJournal.restore(player, _item, _hours)
    if player.claimed then return { skills = {}, recipes = {}, claimed = true } end
    if player.basePays then
        if player.restoreToReservoir then
            player.native.Carpentry = 9
            player.raw.Carpentry = 900
        end
        player.claimed = true
        return { skills = {}, recipes = {}, xpAwarded = true }
    end
    return { skills = {}, recipes = {} }
end
function SkillJournal.hasAnythingToRecover(_player, _item) return false end

function isServer() return serverMode end
BeyondTenServer = {}
function BeyondTenServer.SendPerkSync(_player, _perk, _oldLevel, _newLevel)
    syncCount = syncCount + 1
end

local originalRequire = require
require = function(_name) return true end
dofile(bridgePath)
require = originalRequire

local item = { modData = {} }
local writer = {
    native = { Carpentry = 10, Fitness = 10 },
    mastery = { Carpentry = 200, Fitness = 150 },
    claimed = false,
}

skipPhysical = true
local data = SkillJournal.snapshot(writer, item)
assertEqual(data.PartnerBeyondTenSkillJournalBridge.xp.Carpentry, 200, "records mastery")
assertEqual(data.PartnerBeyondTenSkillJournalBridge.xp.Fitness, nil, "skips physical mastery")

writer.mastery.Carpentry = 100
data = SkillJournal.snapshot(writer, item)
assertEqual(data.PartnerBeyondTenSkillJournalBridge.xp.Carpentry, 200, "rewrite keeps higher page value")

skipPhysical = false
recoveryFraction = 0.5
local reader = { native = { Carpentry = 10 }, mastery = { Carpentry = 50 }, claimed = false }
local savedNext = next
next = nil
local result = SkillJournal.restore(reader, item, 0.25)
next = savedNext
assertEqual(reader.mastery.Carpentry, 125, "recovery fraction applies to mastery gap")
assertEqual(result.xpAwarded, true, "mastery counts as journal payout")
assertEqual(reader.claimed, true, "mastery payout spends one-life claim")

SkillJournal.restore(reader, item, 0.30)
assertEqual(reader.mastery.Carpentry, 125, "claimed page cannot pay twice")

local stronger = { native = { Carpentry = 10 }, mastery = { Carpentry = 300 }, claimed = false }
SkillJournal.restore(stronger, item, 0.10)
assertEqual(stronger.mastery.Carpentry, 300, "restore never lowers mastery")

local notReady = { native = { Carpentry = 9 }, mastery = { Carpentry = 0 }, claimed = false }
local notReadyResult = SkillJournal.restore(notReady, item, 0.10)
assertEqual(notReady.mastery.Carpentry, 0, "mastery stays behind native level-10 gate")
assertEqual(notReadyResult.xpAwarded, nil, "blocked mastery is not reported as payout")
assertEqual(notReady.claimed, false, "blocked mastery alone does not spend claim")

recoveryFraction = 1
local reservoirReader = {
    native = { Carpentry = 0 },
    mastery = { Carpentry = 0 },
    raw = { Carpentry = 0 },
    claimed = false,
    basePays = true,
    restoreToReservoir = true,
}
local xpSystem = {}
function xpSystem:getXP(value) return reservoirReader.raw[value:getId()] or 0 end
function xpSystem:setXPToLevel(value, level)
    reservoirReader.raw[value:getId()] = level >= 10 and 1000 or 900
    reservoirReader.native[value:getId()] = level
end
function reservoirReader:getXp() return xpSystem end
local reservoirResult = SkillJournal.restore(reservoirReader, item, 0.10)
assertEqual(reservoirReader.native.Carpentry, 10, "level-10 gate is repaired after reservoir transition")
assertEqual(reservoirReader.mastery.Carpentry, 200, "mastery restores after reservoir transition")
assertEqual(reservoirResult.partnerBeyondTenMastery, 1, "reservoir recovery is reported")

local previewReader = { native = { Carpentry = 10 }, mastery = { Carpentry = 0 }, claimed = false }
assertEqual(SkillJournal.hasAnythingToRecover(previewReader, item), true, "mastery-only page remains readable")

serverMode = true
local serverReader = { native = { Carpentry = 10 }, mastery = { Carpentry = 0 }, claimed = false }
SkillJournal.restore(serverReader, item, 0.10)
assertEqual(serverReader.mastery.Carpentry, 200, "server receives mastery target")
assertEqual(syncCount, 1, "server sends Beyond Ten perk sync")

print("BRIDGE_CONTRACT_TEST_OK")
