module sideload.plugin;

import file = std.file;
import std.path;

import plist;

import sideload.bundle;

class PlugIn: Bundle {
    this(string path) {
        auto infoPlist = path.buildPath("Info.plist");
        assertBundle(file.exists(infoPlist), "No Info.plist!");

        super(Plist.fromMemory(cast(ubyte[]) file.read(infoPlist)).dict());
    }
}
