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

    @(NamedArgument("singlethread").Description("Run the signature process on a single thread. Sacrifices speed for more consistency."))
    bool singlethreaded;

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
            },
            !singlethreaded
        );
        progressBar.finish();

        return 0;
    }
}

@(Command("trollsign").Description("Bypass Core-Trust with TrollStore 2's method (CVE-2023-41991)."))
struct TrollsignCommand
{
    @(PositionalArgument(0, "macho").Description("Mach-O executable path."))
    string executablePath;

    int opCall()
    {
        auto log = getLogger();
        log.infoF!"Trollsigning %s"(executablePath);

        import file = std.file;
        import sideload.ct_bypass;
        import sideload.macho;
        MachO[] machOs = MachO.parse(cast(ubyte[]) file.read(executablePath));
        foreach (ref machO; machOs) {
            machO.bypassCoreTrust();
        }
        file.write(executablePath, makeMachO(machOs));
        log.info("Done.");

        return 0;
    }
}
