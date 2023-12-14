module cli_frontend;

import core.stdc.stdlib;

import std.array;
import std.datetime;
import std.exception;
import std.format;
import std.path;
import std.process;
import std.stdio;
import std.sumtype;
import std.string;
import std.typecons;
import file = std.file;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

import botan.cert.x509.x509cert;
import botan.pubkey.algo.rsa;

import plist;

import provision;

import imobiledevice;

import server.appleaccount;
import server.developersession;
import version_string;

import sideload;
import sideload.bundle;
import sideload.application;
import sideload.certificateidentity;
import sideload.sign;

import jcli;

import app;
import utils;

version = X509;

auto openApp(string path) {
    if (!file.exists(path))
        return fail!Application("The specified app file does not exist.");

    if (!path.endsWith(".ipa"))
        return fail!Application("The app is not an ipa file.");

    if (!file.isFile(path))
        return fail!Application("The app should be an ipa file.");

    return ok!Application(new Application(path));
}

auto openAppFolder(string path) {
    if (!file.exists(path))
        return fail!Application("The specified app file does not exist.");

    if (file.isFile(path))
        return fail!Application("The app should be a folder.");

    return ok!Application(new Application(path));
}


auto readFile(string path) {
    return ok!(ubyte[])(cast(ubyte[]) file.read(path));
}

auto readPrivateKey(string path) {
    RandomNumberGenerator rng = RandomNumberGenerator.makeRng();
    return ok!RSAPrivateKey(RSAPrivateKey(loadKey(path, rng)));
}

auto readCertificate(string path) {
    return X509Certificate(path, false);
}

extern(C) char* getpass(const(char)* prompt);

string readPasswordLine(string prompt) {
    return fromStringz(cast(immutable) getpass(prompt.toStringz()));
}

DeveloperSession login(Device device, ADI adi, bool interactive) {
    auto log = getLogger();

    log.info("Logging in...");

    DeveloperSession account;

    // TODO Keyring stuff
    // ...

    if (account) return null;
    if (!interactive) {
        log.error("You are not logged in. (use `sidestore login` to log-in, or add `-i` to make us ask you the account)");
        return null;
    }

    log.info("Please enter your account informations. They will only be sent to Apple servers.");
    log.info("See it for yourself at https://github.com/Dadoum/Sideloader/");

    write("Apple ID: ");
    string appleId = readln().chomp();
    string password = readPasswordLine("Password: ");

    return DeveloperSession.login(
        device,
        adi,
        appleId,
        password,
        (sendCode, submitCode) {
            sendCode();
            string code;
            do {
                write("A code has been sent to your devices, please type it here (type `resend` to resend one): ");
                code = readln().chomp();
                if (code == "resend") {
                    sendCode();
                    continue;
                }
            } while (submitCode(code).match!((Success _) => true, (ReloginNeeded _) => true, (AppleLoginError _) => false));
        })
    .match!(
        (DeveloperSession session) => session,
        (AppleLoginError error) {
            log.errorF!"Can't log-in! %s (%d)"(error.description, error);
            return null;
        }
    );
}

// alias BindWith(alias U) = UseConverter!U;

auto initializeADI(string configurationPath)
{
    scope log = getLogger();
    if (!(file.exists(configurationPath.buildPath("lib/libstoreservicescore.so")) && file.exists(configurationPath.buildPath("lib/libCoreADI.so")))) {
        auto succeeded = downloadAndInstallDeps(configurationPath, (progress) {
            write(format!"%.2f %% completed\r"(progress * 100));
            stdout.flush();

            return false;
        });

        if (!succeeded) {
            log.error("Download failed.");
            exit(1);
        }
        log.info("Download completed.");
    }

    scope provisioningData = app.initializeADI(configurationPath);
    return provisioningData;
}

string systemConfigurationPath()
{
    return environment.get("SIDELOADER_CONFIG_DIR").orDefault(defaultConfigurationPath());
}

string defaultConfigurationPath()
{
    version (Windows) {
        string configurationPath = environment["AppData"];
    } else version (OSX) {
        string configurationPath = "~/Library/Preferences/".expandTilde();
    } else {
        string configurationPath = environment.get("XDG_CONFIG_DIR")
            .orDefault("~/.config")
            .expandTilde();
    }
    return configurationPath.buildPath("Sideloader");
}

// planned commands

import app_id;
import certificate;
import install;
// @Command("login", "Log-in to your Apple account.")
// @Command("logout", "Log-out.")
import sign;
// @Command("swift-setup", "Set-up certificates to build a Swift Package Manager iOS application (requires SPM in the path).")
import team;
import tool;
// @Command("tweak", "Install a tweak in an ipa file.")

mixin template LoginCommand()
{
    import provision;
    @ArgNamed("i", "Prompt to type passwords if needed.")
    bool interactive = false;

    final auto login(Device device, ADI adi) => cli_frontend.login(device, adi, interactive);
}

@Command("version", "Print the version.")
struct VersionCommand {
    void onExecute() {
        writeln(versionStr);
    }
}

int main(string[] args)
{
    import keyring;
    auto kr = makeKeyring();

    return new CommandLineInterface!(app_id, certificate, install, sign, team, tool, cli_frontend)().parseAndExecute(args);
    // return matchAndExecuteAcrossModules!(app_id, certificate, install, sign, team, tool, cli_frontend)(args);
}
