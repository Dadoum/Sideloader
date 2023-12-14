module windowskeyring;

import core.sys.windows.winbase;
import core.sys.windows.windef;
import windows.win32.security.credentials;

import std.format;

import slf4d;

import keyring;

version (Windows):

class WindowsKeyring : KeyringImplementation
{
    this()
    {
    }

    static WindowsKeyring create()
    {
        return new WindowsKeyring;
    }

    private static wchar* targetName()
    {
        DWORD length;
        GetUserNameW(null, &length);
        wchar[] username = new wchar[](length);
        GetUserNameW(username.ptr, &length);

        return cast(wchar*) format!"%s.sideloader-account\0"w(username[0..$ - 1]).ptr;
    }

    void store(string account)
    {
        CREDENTIALW cred = {
            Comment: cast(wchar*) "Sideloader\0"w.ptr,
            CredentialBlobSize: cast(DWORD) account.length,
            CredentialBlob: cast(ubyte*) account.ptr,
            Type: CRED_TYPE_GENERIC,
            TargetName: targetName(),
            Persist: CRED_PERSIST_ENTERPRISE
        };

        auto result = CredWriteW(&cred, 0);
        if (!result)
        {
            getLogger.error("Cannot save the account in the Windows Credential Manager.");
        }
    }

    string lookup()
    {
        CREDENTIALW* cred;
        auto result = CredReadW(targetName(), CRED_TYPE_GENERIC, 0, &cred);
        if (!result)
        {
            return null;
        }
        scope(exit) CredFree(cred);
        return cast(string) cred.CredentialBlob[0..cred.CredentialBlobSize];
    }

    void clear()
    {
        if (!CredDeleteW(targetName(), CRED_TYPE_GENERIC, 0))
        {
            getLogger.warn("Cannot delete the account from the Windows Credential Manager.");
        }
    }
}
