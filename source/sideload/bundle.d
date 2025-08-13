module sideload.bundle;

import std.algorithm.iteration;
import std.array;
import file = std.file;
import std.path;

import plist;

class Bundle {
    PlistDict appInfo;
    string bundleDir;

    Bundle[] _appExtensions;
    Bundle[] _frameworks;
    string[] _libraries;

    this(string bundleDir) {
        if (bundleDir[$ - 1] == '/' || bundleDir[$ - 1] == '\\') bundleDir.length -= 1;
        this.bundleDir = bundleDir;
        string infoPlistPath = bundleDir.buildPath("Info.plist");
        assertBundle(file.exists(infoPlistPath), "No Info.plist here: " ~ infoPlistPath);
        appInfo = Plist.fromMemory(cast(ubyte[]) file.read(infoPlistPath)).dict();

        auto plugInsDir = bundleDir.buildPath("PlugIns");
        if (file.exists(plugInsDir)) {
            _appExtensions = file.dirEntries(plugInsDir, file.SpanMode.shallow).filter!((f) => f.isDir && file.exists(f.buildPath("Info.plist"))).map!((f) => new Bundle(f.name)).array;
        } else {
            _appExtensions = [];
        }

        auto frameworksDir = bundleDir.buildPath("Frameworks");
        if (file.exists(frameworksDir)) {
            _frameworks = file.dirEntries(frameworksDir, file.SpanMode.shallow).filter!((f) => f.isDir && file.exists(f.buildPath("Info.plist"))).map!((f) => new Bundle(f.name)).array;
        } else {
            _frameworks = [];
        }
        _libraries = file.dirEntries(bundleDir, file.SpanMode.breadth).filter!((f) => f.isFile && f.name[$ - ".dylib".length..$] == ".dylib").map!((f) => f.name[bundleDir.length + 1..$]).array;
    }

    void bundleIdentifier(string id) => appInfo["CFBundleIdentifier"] = id.pl;
    string bundleIdentifier() => appInfo["CFBundleIdentifier"].str().native();

    string bundleName() => appInfo["CFBundleName"].str().native();

    string[] libraries() => _libraries;
    Bundle[] frameworks() => _frameworks;
    Bundle[] appExtensions() => _appExtensions;
    Bundle[] subBundles() => frameworks ~ appExtensions;
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