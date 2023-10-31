module graphical_app;

import core.sys.windows.windef;

pragma(linkerDirective, "/SUBSYSTEM:WINDOWS");
static if (__VERSION__ >= 2091)
    pragma(linkerDirective, "/ENTRY:wmainCRTStartup");
else
    pragma(linkerDirective, "/ENTRY:mainCRTStartup");

private class SegmentationFault: Throwable /+ Throwable since it should not be caught +/ {
    this(string file = __FILE__, size_t line = __LINE__) {
        super("Segmentation fault.", file, line);
    }
}

extern (Windows) int SIGSEGV_win(EXCEPTION_POINTERS*) {
    throw new SegmentationFault(); // Make an exception to force Windows to generate a stacktrace.
}
