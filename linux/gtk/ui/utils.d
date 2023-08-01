/// all hacks that have to be nuked or sorted in other modules at some point
module ui.utils;

// GLib Timeout used as runInUIThread
import core.memory;
import std.traits;

import glib.Timeout;

private struct DelegateWrapper {
    int delegate() del;
}

private extern(C) int callDelegate(void* userData) {
    auto delegateWrapper = cast(DelegateWrapper*) userData;
    GC.removeRoot(delegateWrapper);
    return delegateWrapper.del();
}

void runInUIThread(void delegate() del) {
    auto delegateWrapper = new DelegateWrapper({
        del();
        return 0;
    });
    GC.addRoot(delegateWrapper);
    Timeout.add(0, &callDelegate, delegateWrapper);
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
    } catch (Exception ex) {
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

// Animation
import core.time;

import adw.CallbackAnimationTarget;
import adw.TimedAnimation: AdwTimedAnimation = TimedAnimation;

import gtk.Widget;

AdwTimedAnimation TimedAnimation(Widget widget, double from, double to, Duration duration, void delegate(double value) del) {
    struct Callback {
        void delegate(double value) cb;
    }
    return new AdwTimedAnimation(widget, from, to, cast(uint) duration.total!"msecs"(), new CallbackAnimationTarget((progress, data) {
        (cast(Callback*) data).cb(progress);
    }, new Callback(del), null));
}
