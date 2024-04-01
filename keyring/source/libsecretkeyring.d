module libsecretkeyring;

import keyring;

version (LibSecret):

import slf4d;

import gio.SimpleAsyncResult;

import glib.c.functions;
import glib.HashTable;

import secret.Password;
import secret.Schema;
import secret.Service;

import utils;

class LibSecretKeyring : KeyringImplementation
{
    Schema schema;

    this()
    {
        auto typeHashTable = new HashTable(g_str_hash, g_str_equal);
        schema = new Schema(
            "dev.dadoum.Sideloader", SchemaFlags.NONE,
            typeHashTable
        );
    }

    static LibSecretKeyring create()
    {
        return new LibSecretKeyring();
    }

    void store(string account)
    {
        auto accountEntry = new HashTable(g_str_hash, g_str_equal);
        // Password.storev(schema, accountEntry, COLLECTION_DEFAULT, "account", account, null, c!((GObject* sourceObject, GAsyncResult* res) {
        //     Password.storeFinish(new SimpleAsyncResult(cast(GSimpleAsyncResult*)res, false));
        // }).expand);
        Password.storevSync(schema, accountEntry, COLLECTION_DEFAULT, "account", account, null);
    }

    string lookup()
    {
        auto accountEntry = new HashTable(g_str_hash, g_str_equal);
        // Password.lookupv(schema, accountEntry, null, c!((GObject* sourceObject, GAsyncResult* res) {
        //
        // }).expand);
        return Password.lookupvSync(schema, accountEntry, null);
    }

    void clear()
    {
        auto accountEntry = new HashTable(g_str_hash, g_str_equal);
        Password.clearvSync(schema, accountEntry, null);
    }
}
