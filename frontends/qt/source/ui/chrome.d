/++
    Native window chrome.

    The window keeps its system frame: Windows already handles dragging,
    resizing from every edge with the right cursors, snapping, maximising and
    the shadow. Reimplementing those on a frameless window costs a lot of code
    and loses behaviour along the way.

    The only thing the system needs to be told is that the title bar should be
    dark, otherwise it stays white above a dark interface.

    dwmapi is loaded dynamically: this is cosmetic and must not become a link
    dependency, nor break on a machine where the API is missing.
+/
module ui.chrome;

version (Windows) {
    import core.sys.windows.windows;

    import core.stdc.config : cpp_long;

    private enum : DWORD {
        DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19,
        DWMWA_USE_IMMERSIVE_DARK_MODE = 20,
        DWMWA_WINDOW_CORNER_PREFERENCE = 33,
    }

    /// DWM_WINDOW_CORNER_PREFERENCE
    private enum DWMWCP_ROUND = 2;

    private alias DwmSetWindowAttributeFn =
        extern (Windows) HRESULT function(HWND, DWORD, const(void)*, DWORD) nothrow;

    private __gshared DwmSetWindowAttributeFn dwmSetWindowAttribute;
    private __gshared bool dwmResolved;
}

/++
    Switches the system title bar to its dark variant.

    `windowHandle` is the value of `QWidget.winId()`. No effect outside
    Windows, and none on builds older than Windows 10 1809, where the
    attribute is unknown and DWM just returns a failure code we ignore.
+/
void applyDarkTitleBar(size_t windowHandle) {
    version (Windows) {
        HWND hwnd = cast(HWND) windowHandle;
        if (!hwnd)
            return;

        if (!dwmResolved) {
            dwmResolved = true;
            if (auto dwmapi = LoadLibraryA("dwmapi.dll"))
                dwmSetWindowAttribute = cast(DwmSetWindowAttributeFn)
                    GetProcAddress(dwmapi, "DwmSetWindowAttribute");
        }

        if (!dwmSetWindowAttribute)
            return;

        DWORD enabled = TRUE;
        // 20 is the documented attribute; 19 is the same thing on 1809..1909.
        dwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &enabled, DWORD.sizeof);
        dwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1, &enabled, DWORD.sizeof);

        // Windows 11 only. It works here because the window keeps its frame:
        // the caption is hidden by WM_NCCALCSIZE, not by dropping the frame,
        // so the compositor still clips and shadows the window itself.
        DWORD corner = DWMWCP_ROUND;
        dwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &corner, DWORD.sizeof);
    }
}

version (Windows) {
    /// Thickness of the invisible grab strip along each edge, in pixels.
    enum resizeBorder = 8;

    /// Missing from D's Win32 bindings.
    private enum SM_CXPADDEDBORDER = 92;

    /++
        Screen coordinates carried by a WM_NCHITTEST, if that is the message.

        Exists so the caller never has to touch the Win32 MSG type: dqt
        declares its own opaque `tagMSG`, and the two collide on import.
    +/
    bool hitTestPoint(void* message, out int x, out int y) {
        auto msg = cast(MSG*) message;
        if (msg.message != WM_NCHITTEST)
            return false;

        // lParam packs the point as two signed 16-bit halves.
        x = cast(short) (msg.lParam & 0xFFFF);
        y = cast(short) ((msg.lParam >> 16) & 0xFFFF);
        return true;
    }

    /++
        Tells Windows the client area covers the whole window.

        This is what removes the system caption and its icon and title, while
        the window keeps WS_THICKFRAME. Windows therefore still owns resizing,
        snapping, the shadow and maximising — unlike Qt's FramelessWindowHint,
        which strips all of that and leaves you reimplementing it.

        Returns true when the message was handled.
    +/
    bool handleFrameRemoval(void* message, cpp_long* result) {
        auto msg = cast(MSG*) message;
        if (msg.message != WM_NCCALCSIZE || !msg.wParam)
            return false;

        auto params = cast(NCCALCSIZE_PARAMS*) msg.lParam;

        // Maximised, the window rect overhangs the screen by the frame
        // thickness. Without putting it back the content bleeds off-screen.
        if (IsZoomed(msg.hwnd)) {
            int frameX = GetSystemMetrics(SM_CXSIZEFRAME) + GetSystemMetrics(SM_CXPADDEDBORDER);
            int frameY = GetSystemMetrics(SM_CYSIZEFRAME) + GetSystemMetrics(SM_CXPADDEDBORDER);
            params.rgrc[0].left += frameX;
            params.rgrc[0].right -= frameX;
            params.rgrc[0].top += frameY;
            params.rgrc[0].bottom -= frameY;
        }

        *result = 0;
        return true;
    }

    /++
        Maps a hit test to a window edge, so Windows resizes for us.

        `captionHit` says the point belongs to our own title bar and is not on
        one of its buttons; returning HTCAPTION hands dragging, double-click
        to maximise and snapping back to the system.
    +/
    bool handleHitTest(void* message, cpp_long* result, bool captionHit) {
        auto msg = cast(MSG*) message;
        if (msg.message != WM_NCHITTEST)
            return false;

        RECT window;
        GetWindowRect(msg.hwnd, &window);

        int x = cast(short) (msg.lParam & 0xFFFF);
        int y = cast(short) ((msg.lParam >> 16) & 0xFFFF);

        bool left = x < window.left + resizeBorder;
        bool right = x >= window.right - resizeBorder;
        bool top = y < window.top + resizeBorder;
        bool bottom = y >= window.bottom - resizeBorder;

        cpp_long hit = HTCLIENT;
        if (top && left) hit = HTTOPLEFT;
        else if (top && right) hit = HTTOPRIGHT;
        else if (bottom && left) hit = HTBOTTOMLEFT;
        else if (bottom && right) hit = HTBOTTOMRIGHT;
        else if (left) hit = HTLEFT;
        else if (right) hit = HTRIGHT;
        else if (top) hit = HTTOP;
        else if (bottom) hit = HTBOTTOM;
        else if (captionHit) hit = HTCAPTION;
        else return false; // plain client area, let Qt deal with it

        *result = hit;
        return true;
    }
}
