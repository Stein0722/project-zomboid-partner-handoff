-- Partner Mastery Extension v0.3.0, integrated combat specializations.
-- 0.01 percent point = one basis point. Vanilla defaults preserve agreed balance.
PartnerMasteryExtensionCombat = PartnerMasteryExtensionCombat or {}
local P = PartnerMasteryExtensionCombat
P.Config = P.Config or {
    enabled = true,
    indomitable = true,
    shockwave = true,
    overpenetration = true,
    testMode = false,
    forceTier20 = false,
    indomitable15BP = 25,
    indomitable20BP = 100,
    shockwave15BP = 100,
    shockwave20BP = 500,
    shockwaveRadius15Tenths = 15,
    shockwaveRadius20Tenths = 30,
    shockwaveDamage15Pct = 15,
    shockwaveDamage20Pct = 30,
    penChance20BP = {
        AntiMateriel = 1000,
        BoltAction = 700,
        DMR = 400,
        Assault = 200,
        MachineGun = 100,
        HandgunSMG = 100,
    },
    penExtraScale15 = 100,
    penExtraScale20 = 100,
    maxTotalHitCount = 24,
    maxExtraPenetrations = 20,
    maxSplashVictims = 16,
    maxSplashCandidates = 256,
    testAnnouncements = false,
    diagnostics = false,
    diagnosticLimit = 6,
    allowEstimatedFallbackDamage = true,
    debug = false,
}
-- Only explicitly whitelisted keys can be changed by ModOptions.
function P.ApplySettings(settings)
    if type(settings)~='table' then return end
    local c=P.Config
    for _,key in ipairs({'enabled','indomitable','shockwave','overpenetration'}) do
        if settings[key]~=nil then c[key]=settings[key]==true or settings[key]==1 end
    end
    local numeric={
        indomitable15BP={0,10000},indomitable20BP={0,10000},
        shockwave15BP={0,10000},shockwave20BP={0,10000},
        shockwaveRadius15Tenths={0,50},shockwaveRadius20Tenths={0,50},
        shockwaveDamage15Pct={0,100},shockwaveDamage20Pct={0,100},
        penExtraScale15={0,200},penExtraScale20={0,200},
    }
    for key,range in pairs(numeric) do
        local v=tonumber(settings[key])
        if v then c[key]=math.max(range[1],math.min(range[2],math.floor(v+0.5))) end
    end
    if type(settings.penChance20BP)=='table' then
        for kind,old in pairs(c.penChance20BP) do
            local v=tonumber(settings.penChance20BP[kind])
            if v then c.penChance20BP[kind]=math.max(0,math.min(10000,math.floor(v+0.5))) end
        end
    end
end
