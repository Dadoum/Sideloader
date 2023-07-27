import std.base64;
import std.format;
import std.getopt;
import std.path;
import std.process;
import std.range;
import std.sumtype;
import std.string;

import file = std.file;

import slf4d;
import slf4d.default_provider;

import provision;

import constants;
import utils;

import frontend;

__gshared string configurationPath; // TODO: move that variable elsewhere

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

    configureLoggingProvider(new shared DefaultProvider(true, logLevel));

    import core.stdc.locale;
    setlocale(LC_ALL, "");

    Logger log = getLogger();

    configurationPath = environment.get("XDG_CONFIG_DIR")
                                          .orDefault("~/.config")
                                          .buildPath(applicationName)
                                          .expandTilde();
    if (!file.exists(configurationPath)) {
        file.mkdirRecurse(configurationPath);
    }
    log.infoF!"Configuration path: %s"(configurationPath);

	return makeFrontend().run(configurationPath, args);
}
