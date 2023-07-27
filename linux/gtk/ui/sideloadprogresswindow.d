module ui.sideloadprogresswindow;

import core.thread;

import std.format;

import adw.Animation;
import adw.Window;

import gobject.Signals;

import gtk.Box;
import gtk.HeaderBar;
import gtk.Label;
import gtk.MessageDialog;
import gtk.ProgressBar;

import slf4d;

import imobiledevice;

import server.developersession;

import sideload;

import ui.authentication.authenticationassistant;
import ui.sideloadprogresswindow;
import ui.sideloadergtkapplication;
import ui.utils;

class SideloadProgressWindow: Window {
    ProgressBar progressBar;
    Animation anim;

    this(SideloaderGtkApplication app) {
        this.setResizable(false);
        this.setTransientFor(app.mainWindow);
        this.setModal(true);
        this.setTitle("");
        this.setDefaultSize(300, 0);
        this.addOnCloseRequest((_) => true);

        progressBar = new ProgressBar();
        progressBar.setShowText(true);
        progressBar.setHexpand(false);
        progressBar.setHalign(Align.FILL);
        enum padding = 8;
        progressBar.setMarginStart(padding);
        progressBar.setMarginEnd(padding);
        progressBar.setMarginTop(padding);
        progressBar.setMarginBottom(padding);
        this.setChild(progressBar);
    }

    static void sideload(SideloaderGtkApplication app, DeveloperSession session, Application iosApp, iDevice device) {
        SideloadProgressWindow progressWindow = new SideloadProgressWindow(app);
        progressWindow.show();

        new Thread({
            try {
                sideloadFull(device, session, iosApp, (progress, message) {
                    runInUIThread({
                        if (progressWindow.anim) {
                            progressWindow.anim.pause();
                        }

                        auto progressBar = progressWindow.progressBar;
                        auto anim = TimedAnimation(progressBar, progressBar.getFraction(), progress, dur!"msecs"(200), (progress) {
                            progressBar.setFraction(progress);
                            progressBar.setText(message);
                        });
                        anim.setEasing(Easing.EASE_IN_OUT_CUBIC);
                        progressWindow.anim = anim;
                        progressWindow.anim.play();
                    });
                });
                getLogger().info("Sideload succeeded!!");
                runInUIThread({
                    auto infoDialog = new MessageDialog(progressWindow, DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL | DialogFlags.USE_HEADER_BAR, MessageType.INFO, ButtonsType.CLOSE, "Application successfully installed!");
                    infoDialog.addOnResponse((_, __) {
                        infoDialog.close();
                        progressWindow.destroy();
                    });
                    infoDialog.show();
                });
            } catch (Throwable ex) {
                getLogger().errorF!"Sideloading failed: %s"(ex);
                runInUIThread({
                    auto errorDialog = new MessageDialog(progressWindow, DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL | DialogFlags.USE_HEADER_BAR, MessageType.ERROR, ButtonsType.CLOSE, format!"Sideloading failed: %s"(ex.msg));
                    errorDialog.addOnResponse((_, __) {
                        errorDialog.close();
                        progressWindow.destroy();
                    });
                    errorDialog.show();
                });
            }
        }).start();
    }
}
