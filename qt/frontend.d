module frontend;

import core.runtime;

import file = std.file;
import std.path;
import std.process;
import std.traits;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

import qt.core.coreapplication;
import qt.core.dir;
import qt.core.string;
import qt.core.stringlist;
import qt.widgets.application;

import app.frontend;
import constants;
import utils;

import ui.mainwindow;

version(Windows) {
    import logging;
    import segfaulthandler;
}

shared class QtFrontend: Frontend {
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
            configureSegfaultHandler();
        }
        try {
            scope qtApp = new QApplication(Runtime.cArgs.argc, Runtime.cArgs.argv);
            // version (OSX) {
            //     QDir plugInDir = QCoreApplication.applicationDirPath();
            //     plugInDir.cdUp();
            //     plugInDir.cd(QString("plugins"));
            //     QCoreApplication.setLibraryPaths(QStringList(plugInDir.absolutePath()));
            // }
            auto w = new MainWindow();
            w.show();
            return qtApp.exec();
        } catch (Exception ex) {
            getLogger().errorF!"Unhandled exception: %s"(ex);
            throw ex;
        }
    }
}

Frontend makeFrontend() => new QtFrontend();

version(Windows) {
    shared(LoggingProvider) makeLoggingProvider(Level rootLoggingLevel) => new shared OutputDebugStringLoggingProvider(rootLoggingLevel);
} else {
    shared(LoggingProvider) makeLoggingProvider(Level rootLoggingLevel) => new shared DefaultProvider(true, rootLoggingLevel);
}
