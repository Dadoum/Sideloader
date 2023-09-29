module sideload.bundle;

import file = std.file;
import std.path;

import plist;

class Bundle {
    PlistDict appInfo;
    string bundleDir;
    string appId; // registered app id for it

    this(string bundleDir) {
        this.bundleDir = bundleDir;
        string infoPlistPath = bundleDir.buildPath("Info.plist");
        assertBundle(file.exists(infoPlistPath), "No Info.plist");
        appInfo = Plist.fromMemory(cast(ubyte[]) file.read(infoPlistPath)).dict();
    }

    string bundleIdentifier() => appInfo["CFBundleIdentifier"].str().native();
    string bundleName() => appInfo["CFBundleName"].str().native();
}

void assertBundle(bool condition, string msg, string file = __FILE__, int line = __LINE__) {
    if (!condition) {
        throw new InvalidBundleException(msg, file, line);
    }
}

class InvalidBundleException: Exception {
    this(string msg, string file = __FILE__, int line = __LINE__) {
        super("Cannot parse the application bundle! " ~ msg, file, line);
    }
}