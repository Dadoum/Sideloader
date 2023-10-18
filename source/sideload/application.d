module sideload.application;

import std.algorithm.iteration;
import std.algorithm.searching;
import std.array;
import file = std.file;
import std.parallelism;
import std.path;
import std.string;
import std.zip;

import slf4d;

import plist;

import server.developersession;
import sideload.bundle;
import sideload.plugin;

class Application: Bundle {
    string tempPath;

    this(string path) {
        if (file.isFile(path)) {
            tempPath = file.tempDir().buildPath(baseName(path));
            if (file.exists(tempPath)) {
                file.rmdirRecurse(tempPath);
                file.mkdir(tempPath);
            } else {
                file.mkdirRecurse(tempPath);
            }
            auto ipa = new ZipArchive(file.read(path));

            foreach (kv; parallel(ipa.directory().byKeyValue())) {
                auto k = kv.key;
                auto v = kv.value;

                auto entryPath = tempPath.buildPath(k);
                if (k[$ - 1] != '/') {
                    auto dirname = dirName(entryPath);
                    if (!file.exists(dirname)) {
                        file.mkdirRecurse(dirname);
                    }
                    file.write(entryPath, ipa.expand(v));
                }
            }

            auto payloadFolder = tempPath.buildPath("Payload");
            assertBundle(file.exists(payloadFolder), "No Payload folder!");

            auto apps = file.dirEntries(payloadFolder, file.SpanMode.shallow).array;
            assertBundle(apps.length == 1, "No or too many application folder!");

            path = apps[0];
        }

        super(path);
    }

    /// Fetches a mobileprovision file for the app
    void provisionApplication(DeveloperSession account, DeveloperTeam team) {
        auto appBundleIdentifier = appInfo["CFBundleIdentifier"].str().native();
        getLogger().infoF!"AppID: %s.%s"(appBundleIdentifier, team.teamId);
    }
}
