package partner.dynamicweight;

import java.util.List;
import me.zed_0xff.zombie_buddy.Patch;

/**
 * Project Zomboid's Host button starts a second Java process for the co-op
 * server.  The stock command omits ZombieBuddy, so client-side weight getters
 * and the server's transaction validation can disagree.  Add the native agent
 * only to that one GameServer child process.
 */
@Patch(className = "java.lang.ProcessBuilder", methodName = "start")
public final class Patch_CoopServerZombieBuddy {
    private static final String GAME_SERVER = "zombie.network.GameServer";
    private static final String AGENT_ARGUMENT =
            "-agentlib:zbNative=policy=deny-new,frontend=console";

    private Patch_CoopServerZombieBuddy() {
    }

    @Patch.OnEnter
    public static void enter(@Patch.This ProcessBuilder processBuilder) {
        List<String> command = processBuilder.command();
        boolean isGameServer = false;
        boolean alreadyHasAgent = false;

        for (String argument : command) {
            if (GAME_SERVER.equals(argument)) {
                isGameServer = true;
            }
            if (argument != null
                    && (argument.startsWith("-agentlib:zbNative")
                    || argument.startsWith("-javaagent:ZombieBuddy.jar"))) {
                alreadyHasAgent = true;
            }
        }

        if (isGameServer && !alreadyHasAgent) {
            command.add(1, AGENT_ARGUMENT);
            System.out.println(
                    "[Partner Weight Compat] ZombieBuddy added to the co-op server process");
        }
    }
}
