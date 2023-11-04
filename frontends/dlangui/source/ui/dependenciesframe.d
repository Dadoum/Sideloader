module ui.dependenciesframe;

import file = std.file;
import std.path;

import slf4d;

import dlangui;

class DependenciesFrame: VerticalLayout {
    this() {
        addChild(new TextWidget(null, "Deps needed plz download"d));
        addChild(new Button(null, "Yes plz"d));
    }

    static void ensureDeps(string configurationPath, void delegate() onCompletion) {
        if (!(file.exists(configurationPath.buildPath("lib/libstoreservicescore.so")) && file.exists(configurationPath.buildPath("lib/libCoreADI.so")))) {
            // Missing dependencies
            auto tfaWindow = Platform.instance.createWindow("Download required.", null, WindowFlag.ExpandSize, 1, 1);
            tfaWindow.mainWidget = new DependenciesFrame();
            tfaWindow.windowOrContentResizeMode = WindowOrContentResizeMode.resizeWindow;
            tfaWindow.show();
        } else {
            onCompletion();
        }
    }
}
