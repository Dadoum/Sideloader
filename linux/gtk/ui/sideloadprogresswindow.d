module ui.sideloadprogresswindow;

import core.thread;

import std.format;

import gtk.Box;
import gtk.HeaderBar;
import gtk.Label;
import gtk.MessageDialog;
import gtk.ProgressBar;
import gtk.Window;

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

    this(SideloaderGtkApplication app) {
        this.setResizable(false);
        this.setTransientFor(app.mainWindow);
        this.setModal(true);
        this.setTitle("");

        auto headerBar = new HeaderBar();
        headerBar.addCssClass("flat");
        this.setTitlebar(headerBar);

        progressBar = new ProgressBar();
        progressBar.setShowText(true);
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
                        progressWindow.progressBar.setFraction(progress);
                        progressWindow.progressBar.setText(message);
                    });
                });
                getLogger().info("Sideload succeeded!!");
                runInUIThread({
                    auto infoDialog = new MessageDialog(progressWindow, DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL | DialogFlags.USE_HEADER_BAR, MessageType.INFO, ButtonsType.CLOSE, "Application successfully installed!");
                    infoDialog.addOnResponse((_, __) {
                        infoDialog.close();
                        progressWindow.close();
                    });
                    infoDialog.show();
                });
            } catch (Throwable ex) {
                getLogger().errorF!"Sideloading failed: %s"(ex);
                runInUIThread({
                    auto errorDialog = new MessageDialog(progressWindow, DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL | DialogFlags.USE_HEADER_BAR, MessageType.ERROR, ButtonsType.CLOSE, format!"Sideloading failed: %s"(ex.msg));
                    errorDialog.addOnResponse((_, __) {
                        errorDialog.close();
                        progressWindow.close();
                    });
                    errorDialog.show();
                });
            }
        }).start();
    }
}

