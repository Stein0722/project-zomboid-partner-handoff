package partner.largemapbuffer;

import java.lang.reflect.Field;
import java.nio.ByteBuffer;
import sun.misc.Unsafe;
import zombie.core.network.ByteBufferReader;
import zombie.core.network.ByteBufferWriter;
import zombie.iso.SliceY;

/**
 * Build 42.21 uses a single fixed 10 MiB buffer for map_meta.bin and related
 * files. A very large custom-map set can exceed that capacity and leave a
 * zero-byte map_meta.bin. Replace the three final static references together
 * while holding the game's own buffer lock.
 */
public final class LargeMapBufferInstaller {
    private static final int TARGET_CAPACITY = 64 * 1024 * 1024;
    private static final Unsafe UNSAFE = findUnsafe();
    private static volatile boolean installed;

    private LargeMapBufferInstaller() {
    }

    public static void ensureInstalled() {
        if (installed || SliceY.SliceBuffer.capacity() >= TARGET_CAPACITY) {
            installed = true;
            return;
        }

        synchronized (SliceY.SliceBufferLock) {
            if (SliceY.SliceBuffer.capacity() >= TARGET_CAPACITY) {
                installed = true;
                return;
            }

            ByteBuffer replacement = ByteBuffer.allocate(TARGET_CAPACITY);
            putStaticFinal("SliceBuffer", replacement);
            putStaticFinal("sliceBufferReader", new ByteBufferReader(replacement));
            putStaticFinal("sliceBufferWriter", new ByteBufferWriter(replacement));
            UNSAFE.fullFence();

            if (SliceY.SliceBuffer != replacement
                    || SliceY.sliceBufferReader.bb != replacement
                    || SliceY.sliceBufferWriter.bb != replacement) {
                throw new IllegalStateException("SliceY buffer replacement did not stick");
            }

            installed = true;
            System.out.println("[PartnerLargeMapMetaBuffer] SliceY scratch buffer: 10 MiB -> 64 MiB");
        }
    }

    private static Unsafe findUnsafe() {
        try {
            Field field = Unsafe.class.getDeclaredField("theUnsafe");
            field.setAccessible(true);
            return (Unsafe) field.get(null);
        } catch (ReflectiveOperationException ex) {
            throw new ExceptionInInitializerError(ex);
        }
    }

    private static void putStaticFinal(String fieldName, Object value) {
        try {
            Field field = SliceY.class.getDeclaredField(fieldName);
            Object base = UNSAFE.staticFieldBase(field);
            long offset = UNSAFE.staticFieldOffset(field);
            UNSAFE.putObjectVolatile(base, offset, value);
        } catch (ReflectiveOperationException ex) {
            throw new IllegalStateException("Unable to replace SliceY." + fieldName, ex);
        }
    }
}
