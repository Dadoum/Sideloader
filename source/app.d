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

	Device device = new Device(configurationPath.buildPath("device.json"));

	if (!device.initialized) {
		log.info("Creating device...");

		import std.digest;
		import std.random;
		import std.range;
		import std.uni;
		import std.uuid;
		device.serverFriendlyDescription = "<MacBookPro13,2> <macOS;13.1;22C65> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>";
		device.uniqueDeviceIdentifier = randomUUID().toString().toUpper();
		device.adiIdentifier = (cast(ubyte[]) rndGen.take(2).array()).toHexString().toLower();
		device.localUserUUID = (cast(ubyte[]) rndGen.take(8).array()).toHexString().toUpper();
		log.info("Device created successfully.");
	}
	log.debug_("Device OK.");

	ADI adi = new ADI("~/.config/Provision/lib/x86_64".expandTilde());
	adi.provisioningPath = configurationPath;
	adi.identifier = device.adiIdentifier;

	if (!adi.isMachineProvisioned(-2)) {
		log.info("Provisioning device...");

		ProvisioningSession provisioningSession = new ProvisioningSession(adi, device);
		provisioningSession.provision(-2);
		log.info("Device provisioned successfully.");
	}
	log.debug_("Provisioning OK.");

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

	return new SideloaderApplication().run(args);
}
