module sse2;

import botan.constants;
import botan.engine.engine;
import botan.utils.cpuid;

import sse2.sha1_sse2;
import sse2.sha2_sse2;

/**
* Engine for implementations that use some kind of SIMD
*/
final class SHA256SIMDEngine : Engine
{
    public:
    string providerName() const { return "aes_isa"; } // HACK: get priority over all the other engines.

    BlockCipher findBlockCipher(in SCANToken request, AlgorithmFactory) const
    {
        return null;
    }

    HashFunction findHash(in SCANToken request, AlgorithmFactory) const
    {
        static if (BOTAN_HAS_SHA1 && BOTAN_HAS_SIMD_SSE2) {
            if (request.algoName == "SHA-160" && CPUID.hasSse2())
                return new SHA160SSE2_2;
        }

        static if (BOTAN_HAS_SHA2_32 && BOTAN_HAS_SIMD_SSE2) {
            if (request.algoName == "SHA-256" && CPUID.hasSse2())
                return new SHA256SSE2;
        }

        return null;
    }


    StreamCipher findStreamCipher(in SCANToken algo_spec, AlgorithmFactory af) const
    { return null; }

    MessageAuthenticationCode findMac(in SCANToken algo_spec, AlgorithmFactory af) const
    { return null; }

    PBKDF findPbkdf(in SCANToken algo_spec, AlgorithmFactory af) const
    { return null; }

    KeyedFilter getCipher(in string algo_spec, CipherDir dir, AlgorithmFactory af) const
    { return null; }

    static if (BOTAN_HAS_PUBLIC_KEY_CRYPTO):

        ModularExponentiator modExp(const(BigInt)* n, PowerMod.UsageHints hints) const
        { return null; }

        KeyAgreement getKeyAgreementOp(in PrivateKey key, RandomNumberGenerator rng) const
        { return null; }

        Signature getSignatureOp(in PrivateKey key, RandomNumberGenerator rng) const
        { return null; }

        Verification getVerifyOp(in PublicKey key, RandomNumberGenerator rng) const
        { return null; }

        Encryption getEncryptionOp(in PublicKey key, RandomNumberGenerator rng) const
        { return null; }

        Decryption getDecryptionOp(in PrivateKey key, RandomNumberGenerator rng) const
        { return null; }
}

void register() {
    import botan.libstate.libstate;
    globalState().algorithmFactory().addEngine(new SHA256SIMDEngine);
}
