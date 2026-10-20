package partner.dynamicweight;

import me.zed_0xff.zombie_buddy.Patch;

/** Scales the final weight of items worn or held by the character. */
@Patch(className = "zombie.inventory.InventoryItem", methodName = "getEquippedWeight")
public final class Patch_EquippedWeight {
    private static final float MULTIPLIER = 0.01f;

    private Patch_EquippedWeight() {
    }

    @Patch.OnExit
    public static void exit(@Patch.Return(readOnly = false) float weight) {
        if (weight > 0.0f) {
            weight *= MULTIPLIER;
        }
    }
}
