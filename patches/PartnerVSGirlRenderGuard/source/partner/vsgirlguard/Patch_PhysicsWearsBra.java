package partner.vsgirlguard;

import me.zed_0xff.zombie_buddy.Patch;

/** Guard VSGirl's second worn-item scan. */
@Patch(className = "localplayerbody.Physics", methodName = "wearsBra")
public final class Patch_PhysicsWearsBra {
    private Patch_PhysicsWearsBra() {
    }

    @Patch.OnExit(onThrowable = Throwable.class)
    public static void exit(
            @Patch.Return(readOnly = false) boolean returnValue,
            @Patch.Thrown(readOnly = false) Throwable thrown) {
        if (thrown != null) {
            returnValue = false;
            thrown = null;
        }
    }
}
