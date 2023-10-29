module usbmuxd;

import core.stdc.stdlib;

import std.string;

import usbmuxd.c;

class UsbmuxdException: Exception {
    this(int error, string file = __FILE__, int line = __LINE__) {
        super(format!"usbmuxd error: %d"(error), file, line);
    }
}

void assertSuccess(int err) {
    if (err < 0)
        throw new UsbmuxdException(err);
}

ubyte[] readPairRecord(string udid) {
    char* dataPtr;
    uint length;
    usbmuxd_read_pair_record(udid.toStringz(), &dataPtr, &length).assertSuccess();
    ubyte[] data = cast(ubyte[]) dataPtr[0..length].dup;
    free(dataPtr);
    return data;
}
