package partner.largemapbuffer;

import me.zed_0xff.zombie_buddy.Patch;

/** Enlarges the scratch buffer before PZ Opt's asynchronous metadata save. */
@Patch(className = "zombie.iso.IsoMetaGrid", methodName = "saveToBufferMap")
public final class Patch_IsoMetaGridSaveToBufferMap {
    private Patch_IsoMetaGridSaveToBufferMap() {
    }

    @Patch.OnEnter
    public static void enter() {
        LargeMapBufferInstaller.ensureInstalled();
    }
}
