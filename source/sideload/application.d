module sideload.application;

import std.algorithm.iteration;
import std.algorithm.searching;
import std.array;
import file = std.file;
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
    string appFolder;
    Bundle[] plugIns = [];

    this(string path) {
        tempPath = file.tempDir().buildPath(baseName(path));
        if (file.exists(tempPath)) {
            file.rmdirRecurse(tempPath);
            file.mkdir(tempPath);
        } else {
            file.mkdirRecurse(tempPath);
        }
        auto ipa = new ZipArchive(file.read(path));

        foreach (k, v; ipa.directory()) {
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

        appFolder = apps[0];
        auto infoPlist = appFolder.buildPath("Info.plist");
        assertBundle(file.exists(infoPlist), "No Info.plist");

        super(Plist.fromMemory(cast(ubyte[]) file.read(infoPlist)).dict());

        auto plugInsFolder = appFolder.buildPath("PlugIns");
        if (file.exists(plugInsFolder) && file.isDir(plugInsFolder)) {
            foreach (pluginFolder; file.dirEntries(plugInsFolder, file.SpanMode.shallow)) {
                plugIns ~= new PlugIn(pluginFolder);
            }
        }
    }

    /// Fetches a mobileprovision file for the app
    void provisionApplication(DeveloperSession account, DeveloperTeam team) {
        auto appBundleIdentifier = appInfo["CFBundleIdentifier"].str().native();
        getLogger().infoF!"AppID: %s.%s"(appBundleIdentifier, team.teamId);
    }
}
