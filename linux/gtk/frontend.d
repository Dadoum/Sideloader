module frontend;

import file = std.file;
import std.path;
import std.process;
import std.traits;

import glib.MessageLog;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

import constants;
import utils;

import app.frontend;
import ui.sideloadergtkapplication;

shared class GtkFrontend: Frontend {
    string _configurationPath;

    this() {
        MessageLog.logSetHandler(null, GLogLevelFlags.LEVEL_MASK | GLogLevelFlags.FLAG_FATAL | GLogLevelFlags.FLAG_RECURSION,
            (logDomainC, logLevel, messageC, userData) {
            auto logger = getLogger();
            Levels level;
            with (GLogLevelFlags) switch (logLevel) {
                case LEVEL_DEBUG:
                    level = Levels.DEBUG;
                    break;
                case LEVEL_INFO:
                case LEVEL_MESSAGE:
                    level = Levels.INFO;
                    break;
                case LEVEL_WARNING:
                case LEVEL_CRITICAL:
                    level = Levels.WARN;
                    break;
                default:
                    level = Levels.ERROR;
                    break;
            }
            import std.string;
            logger.log(level, cast(string) messageC.fromStringz(), null, cast(string) logDomainC.fromStringz(), "");
        }, null);

        _configurationPath = environment.get("XDG_CONFIG_DIR")
            .orDefault("~/.config")
            .buildPath(applicationName)
            .expandTilde();
    }

    override string configurationPath() {
        return _configurationPath;
    }

    override int run(string[] args) {
        return new SideloaderGtkApplication(_configurationPath).run(args);
    }
}

Frontend makeFrontend() => new GtkFrontend();
shared(LoggingProvider) makeLoggingProvider(Level rootLoggingLevel) => new shared DefaultProvider(true, rootLoggingLevel);
