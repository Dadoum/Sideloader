module plist;

import core.stdc.stdlib;
import std.traits;
import std.string;

import plist.c;

public alias PlistType = plist_type;

public abstract class Plist {
    private plist_t handle;
    private bool owns;

    this(plist_t handle, bool owns) {
        this.handle = handle;
        this.owns = owns;
    }

    public PlistType nodeType() {
        return plist_get_node_type(handle);
    }

    public static Plist wrap(plist_t handle, bool owns = true) {
        Plist obj;
        with (PlistType) final switch (plist_get_node_type(handle)) {
            case PLIST_BOOLEAN:
                obj = new PlistBoolean(handle, owns);
                break;
            case PLIST_UINT:
                obj = new PlistUint(handle, owns);
                break;
            case PLIST_REAL:
                obj = new PlistReal(handle, owns);
                break;
            case PLIST_STRING:
                obj = new PlistString(handle, owns);
                break;
            case PLIST_ARRAY:
                obj = new PlistArray(handle, owns);
                break;
            case PLIST_DICT:
                obj = new PlistDict(handle, owns);
                break;
            case PLIST_DATE:
                obj = new PlistDate(handle, owns);
                break;
            case PLIST_DATA:
                obj = new PlistData(handle, owns);
                break;
            case PLIST_KEY:
                obj = new PlistKey(handle, owns);
                break;
            case PLIST_UID:
                obj = new PlistUid(handle, owns);
                break;
            case PLIST_NONE:
                obj = new PlistNone(handle, owns);
                break;
        }

        return obj;
    }

    public static Plist fromXml(string xml) {
        plist_t handle;
        plist_from_xml(cast(const char*) xml.ptr, cast(uint) xml.length, &handle);
        return wrap(handle);
    }

    public static Plist fromBin(ubyte[] bin) {
        plist_t handle;
        plist_from_bin(cast(const char*) bin.ptr, cast(uint) bin.length, &handle);
        return wrap(handle);
    }

    ~this() {
        if (owns && nodeType() != PlistType.PLIST_NONE) {
            plist_free(handle);
        }
    }

    public R copy(this R)() if (!is(T == Plist)) {
        return new R(plist_copy(handle), true);
    }

    public Plist copy() {
        return Plist.wrap(plist_copy(handle), true);
    }

    public string toXml() {
        char* str;
        uint length;
        plist_to_xml(handle, &str, &length);
        auto xml = cast(string) str[0..length].dup;
        plist_to_xml_free(str);
        return xml;
    }

    PlistBoolean boolean() {
        if (handle == null) {
            return null;
        }
        return cast(PlistBoolean) this;
    }

    PlistUint uinteger() {
        if (handle == null) {
            return null;
        }
        return cast(PlistUint) this;
    }

    PlistReal real_() {
        if (handle == null) {
            return null;
        }
        return cast(PlistReal) this;
    }

    PlistString str() {
        if (handle == null) {
            return null;
        }
        return cast(PlistString) this;
    }

    PlistArray array() {
        if (handle == null) {
            return null;
        }
        return cast(PlistArray) this;
    }

    PlistDict dict() {
        if (handle == null) {
            return null;
        }
        return cast(PlistDict) this;
    }

    PlistDate date() {
        if (handle == null) {
            return null;
        }
        return cast(PlistDate) this;
    }

    PlistData data() {
        if (handle == null) {
            return null;
        }
        return cast(PlistData) this;
    }

    PlistKey key() {
        if (handle == null) {
            return null;
        }
        return cast(PlistKey) this;
    }

    PlistUid uid() {
        if (handle == null) {
            return null;
        }
        return cast(PlistUid) this;
    }
}

public class PlistBoolean: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(bool val) {
        this(plist_new_bool(val), true);
    }

    public T opCast(T: bool)() {
        ubyte val;
        plist_get_bool_val(handle, &val);
        return cast(T) val;
    }

    public void opAssign(bool val) {
        plist_set_bool_val(handle, val);
    }

    public auto native() {
        return cast(bool) this;
    }
}

class PlistUint: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(ulong val) {
        this(plist_new_uint(val), true);
    }

    public T opCast(T)() if (isUnsigned!T) {
        ulong val;
        plist_get_uint_val(handle, &val);
        return cast(T) val;
    }

    public void opAssign(T)(T val) if (isUnsigned!T) {
        plist_set_uint_val(handle, cast(ulong) val);
    }

    public auto native() {
        return cast(ulong) this;
    }
}

class PlistReal: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(double val) {
        this(plist_new_real(val), true);
    }

    public T opCast(T)() if (isFloatingPoint!T) {
        double val;
        plist_get_real_val(handle, &val);
        return cast(T) val;
    }

    public void opAssign(T)(T val) if (isFloatingPoint!T) {
        plist_set_real_val(handle, cast(double) val);
    }

    public auto native() {
        return cast(double) this;
    }
}

class PlistString: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(string val) {
        this(plist_new_string(val.toStringz), true);
    }

    public T opCast(T)() if (isSomeString!T) {
        char* val;
        plist_get_string_val(handle, &val);
        auto str = val.fromStringz.dup;
        plist_mem_free(val);
        return cast(T) str;
    }

    public void opAssign(T)(T val) if (isSomeString!T) {
        plist_set_string_val(handle, cast(const char*) val.toStringz);
    }

    public auto native() {
        return cast(string) this;
    }
}

class PlistArray: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this() {
        this(plist_new_array(), true);
    }

    public uint length() {
        return plist_array_get_size(handle);
    }

    public uint opDollar(size_t pos)() {
        return length();
    }

    public Plist opIndex(uint index) {
        return Plist.wrap(plist_array_get_item(handle, index), false);
    }

    public void opIndexAssign(Plist element, uint key) {
        element.owns = false;
        plist_array_set_item(handle, element.handle, key);
    }

    public void opOpAssign(string s: "~")(Plist element) {
        element.owns = false;
        plist_array_append_item(handle, element.handle);
    }

    class PlistArrayIter {
        private plist_array_iter handle;
        private PlistArray array;

        public this(plist_array_iter handle, PlistArray array) {
            this.handle = handle;
            this.array = array;
        }

        ~this() {
            free(handle);
        }

        bool next(out Plist plist) {
            plist_t plist_h;
            plist_array_next_item(array.handle, handle, &plist_h);
            if (!plist_h)
                return false;
            plist = Plist.wrap(plist_h, false);
            return true;
        }
    }

    public PlistArrayIter iter() {
        plist_array_iter iter;
        plist_array_new_iter(handle, &iter);
        return new PlistArrayIter(iter, this);
    }

    public void append(Plist[] array) {
        foreach (element; array) {
            this ~= element;
            element.owns = false;
        }
    }

    public auto native() {
        Plist[] array = new Plist[length()];

        auto iterator = iter();

        Plist val;
        int index = 0;

        while (iterator.next(val)) {
            array[index++] = val;
        }
        return array;
    }
}

class PlistDict: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this() {
        this(plist_new_dict(), true);
    }

    public uint length() {
        return plist_dict_get_size(handle);
    }

    public uint opDollar(size_t pos)() {
        return length();
    }

    public Plist opIndex(string key) {
        auto item = plist_dict_get_item(handle, key.toStringz);
        return item ? Plist.wrap(item, false) : null;
    }

    public void opIndexAssign(Plist element, string key) {
        element.owns = false;
        plist_dict_set_item(handle, key.toStringz, element.handle);
    }

    class PlistDictIter {
        private plist_dict_iter handle;
        private PlistDict dict;

        public this(plist_dict_iter handle, PlistDict dict) {
            this.handle = handle;
            this.dict = dict;
        }

        ~this() {
            free(handle);
        }

        bool next(out Plist plist, out string key) {
            plist_t plist_h = null;
            char* k = null;
            plist_dict_next_item(dict.handle, handle, &k, &plist_h);
            if (!plist_h)
                return false;
            key = k.fromStringz.dup;
            free(k);
            plist = Plist.wrap(plist_h, false);
            return true;
        }
    }

    public PlistDictIter iter() {
        plist_dict_iter iter;
        plist_dict_new_iter(handle, &iter);
        return new PlistDictIter(iter, this);
    }

    public void append(Plist[string] array) {
        foreach (element; array.byKeyValue) {
            if (element.value.owns) {
                element.value.owns = false;
            } else {
                element.value = element.value.copy();
            }
            this[element.key] = element.value;
        }
    }

    public auto native() {
        Plist[string] dictionary;

        auto iterator = iter();

        Plist val;
        string key;

        while (iterator.next(val, key)) {
            dictionary[key] = val;
        }
        return dictionary;
    }
}

class PlistDate: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    // public this() {
    //     this(plist_new_date(), true);
    // }
}

class PlistData: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(ubyte[] val) {
        this(plist_new_data(cast(const char*) val.ptr, val.length), true);
    }

    public ubyte[] opCast(T: ubyte[])() {
        char* ptr;
        ulong length;
        plist_get_data_val(handle, &ptr, &length);
        auto data = cast(ubyte[]) ptr[0..length].dup;
        plist_mem_free(ptr);
        return data;
    }

    public void opAssign(ubyte[] val) {
        plist_set_data_val(handle, cast(const char*) val.ptr, val.length);
    }

    public auto native() {
        return cast(ubyte[]) this;
    }
}

class PlistKey: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }
}

class PlistUid: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(ulong val) {
        this(plist_new_uid(val), true);
    }

    public void opAssign(ulong val) {
        plist_set_uid_val(handle, val);
    }
}

class PlistNone: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }
}

pragma(inline, true) auto pl(bool obj) {
    return new PlistBoolean(obj);
}

pragma(inline, true) auto pl(U)(U obj) if (isIntegral!U) {
    return new PlistUint(obj);
}

pragma(inline, true) auto pl(U)(U obj) if (isFloatingPoint!U) {
    return new PlistReal(obj);
}

pragma(inline, true) auto pl(U)(U obj) if (isSomeString!U) {
    return new PlistString(cast(string) obj);
}

pragma(inline, true) auto pl(Plist[] obj) {
    auto array = new PlistArray();
    array.append(obj);
    return array;
}

pragma(inline, true) auto pl(Plist[string] obj) {
    auto dict = new PlistDict();
    dict.append(obj);
    return dict;
}

pragma(inline, true) auto pl(ubyte[] obj) {
    return new PlistData(obj);
}
