module cli_frontend;

import core.stdc.stdlib;

import std.array;
import std.datetime;
import std.exception;
import std.format;
import std.parallelism;
import std.path;
import std.process;
import std.stdio;
import std.sumtype;
import std.string;
import std.traits;
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

import argparse;

import app;
import utils;

version = X509;

noreturn wrongArgument(string msg) {
    getLogger().error(msg);
    exit(1);
}

auto openApp(string path) {
    if (!file.exists(path))
        return wrongArgument("The specified app file does not exist.");

    if (!path.endsWith(".ipa"))
        return wrongArgument("The app is not an ipa file.");

    if (!file.isFile(path))
        return wrongArgument("The app should be an ipa file.");

    return new Application(path);
}

auto openAppFolder(string path) {
    if (!file.exists(path))
        return wrongArgument("The specified app file does not exist.");

    if (file.isFile(path))
        return wrongArgument("The app should be a folder.");

    return new Application(path);
}


auto readFile(string path) {
    return cast(ubyte[]) file.read(path);
}

auto readPrivateKey(string path) {
    RandomNumberGenerator rng = RandomNumberGenerator.makeRng();
    return RSAPrivateKey(loadKey(path, rng));
}

auto readCertificate(string path) {
    return X509Certificate(path, false);
}

extern(C) char* getpass(const(char)* prompt);

string readPasswordLine(string prompt) {
    version (Windows) {
        write(prompt.toStringz(), " [/!\\ The password will appear in clear text in the terminal]: ");
        return readln().chomp();
    } else {
        return fromStringz(cast(immutable) getpass(prompt.toStringz()));
    }
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
            } while (submitCode(code).match!((Success _) => false, (ReloginNeeded _) => false, (AppleLoginError _) => true));
        })
    .match!(
        (DeveloperSession session) => session,
        (AppleLoginError error) {
            log.errorF!"Can't log-in! %s (%d)"(error.description, error);
            return null;
        }
    );
}

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
// @(Command("login").Description("Log-in to your Apple account."))
// @(Command("logout").Description("Log-out."))
import sign;
// @(Command("swift-setup").Description("Set-up certificates to build a Swift Package Manager iOS application (requires SPM in the path)."))
import team;
import tool;
// @(Command("tweak").Description("Install a tweak in an ipa file."))

mixin template LoginCommand()
{
    import provision;
    @(NamedArgument("i", "interactive").Description("Prompt to type passwords if needed."))
    bool interactive = false;

    final auto login(Device device, ADI adi) => cli_frontend.login(device, adi, interactive);
}

@(Command("version").Description("Print the version."))
struct VersionCommand {
    int opCall() {
        writeln(versionStr);
        return 0;
    }
}

int entryPoint(Commands commands)
{
    version (linux) {
        import core.stdc.locale;
        setlocale(LC_ALL, "");
    }

    defaultPoolThreads = commands.threadCount;
    configureLoggingProvider(new shared DefaultProvider(true, commands.debug_ ? Levels.DEBUG : Levels.INFO));

    try
    {
        return commands.cmd.match!(
                (AppIdCommand cmd) => cmd(),
                (CertificateCommand cmd) => cmd(),
                (InstallCommand cmd) => cmd(),
                (SignCommand cmd) => cmd(),
                (TeamCommand cmd) => cmd(),
                (ToolCommand cmd) => cmd(),
                (VersionCommand cmd) => cmd(),
        );
    }
    catch (Exception ex)
    {
        getLogger().errorF!"%s at %s:%d: %s"(typeid(ex).name, ex.file, ex.line, ex.msg);
        getLogger().debugF!"Full exception: %s"(ex);
        return 1;
    }
}

struct Commands
{
    @(NamedArgument("d", "debug").Description("Enable debug logging"))
    bool debug_;

    @(NamedArgument("thread-count").Description("Numbers of threads to be used for signing the application bundle"))
    uint threadCount = uint.max;

    @SubCommands
    SumType!(AppIdCommand, CertificateCommand, InstallCommand, SignCommand, TeamCommand, ToolCommand, VersionCommand) cmd;
}

mixin CLI!Commands.main!entryPoint;

