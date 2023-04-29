module ui.devicewidget;

import adw.ActionRow;
import adw.ExpanderRow;
import adw.PreferencesGroup;

import gtk.Dialog;
import gtk.Label;
import gtk.Window;

import imobiledevice;

class DeviceWidget: PreferencesGroup {
    iDevice device;
    LockdowndClient lockdowndClient;

    this(string udid) {
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
        phoneExpander.setSubtitle(udid);
        phoneExpander.setIconName("phone"); {
            ActionRow installApplicationRow = new ActionRow();
            installApplicationRow.setTitle("Install application...");
            installApplicationRow.setIconName("system-software-install-symbolic");
            installApplicationRow.setActivatable(true);
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
}
