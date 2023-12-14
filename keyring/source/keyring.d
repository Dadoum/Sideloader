module keyring;

import libsecretkeyring;
import osxkeyring;
import windowskeyring;
import memorykeyring;

interface KeyringImplementation
{
    void store(string account);
    string lookup();
    void clear();
}

struct Keyring
{
    KeyringImplementation backend;

    void store(string account)
    {

    }
}

Keyring makeKeyring()
{
    version (Windows)
    {
        if (auto keyring = WindowsKeyring.create())
        {
            return Keyring(keyring);
        }
    }
    else version (OSX)
    {
        if (auto keyring = OSXKeyring.create())
        {
            return Keyring(keyring);
        }
    }
    else version (LibSecret)
    {
        if (auto keyring = LibSecretKeyring.create())
        {
            return Keyring(keyring);
        }
    }

    return Keyring(new MemoryKeyring());
}
