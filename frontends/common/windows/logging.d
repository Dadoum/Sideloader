module logging;

import core.sys.windows.winbase;

import std.string;

import slf4d;
import slf4d.default_provider;
import slf4d.default_provider.formatters;
import slf4d.handler;
import slf4d.provider;

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

    public shared this(Level rootLoggingLevel = Levels.INFO) {
        auto baseHandler = new shared MultiLogHandler([new shared OutputDebugStringLogHandler()]);
        this.loggerFactory = new shared DefaultLoggerFactory(baseHandler, rootLoggingLevel);
    }

    public shared shared(DefaultLoggerFactory) getLoggerFactory() {
        return this.loggerFactory;
    }
}
