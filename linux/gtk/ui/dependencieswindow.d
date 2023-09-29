module ui.dependencieswindow;

import core.thread.osthread;

import std.format;

import slf4d;

import adw.HeaderBar;
import adw.Window;

import glib.Timeout;

import gtk.Box;
import gtk.Button;
import gtk.Label;
import gtk.ProgressBar;
import gtk.Stack;
import gtk.WindowHandle;

import gdk.Cursor;

import constants;
import main;

import ui.sideloadergtkapplication;
import ui.utils;

// HELP NEEDED: Better design for this window
class DependenciesWindow: Window {
    string configPath;

    this(SideloaderGtkApplication app) {
        this.setResizable(false);
        this.setTitle("");

        configPath = app.configurationPath;

        WindowHandle wh = new WindowHandle(); {
            Box box = new Box(Orientation.VERTICAL, 4);
            box.setMarginTop(16);
            box.setMarginBottom(16);
            box.setMarginStart(16);
            box.setMarginEnd(16); {
                Label text = new Label(applicationName ~ " requires some libraries to be installed.\nInstalling them will cause a ≈150 MB download and 5 MB of storage space.\n\nProceed?");
                text.setHexpand(true);
                text.setVexpand(true);
                text.setWrap(true);
                box.append(text);

                Stack stack = new Stack(); {
                    ProgressBar downloadProgress = new ProgressBar();
                    downloadProgress.setShowText(true);
                    downloadProgress.setText("-"); {

                    }
                    stack.addChild(downloadProgress);

                    Box buttonBox = new Box(Orientation.HORIZONTAL, 4);
                    buttonBox.setHalign(Align.END); {
                        Button quitButton = new Button("Quit");
                        quitButton.addOnClicked((_) {
                            this.close();
                        });
                        buttonBox.append(quitButton);

                        Button proceedButton = new Button("Proceed");
                        proceedButton.addOnClicked((_) {
                            quitButton.setSensitive(false);
                            proceedButton.setSensitive(false);
                            this.setCursor(new Cursor("wait", null));
                            stack.setVisibleChild(downloadProgress);

                            Thread t = new Thread(() {
                                auto succeeded = frontend.downloadAndInstallDeps((progress) {
                                    runInUIThread({
                                        downloadProgress.setFraction(progress);
                                        downloadProgress.setText(format!"%.2f %% completed"(progress * 100));
                                    });

                                    return !this.getVisible();
                                });

                                if (!succeeded) {
                                    runInUIThread(() => this.close());
                                    return;
                                }

                                runInUIThread({
                                    this.close();
                                    app.configureMainWindow();
                                });
                            });

                            t.start();
                        });
                        buttonBox.append(proceedButton);
                    }
                    stack.addChild(buttonBox);
                    stack.setVisibleChild(buttonBox);
                }
                box.append(stack);
            }
            wh.setChild(box);
        }
        this.setChild(wh);
    }
}
