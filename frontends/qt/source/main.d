module main;

import core.runtime;
import core.stdc.signal;
import core.stdcpp.new_: cpp_new;

import file = std.file;
import std.path;
import std.process;
import std.traits;

import std.conv : to;

import qt.core.coreapplication;
import qt.core.dir;
import qt.core.string;
import qt.core.stringlist;
import qt.gui.fontdatabase;
import qt.gui.guiapplication;
import qt.gui.icon;
import qt.widgets.application;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

import constants;
import utils;

import ui.chrome;
import ui.dependencieswindow;
import ui.mainwindow;

int main(string[] args) {
    version (linux) {
        import core.stdc.locale;
        setlocale(LC_ALL, "");
    }

    debug {
        Level level = Levels.TRACE;
    } else {
        Level level = Levels.INFO;
    }

    signal(SIGSEGV, cast(Parameters!signal[1]) &SIGSEGV_trace);

    version (Windows) {
        string configurationPath = environment["AppData"];
    } else version (OSX) {
        string configurationPath = "~/Library/Preferences/".expandTilde();
    } else {
        string configurationPath = environment.get("XDG_CONFIG_DIR")
        .orDefault("~/.config")
        .expandTilde();
    }
    configurationPath = configurationPath.buildPath(applicationName);

    version(Windows) {
        import graphical_app;
        SetUnhandledExceptionFilter(&SIGSEGV_win);

        import logging;
        // Logs go to a file as well: a GUI build has no console, and
        // OutputDebugString needs a debugger attached to be of any use.
        auto loggingProvider = new shared OutputDebugStringLoggingProvider(
            level, configurationPath.buildPath("logs"));
    } else {
        auto loggingProvider = new shared DefaultProvider(true, level);
    }
    configureLoggingProvider(loggingProvider);

    auto log = getLogger();

    log.info(versionStr);
    log.infoF!"Configuration path: %s"(configurationPath);
    scope qtApp = new QApplication(Runtime.cArgs.argc, Runtime.cArgs.argv);

    // Fusion before the stylesheet: it is the only Qt style that applies QSS
    // throughout. The native Windows style ignores part of the rules and
    // leaves mismatched controls behind.
    QApplication.setStyle(*cpp_new!QString("Fusion"));

    // The wordmark uses Poppins, which is bundled rather than assumed: no
    // Windows install ships it. Registered before the stylesheet so the
    // font-family resolves on first layout.
    string fontDir = QCoreApplication.applicationDirPath().toConstWString().to!string() ~ "/fonts/";
    foreach (fontFile; ["Poppins-Bold.ttf", "Poppins-SemiBold.ttf"]) {
        if (QFontDatabase.addApplicationFont(*cpp_new!QString(fontDir ~ fontFile)) == -1)
            log.warnF!"Could not load bundled font %s"(fontFile);
    }

    // Set on the application so every window and dialog inherits it. The
    // tray icon also reads it back off the main window via WM_GETICON.
    string brandingDir = QCoreApplication.applicationDirPath().toConstWString().to!string()
        ~ "/branding/";
    auto appIcon = QIcon(*cpp_new!QString(brandingDir ~ "sideloader.ico"));
    if (appIcon.isNull())
        log.warn("Application icon not found; falling back to the system default.");
    else
        QGuiApplication.setWindowIcon(appIcon);

    qtApp.setStyleSheet(*cpp_new!QString(import("theme.qss")));

    DependenciesWindow.ensureDeps(configurationPath, (device, adi) {
        auto w = new MainWindow(configurationPath, device, adi);

        // --tray is what the autostart entry passes: start in the
        // notification area, without a window flashing up at sign-in.
        import std.algorithm : canFind;
        bool startHidden = args.canFind("--tray");

        if (startHidden)
            w.hide();
        else
            w.show();
        // Re-applied after show(): Qt can recreate the native window while
        // realising it, which discards the DWM attribute set in the
        // constructor and leaves a white title bar.
        applyDarkTitleBar(cast(size_t) w.winId());
    });
    return qtApp.exec();
}

private class SegmentationFault: Throwable /+ Throwable since it should not be caught +/ {
    this(string file = __FILE__, size_t line = __LINE__) {
        super("Segmentation fault.", file, line);
    }
}

extern(C) void SIGSEGV_trace(int) @system {
    throw new SegmentationFault();
}
