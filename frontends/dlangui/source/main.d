module main;

import core.runtime;
import core.stdc.signal;

import file = std.file;
import std.path;
import std.process;
import std.traits;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

import dlangui;
import dlangui.core.logger;

import app;
import constants;
import utils;

import ui.mainframe;
import ui.dependenciesframe;

mixin APP_ENTRY_POINT;

extern (C) int UIAppMain() {
    debug {
        Level level = Levels.TRACE;
    } else {
        Level level = Levels.INFO;
    }

    import core.thread;
    import imobiledevice;
    new Thread({
        import tools;
        auto device = new iDevice(iDevice.deviceList()[0].udid);
        auto lockdown = new LockdowndClient(device, "sideloader.trust-client");
        toolList(device);
    }).start();

    signal(SIGSEGV, cast(Parameters!signal[1]) &SIGSEGV_trace);
    version(Windows) {
        import graphical_app;
        SetUnhandledExceptionFilter(&SIGSEGV_win);

        import logging;
        auto loggingProvider = new shared OutputDebugStringLoggingProvider(level);
    } else {
        auto loggingProvider = new shared DefaultProvider(true, level);
    }

    version (Windows) {
        string configurationPath = environment["LocalAppData"];
    } else version (OSX) {
        string configurationPath = "~/Library/Preferences/".expandTilde();
    } else {
        string configurationPath = environment.get("XDG_CONFIG_DIR")
        .orDefault("~/.config")
        .expandTilde();
    }
    configurationPath = configurationPath.buildPath(applicationName);

    Log.setStdoutLogger();

    // Most of the time on GNOME, SDL is wrong about DPI. So we just override it.
    if (environment.get("XDG_CURRENT_DESKTOP") == "GNOME" && environment.get("XDG_SESSION_TYPE") == "wayland") {
        overrideScreenDPI(96);
    }

    getLogger().info("Using DlangUI frontend.");

    DependenciesFrame.ensureDeps(configurationPath, {
        Window w = Platform.instance.createWindow(applicationName, null, WindowFlag.ExpandSize | WindowFlag.Resizable, 350, 400);
        w.mainWidget = new MainFrame();
        w.windowOrContentResizeMode = WindowOrContentResizeMode.resizeWindow;
        w.show();
    });

    return Platform.instance.enterMessageLoop();
}

private class SegmentationFault: Throwable /+ Throwable since it should not be caught +/ {
    this(string file = __FILE__, size_t line = __LINE__) {
        super("Segmentation fault.", file, line);
    }
}

extern(C) void SIGSEGV_trace(int) @system {
    throw new SegmentationFault();
}

