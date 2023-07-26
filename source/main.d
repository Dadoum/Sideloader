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

    auto device = new Device(configurationPath.buildPath("device.json"));

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

    auto adi = new ADI(configurationPath.buildPath("lib"));
    adi.provisioningPath = configurationPath;
    adi.identifier = device.adiIdentifier;

    if (!adi.isMachineProvisioned(-2)) {
        log.info("Provisioning device...");

        ProvisioningSession provisioningSession = new ProvisioningSession(adi, device);
        provisioningSession.provision(-2);
        log.info("Device provisioned successfully.");
    }
    log.debug_("Provisioning OK.");

	return makeFrontend().run(configurationPath, args);
}
