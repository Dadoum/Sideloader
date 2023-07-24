module frontend;

import glib.MessageLog;

import slf4d;

import app.frontend;
import ui.sideloadergtkapplication;

class GtkFrontend: Frontend {
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
    }

    int run(string configurationPath, string[] args) {
        return new SideloaderGtkApplication(configurationPath).run(args);
    }
}

Frontend makeFrontend() => new GtkFrontend();
