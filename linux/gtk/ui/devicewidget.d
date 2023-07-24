module ui.devicewidget;

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

class DeviceWidget: PreferencesGroup {
    iDevice device;
    LockdowndClient lockdowndClient;

    this(string deviceId, string udid) {
        device = new iDevice(udid);
        string deviceName;
        try {
            lockdowndClient = new LockdowndClient(device, "sideloader");
            deviceName = lockdowndClient.deviceName();
        } catch (LockdowndException) {
            deviceName = null;
        }

        ExpanderRow phoneExpander = new ExpanderRow();
        phoneExpander.setTitle(deviceName);
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
                Dialog dialog = new Dialog();
                dialog.getContentArea().append(new Label("Not implemented yet"));
                dialog.setTransientFor(cast(Window) this.getRoot());
                dialog.setModal(true);
                dialog.addButton("OK", 0);
                dialog.addOnResponse((_a, _b) => dialog.close());
                dialog.show();
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
