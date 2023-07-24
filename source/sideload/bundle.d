module sideload.bundle;

import plist;

class Bundle {
    PlistDict appInfo;
    string appId; // registered app id for it

    this(PlistDict appInfo) {
        this.appInfo = appInfo;
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