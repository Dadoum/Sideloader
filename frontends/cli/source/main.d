module main;

import std.algorithm;
import std.array;
import std.datetime;
import std.format;
import std.path;
import std.stdio;
import std.sumtype;
import std.typecons;
import file = std.file;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

import plist;

import imobiledevice;

import server.appleaccount;
import server.developersession;

import sideload;
import sideload.bundle;
import sideload.application;
import sideload.certificateidentity;

import app;

version = X509;

int main(string[] args) {
    version (linux) {
        import core.stdc.locale;
        setlocale(LC_ALL, "");
    }

    auto configurationPath = "./sideloader-config";
    configureLoggingProvider(new shared DefaultProvider(true, Levels.INFO));

    auto log = getLogger();

    string appPath;

    if (args.length != 2) {
        log.errorF!"Usage: %s <app path, .ipa or .app>"(args.length ? args[0] : "sideloader");
        return 1;
    }
    appPath = args[1];

    if (!(file.exists(configurationPath.buildPath("lib/libstoreservicescore.so")) && file.exists(configurationPath.buildPath("lib/libCoreADI.so")))) {
        auto succeeded = downloadAndInstallDeps(configurationPath, (progress) {
            write(format!"%.2f %% completed\r"(progress * 100));
            stdout.flush();

            return false;
        });

        if (!succeeded) {
            log.error("Download failed.");
            return 1;
        }
        log.info("Download completed.");
    }

    scope provisioningData = initializeADI(configurationPath);
    scope adi = provisioningData.adi;
    scope akDevice = provisioningData.device;
    scope app = new Application(appPath);

    write("Enter your Apple ID: ");
    stdout.flush();
    string appleId = readln()[0..$ - 1];
    write("Enter your password (will appear in clear in your terminal): ");
    stdout.flush();
    string password = readln()[0..$ - 1];

    DeveloperSession appleAccount = DeveloperSession.login(
        akDevice,
        adi,
        appleId,
        password,
            (sendCode, submitCode) {
            sendCode();
            write("A code has been sent to your devices, please write it here: ");
            stdout.flush();
            string code = readln();
            submitCode(code);
        }).match!(
            (DeveloperSession session) => session,
            (AppleLoginError error) {
            auto errorStr = format!"%s (%d)"(error.description, error);
            getLogger().errorF!"Apple auth error: %s"(errorStr);
            return null;
        }
    );

    if (appleAccount) {
        string udid = iDevice.deviceList()[0].udid;
        log.infoF!"Initiating connection the device (UUID: %s)"(udid);
        auto device = new iDevice(udid);
        sideloadFull(configurationPath, device, appleAccount, app, (progress, action) {
            log.infoF!"%s (%.2f%%)"(action, progress * 100);
        });
    }

    return 0;
}
