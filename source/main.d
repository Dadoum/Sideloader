import core.stdc.signal;

import std.base64;
import std.format;
import std.getopt;
import std.process;
import std.range;
import std.sumtype;
import std.string;
import std.traits;

import file = std.file;

import slf4d;

import constants;
import utils;

import app.frontend;
import native_frontend = frontend;
import version_string;

Frontend frontend;

int main(string[] args) {
    Levels logLevel = Levels.INFO;
    debug {
        logLevel = Levels.DEBUG;
    }

    bool traceLog;
    getopt(
        args,
        "trace", "Write more logs", &traceLog
    );

    if (traceLog) {
        logLevel = Levels.TRACE;
    }

    configureLoggingProvider(native_frontend.makeLoggingProvider(logLevel));

    import core.stdc.locale;
    setlocale(LC_ALL, "");

    Logger log = getLogger();

    signal(SIGSEGV, cast(Parameters!signal[1]) &SIGSEGV_trace);

    frontend = native_frontend.makeFrontend();
    log.info(versionStr);
    log.infoF!"Configuration path: %s"(frontend.configurationPath());
    if (!file.exists(frontend.configurationPath)) {
        file.mkdirRecurse(frontend.configurationPath);
    }

	return frontend.run(args);
}

public class SegmentationFault: Throwable /+ Throwable since it should not be caught +/ {
    this(string file = __FILE__, size_t line = __LINE__) {
        super("Segmentation fault.", file, line);
    }
}

extern(C) void SIGSEGV_trace(int) @system {
    throw new SegmentationFault();
}
