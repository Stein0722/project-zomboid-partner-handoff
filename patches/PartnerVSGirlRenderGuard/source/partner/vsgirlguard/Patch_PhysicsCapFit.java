package partner.vsgirlguard;

import me.zed_0xff.zombie_buddy.Patch;

/** Guard VSGirl's combined bra and coverage check. */
@Patch(className = "localplayerbody.Physics", methodName = "capFit")
public final class Patch_PhysicsCapFit {
    private Patch_PhysicsCapFit() {
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
