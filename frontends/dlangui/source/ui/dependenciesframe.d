module ui.dependenciesframe;

import file = std.file;
import std.path;

import slf4d;

import dlangui;

import app;

class DependenciesFrame: VerticalLayout {
    this(string configurationPath, void delegate() onCompletion) {
        auto log = getLogger();

        addChild(new TextWidget(null, "A ~130 MB download is required. This will require 5 MB on your computer."d));
        ProgressBarWidget progressBar = new ProgressBarWidget();
        progressBar.animationInterval = 50;
        Button button = new Button(null, "Proceed"d);
        button.click = (_) {
            import core.thread;
            auto win = window();
            new Thread({
                log.info("Downloading Apple's APK.");
                // auto succeeded = downloadAndInstallDeps(configurationPath, (progress) {
                //     executeInUiThread({
                //         progressBar.progress(cast(int) (progress * 1000));
                //     });
                //     return win.windowState() == WindowState.hidden;
                // });
                auto succeeded = true;

                if (succeeded) {
                    log.info("Download successful.");
                    executeInUiThread({
                        onCompletion();
                        win.close();
                    });
                }
            }).start();
            return true;
        };

        addChild(button);
        addChild(progressBar);
    }

    static void ensureDeps(string configurationPath, void delegate() onCompletion) {
        if (!(file.exists(configurationPath.buildPath("lib/libstoreservicescore.so")) && file.exists(configurationPath.buildPath("lib/libCoreADI.so")))) {
            // Missing dependencies
            auto depWindow = Platform.instance.createWindow("Download required.", null, WindowFlag.ExpandSize, 1, 1);
            depWindow.mainWidget = new DependenciesFrame(configurationPath, onCompletion);
            depWindow.windowOrContentResizeMode = WindowOrContentResizeMode.resizeWindow;
            depWindow.show();
        } else {
            onCompletion();
        }
    }
}
