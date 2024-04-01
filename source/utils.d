module utils;

T orDefault(T)(T obj, lazy T default_) {
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

private struct Delegate(alias U)
{
    import std.traits;
    import std.typecons;

    static if (is(typeof(&U) == delegate))
    {
        enum del = &U;
    }
    else
    {
        alias del = U;
    }

    typeof(del) delegate_ = del;

    extern(C) static auto assemble(Parameters!U params, void* context)
    {
        return (cast(Delegate*) context).delegate_(params);
    }

    pragma(inline, true)
    Tuple!(typeof(&assemble), void*) internalExpand()
    {
        return tuple(&assemble, cast(void*) &this);
    }
    alias expand = internalExpand.expand;
    alias expand this;
    // alias opCall = internalExpand.expand;
}

pragma(inline, true)
auto c(alias U)()
{
    return new Delegate!U().internalExpand;
}
