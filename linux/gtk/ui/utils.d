/// all hacks that have to be nuked at some point
module ui.utils;

// GLib Timeout used as runInUIThread
import std.traits;

import glib.Timeout;

private struct DelegateWrapper {
    int delegate() del;
}

private extern(C) int callDelegate(void* userData) {
    return (cast(DelegateWrapper*) userData).del();
}

void runInUIThread(void delegate() del) {
    Timeout.add(0, &callDelegate, new DelegateWrapper({
        del();
        return 0;
    }));
}
