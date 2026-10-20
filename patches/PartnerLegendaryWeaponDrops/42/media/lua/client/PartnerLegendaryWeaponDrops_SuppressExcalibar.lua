-- Disable Excalibar's built-in fixed placements and common attached-zombie
-- sources when the Partner extreme-rare container system is selected.

local function settings()
    return SandboxVars and SandboxVars.PartnerLegendaryDrops
end

local function suppressExcalibarSources()
    local cfg = settings()
    if not cfg or cfg.SuppressOriginalSources == false then return end

    if SandboxVars and SandboxVars.P4Excalibar then
        SandboxVars.P4Excalibar.WorldSpawn = false
        SandboxVars.P4Excalibar.SpawnChanceMultiplier = 0
    end

    if AttachedWeaponDefinitions then
        if AttachedWeaponDefinitions.ExcaliparBack then
            AttachedWeaponDefinitions.ExcaliparBack.chance = 0
        end
        if AttachedWeaponDefinitions.ExcaliparInStomach then
            AttachedWeaponDefinitions.ExcaliparInStomach.chance = 0
        end
    end

    if P4ExcalibarSpawn then
        if P4ExcalibarSpawn.options and P4ExcalibarSpawn.options.EasyToFind then
            P4ExcalibarSpawn.options.EasyToFind.value = false
        end
        P4ExcalibarSpawn.pendingSpawns = {}
        if P4ExcalibarSpawn.updateEvent then
            P4ExcalibarSpawn.updateEvent()
        end
    end

    print("[PartnerLegendaryDrops] Original Excalibar spawn sources suppressed.")
end

Events.OnGameStart.Add(suppressExcalibarSources)
Events.OnLoad.Add(suppressExcalibarSources)

