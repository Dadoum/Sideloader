module cms.cms_dec;

import memutils.vector;

import botan.asn1.ber_dec;
import botan.asn1.oids;
import botan.codec.pem;

ubyte[] dataFromCMS(DataSource source) {
    OIDS.setDefaults();
    if (!maybeBER(source) || PEM.matches(source)) {
        source = cast(DataSource) DataSourceMemory(PEM.decodeCheckLabel(source, "PKCS7"));
    }

    Vector!AlgorithmIdentifier alg_ids;
    Vector!ubyte plistData;

    BERDecoder(source)
        .startCons(ASN1Tag.SEQUENCE)
            .decodeAndCheck(OIDS.lookup("CMS.SignedData"), "Not a CMS file")
            .startCons(ASN1Tag.UNIVERSAL, ASN1Tag.PRIVATE)
                // SignedData
                .startCons(ASN1Tag.SEQUENCE)
                    // CMSVersion
                    .decodeAndCheck!size_t(1, "Unsupported CMS version")
                    .decodeList!AlgorithmIdentifier(alg_ids, ASN1Tag.SET)
                    // CertificateList
                    .startCons(ASN1Tag.SEQUENCE)
                        .decodeAndCheck(OIDS.lookup("CMS.DataContent"), "Not a mobile provision file")
                        .startCons(ASN1Tag.UNIVERSAL, ASN1Tag.PRIVATE)
                            .decode(plistData, ASN1Tag.OCTET_STRING)
                        .verifyEnd()
                        .endCons()
                    .verifyEnd()
                    .endCons()
                .discardRemaining()
                .endCons()
            .verifyEnd()
            .endCons()
        .verifyEnd()
        .endCons();

    return plistData[].dup;
}

ubyte[] dataFromCMS(ubyte[] data)
{
    return dataFromCMS(cast(DataSource) DataSourceMemory(data.ptr, data.length));
}

/+
import memutils.vector;
public import botan.pubkey.pk_keys;
public import botan.asn1.alg_id;
public import botan.filters.pipe;
import botan.asn1.der_enc;
import botan.asn1.ber_dec;
import botan.asn1.alg_id;
import botan.asn1.asn1_attribute;
import botan.codec.pem;
import botan.pubkey.pk_algs;
import botan.utils.types;
import botan.asn1.ber_dec;
import botan.asn1.oids;
import botan.cert.x509.x509cert;
import botan.cert.x509.x509self;
import botan.pubkey.pk_keys;
import botan.asn1.oids;

static this() {
    OIDS.setDefaults();
}

struct MobileProvisionData
{
    this(ubyte[] data)
    {
        this(cast(DataSource) DataSourceMemory(data.ptr, data.length));
    }

    /++
     +  /!\ THE CODE IS MADE UNDER THE ASSUMPTION THE DATA IS TRUSTED TO BE VALID!!!!!
     +/
    this(DataSource source) {
        if (!maybeBER(source) || PEM.matches(source)) {
            source = cast(DataSource) DataSourceMemory(PEM.decodeCheckLabel(source, "PKCS7"));
        }

        Vector!AlgorithmIdentifier alg_ids;
        Vector!ubyte plistData;

        BERDecoder(source)
            .startCons(ASN1Tag.SEQUENCE)
                .decodeAndCheck(OIDS.lookup("CMS.SignedData"), "Not a CMS file")
                .startCons(ASN1Tag.UNIVERSAL, ASN1Tag.PRIVATE)
                    // SignedData
                    .startCons(ASN1Tag.SEQUENCE)
                        // CMSVersion
                        .decodeAndCheck!size_t(1, "Unsupported CMS version")
                        .decodeList!AlgorithmIdentifier(alg_ids, ASN1Tag.SET)
                        // CertificateList
                        .startCons(ASN1Tag.SEQUENCE)
                            .decodeAndCheck(OIDS.lookup("CMS.DataContent"), "Not a mobile provision file")
                            .startCons(ASN1Tag.UNIVERSAL, ASN1Tag.PRIVATE)
                                .decode(plistData, ASN1Tag.OCTET_STRING)
                            .verifyEnd()
                            .endCons()
                        .verifyEnd()
                        .endCons()
                    .discardRemaining()
                    .endCons()
                .verifyEnd()
                .endCons()
            .verifyEnd()
            .endCons();

        import slf4d;
        getLogger().info(cast(string) plistData[]);
        // auto berDecoder = BERDecoder(source);
        // BERObject cmsObject = berDecoder.getNextObject();
        // funTest(cmsObject);
    }

    void funTest(ref BERObject cmsObject, uint sz = 0) {
        BERDecoder contentDecoder = BERDecoder(cmsObject.value);
        while (contentDecoder.moreItems())
        {
            import std.stdio;
            import std.range;
            BERObject innerObject = contentDecoder.getNextObject();

            writefln!"%s%s %s"('\t'.repeat(sz), innerObject.type_tag, innerObject.value[]);

            if (innerObject.type_tag == ASN1Tag.UNIVERSAL || innerObject.type_tag == ASN1Tag.SEQUENCE) {
                funTest(innerObject, sz + 1);
            }
        }
    }
}
// +/