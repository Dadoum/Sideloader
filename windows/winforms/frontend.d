module frontend;

import std.path;
import std.process;

import dfl;

import slf4d;
import slf4d.provider;

import constants;
import app.frontend;

import logging;
import segfaulthandler;

import ui.sideloaderform;

shared class WindowsFrontend: Frontend {
    string _configurationPath;

    this() {
        Application.enableVisualStyles();
        _configurationPath = environment["LocalAppData"].buildPath(applicationName);
    }

    override string configurationPath() {
        return _configurationPath;
    }

    override int run(string[] args) {
        configureSegfaultHandler();
        try {
            Application.run(new SideloaderForm());
            return 0;
        } catch (Exception ex) {
            getLogger().errorF!"Unhandled exception: %s"(ex);
            msgBox(ex.msg, "Unhandled exception!", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
            throw ex;
        }
    }
}

Frontend makeFrontend() => new WindowsFrontend();

shared(LoggingProvider) makeLoggingProvider(Level rootLoggingLevel) => new shared OutputDebugStringLoggingProvider(rootLoggingLevel);
