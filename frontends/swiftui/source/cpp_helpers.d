module cpp_helpers;

template isTranslatable(T...) {
    static if (T.length) {
        static if (is(T[0] == U[], U)) {
            enum isTranslatable = false;
        } else {
            enum isTranslatable = isTranslatable!(T[1..$]);
        }
    } else {
        enum isTranslatable = true;
    }
}

mixin template BindCtor(alias U) {
    import std.traits;

    alias Params = Parameters!U;
    static if (isTranslatable!Params) {
        this(Params params) {
            handle = new T(params);
        }
    }
}

mixin template BindDtor(alias U) {
    import std.traits;

    ~this() {
        handle.__dtor();
    }
}

mixin template BindFunction(alias U) {
    import std.traits;

    alias Params = Parameters!U;
    static if (isTranslatable!Params && isTranslatable!(ReturnType!U)) {
        static if (__traits(isStaticFunction, U)) {
            mixin(`static auto `~__traits(identifier, U)~`(Params params) {
                return `~__traits(parent, U).stringof~`.`~__traits(identifier, U)~`(params);
            }`);
        } else {
            mixin(`auto `~__traits(identifier, U)~`(Params params) {
                return handle.`~__traits(identifier, U)~`(params);
            }`);
        }
    }
}

mixin template WrapClass(T) {
    mixin(`
        extern (C++) class `~T.stringof~` {
            T handle;

            static foreach (func; __traits(allMembers, T)) {
                static foreach (overload; __traits(getOverloads, T, func)) {
                    static if (__traits(identifier, overload) == "__ctor") {
                        mixin BindCtor!(overload);
                    } else static if (__traits(identifier, overload) == "__dtor") {
                        mixin BindDtor!(overload);
                    }
                        mixin BindFunction!(overload);
                    }
                }
            }

    `);
}
