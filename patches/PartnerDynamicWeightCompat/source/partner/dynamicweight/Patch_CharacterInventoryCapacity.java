package partner.dynamicweight;

import me.zed_0xff.zombie_buddy.Patch;
import zombie.characters.IsoGameCharacter;
import zombie.inventory.ItemContainer;
import zombie.iso.IsoObject;

/**
 * Build 42 keeps the character's ItemContainer capacity near 50 even when a
 * trait or Project RPG raises IsoGameCharacter.maxWeight.  Transfer validation
 * reads ItemContainer.getCapacity(), while the UI displays getMaxWeight().
 * Make both paths use the same character maximum.
 */
@Patch(className = "zombie.inventory.ItemContainer", methodName = "getCapacity")
public final class Patch_CharacterInventoryCapacity {
    private Patch_CharacterInventoryCapacity() {
    }

    @Patch.OnExit
    public static void exit(
            @Patch.This ItemContainer container,
            @Patch.Return(readOnly = false) int capacity) {
        IsoObject parent = container.getParent();
        if (parent instanceof IsoGameCharacter) {
            capacity = Math.max(capacity, ((IsoGameCharacter) parent).getMaxWeight());
        }
    }
}
