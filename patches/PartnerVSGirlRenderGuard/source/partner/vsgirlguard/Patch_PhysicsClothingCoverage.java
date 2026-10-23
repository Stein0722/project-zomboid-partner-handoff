package partner.vsgirlguard;

import me.zed_0xff.zombie_buddy.Patch;

/**
 * Keep a transient worn-item list race from escaping VSGirl's render-time
 * clothing coverage calculation. A value of 1 is a conservative, covered
 * fallback for the single unstable frame; normal frames keep the original
 * result unchanged.
 */
@Patch(className = "localplayerbody.Physics", methodName = "clothingCoverage")
public final class Patch_PhysicsClothingCoverage {
    private Patch_PhysicsClothingCoverage() {
    }

    @Patch.OnExit(onThrowable = Throwable.class)
    public static void exit(
            @Patch.Return(readOnly = false) int returnValue,
            @Patch.Thrown(readOnly = false) Throwable thrown) {
        if (thrown != null) {
            returnValue = 1;
            thrown = null;
        }
    }
}
