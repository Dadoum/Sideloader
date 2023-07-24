module server.applesrpsession;

import botan.algo_base.symkey;
import botan.codec.hex;
import botan.hash.hash;
import botan.hash.sha2_32;
import botan.libstate.global_state;
import botan.libstate.libstate;
import botan.mac.hmac;
import botan.math.bigint.bigint;
import botan.math.numbertheory.numthry;
import botan.pbkdf.pbkdf2;
import botan.pubkey.algo.dl_group;
import botan.rng.rng;
import botan.utils.types;

class AppleSRPSession {
    private RandomNumberGenerator rng;
    private DLGroup group;

    private const BigInt* g;
    private const BigInt* p;
    const size_t p_bytes;

    private BigInt k;
    private BigInt a;
    private BigInt A_num;
    private ubyte[] A;

    private BigInt S;

    public ubyte[] K;
    public ubyte[] M1;

    enum hash_id = "SHA-256";

    this() {
        rng = RandomNumberGenerator.makeRng();
        group = DLGroup("modp/srp/2048");
        g = &group.getG();
        p = &group.getP();
        p_bytes = p.bytes();
    }

    /++
     + Returns A
     +/
    ubyte[] step1() {
        k = hashSeq(hash_id, p_bytes, p, g);
        a = BigInt(rng, 256);
        A_num = powerMod(g, &a, p);
        A = A_num.byteArray();

        return A;
    }

    /++
     + Returns M1
     +/
    ubyte[] step2(string appleId, string password, bool isS2kFo, ubyte[] B, ubyte[] salt, ulong iterations) {
        BigInt B_num = B.bigInt();
        Vector!ubyte salt_vec = salt;

        Unique!HashFunction hash_fn = globalState().algorithmFactory().makeHashFunction(hash_id);
        hash_fn.update(password);
        auto passwordHashOctetStr = hash_fn.finished();
        ubyte[] passwordHash;
        if (isS2kFo) {
            passwordHash = cast(ubyte[]) passwordHashOctetStr.hexEncode(false);
        } else {
            passwordHash = passwordHashOctetStr[].dup;
        }

        auto pbkdf2 = new PKCS5_PBKDF2(new HMAC(new SHA256()));
        auto passwordKey = pbkdf2.deriveKey(32, cast(const(string)) passwordHash, salt.ptr, salt.length, iterations);
        auto hashedPassword = passwordKey.bitsOf()[].dup;

        BigInt u = hashSeq(hash_id, p.bytes(), &A_num, &B_num);
        BigInt x = computeX(hash_id, "", cast(string) hashedPassword, salt_vec);
        BigInt ref_1 = (B_num - (k * powerMod(g, &x, p))) % (*p);
        auto ref_2_2 = (u * x);
        BigInt ref_2 = (a + ref_2_2);
        S = powerMod(&ref_1, &ref_2, p);

        hash_fn.update(S.byteArray());
        K = hash_fn.finished()[].dup;

        hash_fn.update((*p).byteArray());
        auto p_hashed = hash_fn.finished()[].dup;

        hash_fn.update(BigInt.encode1363(g, p.bytes()));
        auto g_hashed = hash_fn.finished()[].dup;

        ubyte[] xor = new ubyte[p_hashed.length];
        foreach (index, ref b; xor) {
            b = g_hashed[index] ^ p_hashed[index];
        }

        hash_fn.update(appleId);
        auto hashedAppleId = hash_fn.finished()[].dup;

        hash_fn.update(xor);
        hash_fn.update(hashedAppleId);
        hash_fn.update(salt);
        hash_fn.update(A);
        hash_fn.update(B);
        hash_fn.update(K);
        return M1 = hash_fn.finished()[].dup;
    }

    bool step3(ubyte[] M2) {
        Unique!HashFunction hash_fn = globalState().algorithmFactory().makeHashFunction(hash_id);
        hash_fn.update(A);
        hash_fn.update(M1);
        hash_fn.update(K);
        ubyte[] expectedM2 = hash_fn.finished()[].dup;

        return M2 == expectedM2;
    }
}

private:

BigInt hashSeq(in string hash_id,
    size_t pad_to,
    const(BigInt)* in1,
    const(BigInt)* in2)
{
    Unique!HashFunction hash_fn = globalState().algorithmFactory().makeHashFunction(hash_id);

    hash_fn.update(BigInt.encode1363(in1, pad_to));
    hash_fn.update(BigInt.encode1363(in2, pad_to));

    return BigInt.decode(hash_fn.finished());
}

BigInt computeX(in string hash_id,
    in string identifier,
    in string password,
    const ref Vector!ubyte salt)
{
    Unique!HashFunction hash_fn = globalState().algorithmFactory().makeHashFunction(hash_id);

    hash_fn.update(identifier);
    hash_fn.update(":");
    hash_fn.update(password);

    SecureVector!ubyte inner_h = hash_fn.finished();

    hash_fn.update(salt);
    hash_fn.update(inner_h);

    SecureVector!ubyte outer_h = hash_fn.finished();

    return BigInt.decode(outer_h);
}

import botan.math.bigint.bigint;
ubyte[] byteArray(ref const(BigInt) bigInt) {
    ubyte[] ret = new ubyte[](bigInt.bytes());
    bigInt.binaryEncode(ret.ptr);
    return ret;
}

ubyte[] byteArray(ref const(BigInt) bigInt, size_t padTo) {
    return bigInt.encode1363(&bigInt, padTo)[];
}

BigInt bigInt(ubyte[] data) {
    return BigInt.decode(data.ptr, data.length);
}