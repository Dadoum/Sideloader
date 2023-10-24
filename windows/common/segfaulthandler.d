module segfaulthandler;

import core.sys.windows.winbase;
import core.sys.windows.windef;

public void configureSegfaultHandler() {
    SetUnhandledExceptionFilter(&SIGSEGV_win);
}

private class SegmentationFault: Throwable /+ Throwable since it should not be caught +/ {
    this(string file = __FILE__, size_t line = __LINE__) {
        super("Segmentation fault.", file, line);
    }
}

extern (Windows) int SIGSEGV_win(EXCEPTION_POINTERS*) {
    throw new SegmentationFault(); // Make an exception to force Windows to generate a stacktrace.
}
