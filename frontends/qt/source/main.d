module main;

import core.runtime;
import core.stdc.signal;

import file = std.file;
import std.path;
import std.process;
import std.traits;

import qt.core.coreapplication;
import qt.core.dir;
import qt.core.string;
import qt.core.stringlist;
import qt.widgets.application;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

version(Windows) {
    import graphical_app;
}

import constants;
import utils;

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
    configureLoggingProvider(new shared DefaultProvider(true, level));

    version (Windows) {
        configureSegfaultHandler();
    }

    scope qtApp = new QApplication(Runtime.cArgs.argc, Runtime.cArgs.argv);
    auto w = new MainWindow();
    w.show();
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
