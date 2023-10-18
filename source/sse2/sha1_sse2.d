module sse2.sha1_sse2;

import botan.constants;

version (GNU) {
    enum GDC = true;
} else {
    enum GDC = false;
}

static if (BOTAN_HAS_SHA1 && (BOTAN_HAS_SIMD_SSE2 || GDC)):

import botan.hash.sha160;
import botan.utils.rotate;
import botan.hash.hash;
import std.format : format;

import inteli.smmintrin;
import inteli.shaintrin;

/**
* SHA-160 using SSE2 for the message expansion
*/
class SHA160SSE2_2 : SHA160
{
    public:
    override HashFunction clone() const { return new SHA160SSE2_2; }
    this()
    {
        super(0);
    } // no W needed

    protected:
    /*
    * SHA-160 Compression Function using SSE for message expansion
    */
    override void compressN(const(ubyte)* input_bytes, size_t blocks)
    {
        const(__m128i) K00_19 = _mm_set1_epi32(0x5A827999);
        const(__m128i) K20_39 = _mm_set1_epi32(0x6ED9EBA1);
        const(__m128i) K40_59 = _mm_set1_epi32(0x8F1BBCDC);
        const(__m128i) K60_79 = _mm_set1_epi32(0xCA62C1D6);

        uint A = m_digest[0],
        B = m_digest[1],
        C = m_digest[2],
        D = m_digest[3],
        E = m_digest[4];

        __m128i* input = cast(__m128i*)(input_bytes);

        foreach (size_t i; 0 .. blocks)
        {
            union v4si {
                uint[4] u32;
                __m128i u128;
            }

            v4si P0, P1, P2, P3;

            __m128i W0 = _mm_loadu_si128(input);
            mixin(prep00_15!(P0, W0));

            __m128i W1 = _mm_loadu_si128(&input[1]);
            mixin(prep00_15!(P1, W1));

            __m128i W2 = _mm_loadu_si128(&input[2]);
            mixin(prep00_15!(P2, W2));

            __m128i W3 = _mm_loadu_si128(&input[3]);
            mixin(prep00_15!(P3, W3));


            mixin(`
        F1(A, B, C, D, E, ` ~ GET_P_32!(P0, 0) ~ `);
        F1(E, A, B, C, D, ` ~ GET_P_32!(P0, 1) ~ `);
        F1(D, E, A, B, C, ` ~ GET_P_32!(P0, 2) ~ `);
        F1(C, D, E, A, B, ` ~ GET_P_32!(P0, 3) ~ `);
        ` ~ prep!(P0, W0, W1, W2, W3, K00_19) ~ `

        F1(B, C, D, E, A, ` ~ GET_P_32!(P1, 0) ~ `);
        F1(A, B, C, D, E, ` ~ GET_P_32!(P1, 1) ~ `);
        F1(E, A, B, C, D, ` ~ GET_P_32!(P1, 2) ~ `);
        F1(D, E, A, B, C, ` ~ GET_P_32!(P1, 3) ~ `);
        ` ~ prep!(P1, W1, W2, W3, W0, K20_39) ~ `

        F1(C, D, E, A, B, ` ~ GET_P_32!(P2, 0) ~ `);
        F1(B, C, D, E, A, ` ~ GET_P_32!(P2, 1) ~ `);
        F1(A, B, C, D, E, ` ~ GET_P_32!(P2, 2) ~ `);
        F1(E, A, B, C, D, ` ~ GET_P_32!(P2, 3) ~ `);
        ` ~ prep!(P2, W2, W3, W0, W1, K20_39) ~ `

        F1(D, E, A, B, C, ` ~ GET_P_32!(P3, 0) ~ `);
        F1(C, D, E, A, B, ` ~ GET_P_32!(P3, 1) ~ `);
        F1(B, C, D, E, A, ` ~ GET_P_32!(P3, 2) ~ `);
        F1(A, B, C, D, E, ` ~ GET_P_32!(P3, 3) ~ `);
        ` ~ prep!(P3, W3, W0, W1, W2, K20_39) ~ `

        F1(E, A, B, C, D, ` ~ GET_P_32!(P0, 0) ~ `);
        F1(D, E, A, B, C, ` ~ GET_P_32!(P0, 1) ~ `);
        F1(C, D, E, A, B, ` ~ GET_P_32!(P0, 2) ~ `);
        F1(B, C, D, E, A, ` ~ GET_P_32!(P0, 3) ~ `);
        ` ~ prep!(P0, W0, W1, W2, W3, K20_39) ~ `

        F2(A, B, C, D, E, ` ~ GET_P_32!(P1, 0) ~ `);
        F2(E, A, B, C, D, ` ~ GET_P_32!(P1, 1) ~ `);
        F2(D, E, A, B, C, ` ~ GET_P_32!(P1, 2) ~ `);
        F2(C, D, E, A, B, ` ~ GET_P_32!(P1, 3) ~ `);
        ` ~ prep!(P1, W1, W2, W3, W0, K20_39) ~ `

        F2(B, C, D, E, A, ` ~ GET_P_32!(P2, 0) ~ `);
        F2(A, B, C, D, E, ` ~ GET_P_32!(P2, 1) ~ `);
        F2(E, A, B, C, D, ` ~ GET_P_32!(P2, 2) ~ `);
        F2(D, E, A, B, C, ` ~ GET_P_32!(P2, 3) ~ `);
        ` ~ prep!(P2, W2, W3, W0, W1, K40_59) ~ `

        F2(C, D, E, A, B, ` ~ GET_P_32!(P3, 0) ~ `);
        F2(B, C, D, E, A, ` ~ GET_P_32!(P3, 1) ~ `);
        F2(A, B, C, D, E, ` ~ GET_P_32!(P3, 2) ~ `);
        F2(E, A, B, C, D, ` ~ GET_P_32!(P3, 3) ~ `);
        ` ~ prep!(P3, W3, W0, W1, W2, K40_59) ~ `

        F2(D, E, A, B, C, ` ~ GET_P_32!(P0, 0) ~ `);
        F2(C, D, E, A, B, ` ~ GET_P_32!(P0, 1) ~ `);
        F2(B, C, D, E, A, ` ~ GET_P_32!(P0, 2) ~ `);
        F2(A, B, C, D, E, ` ~ GET_P_32!(P0, 3) ~ `);
        ` ~ prep!(P0, W0, W1, W2, W3, K40_59) ~ `

        F2(E, A, B, C, D, ` ~ GET_P_32!(P1, 0) ~ `);
        F2(D, E, A, B, C, ` ~ GET_P_32!(P1, 1) ~ `);
        F2(C, D, E, A, B, ` ~ GET_P_32!(P1, 2) ~ `);
        F2(B, C, D, E, A, ` ~ GET_P_32!(P1, 3) ~ `);
        ` ~ prep!(P1, W1, W2, W3, W0, K40_59) ~ `

        F3(A, B, C, D, E, ` ~ GET_P_32!(P2, 0) ~ `);
        F3(E, A, B, C, D, ` ~ GET_P_32!(P2, 1) ~ `);
        F3(D, E, A, B, C, ` ~ GET_P_32!(P2, 2) ~ `);
        F3(C, D, E, A, B, ` ~ GET_P_32!(P2, 3) ~ `);
        ` ~ prep!(P2, W2, W3, W0, W1, K40_59) ~ `

        F3(B, C, D, E, A, ` ~ GET_P_32!(P3, 0) ~ `);
        F3(A, B, C, D, E, ` ~ GET_P_32!(P3, 1) ~ `);
        F3(E, A, B, C, D, ` ~ GET_P_32!(P3, 2) ~ `);
        F3(D, E, A, B, C, ` ~ GET_P_32!(P3, 3) ~ `);
        ` ~ prep!(P3, W3, W0, W1, W2, K60_79) ~ `

        F3(C, D, E, A, B, ` ~ GET_P_32!(P0, 0) ~ `);
        F3(B, C, D, E, A, ` ~ GET_P_32!(P0, 1) ~ `);
        F3(A, B, C, D, E, ` ~ GET_P_32!(P0, 2) ~ `);
        F3(E, A, B, C, D, ` ~ GET_P_32!(P0, 3) ~ `);
        ` ~ prep!(P0, W0, W1, W2, W3, K60_79) ~ `

        F3(D, E, A, B, C, ` ~ GET_P_32!(P1, 0) ~ `);
        F3(C, D, E, A, B, ` ~ GET_P_32!(P1, 1) ~ `);
        F3(B, C, D, E, A, ` ~ GET_P_32!(P1, 2) ~ `);
        F3(A, B, C, D, E, ` ~ GET_P_32!(P1, 3) ~ `);
        ` ~ prep!(P1, W1, W2, W3, W0, K60_79) ~ `

        F3(E, A, B, C, D, ` ~ GET_P_32!(P2, 0) ~ `);
        F3(D, E, A, B, C, ` ~ GET_P_32!(P2, 1) ~ `);
        F3(C, D, E, A, B, ` ~ GET_P_32!(P2, 2) ~ `);
        F3(B, C, D, E, A, ` ~ GET_P_32!(P2, 3) ~ `);
        ` ~ prep!(P2, W2, W3, W0, W1, K60_79) ~ `

        F4(A, B, C, D, E, ` ~ GET_P_32!(P3, 0) ~ `);
        F4(E, A, B, C, D, ` ~ GET_P_32!(P3, 1) ~ `);
        F4(D, E, A, B, C, ` ~ GET_P_32!(P3, 2) ~ `);
        F4(C, D, E, A, B, ` ~ GET_P_32!(P3, 3) ~ `);
        ` ~ prep!(P3, W3, W0, W1, W2, K60_79) ~ `

        F4(B, C, D, E, A, ` ~ GET_P_32!(P0, 0) ~ `);
        F4(A, B, C, D, E, ` ~ GET_P_32!(P0, 1) ~ `);
        F4(E, A, B, C, D, ` ~ GET_P_32!(P0, 2) ~ `);
        F4(D, E, A, B, C, ` ~ GET_P_32!(P0, 3) ~ `);

        F4(C, D, E, A, B, ` ~ GET_P_32!(P1, 0) ~ `);
        F4(B, C, D, E, A, ` ~ GET_P_32!(P1, 1) ~ `);
        F4(A, B, C, D, E, ` ~ GET_P_32!(P1, 2) ~ `);
        F4(E, A, B, C, D, ` ~ GET_P_32!(P1, 3) ~ `);

        F4(D, E, A, B, C, ` ~ GET_P_32!(P2, 0) ~ `);
        F4(C, D, E, A, B, ` ~ GET_P_32!(P2, 1) ~ `);
        F4(B, C, D, E, A, ` ~ GET_P_32!(P2, 2) ~ `);
        F4(A, B, C, D, E, ` ~ GET_P_32!(P2, 3) ~ `);

        F4(E, A, B, C, D, ` ~ GET_P_32!(P3, 0) ~ `);
        F4(D, E, A, B, C, ` ~ GET_P_32!(P3, 1) ~ `);
        F4(C, D, E, A, B, ` ~ GET_P_32!(P3, 2) ~ `);
        F4(B, C, D, E, A, ` ~ GET_P_32!(P3, 3) ~ `);`);

            A = (m_digest[0] += A);
            B = (m_digest[1] += B);
            C = (m_digest[2] += C);
            D = (m_digest[3] += D);
            E = (m_digest[4] += E);

            input += (hashBlockSize / 16);
        }
    }

}


private:

/*
* First 16 bytes just need ubyte swapping. Preparing just means
* adding in the round constants.
*/

/*
    Using SSE4; slower on Core2 and Nehalem
    #define GET_P_32(P, i) _mm_extract_epi32(P.u128, i)

    Much slower on all tested platforms
    #define GET_P_32(P,i) _mm_cvtsi128_si32(_mm_srli_si128(P.u128, i*4))
*/
enum string GET_P_32(alias P, ubyte i) =
BOTAN_FORCE_SSE4
? `_mm_extract_epi32(` ~ __traits(identifier, P).stringof ~ `.u128, ` ~ i.stringof ~ `)`
: __traits(identifier, P) ~ `.u32[` ~ i.stringof ~ `]`;

enum string prep00_15(alias P, alias _W) = q{
    {
        enum SHUF = _MM_SHUFFLE(2, 3, 0, 1);
        %1$s = _mm_shufflehi_epi16!SHUF(%1$s);
        %1$s = _mm_shufflelo_epi16!SHUF(%1$s);
        %1$s = _mm_or_si128(_mm_slli_epi16(%1$s, 8), _mm_srli_epi16(%1$s, 8));
        %2$s.u128 = _mm_add_epi32(%1$s, K00_19);
    }
}.format(__traits(identifier, _W), __traits(identifier, P));

/*
For each multiple of 4, t, we want to calculate this:

W[t+0] = rol(W[t-3] ^ W[t-8] ^ W[t-14] ^ W[t-16], 1);
W[t+1] = rol(W[t-2] ^ W[t-7] ^ W[t-13] ^ W[t-15], 1);
W[t+2] = rol(W[t-1] ^ W[t-6] ^ W[t-12] ^ W[t-14], 1);
W[t+3] = rol(W[t]    ^ W[t-5] ^ W[t-11] ^ W[t-13], 1);

we'll actually calculate this:

W[t+0] = rol(W[t-3] ^ W[t-8] ^ W[t-14] ^ W[t-16], 1);
W[t+1] = rol(W[t-2] ^ W[t-7] ^ W[t-13] ^ W[t-15], 1);
W[t+2] = rol(W[t-1] ^ W[t-6] ^ W[t-12] ^ W[t-14], 1);
W[t+3] = rol(  0     ^ W[t-5] ^ W[t-11] ^ W[t-13], 1);
W[t+3] ^= rol(W[t+0], 1);

the parameters are:

W0 = &W[t-16];
W1 = &W[t-12];
W2 = &W[t- 8];
W3 = &W[t- 4];

and on output:
prepared = W0 + K
W0 = W[t]..W[t+3]
*/

/* note that there is a step here where i want to do a rol by 1, which
* normally would look like this:
*
* r1 = psrld r0,$31
* r0 = pslld r0,$1
* r0 = por r0,r1
*
* but instead i do this:
*
* r1 = pcmpltd r0,zero
* r0 = paddd r0,r0
* r0 = psub r0,r1
*
* because pcmpltd and paddd are availabe in both MMX units on
* efficeon, pentium-m, and opteron but shifts are available in
* only one unit.
*/
string prep(alias _prep, alias _XW0, alias _XW1, alias _XW2, alias _XW3, alias _K)()
{
    enum prep = __traits(identifier, _prep);
    enum XW0 = __traits(identifier, _XW0);
    enum XW1 = __traits(identifier, _XW1);
    enum XW2 = __traits(identifier, _XW2);
    enum XW3 = __traits(identifier, _XW3);
    enum K = __traits(identifier, _K);
    return `{
                __m128i r0, r1, r2, r3;

                /* load W[t-4] 16-ubyte aligned, and shift */
                r3 = _mm_srli_si128!4(` ~ XW3 ~ `);
                r0 = ` ~ XW0 ~ `;
                /* get high 64-bits of XW0 into low 64-bits */
                r1 = _mm_shuffle_epi32!(_MM_SHUFFLE(1,0,3,2))(` ~ XW0 ~ `);
                /* load high 64-bits of r1 */
                r1 = _mm_unpacklo_epi64(r1, ` ~ XW1 ~ `);
                r2 = ` ~ XW2 ~ `;
                r0 = _mm_xor_si128(r1, r0);
                r2 = _mm_xor_si128(r3, r2);
                r0 = _mm_xor_si128(r2, r0);
                /* unrotated W[t]..W[t+2] in r0 ... still need W[t+3] */

                r2 = _mm_slli_si128!12(r0);
                r1 = _mm_cmplt_epi32(r0, _mm_setzero_si128());
                r0 = _mm_add_epi32(r0, r0);    /* shift left by 1 */
                r0 = _mm_sub_epi32(r0, r1);    /* r0 has W[t]..W[t+2] */

                r3 = _mm_srli_epi32(r2, 30);
                r2 = _mm_slli_epi32(r2, 2);
                r0 = _mm_xor_si128(r0, r3);
                r0 = _mm_xor_si128(r0, r2);    /* r0 now has W[t+3] */
                ` ~ XW0 ~ ` = r0;
                ` ~ prep ~ `.u128 = _mm_add_epi32(r0, ` ~ K ~ `);
        }`;
}

pure:

/*
* SHA-160 F1 Function
*/
void F1(uint A, ref uint B, uint C, uint D, ref uint E, uint msg)
{
    E += (D ^ (B & (C ^ D))) + msg + rotateLeft(A, 5);
    B  = rotateLeft(B, 30);
}

/*
* SHA-160 F2 Function
*/
void F2(uint A, ref uint B, uint C, uint D, ref uint E, uint msg)
{
    E += (B ^ C ^ D) + msg + rotateLeft(A, 5);
    B  = rotateLeft(B, 30);
}

/*
* SHA-160 F3 Function
*/
void F3(uint A, ref uint B, uint C, uint D, ref uint E, uint msg)
{
    E += ((B & C) | ((B | C) & D)) + msg + rotateLeft(A, 5);
    B  = rotateLeft(B, 30);
}

/*
* SHA-160 F4 Function
*/
void F4(uint A, ref uint B, uint C, uint D, ref uint E, uint msg)
{
    E += (B ^ C ^ D) + msg + rotateLeft(A, 5);
    B  = rotateLeft(B, 30);
}
