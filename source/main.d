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

    /*
    // string appleId =  "hubert.erganov@outlook.com"; string password = "!Qwerty9!";
    // string appleId =  "hubert.erganov.pro@outlook.com"; string password = "!Qwerty7!"; // locked
    string appleId =  "benjiehack@outlook.com"; string password = "!Qwerty0!";

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

    DevelopmentCertificate certificate = void;

    RandomNumberGenerator rng = RandomNumberGenerator.makeRng();
    RSAPrivateKey key = void;
    if (file.exists(keyFile)) {
        log.info("A key has already been generated");
        key = RSAPrivateKey(loadKey(keyFile, rng));

        log.info("Checking if any certificate online is matching the private key...");
        auto certificates = appleAccount.listAllDevelopmentCerts!iOS(team).unwrap();
        auto sideloaderCertificates = certificates.find!((cert) => cert.machineName == applicationName);
        if (sideloaderCertificates.length != 0) {
            Vector!ubyte certContent;
            Vector!ubyte ourPublicKey = key.x509SubjectPublicKey();
            foreach (cert; sideloaderCertificates) {
                certContent = Vector!ubyte(cert.certContent);
                auto x509cert = X509Certificate(certContent, false);
                if (x509cert.subjectPublicKey().x509SubjectPublicKey() == ourPublicKey) {
                    log.info("Matching certificate found.");
                    certificate = cert;
                    goto certificateReady;
                }
                // +/
            }
        }
    } else {
        log.info("Generating a new RSA key");
        key = RSAPrivateKey(rng, 2048);

        file.write(keyFile, botan.pubkey.x509_key.PEM_encode(key));
    }

    {
        X509CertOptions subject;
        subject.country = "US";
        subject.state = "STATE";
        subject.locality = "LOCAL";
        subject.organization = "ORGANIZATION";
        subject.common_name = "CN";

        auto certRequest = createCertReq(subject, key.m_priv, "SHA-256", rng);

        log.info("Submitting a new certificate request to Apple...");

        if (!file.exists(certificatePath))
            file.mkdir(certificatePath);

        auto certificateId = appleAccount.submitDevelopmentCSR!iOS(team, certRequest.PEM_encode()).unwrap();
        certificate = appleAccount.listAllDevelopmentCerts!iOS(team).unwrap().find!((cert) => cert.certificateId == certificateId)[0];
    }

  certificateReady:
    file.write(certificateFile, certificate.certContent);
    log.info("Certificate retrieved successfully, and has been written.");

    auto appIDs = appleAccount.listAppIds!iOS(team);
    log.infoF!"%s"(appIDs);

    auto appGroups = appleAccount.listApplicationGroups!iOS(team);
    log.infoF!"%s"(appGroups);


    // */

	return makeFrontend().run(configurationPath, args);
    // import ui.sideloadergtkapplication;
    // return new SideloaderGtkApplication(configurationPath).run(args);
}
