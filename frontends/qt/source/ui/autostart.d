/++
    Start on sign-in.

    Uses the per-user Run key rather than a Windows service. A service runs
    without a desktop session, which is useless here: renewing needs the
    device plugged in, and any prompt needs someone to answer it. What is
    wanted is a background app, and that is what Run gives.
+/
module ui.autostart;

version (Windows) {
    import core.sys.windows.windows;

    import std.utf : toUTF16z;

    pragma(lib, "advapi32");

    private enum runKey = `Software\Microsoft\Windows\CurrentVersion\Run`;
    private enum valueName = "Sideloader";
}

/// Whether Sideloader is registered to start with the session.
bool isAutostartEnabled() {
    version (Windows) {
        HKEY key;
        if (RegOpenKeyExW(HKEY_CURRENT_USER, runKey.toUTF16z(), 0, KEY_READ, &key) != ERROR_SUCCESS)
            return false;

        scope(exit) RegCloseKey(key);

        DWORD size;
        return RegQueryValueExW(key, valueName.toUTF16z(), null, null, null, &size) == ERROR_SUCCESS;
    } else {
        return false;
    }
}

/++
    Registers or removes the autostart entry.

    `executablePath` is quoted: without it a path containing a space, which
    every install under Program Files has, is read as a command plus
    arguments.
+/
bool setAutostartEnabled(bool enabled, string executablePath) {
    version (Windows) {
        HKEY key;
        if (RegCreateKeyExW(HKEY_CURRENT_USER, runKey.toUTF16z(), 0, null, 0,
                KEY_WRITE, null, &key, null) != ERROR_SUCCESS)
            return false;

        scope(exit) RegCloseKey(key);

        if (!enabled)
            return RegDeleteValueW(key, valueName.toUTF16z()) == ERROR_SUCCESS;

        string command = `"` ~ executablePath ~ `" --tray`;
        auto encoded = command.toUTF16z();
        DWORD bytes = cast(DWORD) ((command.length + 1) * wchar.sizeof);

        return RegSetValueExW(key, valueName.toUTF16z(), 0, REG_SZ,
            cast(const(ubyte)*) encoded, bytes) == ERROR_SUCCESS;
    } else {
        return false;
    }
}
