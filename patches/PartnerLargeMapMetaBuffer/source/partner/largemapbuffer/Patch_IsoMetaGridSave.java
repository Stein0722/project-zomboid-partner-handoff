package partner.largemapbuffer;

import me.zed_0xff.zombie_buddy.Patch;

/** Enlarges the scratch buffer before normal synchronous metadata saves. */
@Patch(className = "zombie.iso.IsoMetaGrid", methodName = "save")
public final class Patch_IsoMetaGridSave {
    private Patch_IsoMetaGridSave() {
    }

    @Patch.OnEnter
    public static void enter() {
        LargeMapBufferInstaller.ensureInstalled();
    }
}
