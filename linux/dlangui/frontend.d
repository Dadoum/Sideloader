module frontend;

import dlangui;

import slf4d;

import app.frontend;
import constants;

extern(C) int DLANGUImain(string[] args);

class DlangUIFrontend: Frontend {
    int run(string configurationPath, string[] args) {
        return DLANGUImain(args);
    }
}

extern (C) int UIAppMain()
{
    // Most of the time on GNOME, SDL is wrong about DPI. So we just override it.
    overrideScreenDPI(96);
    getLogger().info("Using DlangUI frontend.");
    Window w = Platform.instance.createWindow(applicationName, null, WindowFlag.ExpandSize | WindowFlag.Resizable, 0, 0);
    w.windowOrContentResizeMode = WindowOrContentResizeMode.resizeWindow;
    VerticalLayout layout = new VerticalLayout();
    layout.alignment = Align.Center;
    layout.addChild(new ComboBox());
    HorizontalLayout ha = new HorizontalLayout();
    ha.addChild(new EditLine());
    auto selectIPA = new Button();
    // selectIPA.fill;
    selectIPA.text = "...";
    ha.addChild(selectIPA);
    layout.addChild(ha);

    auto sideload = new Button();
    ha.alignment = Align.Right;

    layout.margins = 8;
    w.mainWidget = layout;
    w.show();
    return Platform.instance.enterMessageLoop();
}

Frontend makeFrontend() => new DlangUIFrontend();