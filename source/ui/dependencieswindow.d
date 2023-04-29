module ui.dependencieswindow;

import core.thread.osthread;

import file = std.file;
import std.format;
import std.math;
import std.net.curl;
import std.path;
import std.zip;

import constants;

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

import ui.sideloaderapplication;

import slf4d;

// HELP NEEDED: Better design for this window
class DependenciesWindow: Window {
    string configPath;

    this(SideloaderApplication app) {
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
                                downloadAndInstallDeps((progress) {
                                    int delegate() del = () {
                                        downloadProgress.setFraction(progress);
                                        downloadProgress.setText(format!"%.2f %% completed"(progress * 100));
                                        return 0;
                                    };

                                    Timeout.add(0, &callDelegate, new DelegateWrapper(del));
                                });

                                int delegate() del = () {
                                    this.close();
                                    app.configureMainWindow();
                                    return 0;
                                };

                                Timeout.add(0, &callDelegate, new DelegateWrapper(del));
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

    void downloadAndInstallDeps(void delegate(float progress) downloadCallback) {
        auto http = HTTP();
        auto log = getLogger();
        log.info("Downloading APK...");
        http.onProgress = (size_t dlTotal, size_t dlNow, size_t ulTotal, size_t ulNow) {
            downloadCallback(cast(float) dlNow / 150_000_000.0); // Approximation of the size since Appe doesn't give it...
            return 0;
        };
        log.info("Downloaded successfully!");
        auto apkData = get!(HTTP, ubyte)(nativesUrl, http);
        downloadCallback(1.);
        auto apk = new ZipArchive(apkData);
        auto dir = apk.directory();

        string libPath = configPath.buildPath("lib");
        if (!file.exists(libPath)) {
            file.mkdir(libPath);
        }
        log.info("Extracted successfully!");

        version (X86_64) {
            enum string architectureIdentifier = "x86_64";
        } else version (X86) {
            enum string architectureIdentifier = "x86";
        } else version (AArch64) {
            enum string architectureIdentifier = "arm64-v8a";
        } else version (ARM) {
            enum string architectureIdentifier = "armeabi-v7a";
        } else {
            static assert(false, "Architecture not supported :(");
        }
        file.write(libPath.buildPath("libCoreADI.so"), apk.expand(dir["lib/" ~ architectureIdentifier ~ "/libCoreADI.so"]));
        file.write(libPath.buildPath("libstoreservicescore.so"), apk.expand(dir["lib/" ~ architectureIdentifier ~ "/libstoreservicescore.so"]));
    }
}

struct DelegateWrapper {
    int delegate() del;
}

private extern(C) int callDelegate(void* userData) {
    return (cast(DelegateWrapper*) userData).del();
}