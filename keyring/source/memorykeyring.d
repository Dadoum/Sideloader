module memorykeyring;

import keyring;

class MemoryKeyring : KeyringImplementation
{
    string account;

    void store(string account)
    {
        this.account = account;
    }

    string lookup()
    {
        return account;
    }

    void clear()
    {
        account = null;
    }
}
