module frontend;

import std.path;
import std.process;

import dfl;

import slf4d;
import slf4d.provider;

import constants;
import app.frontend;

import logging;
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
        Application.run(new SideloaderForm());
        return 0;
    }
}

Frontend makeFrontend() => new WindowsFrontend();

shared(LoggingProvider) makeLoggingProvider(Level rootLoggingLevel) => new shared OutputDebugStringLoggingProvider(rootLoggingLevel);
pragma(linkerDirective, "/SUBSYSTEM:WINDOWS");
static if (__VERSION__ >= 2091)
    pragma(linkerDirective, "/ENTRY:wmainCRTStartup");
else
    pragma(linkerDirective, "/ENTRY:mainCRTStartup");
