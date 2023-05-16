import std.algorithm.searching;
import std.base64;
import std.format;
import std.path;
import std.process;
import std.range;
import std.sumtype;
import std.string;

import file = std.file;

import infiniteloop.openssl;

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

    //+
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

    // string appleId =  "hubert.erganov@outlook.com"; string password = "!Qwerty4!";
    string appleId =  "hubert.erganov.pro@outlook.com"; string password = "!Qwerty5!";

    //+
    DeveloperSession appleAccount = DeveloperSession.login(device, adi, appleId, password, (sendCode, submitCode) {
        sendCode();

        import std.stdio;
        write("2FA code: ");
        stdout.flush();
        string code = readln()[0..$-1];

        submitCode(code);
    }).match!(
        (DeveloperSession session) => session,
        (AppleLoginError error) {
            log.errorF!"Apple auth error: %s"(error);
            return null;
        }
    );

    auto teams = appleAccount.listTeams().unwrap();
    auto team = teams[0];
    // +/

    import std.digest.sha;
    import std.uni;
    string certificatePath = configurationPath.buildPath("certificates").buildPath(sha1Of(appleId).toHexString().toLower());
    if (!file.exists(certificatePath)) {
        file.mkdir(certificatePath);
    }

    string keyFile = certificatePath.buildPath("key.pem");
    string certificateFile = certificatePath.buildPath("certificate.crt");

    DevelopmentCertificate certificate;

    RsaKey key;
    if (file.exists(keyFile)) {
        log.info("A key has already been generated");
        key = new RsaKey(file.readText(keyFile));

        log.info("Checking if any certificate online is matching the private key...");
        auto certificates = appleAccount.listAllDevelopmentCerts!iOS(team).unwrap();
        auto sideloaderCertificates = certificates.find!((cert) => cert.machineName == applicationName);
        if (sideloaderCertificates.length != 0) {
            foreach (cert; sideloaderCertificates) {
                auto x509cert = new X509Certificate(format!
                "-----BEGIN CERTIFICATE-----
%s
-----END CERTIFICATE-----"(Base64.encode(cert.certContent).chunks(64).join('\n')));
                if (x509cert.validateCertificateKey(key)) {
                    log.info("Matching certificate found.");
                    certificate = cert;
                    goto certificateReady;
                }
            }
        }
    } else {
        log.info("Generating a new RSA key");
        key = new RsaKey(RsaKeyConfig(2048));

        file.write(keyFile, key.toPEM());
    }

    {
        log.info("Submitting a new certificate request to Apple...");
        immutable string[string] subject = [
            "C":  "US",
            "ST": "STATE",
            "L": "LOCAL",
            "O":  "ORGANIZATION",
            "CN": "CN"
        ];

        if (!file.exists(certificatePath))
            file.mkdir(certificatePath);

        auto csr = newX509CertificateSigningRequest(
            subject, key
        );

        auto certificateId = appleAccount.submitDevelopmentCSR!iOS(team, csr.toPEM()).unwrap();
        certificate = appleAccount.listAllDevelopmentCerts!iOS(team).unwrap().find!((cert) => cert.certificateId == certificateId)[0];
    }

  certificateReady:
    file.write(certificateFile, certificate.certContent);
    log.info("Certificate retrieved successfully, and has been written.");
    // +/

    auto appIDs = appleAccount.listAppIds!iOS(team);
    log.infoF!"%s"(appIDs);

    auto appGroups = appleAccount.listApplicationGroups!iOS(team);
    log.infoF!"%s"(appGroups);

	return 0; // new SideloaderApplication(configurationPath).run(args);
}
