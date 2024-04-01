module test1;

import cpp_helpers;
import provision;

extern(C) void hello(string a) {
    import std.stdio;
    writeln(a);
}
