module utils;

T orDefault(T)(T obj, T default_) {
    return obj == null ? default_ : obj;
}

import std.datetime: dur, SysTime;
auto stripMilliseconds(return SysTime time) {
    time.fracSecs = dur!"msecs"(0);
    return time;
}

string locale() {
    import core.stdc.locale;
    import std.string;
    string locale = cast(string) setlocale(LC_CTYPE, null).fromStringz().split('@')[0].split('.')[0];
    if (locale == "C" || locale == "POSIX") {
        locale = "en_US";
    }
    return locale;
}

import std.net.curl;
extern(C) private struct curl_blob {
    void *data;
    size_t len;
    uint flags; /* bit 0 is defined, the rest are reserved and should be
                                    left zeroes */
}

enum CURLOPT_CAINFO_BLOB = cast(CurlOption) 40_309;

void setBlob(Curl handle, CurlOption option, ubyte[] dataBlob) {
    curl_blob blob = {
        data: dataBlob.ptr,
        len: dataBlob.length,
        flags: 0
    };

    handle.set(option, cast(void*) &blob);
}