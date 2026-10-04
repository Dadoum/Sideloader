/++
    Secret storage backed by the Windows Credential Manager.

    The developer session token is a live credential for the user's Apple
    account, so it does not belong in a file next to the executable. The
    Credential Manager encrypts entries with DPAPI, tied to the Windows user
    account, and is the place users already look to revoke such things.

    Only Windows is implemented. Elsewhere the functions report failure, so
    the caller simply falls back to signing in every time rather than
    silently writing a token in the clear.
+/
module ui.credentials;

version (Windows) {
    import core.sys.windows.windows;

    import std.string : fromStringz;
    import std.utf : toUTF16z;

    pragma(lib, "advapi32");

    private enum DWORD CRED_TYPE_GENERIC = 1;
    private enum DWORD CRED_PERSIST_LOCAL_MACHINE = 2;

    private struct CREDENTIALW {
        DWORD Flags;
        DWORD Type;
        LPWSTR TargetName;
        LPWSTR Comment;
        FILETIME LastWritten;
        DWORD CredentialBlobSize;
        ubyte* CredentialBlob;
        DWORD Persist;
        DWORD AttributeCount;
        void* Attributes;
        LPWSTR TargetAlias;
        LPWSTR UserName;
    }

    /// CRED_MAX_CREDENTIAL_BLOB_SIZE. Anything larger is rejected outright,
    /// which is easy to hit: Apple's URL bag alone is five times this.
    private enum maxBlobSize = 2560;

    private extern (Windows) nothrow @nogc {
        BOOL CredWriteW(CREDENTIALW* credential, DWORD flags);
        BOOL CredReadW(LPCWSTR targetName, DWORD type, DWORD flags, CREDENTIALW** credential);
        BOOL CredDeleteW(LPCWSTR targetName, DWORD type, DWORD flags);
        void CredFree(void* buffer);
    }
}

/++
    Writes a secret under `target`, replacing any previous value.

    Returns false if the store refused it, or on a platform without one.
+/
bool storeSecret(string target, string userName, string secret) {
    version (Windows) {
        auto blob = cast(ubyte[]) secret.dup;

        if (blob.length > maxBlobSize) {
            import slf4d;
            getLogger().errorF!
                "Secret is %d bytes; the Credential Manager caps entries at %d."
                (blob.length, maxBlobSize);
            return false;
        }

        CREDENTIALW credential;
        credential.Type = CRED_TYPE_GENERIC;
        credential.TargetName = cast(LPWSTR) target.toUTF16z();
        credential.UserName = cast(LPWSTR) userName.toUTF16z();
        credential.CredentialBlobSize = cast(DWORD) blob.length;
        credential.CredentialBlob = blob.ptr;
        credential.Persist = CRED_PERSIST_LOCAL_MACHINE;

        if (CredWriteW(&credential, 0))
            return true;

        import slf4d;
        getLogger().errorF!"CredWriteW failed with error %d."(GetLastError());
        return false;
    } else {
        return false;
    }
}

/// Reads the secret stored under `target`, or null if there is none.
string loadSecret(string target) {
    version (Windows) {
        CREDENTIALW* credential;
        if (!CredReadW(target.toUTF16z(), CRED_TYPE_GENERIC, 0, &credential))
            return null;

        scope(exit) CredFree(credential);

        if (credential.CredentialBlobSize == 0 || credential.CredentialBlob is null)
            return null;

        // Copied out before CredFree reclaims the buffer.
        return (cast(char*) credential.CredentialBlob)[0 .. credential.CredentialBlobSize].idup;
    } else {
        return null;
    }
}

/// Removes the secret stored under `target`. Absent entries are not an error.
void forgetSecret(string target) {
    version (Windows) {
        CredDeleteW(target.toUTF16z(), CRED_TYPE_GENERIC, 0);
    }
}
