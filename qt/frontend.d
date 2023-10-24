module frontend;

import file = std.file;
import std.path;
import std.process;
import std.traits;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

import constants;
import utils;

import app.frontend;

version(Windows) {
    import logging;
    import segfaulthandler;
}

shared class QtFrontend: Frontend {
    string _configurationPath;

    this() {
        version (Windows) {
            _configurationPath = environment["LocalAppData"].buildPath(applicationName);
        } else version (OSX) {
            _configurationPath = "~/Library/Preferences".expandTilde();
        } else {
            _configurationPath = environment.get("XDG_CONFIG_DIR")
                .orDefault("~/.config")
                .buildPath(applicationName)
                .expandTilde();
        }
    }

    override string configurationPath() {
        return _configurationPath;
    }

    override int run(string[] args) {
        version (Windows) {
            configureSegfaultHandler();
        }
        try {
            // Application.run(new SideloaderForm());
            return 0;
        } catch (Exception ex) {
            getLogger().errorF!"Unhandled exception: %s"(ex);
            // msgBox(ex.msg, "Unhandled exception!", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
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
