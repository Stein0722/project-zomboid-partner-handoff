package partner.vsgirlguard;

import me.zed_0xff.zombie_buddy.Patch;

/** Treat one unstable render frame as not covered and retry next frame. */
@Patch(className = "localplayerbody.TextureCaps", methodName = "worn")
public final class Patch_TextureCapsWorn {
    private Patch_TextureCapsWorn() {
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
