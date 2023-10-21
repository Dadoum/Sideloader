import std.base64;
import std.format;
import std.getopt;
import std.range;
import std.sumtype;
import std.string;

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

    frontend = native_frontend.makeFrontend();
    log.info(versionStr);
    log.infoF!"Configuration path: %s"(frontend.configurationPath());
    if (!file.exists(frontend.configurationPath)) {
        file.mkdirRecurse(frontend.configurationPath);
    }

	return frontend.run(args);
}
