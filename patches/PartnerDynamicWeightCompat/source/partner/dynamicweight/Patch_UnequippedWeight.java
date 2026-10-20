package partner.dynamicweight;

import me.zed_0xff.zombie_buddy.Patch;

/** Scales the final weight used for ordinary inventory and container checks. */
@Patch(className = "zombie.inventory.InventoryItem", methodName = "getUnequippedWeight")
public final class Patch_UnequippedWeight {
    private static final float MULTIPLIER = 0.01f;

    private Patch_UnequippedWeight() {
    }

    @Patch.OnExit
    public static void exit(@Patch.Return(readOnly = false) float weight) {
        if (weight > 0.0f) {
            weight *= MULTIPLIER;
        }
    }
}
