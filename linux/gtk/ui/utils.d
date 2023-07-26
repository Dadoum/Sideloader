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

// not implemented
import gtk.Dialog;
import gtk.Label;
import gtk.Window;

import ui.sideloadergtkapplication;

void notImplemented(Window parentWindow = runningApplication.mainWindow) {
    runInUIThread({
        Dialog dialog = new Dialog();
        dialog.getContentArea().append(new Label("Not implemented yet"));
        dialog.setTransientFor(parentWindow);
        dialog.setModal(true);
        dialog.addButton("OK", 0);
        dialog.addOnResponse((_a, _b) => dialog.close());
        dialog.show();
    });
}

// Fallback exception window
import std.format;

import slf4d;

import gtk.MessageDialog;

void uiTry(void delegate() del, Window parentWindow = runningApplication.mainWindow) {
    try {
        del();
    } catch (Throwable ex) {
        runInUIThread({
            getLogger().errorF!"Exception occured: %s"(ex);
            auto errorDialog = new MessageDialog(parentWindow, DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL | DialogFlags.USE_HEADER_BAR, MessageType.ERROR, ButtonsType.CLOSE, format!"Exception occured: %s"(ex.msg));
            errorDialog.addOnResponse((_, __) {
                errorDialog.close();
            });
            errorDialog.show();
        });
    }
}
