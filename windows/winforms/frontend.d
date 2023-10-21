module frontend;

import core.sys.windows.winbase;
import core.sys.windows.windef;

import std.path;
import std.process;

import dfl;

import slf4d;
import slf4d.provider;

import constants;
import app.frontend;

import logging;
import ui.sideloaderform;

shared class WindowsFrontend: Frontend {
    string _configurationPath;

    this() {
        Application.enableVisualStyles();
        _configurationPath = environment["LocalAppData"].buildPath(applicationName);
    }

    override string configurationPath() {
        return _configurationPath;
    }

    override int run(string[] args) {
        SetUnhandledExceptionFilter(&SIGSEGV_win);
        try {
            Application.run(new SideloaderForm());
            return 0;
        } catch (Exception ex) {
            getLogger().errorF!"Unhandled exception: %s"(ex);
            msgBox(ex.msg, "Unhandled exception!", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
            throw ex;
        }
    }
}

Frontend makeFrontend() => new WindowsFrontend();

shared(LoggingProvider) makeLoggingProvider(Level rootLoggingLevel) => new shared OutputDebugStringLoggingProvider(rootLoggingLevel);
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
