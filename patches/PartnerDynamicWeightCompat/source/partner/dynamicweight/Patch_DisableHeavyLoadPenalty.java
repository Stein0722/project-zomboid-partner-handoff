package partner.dynamicweight;

import me.zed_0xff.zombie_buddy.Patch;
import zombie.characters.Moodles.Moodle;
import zombie.scripting.objects.MoodleType;

/**
 * The mod intentionally makes carried weight almost irrelevant.  Keep the
 * Heavy Load moodle from retaining a stale server-side level after large
 * inventories are synchronized, which otherwise multiplies endurance drain.
 */
@Patch(className = "zombie.characters.Moodles.Moodle", methodName = "getLevel")
public final class Patch_DisableHeavyLoadPenalty {
    private Patch_DisableHeavyLoadPenalty() {
    }

    @Patch.OnExit
    public static void exit(
            @Patch.This Moodle moodle,
            @Patch.Return(readOnly = false) int level) {
        if (moodle.getMoodleType() == MoodleType.HEAVY_LOAD) {
            level = 0;
        }
    }
}
