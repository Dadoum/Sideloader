import std.path;
import std.process;
import std.sumtype;

import file = std.file;

import slf4d;
import slf4d.default_provider;

import provision;

import glib.MessageLog;

import constants;
import server.appleaccount;
import server.developersession;
import ui.sideloaderapplication;
import utils;

int main(string[] args) {
    debug {
        configureLoggingProvider(new shared DefaultProvider(true, Levels.TRACE));
    } else {
        configureLoggingProvider(new shared DefaultProvider(true, Levels.INFO));
    }

    import core.stdc.locale;
    setlocale(LC_ALL, "");

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

    Logger log = getLogger();

    string configurationPath = environment.get("XDG_CONFIG_DIR")
                                          .orDefault("~/.config")
                                          .buildPath(applicationName)
                                          .expandTilde();
    if (!file.exists(configurationPath)) {
        file.mkdirRecurse(configurationPath);
    }
    log.infoF!"Configuration path: %s"(configurationPath);

    /+
    DeveloperSession appleAccount = DeveloperSession.login(device, adi, "hubert.erganov@outlook.com", "!!Qwerty1234!!", (sendCode, submitCode) {
        sendCode();

        import std.stdio;
    	write("2FA code: ");
		stdout.flush();
		string code = readln()[0..$-1];

		submitCode(code);
	}).match!(
			(DeveloperSession session) => session,
			(AppleLoginError error) {
				return null;
			}
	);
	// +/

	return new SideloaderApplication(configurationPath).run(args);
}
