module ui.utils;

struct Observer(T) {
    const(T) obj;
    this(T obj, void delegate(T val)[] dels = []) {
        this.obj = obj;
        this.dels = dels;
    }

    void delegate(T val)[] dels;

    size_t connect(void delegate(T val) del) {
        auto offset = 0;
        while (offset < dels.length) {
            if (dels[offset] == null) {
                break;
            }
        }
        if (offset >= dels.length) {
            dels.length = offset + 1;
        }
        dels[offset] = del;
        return offset;
    }

    void disconnect(size_t id) {
        dels[id] = null;
    }

    scope Observer opAssign(T val) {
        foreach (del; dels) {
            del(val);
        }
        return Observer(val, dels);
    }

    alias obj this;
}

import std.conv;
import std.format;

import slf4d;

import dlangui;

void uiTry(alias U)(Window w) {
    try {
        U();
    } catch (Exception ex) {
        getLogger().errorF!"Exception occured: %s"(ex);
        w.executeInUiThread({
            w.showMessageBox("Exception occured"d, format!"%s@%s(%s): %s"d(typeid(ex).toString(), ex.file, ex.line, ex.msg));
        });
    }
}