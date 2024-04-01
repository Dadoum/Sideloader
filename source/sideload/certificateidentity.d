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
    RandomNumberGenerator rng = void;
    X509Certificate certificate = void;
    RSAPrivateKey privateKey = void;

    string keyFile;

    this(X509Certificate certificate, RSAPrivateKey privateKey) {
        rng = RandomNumberGenerator.makeRng();
        this.certificate = certificate;
        this.privateKey = privateKey;
    }

    this(string configurationPath, DeveloperSession appleAccount) {
        auto log = getLogger();
        scope(success) log.debug_("Certificate retrieved successfully.");

        string keyPath = configurationPath.buildPath("keys").buildPath(sha1Of(appleAccount.appleId).toHexString().toLower());
        if (!file.exists(keyPath)) {
            file.mkdirRecurse(keyPath);
        }

        keyFile = keyPath.buildPath("key.pem");

        rng = RandomNumberGenerator.makeRng();

        auto teams = appleAccount.listTeams().unwrap();
        auto team = teams[0];

        if (file.exists(keyFile)) {
            log.debug_("A key has already been generated");
            privateKey = RSAPrivateKey(loadKey(keyFile, rng));

            log.debug_("Checking if any certificate online is matching the private key...");
            auto certificates = appleAccount.listAllDevelopmentCerts!iOS(team).unwrap();
            auto sideloaderCertificates = certificates.find!((cert) => cert.machineName == applicationName);
            if (sideloaderCertificates.length != 0) {
                Vector!ubyte certContent;
                Vector!ubyte ourPublicKey = privateKey.x509SubjectPublicKey();
                foreach (cert; sideloaderCertificates) {
                    certContent = Vector!ubyte(cert.certContent);
                    auto x509cert = X509Certificate(certContent, false);
                    if (x509cert.subjectPublicKey().x509SubjectPublicKey() == ourPublicKey) {
                        log.debug_("Matching certificate found.");
                        certificate = X509Certificate(Vector!ubyte(certContent), false);
                        return;
                    }
                    // +/
                }
            }
        } else {
            log.debug_("Generating a new RSA key");
            privateKey = RSAPrivateKey(rng, 2048);

            file.write(keyFile, botan.pubkey.pkcs8.PEM_encode(privateKey));
        }

        X509CertOptions subject;
        subject.country = "US";
        subject.state = "STATE";
        subject.locality = "LOCAL";
        subject.organization = "ORGANIZATION";
        subject.common_name = "CN";

        auto certRequest = createCertReq(subject, privateKey.m_priv, "SHA-256", rng);

        log.debug_("Submitting a new certificate request to Apple...");

        auto certificateId = appleAccount.submitDevelopmentCSR!iOS(team, certRequest.PEM_encode()).unwrap();
        auto appleCertificateInfo = appleAccount.listAllDevelopmentCerts!iOS(team).unwrap().find!((cert) => cert.certificateId == certificateId)[0];
        certificate = X509Certificate(Vector!ubyte(appleCertificateInfo.certContent), false);
    }
}
