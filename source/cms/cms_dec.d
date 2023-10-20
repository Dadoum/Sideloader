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
