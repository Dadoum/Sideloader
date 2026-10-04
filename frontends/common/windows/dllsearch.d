/++
    Restricts where Windows looks for DLLs loaded at runtime.

    The default LoadLibrary search order ends with %PATH%, and the requests
    library probes OpenSSL under several names in turn: it asks for
    libssl-3-x64.dll first, which Sideloader does not ship. That name then
    resolves against whatever OpenSSL happens to sit on the machine -- Git's,
    a laptop vendor's media tool, Bonjour -- and the mismatched libssl and
    libcrypto pair either refuses to load or misbehaves on the first HTTPS
    request.

    Dropping %PATH% from the search order makes the names we do not ship fail
    cleanly, so the probe falls through to the libssl-3.dll sitting next to
    the executable. It also closes the DLL hijacking hole that searching
    %PATH% opens in the first place.
+/
module dllsearch;

version (Windows):

import core.sys.windows.windef;

/// Application directory, any directory added by AddDllDirectory, and
/// System32 -- notably not %PATH% and not the current directory.
private enum DWORD LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = 0x0000_1000;

private extern (Windows) BOOL SetDefaultDllDirectories(DWORD directoryFlags) nothrow @nogc;

/++
    A CRT constructor rather than a module constructor: requests loads
    OpenSSL from its own `shared static this`, and D leaves the order of
    module constructors unspecified between modules that do not import one
    another. CRT initialisers all run before any module constructor, so this
    is the only placement that is guaranteed to win the race.
+/
pragma(crt_constructor)
extern (C) void restrictDllSearchPath() {
    SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
}
