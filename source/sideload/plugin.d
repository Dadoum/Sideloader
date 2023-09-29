module sideload.plugin;

import file = std.file;
import std.path;

import plist;

import sideload.bundle;

class PlugIn: Bundle {
    this(string path) {
        super(path);
    }
}
