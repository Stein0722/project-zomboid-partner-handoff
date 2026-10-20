-- Partner VSGirl All-Female Zombie Bridge
--
-- VSGirl Body Extension deliberately rejects the original All-female variant.
-- This bridge keeps the Extension active and changes only zombie gender data.
-- OnZombieCreate runs once per spawned zombie, so there is no per-frame scan.

local FEMALE_OUTFIT_FLAG_OFFSET = 2147483648

local function makeZombieFemale(zombie)
    if not zombie then
        return
    end

    -- Persistent outfits store the gender in the signed high bit. Converting
    -- the ID before the outfit is dressed stops police, military, and other
    -- special-outfit zombies from changing themselves back to male.
    local outfitID = zombie:getPersistentOutfitID()
    if outfitID and outfitID > 0 then
        zombie:setPersistentOutfitID(
            outfitID - FEMALE_OUTFIT_FLAG_OFFSET,
            zombie:isPersistentOutfitInit()
        )
    end

    if not zombie:isFemale() then
        zombie:setFemaleEtc(true)
    end
end

Events.OnZombieCreate.Add(makeZombieFemale)

print("[PartnerVSGirlAllFemaleBridge] All-female zombie bridge loaded")

