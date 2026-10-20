package partner.coopbridge;

import me.zed_0xff.zombie_buddy.Patch;

/**
 * The Host button starts a second Java process for the co-op server. The
 * stock command copies one garbage-collector argument from this method. We
 * replace that optional argument with the ZombieBuddy native agent argument,
 * allowing server-side Java mods to load before multiplayer transactions are
 * validated. The child JVM then uses its safe default garbage collector.
 */
@Patch(className = "zombie.network.CoopMaster", methodName = "getGarbageCollector")
public final class Patch_CoopServerAgent {
    private static final String AGENT_ARGUMENT =
            "-agentlib:zbNative=policy=deny-new,frontend=console";

    private Patch_CoopServerAgent() {
    }

    @Patch.OnExit
    public static void exit(@Patch.Return(readOnly = false) String result) {
        result = AGENT_ARGUMENT;
    }
}
