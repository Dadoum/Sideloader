module server.applesrpsession;

import std.bigint;
import std.digest.sha;

import slf4d;

import crypto.bigint;

import kdf.pbkdf2;

class AppleSRPSession {
    private const BigInt g;
    private const ubyte[] g_bytes;
    private const BigInt N;
    private const ubyte[] N_bytes;

    private BigInt a;
    private BigInt A;
    private ubyte[] A_bytes;

    public ubyte[] K_bytes;
    public ubyte[] M1_bytes;

    this() {
        g_bytes = [0x2];
        g = BigIntHelper.fromBytes(g_bytes); // yeah, I know, this is ridiculous
        N_bytes = [
            0xac, 0x6b, 0xdb, 0x41, 0x32, 0x4a, 0x9a, 0x9b, 0xf1, 0x66, 0xde, 0x5e, 0x13, 0x89, 0x58, 0x2f,
            0xaf, 0x72, 0xb6, 0x65, 0x19, 0x87, 0xee, 0x07, 0xfc, 0x31, 0x92, 0x94, 0x3d, 0xb5, 0x60, 0x50,
            0xa3, 0x73, 0x29, 0xcb, 0xb4, 0xa0, 0x99, 0xed, 0x81, 0x93, 0xe0, 0x75, 0x77, 0x67, 0xa1, 0x3d,
            0xd5, 0x23, 0x12, 0xab, 0x4b, 0x03, 0x31, 0x0d, 0xcd, 0x7f, 0x48, 0xa9, 0xda, 0x04, 0xfd, 0x50,
            0xe8, 0x08, 0x39, 0x69, 0xed, 0xb7, 0x67, 0xb0, 0xcf, 0x60, 0x95, 0x17, 0x9a, 0x16, 0x3a, 0xb3,
            0x66, 0x1a, 0x05, 0xfb, 0xd5, 0xfa, 0xaa, 0xe8, 0x29, 0x18, 0xa9, 0x96, 0x2f, 0x0b, 0x93, 0xb8,
            0x55, 0xf9, 0x79, 0x93, 0xec, 0x97, 0x5e, 0xea, 0xa8, 0x0d, 0x74, 0x0a, 0xdb, 0xf4, 0xff, 0x74,
            0x73, 0x59, 0xd0, 0x41, 0xd5, 0xc3, 0x3e, 0xa7, 0x1d, 0x28, 0x1e, 0x44, 0x6b, 0x14, 0x77, 0x3b,
            0xca, 0x97, 0xb4, 0x3a, 0x23, 0xfb, 0x80, 0x16, 0x76, 0xbd, 0x20, 0x7a, 0x43, 0x6c, 0x64, 0x81,
            0xf1, 0xd2, 0xb9, 0x07, 0x87, 0x17, 0x46, 0x1a, 0x5b, 0x9d, 0x32, 0xe6, 0x88, 0xf8, 0x77, 0x48,
            0x54, 0x45, 0x23, 0xb5, 0x24, 0xb0, 0xd5, 0x7d, 0x5e, 0xa7, 0x7a, 0x27, 0x75, 0xd2, 0xec, 0xfa,
            0x03, 0x2c, 0xfb, 0xdb, 0xf5, 0x2f, 0xb3, 0x78, 0x61, 0x60, 0x27, 0x90, 0x04, 0xe5, 0x7a, 0xe6,
            0xaf, 0x87, 0x4e, 0x73, 0x03, 0xce, 0x53, 0x29, 0x9c, 0xcc, 0x04, 0x1c, 0x7b, 0xc3, 0x08, 0xd8,
            0x2a, 0x56, 0x98, 0xf3, 0xa8, 0xd0, 0xc3, 0x82, 0x71, 0xae, 0x35, 0xf8, 0xe9, 0xdb, 0xfb, 0xb6,
            0x94, 0xb5, 0xc8, 0x03, 0xd8, 0x9f, 0x7a, 0xe4, 0x35, 0xde, 0x23, 0x6d, 0x52, 0x5f, 0x54, 0x75,
            0x9b, 0x65, 0xe3, 0x72, 0xfc, 0xd6, 0x8e, 0xf2, 0x0f, 0xa7, 0x11, 0x1f, 0x9e, 0x4a, 0xff, 0x73
        ];
        N = BigIntHelper.fromBytes(N_bytes);
    }

    /++
     + Returns A
     +/
    ubyte[] step1() {
        a = BigIntHelper.randomGenerate(256);
        A = powmod(g, a, N);

        A_bytes = BigIntHelper.toUBytes(A);
        return A_bytes;
    }

    /++
     + Returns M1
     +/
    ubyte[] step2(string appleId, string password, bool isS2kFo, ubyte[] B_bytes, ubyte[] salt, ulong iterations) {
        ubyte[] passwordHash = sha256Of(password).dup;
        if (isS2kFo) {
            passwordHash = cast(ubyte[]) passwordHash.toHexString();
        }

        // !!SRP variant!! pass the password through PBKDF2
        passwordHash = pbkdf2!SHA256(passwordHash, salt, cast(uint) iterations, 32);

        auto sha256 = new SHA256Digest();
        // !!SRP variant!! no username in X
        sha256.put(cast(ubyte[]) ":");
        sha256.put(passwordHash);
        auto unseasonedX = sha256.finish();
        sha256.put(salt);
        sha256.put(unseasonedX);
        auto X_bytes = sha256.finish();
        auto X = BigIntHelper.fromBytes(X_bytes);

        BigInt B = BigIntHelper.fromBytes(B_bytes);

        auto N_length = N_bytes.length;
        auto A_length = A_bytes.length;
        auto B_length = B_bytes.length;
        auto g_length = g_bytes.length;

        ubyte[] U_intermediate = new ubyte[](2*N_length);
        U_intermediate[] = 0;
        U_intermediate[(N_length - A_length)..N_length] = A_bytes;
        U_intermediate[($ - B_length)..$] = B_bytes;
        ubyte[] U_bytes = sha256Of(U_intermediate).dup;
        BigInt U = BigIntHelper.fromBytes(U_bytes);

        ubyte[] k_intermediate = new ubyte[](2*N_length);
        k_intermediate[] = 0;
        k_intermediate[0..N_length] = N_bytes;
        k_intermediate[($ - g_length)..$] = g_bytes;
        ubyte[] k_bytes = sha256Of(k_intermediate).dup;
        BigInt k = BigIntHelper.fromBytes(k_bytes);

        BigInt S = powmod((B - ((k * powmod(g, X, N)) % N)) % N, (U * X + a), N);
        // powmod preserves sign, so every other time it gives a negative number,
        // while crypto assumes only natural numbers
        if (S < 0) {
            S += N;
        }
        ubyte[] S_bytes = BigIntHelper.toUBytes(S);

        K_bytes = sha256Of(S_bytes).dup;

        auto N_hash = sha256Of(N_bytes).dup;
        auto g_padded = new ubyte[](N_length);
        g_padded[] = 0;
        g_padded[$-g_length..$] = g_bytes;
        auto g_hash = sha256Of(g_padded);

        ubyte[] xor = new ubyte[N_hash.length];
        foreach (index, ref b; xor) {
            b = N_hash[index] ^ g_hash[index];
        }

        sha256.put(xor);
        sha256.put(sha256Of(appleId));
        sha256.put(salt);
        sha256.put(A_bytes);
        sha256.put(B_bytes);
        sha256.put(K_bytes);
        return M1_bytes = sha256.finish();
    }

    bool step3(ubyte[] M2) {
        SHA256Digest sha256 = new SHA256Digest();
        sha256.put(A_bytes);
        sha256.put(M1_bytes);
        sha256.put(K_bytes);
        ubyte[] expectedM2 = sha256.finish();

        return M2 == expectedM2;
    }

    ubyte[] K() {
        return K_bytes;
    }
}
