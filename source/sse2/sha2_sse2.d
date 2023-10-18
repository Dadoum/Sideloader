module sse2.sha2_sse2;

import botan.constants;

version (GNU) {
    enum GDC = true;
} else {
    enum GDC = false;
}

static if (BOTAN_HAS_SHA2_32 && (BOTAN_HAS_SIMD_SSE2 || GDC)):

import core.bitop: bswap;
import core.stdc.stdint;

import botan.hash.sha2_32;
import botan.hash.hash;
import std.format : format;

import inteli.smmintrin;
import inteli.shaintrin;

// Copied from botan C++
class SHA256SSE2: SHA256 {
    override HashFunction clone() const { return new SHA256SSE2; }
    this()
    {
        super();
    } // no W needed

    protected:
    /*
    * SHA-256 Compression Function using SSE for message expansion
    */
    override void compressN(const(ubyte)* input_bytes, size_t blocks)
    {
        enum const(uint32_t)[] K = [
            0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
            0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3, 0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
            0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
            0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
            0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13, 0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
            0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
            0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
            0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208, 0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2,
        ];

        const __m128i* K_mm = cast(const __m128i*) K.ptr;

        uint32_t* state = m_digest.ptr;

        __m128i* input_mm = cast(__m128i*) input_bytes;
        const __m128i MASK = _mm_set_epi64x(ulong(0x0c0d0e0f08090a0b), ulong(0x0405060700010203));

        // Load initial values
        __m128i STATE0 = _mm_loadu_si128(cast(__m128i*) &state[0]);
        __m128i STATE1 = _mm_loadu_si128(cast(__m128i*) &state[4]);

        STATE0 = _mm_shuffle_epi32!0xB1(STATE0);  // CDAB
        STATE1 = _mm_shuffle_epi32!0x1B(STATE1);  // EFGH

        __m128i TMP = _mm_alignr_epi8!8(STATE0, STATE1);  // ABEF
        STATE1 = _mm_blend_epi16!0xF0(STATE1, STATE0);    // CDGH
        STATE0 = TMP;

        while(blocks > 0) {
            // Save current state
            const __m128i ABEF_SAVE = STATE0;
            const __m128i CDGH_SAVE = STATE1;

            __m128i MSG;

            __m128i TMSG0 = _mm_shuffle_epi8(_mm_loadu_si128(input_mm), MASK);
            __m128i TMSG1 = _mm_shuffle_epi8(_mm_loadu_si128(input_mm + 1), MASK);
            __m128i TMSG2 = _mm_shuffle_epi8(_mm_loadu_si128(input_mm + 2), MASK);
            __m128i TMSG3 = _mm_shuffle_epi8(_mm_loadu_si128(input_mm + 3), MASK);

            // Rounds 0-3
            MSG = _mm_add_epi32(TMSG0, _mm_load_si128(K_mm));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            // Rounds 4-7
            MSG = _mm_add_epi32(TMSG1, _mm_load_si128(K_mm + 1));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG0 = _mm_sha256msg1_epu32(TMSG0, TMSG1);

            // Rounds 8-11
            MSG = _mm_add_epi32(TMSG2, _mm_load_si128(K_mm + 2));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG1 = _mm_sha256msg1_epu32(TMSG1, TMSG2);

            // Rounds 12-15
            MSG = _mm_add_epi32(TMSG3, _mm_load_si128(K_mm + 3));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG0 = _mm_add_epi32(TMSG0, _mm_alignr_epi8!4(TMSG3, TMSG2));
            TMSG0 = _mm_sha256msg2_epu32(TMSG0, TMSG3);
            TMSG2 = _mm_sha256msg1_epu32(TMSG2, TMSG3);

            // Rounds 16-19
            MSG = _mm_add_epi32(TMSG0, _mm_load_si128(K_mm + 4));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG1 = _mm_add_epi32(TMSG1, _mm_alignr_epi8!4(TMSG0, TMSG3));
            TMSG1 = _mm_sha256msg2_epu32(TMSG1, TMSG0);
            TMSG3 = _mm_sha256msg1_epu32(TMSG3, TMSG0);

            // Rounds 20-23
            MSG = _mm_add_epi32(TMSG1, _mm_load_si128(K_mm + 5));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG2 = _mm_add_epi32(TMSG2, _mm_alignr_epi8!4(TMSG1, TMSG0));
            TMSG2 = _mm_sha256msg2_epu32(TMSG2, TMSG1);
            TMSG0 = _mm_sha256msg1_epu32(TMSG0, TMSG1);

            // Rounds 24-27
            MSG = _mm_add_epi32(TMSG2, _mm_load_si128(K_mm + 6));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG3 = _mm_add_epi32(TMSG3, _mm_alignr_epi8!4(TMSG2, TMSG1));
            TMSG3 = _mm_sha256msg2_epu32(TMSG3, TMSG2);
            TMSG1 = _mm_sha256msg1_epu32(TMSG1, TMSG2);

            // Rounds 28-31
            MSG = _mm_add_epi32(TMSG3, _mm_load_si128(K_mm + 7));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG0 = _mm_add_epi32(TMSG0, _mm_alignr_epi8!4(TMSG3, TMSG2));
            TMSG0 = _mm_sha256msg2_epu32(TMSG0, TMSG3);
            TMSG2 = _mm_sha256msg1_epu32(TMSG2, TMSG3);

            // Rounds 32-35
            MSG = _mm_add_epi32(TMSG0, _mm_load_si128(K_mm + 8));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG1 = _mm_add_epi32(TMSG1, _mm_alignr_epi8!4(TMSG0, TMSG3));
            TMSG1 = _mm_sha256msg2_epu32(TMSG1, TMSG0);
            TMSG3 = _mm_sha256msg1_epu32(TMSG3, TMSG0);

            // Rounds 36-39
            MSG = _mm_add_epi32(TMSG1, _mm_load_si128(K_mm + 9));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG2 = _mm_add_epi32(TMSG2, _mm_alignr_epi8!4(TMSG1, TMSG0));
            TMSG2 = _mm_sha256msg2_epu32(TMSG2, TMSG1);
            TMSG0 = _mm_sha256msg1_epu32(TMSG0, TMSG1);

            // Rounds 40-43
            MSG = _mm_add_epi32(TMSG2, _mm_load_si128(K_mm + 10));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG3 = _mm_add_epi32(TMSG3, _mm_alignr_epi8!4(TMSG2, TMSG1));
            TMSG3 = _mm_sha256msg2_epu32(TMSG3, TMSG2);
            TMSG1 = _mm_sha256msg1_epu32(TMSG1, TMSG2);

            // Rounds 44-47
            MSG = _mm_add_epi32(TMSG3, _mm_load_si128(K_mm + 11));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG0 = _mm_add_epi32(TMSG0, _mm_alignr_epi8!4(TMSG3, TMSG2));
            TMSG0 = _mm_sha256msg2_epu32(TMSG0, TMSG3);
            TMSG2 = _mm_sha256msg1_epu32(TMSG2, TMSG3);

            // Rounds 48-51
            MSG = _mm_add_epi32(TMSG0, _mm_load_si128(K_mm + 12));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG1 = _mm_add_epi32(TMSG1, _mm_alignr_epi8!4(TMSG0, TMSG3));
            TMSG1 = _mm_sha256msg2_epu32(TMSG1, TMSG0);
            TMSG3 = _mm_sha256msg1_epu32(TMSG3, TMSG0);

            // Rounds 52-55
            MSG = _mm_add_epi32(TMSG1, _mm_load_si128(K_mm + 13));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG2 = _mm_add_epi32(TMSG2, _mm_alignr_epi8!4(TMSG1, TMSG0));
            TMSG2 = _mm_sha256msg2_epu32(TMSG2, TMSG1);

            // Rounds 56-59
            MSG = _mm_add_epi32(TMSG2, _mm_load_si128(K_mm + 14));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            TMSG3 = _mm_add_epi32(TMSG3, _mm_alignr_epi8!4(TMSG2, TMSG1));
            TMSG3 = _mm_sha256msg2_epu32(TMSG3, TMSG2);

            // Rounds 60-63
            MSG = _mm_add_epi32(TMSG3, _mm_load_si128(K_mm + 15));
            STATE1 = _mm_sha256rnds2_epu32(STATE1, STATE0, MSG);
            STATE0 = _mm_sha256rnds2_epu32(STATE0, STATE1, _mm_shuffle_epi32!0x0E(MSG));

            // Add values back to state
            STATE0 = _mm_add_epi32(STATE0, ABEF_SAVE);
            STATE1 = _mm_add_epi32(STATE1, CDGH_SAVE);

            input_mm += 4;
            blocks--;
        }

        STATE0 = _mm_shuffle_epi32!0x1B(STATE0);  // FEBA
        STATE1 = _mm_shuffle_epi32!0xB1(STATE1);  // DCHG

        // Save state
        _mm_storeu_si128(cast(__m128i*) &state[0], _mm_blend_epi16!0xF0(STATE0, STATE1));  // DCBA
        _mm_storeu_si128(cast(__m128i*) &state[4], _mm_alignr_epi8!8(STATE1, STATE0));     // ABEF
    }
}
