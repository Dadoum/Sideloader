module frontend;

import core.runtime;

import file = std.file;
import std.path;
import std.process;
import std.traits;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

import dlangui;
import dlangui.core.logger;

import app.frontend;
import constants;
import utils;

import ui.mainframe;

version(Windows) {
    import logging;
    import graphical_app;
}

extern(C) int DLANGUImain(string[] args);

shared class DlangUIFrontend: Frontend {
    string _configurationPath;

    this() {
        version (Windows) {
            _configurationPath = environment["LocalAppData"];
        } else version (OSX) {
            _configurationPath = "~/Library/Preferences/".expandTilde();
        } else {
            _configurationPath = environment.get("XDG_CONFIG_DIR")
            .orDefault("~/.config")
            .expandTilde();
        }
        _configurationPath = _configurationPath.buildPath(applicationName);
    }

    override string configurationPath() {
        return _configurationPath;
    }

    override int run(string[] args) {
        version (Windows) {
            import core.sys.windows.winbase;
            SetUnhandledExceptionFilter(&SIGSEGV_win);
        }

        return DLANGUImain(args);
    }
}

Frontend makeFrontend() => new DlangUIFrontend();

version(Windows) {
    shared(LoggingProvider) makeLoggingProvider(Level rootLoggingLevel) => new shared OutputDebugStringLoggingProvider(rootLoggingLevel);
} else {
    shared(LoggingProvider) makeLoggingProvider(Level rootLoggingLevel) => new shared DefaultProvider(true, rootLoggingLevel);
}

extern (C) int UIAppMain()
{
    // Most of the time on GNOME, SDL is wrong about DPI. So we just override it.
    if (environment.get("XDG_CURRENT_DESKTOP") == "GNOME" && environment.get("XDG_SESSION_TYPE") == "wayland") {
        overrideScreenDPI(96);
    }

    Log.setStdoutLogger();

    getLogger().info("Using DlangUI frontend.");
    Window w = Platform.instance.createWindow(applicationName, null, WindowFlag.ExpandSize | WindowFlag.Resizable, 0, 0);
    w.resizeWindow(Point(350, 400));
    w.adjustWindowOrContentSize(350, 400);
    w.windowOrContentResizeMode = WindowOrContentResizeMode.shrinkWidgets;
    w.mainWidget = new MainFrame();
    w.show();

    return Platform.instance.enterMessageLoop();
}
