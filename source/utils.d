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
