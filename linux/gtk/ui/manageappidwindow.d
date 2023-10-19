module ui.manageappidwindow;

import core.thread;

import file = std.file;

import adw.ActionRow;
import adw.ExpanderRow;

import gdk.Cursor;

import gtk.Dialog;
import gtk.FileChooserNative;
import gtk.FileFilter;
import gtk.ListBox;
import gtk.ScrolledWindow;
import gtk.Window;

import server.developersession;

import ui.utils;

class ManageAppIdWindow: Dialog {
    ListBox appIdListBox;

    Cursor defaultCursor;
    Cursor waitCursor;

    this(Window mainWindow, DeveloperSession session) {
        this.setTitle("Manage App IDs");
        this.setTransientFor(mainWindow);
        this.setDefaultSize(500, 300);
        this.setModal(true);

        defaultCursor = this.getCursor();
        waitCursor = new Cursor("wait", defaultCursor);

        auto scroll = new ScrolledWindow();
        appIdListBox = new ListBox(); {
            // TODO teams
            setBusy(true);
            new Thread({
                auto team = session.listTeams().unwrap()[0];
                auto appIdsResponse = session.listAppIds!iOS(team).unwrap();
                runInUIThread({
                    foreach (appId; appIdsResponse.appIds) {
                        appIdListBox.append(new CertificateRow(this, session, team, appId));
                    }
                    setBusy(false);
                });
            }).start();
        }
        scroll.setChild(appIdListBox);
        this.setChild(scroll);
    }

    void setBusy(bool val) {
        this.setSensitive(!val);
        this.setCursor(val ? waitCursor : defaultCursor);
    }

    class CertificateRow: ExpanderRow {
        this(ManageAppIdWindow window, DeveloperSession session, DeveloperTeam team, AppId appId) {
            this.setTitle(appId.name);
            this.setSubtitle(appId.identifier);

            ActionRow expirationDate = new ActionRow();
            expirationDate.setTitle("Expires on " ~ appId.expirationDate.toSimpleString());
            this.addRow(expirationDate);

            ActionRow manageFeaturesRow = new ActionRow();
            manageFeaturesRow.setTitle("Manage features");
            manageFeaturesRow.setActivatable(true);
            manageFeaturesRow.addOnActivated((_) {
                notImplemented();
            });
            this.addRow(manageFeaturesRow);

            ActionRow downloadMPRow = new ActionRow();
            downloadMPRow.setTitle("Download Provisioning Profile");
            downloadMPRow.setActivatable(true);
            downloadMPRow.addOnActivated((_) {
                auto fileChooser = new FileChooserNative(
                    "Save Provisioning Profile",
                    window,
                    FileChooserAction.SAVE,
                    "_Save",
                    "_Cancel"
                );
                fileChooser.setTransientFor(window);
                fileChooser.setModal(true);
                auto mpFilter = new FileFilter();
                mpFilter.addPattern("*.mobileprovision");
                mpFilter.addSuffix(".mobileprovision");
                mpFilter.setName("Apple Provisioning Profile");
                fileChooser.addFilter(mpFilter);
                fileChooser.setCurrentName(appId.identifier ~ ".mobileprovision");
                fileChooser.addOnResponse((response, _) {
                    if (response == ResponseType.ACCEPT) {
                        setBusy(true);
                        new Thread({
                            uiTry({
                                scope(exit) runInUIThread(() => setBusy(false));

                                auto profile = session.downloadTeamProvisioningProfile!iOS(team, appId).unwrap();
                                string path = fileChooser.getFile().getPath();
                                file.write(path, profile.encodedProfile);
                            });
                        }).start();
                    }
                });
                fileChooser.show();
            });
            this.addRow(downloadMPRow);

            ActionRow deleteAppIdRow = new ActionRow();
            deleteAppIdRow.setTitle("Delete App ID");
            deleteAppIdRow.setSubtitle("That won't let you create more App IDs though");
            deleteAppIdRow.setActivatable(true);
            deleteAppIdRow.addOnActivated((_) {
                setBusy(true);
                new Thread({
                    uiTry({
                        scope(exit) runInUIThread(() => setBusy(false));
                        session.deleteAppId!iOS(team, appId).unwrap();
                        runInUIThread(() => unparent());
                    });
                }).start();
            });
            this.addRow(deleteAppIdRow);
        }
    }
}
