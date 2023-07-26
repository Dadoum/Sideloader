module version_string;

debug { enum isDebug = " (DEBUG)"; } else { enum isDebug = ""; }

enum versionStr = "Local build from " ~ __DATE__ ~ isDebug;