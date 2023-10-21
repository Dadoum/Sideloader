module version_string;

import std.format;

debug { enum isDebug = " (DEBUG)"; } else { enum isDebug = ""; }

enum versionStr = format!"Sideloader, compiled locally with %s on %s at %s%s"(__VENDOR__, __DATE__, __TIME__, isDebug);
