module ui.devicewidget;

import core.thread;

import std.format;

import adw.ActionRow;
import adw.ExpanderRow;
import adw.PreferencesGroup;

import gtk.Dialog;
import gtk.FileChooserNative;
import gtk.FileFilter;
import gtk.Label;
import gtk.MessageDialog;
import gtk.Window;

import slf4d;

import imobiledevice;

import server.developersession;

import sideload;

import ui.authentication.authenticationassistant;
import ui.sideloadprogresswindow;
import ui.sideloadergtkapplication;
import ui.utils;

class DeviceWidget: PreferencesGroup {
    iDevice device;
    LockdowndClient lockdowndClient;

    this(iDeviceInfo deviceInfo) {
        string udid = deviceInfo.udid;
        string deviceId = format!"%s (%s)"(udid, deviceInfo.connType == iDeviceConnectionType.network ? "Network" : "USB");

        device = new iDevice(udid);

        ExpanderRow phoneExpander = new ExpanderRow();
        new Thread({
            try {
                lockdowndClient = new LockdowndClient(device, "sideloader");
                runInUIThread(() { if (phoneExpander) phoneExpander.setTitle(lockdowndClient.deviceName()); });
            } catch (iMobileDeviceException!lockdownd_error_t ex) {
                getLogger().errorF!"Cannot get device name for %s: %s"(deviceId, ex);
            }
        }).start();
        phoneExpander.setSubtitle(deviceId);
        phoneExpander.setIconName("phone"); {
            ActionRow installApplicationRow = new ActionRow();
            installApplicationRow.setTitle("Install application...");
            installApplicationRow.setIconName("system-software-install-symbolic");
            installApplicationRow.setActivatable(true);
            installApplicationRow.addOnActivated((_) => selectApplication());
            phoneExpander.addRow(installApplicationRow);

            ActionRow informationsRow = new ActionRow();
            informationsRow.setTitle("Informations");
            informationsRow.setIconName("info-symbolic");
            informationsRow.setActivatable(true);
            informationsRow.addOnActivated((_) {
                notImplemented();
            });
            phoneExpander.addRow(informationsRow);
        }

        add(phoneExpander);
    }

    void selectApplication() {
        auto rootWindow = cast(Window) this.getRoot();
        auto fileChooser = new FileChooserNative(
            "Select iOS application",
            rootWindow,
            FileChooserAction.OPEN,
            "_Select",
            "_Cancel"
        );
        fileChooser.setTransientFor(rootWindow);
        fileChooser.setModal(true);
        auto ipaFilter = new FileFilter();
        ipaFilter.addPattern("*.ipa");
        ipaFilter.setName("iOS application package");
        fileChooser.addFilter(ipaFilter);
        fileChooser.addOnResponse((response, _) {
            if (response == ResponseType.ACCEPT) {
                string path = fileChooser.getFile().getPath();
                getLogger().infoF!`Application "%s" selected for installation.`(path);
                try {
                    Application app = new Application(path);
                    AuthenticationAssistant.authenticate(runningApplication, (developer) {
                        SideloadProgressWindow.sideload(runningApplication, developer, app, device);
                    });
                } catch (Exception ex) {
                    getLogger().errorF!"Invalid application: %s"(ex);
                    auto errorDialog = new MessageDialog(cast(Window) this.getRoot(), DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL | DialogFlags.USE_HEADER_BAR, MessageType.ERROR, ButtonsType.CLOSE, format!"Sideloading failed: %s"(ex.msg));
                    errorDialog.addOnResponse((_, __) {
                        errorDialog.close();
                    });
                    errorDialog.show();
                }
            }
        });

        fileChooser.show();
    }
}
