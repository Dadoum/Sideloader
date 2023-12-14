module sign;

import slf4d;
import slf4d.default_provider;

import botan.pubkey.algo.rsa;

import jcli;
import progress;

import server.developersession;

import sideload.application;
import sideload.certificateidentity;
import sideload.sign: sideloadSign = sign;

import cli_frontend;

@Command("sign", "Sign an application bundle.")
struct SignCommand
{
    @ArgNamed("cert|c", "Certificate (signed by Apple).")
    string certificatePath;

    @ArgNamed("key|k", "Private key (matching the signed certificate).")
    @BindWith!readPrivateKey
    RSAPrivateKey privateKey;

    @ArgNamed("provision|m", "App's provisioning certificate.")
    @BindWith!readFile
    ubyte[] mobileProvisionFile;

    @ArgPositional("app path", "App path.")
    @BindWith!openAppFolder
    Application app;

    int onExecute()
    {
        version (linux) {
            import core.stdc.locale;
            setlocale(LC_ALL, "");
        }

        configureLoggingProvider(new shared DefaultProvider(true, Levels.INFO));

        auto log = getLogger();

        scope certificate = readCertificate(certificatePath);

        string configurationPath = systemConfigurationPath();

        scope provisioningData = initializeADI(configurationPath);
        scope adi = provisioningData.adi;
        scope akDevice = provisioningData.device;

        double accumulator = 0;

        log.infoF!"Signing %s..."(app.bundleName());
        Bar progressBar = new Bar();
        double progress = 0;
        sideloadSign(
            app,
            new CertificateIdentity(certificate, privateKey),
                [app.bundleIdentifier(): ProvisioningProfile("", "", mobileProvisionFile)], // TODO make a better ctor
                (p) {
                progressBar.index = cast(int) (progress += p * 100);
                progressBar.update();
            }
        );
        progressBar.finish();

        return 0;
    }
}
