module logging;

import core.sys.windows.winbase;

import std.string;

import slf4d;
import slf4d.default_provider;
import slf4d.default_provider.formatters;
import slf4d.handler;
import slf4d.provider;
import slf4d.writer;

class OutputDebugStringLogHandler : LogHandler {
    public shared void handle(immutable LogMessage msg) {
        string logStr = formatLogMessage(msg, false) ~ "\n";
        // if (msg.level.value >= Levels.ERROR.value) {
            // OutputDebugStringA(logStr.toStringz());
        // } else {
            OutputDebugStringA(logStr.toStringz());
        // }
    }
}

class OutputDebugStringLoggingProvider : LoggingProvider {
    private shared DefaultLoggerFactory loggerFactory;

    /++
        OutputDebugString alone is only readable with a debugger attached,
        which makes a released GUI build impossible to diagnose: there is no
        console for stdout to reach. When a directory is given, the same
        messages are also written to a rotating file there.
    +/
    public shared this(Level rootLoggingLevel = Levels.INFO, string logDir = null) {
        shared(LogHandler)[] handlers = [new shared OutputDebugStringLogHandler()];

        if (logDir !is null) {
            try {
                import std.file : mkdirRecurse;
                mkdirRecurse(logDir);
                handlers ~= new shared SerializingLogHandler(
                    new DefaultStringLogSerializer(false),
                    new RotatingFileLogWriter(logDir, "sideloader", 2_000_000));
            } catch (Exception) {
                // A missing log file must never stop the application.
            }
        }

        auto baseHandler = new shared MultiLogHandler(handlers);
        this.loggerFactory = new shared DefaultLoggerFactory(baseHandler, rootLoggingLevel);
    }

    public shared shared(DefaultLoggerFactory) getLoggerFactory() {
        return this.loggerFactory;
    }
}
