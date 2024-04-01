module sign;

import slf4d;
import slf4d.default_provider;

import botan.pubkey.algo.rsa;

import argparse;
import progress;

import server.developersession;

import sideload.application;
import sideload.certificateidentity;
import sideload.sign: sideloadSign = sign;

import cli_frontend;

@(Command("sign").Description("Sign an application bundle."))
struct SignCommand
{
    @(NamedArgument("c", "cert").Description("Certificate (signed by Apple).").Required())
    string certificatePath;

    @(NamedArgument("k", "key").Description("Private key (matching the signed certificate).").Required())
    string privateKeyPath;

    @(NamedArgument("m", "provision").Description("App's provisioning certificate.").Required())
    string mobileProvisionPath;

    @(PositionalArgument(0, "app path").Description("App path."))
    string appFolder;

    int opCall()
    {
        auto log = getLogger();

        RSAPrivateKey privateKey = readPrivateKey(privateKeyPath);
        ubyte[] mobileProvisionFile = readFile(mobileProvisionPath);
        Application app = openAppFolder(appFolder);
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
