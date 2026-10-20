package partner.largemapbuffer;

import me.zed_0xff.zombie_buddy.Patch;

/** Enlarges the scratch buffer before map_meta.bin is read. */
@Patch(className = "zombie.iso.IsoMetaGrid", methodName = "load")
public final class Patch_IsoMetaGridLoad {
    private Patch_IsoMetaGridLoad() {
    }

    @Patch.OnEnter
    public static void enter() {
        LargeMapBufferInstaller.ensureInstalled();
    }
}
