module ui.tfaframe;

import dlangui;

import server.appleaccount;
import server.developersession;

class TFAFrame: VerticalLayout {
    this(Send2FADelegate sendCode, Submit2FADelegate submitCode) {
        // addChild();
    }

    static void tfa(Window parentWindow, Send2FADelegate sendCode, Submit2FADelegate submitCode) {
        sendCode();
        auto tfaWindow = Platform.instance.createWindow("A code has been sent", parentWindow, WindowFlag.ExpandSize, 1, 1);
        tfaWindow.mainWidget = new TFAFrame(sendCode, submitCode);
        tfaWindow.windowOrContentResizeMode = WindowOrContentResizeMode.resizeWindow;
        tfaWindow.show();
    }
}
