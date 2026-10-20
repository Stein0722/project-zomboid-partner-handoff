package partner.dynamicweight;

import me.zed_0xff.zombie_buddy.Patch;

/** Scales the final weight of items attached to the character's hotbar. */
@Patch(className = "zombie.inventory.InventoryItem", methodName = "getHotbarEquippedWeight")
public final class Patch_HotbarEquippedWeight {
    private static final float MULTIPLIER = 0.01f;

    private Patch_HotbarEquippedWeight() {
    }

    @Patch.OnExit
    public static void exit(@Patch.Return(readOnly = false) float weight) {
        if (weight > 0.0f) {
            weight *= MULTIPLIER;
        }
    }
}
