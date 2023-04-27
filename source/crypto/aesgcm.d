module crypto.aesgcm;

import std.conv;

// Here is the only reference to openssl in the login procedure.
import deimos.openssl.evp;

ubyte[] decryptGCM(ubyte[] key, ubyte[] iv, ubyte[] gmac, ubyte[] data) {
    auto ctx = EVP_CIPHER_CTX_new();
    scope(exit) EVP_CIPHER_CTX_free(ctx);

    EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), null, null, null);
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, 16, null);
    int status = EVP_DecryptInit_ex(ctx, null, null, key.ptr, iv.ptr);
    int numberOfBytes;
    EVP_DecryptUpdate(ctx, null, &numberOfBytes, gmac.ptr, cast(int) gmac.length);

    ubyte[] plaintext = new ubyte[data.length];
    status = EVP_DecryptUpdate (ctx, plaintext.ptr, &numberOfBytes, data.ptr, cast(int) data.length);
    assert(status == 1, to!string(status) ~ " != 1");
    return plaintext;
}
