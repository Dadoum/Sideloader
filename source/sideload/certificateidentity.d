module sideload.certificateidentity;

import std.algorithm.searching;
import std.digest.sha;
import file = std.file;
import std.path;
import std.uni;

import slf4d;

import botan.constants;
version = X509;
import botan.cert.x509.certstor;
import botan.cert.x509.x509_crl;
import botan.cert.x509.x509self;
import botan.pubkey.algo.rsa;
import botan.rng.rng;

import constants;
import server.appleaccount;
import server.developersession;

import sideload.bundle;

class CertificateIdentity {
    RSAPrivateKey privateKey = void;
    DevelopmentCertificate appleCertificateInfo = void;
    X509Certificate certificate = void;

    string certFile;
    string keyFile;

    this(string configurationPath, DeveloperSession appleAccount) { // Gets the key if it exists, and generates or retrieves the matching certificate.
        auto log = getLogger();

        auto teams = appleAccount.listTeams().unwrap();
        auto team = teams[0];

        string keyPath = configurationPath.buildPath("keys").buildPath(sha1Of(appleAccount.appleId).toHexString().toLower());
        if (!file.exists(keyPath)) {
            file.mkdirRecurse(keyPath);
        }

        keyFile = keyPath.buildPath("key.pem");

        RandomNumberGenerator rng = RandomNumberGenerator.makeRng();

        if (file.exists(keyFile)) {
            log.info("A key has already been generated");
            privateKey = RSAPrivateKey(loadKey(keyFile, rng));

            log.info("Checking if any certificate online is matching the private key...");
            auto certificates = appleAccount.listAllDevelopmentCerts!iOS(team).unwrap();
            auto sideloaderCertificates = certificates.find!((cert) => cert.machineName == applicationName);
            if (sideloaderCertificates.length != 0) {
                Vector!ubyte certContent;
                Vector!ubyte ourPublicKey = privateKey.x509SubjectPublicKey();
                foreach (cert; sideloaderCertificates) {
                    certContent = Vector!ubyte(cert.certContent);
                    auto x509cert = X509Certificate(certContent, false);
                    if (x509cert.subjectPublicKey().x509SubjectPublicKey() == ourPublicKey) {
                        log.info("Matching certificate found.");
                        appleCertificateInfo = cert;
                        goto certificateReady;
                    }
                    // +/
                }
            }
        } else {
            log.info("Generating a new RSA key");
            privateKey = RSAPrivateKey(rng, 2048);

            file.write(keyFile, botan.pubkey.pkcs8.PEM_encode(privateKey));
        }

        {
            X509CertOptions subject;
            subject.country = "US";
            subject.state = "STATE";
            subject.locality = "LOCAL";
            subject.organization = "ORGANIZATION";
            subject.common_name = "CN";

            auto certRequest = createCertReq(subject, privateKey.m_priv, "SHA-256", rng);

            log.info("Submitting a new certificate request to Apple...");

            auto certificateId = appleAccount.submitDevelopmentCSR!iOS(team, certRequest.PEM_encode()).unwrap();
            appleCertificateInfo = appleAccount.listAllDevelopmentCerts!iOS(team).unwrap().find!((cert) => cert.certificateId == certificateId)[0];
        }

      certificateReady:
        log.info("Certificate retrieved successfully.");
        certificate = X509Certificate(appleCertificateInfo.certContent, false);
        // temporary, remove when real signing is implemented
        certFile = keyPath.buildPath("cert.der");
        file.write(certFile, appleCertificateInfo.certContent);
    }

    import server.developersession;
    void sign(Bundle bundle, ProvisioningProfile profile) {
        auto executablePath = bundle.bundleDir.buildPath(bundle.appInfo["CFBundleExecutable"].str().native());
        // executablePath;
    }
}
