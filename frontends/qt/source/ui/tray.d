/++
    Notification-area icon.

    dqt exposes no QSystemTrayIcon, so the icon itself is registered through
    Shell_NotifyIconW. Only the icon is native: the menu it opens is a QMenu,
    styled by the application stylesheet like every other menu, which a Win32
    HMENU could not be.

    Mouse activity on the icon arrives as a user-defined message on the main
    window, which already overrides nativeEvent to handle the frame.
+/
module ui.tray;

version (Windows) {
    import core.sys.windows.windows;

    import std.utf : toUTF16;

    pragma(lib, "shell32");

    /// Delivered to the owner window when the icon is clicked.
    enum UINT WM_SIDELOADER_TRAY = WM_APP + 1;

    private enum uint iconId = 1;

    private enum : DWORD {
        NIM_ADD = 0,
        NIM_MODIFY = 1,
        NIM_DELETE = 2,
    }

    private enum : UINT {
        NIF_MESSAGE = 0x01,
        NIF_ICON = 0x02,
        NIF_TIP = 0x04,
        NIF_INFO = 0x10,
    }

    private struct NOTIFYICONDATAW {
        DWORD cbSize;
        HWND hWnd;
        UINT uID;
        UINT uFlags;
        UINT uCallbackMessage;
        HICON hIcon;
        WCHAR[128] szTip;
        DWORD dwState;
        DWORD dwStateMask;
        WCHAR[256] szInfo;
        UINT uVersion;
        WCHAR[64] szInfoTitle;
        DWORD dwInfoFlags;
        GUID guidItem;
        HICON hBalloonIcon;
    }

    private extern (Windows) nothrow @nogc {
        BOOL Shell_NotifyIconW(DWORD message, NOTIFYICONDATAW* data);
    }

    private __gshared HWND ownerWindow;
    private __gshared bool iconInstalled;

    private void copyInto(WCHAR[] destination, string text) {
        auto encoded = text.toUTF16();
        size_t count = encoded.length < destination.length - 1
            ? encoded.length
            : destination.length - 1;
        destination[0 .. count] = encoded[0 .. count];
        destination[count] = 0;
    }

    private NOTIFYICONDATAW baseData(HWND hwnd) {
        NOTIFYICONDATAW data;
        data.cbSize = NOTIFYICONDATAW.sizeof;
        data.hWnd = hwnd;
        data.uID = iconId;
        return data;
    }
}

/++
    Puts the icon in the notification area.

    `windowHandle` is the value of `QWidget.winId()` for the window that will
    receive WM_SIDELOADER_TRAY. Returns false where there is no tray.
+/
bool installTrayIcon(size_t windowHandle, string tooltip) {
    version (Windows) {
        HWND hwnd = cast(HWND) windowHandle;
        if (!hwnd)
            return false;

        ownerWindow = hwnd;

        auto data = baseData(hwnd);
        data.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
        data.uCallbackMessage = WM_SIDELOADER_TRAY;
        // The window icon is reused so the tray matches the taskbar; falls
        // back to the shell's default when the window has none.
        data.hIcon = cast(HICON) SendMessageW(hwnd, WM_GETICON, ICON_SMALL, 0);
        if (!data.hIcon)
            data.hIcon = LoadIconW(null, IDI_APPLICATION);
        copyInto(data.szTip[], tooltip);

        iconInstalled = Shell_NotifyIconW(NIM_ADD, &data) != 0;
        return iconInstalled;
    } else {
        return false;
    }
}

/// Removes the icon. Leaving it behind would strand a dead icon in the tray
/// until the user hovers over it.
void removeTrayIcon() {
    version (Windows) {
        if (!iconInstalled)
            return;

        auto data = baseData(ownerWindow);
        Shell_NotifyIconW(NIM_DELETE, &data);
        iconInstalled = false;
    }
}

/// Shows a balloon notification from the icon.
void showTrayMessage(string title, string message) {
    version (Windows) {
        if (!iconInstalled)
            return;

        auto data = baseData(ownerWindow);
        data.uFlags = NIF_INFO;
        copyInto(data.szInfoTitle[], title);
        copyInto(data.szInfo[], message);
        Shell_NotifyIconW(NIM_MODIFY, &data);
    }
}

/++
    Whether a message is a tray click that should open the menu.

    Both buttons open it: the left button has no other job here, and users
    reach for either.
+/
bool isTrayMenuRequest(void* message) {
    version (Windows) {
        auto msg = cast(MSG*) message;
        if (msg.message != WM_SIDELOADER_TRAY)
            return false;

        auto event = cast(UINT) (msg.lParam & 0xFFFF);
        return event == WM_LBUTTONUP || event == WM_RBUTTONUP;
    } else {
        return false;
    }
}

/// Cursor position in screen coordinates, for placing the menu.
void trayCursorPosition(out int x, out int y) {
    version (Windows) {
        POINT point;
        GetCursorPos(&point);
        x = point.x;
        y = point.y;
    }
}
