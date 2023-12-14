module ui.managecertificateswindow;

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

class ManageCertificatesWindow: Dialog {
    ListBox certificateListBox;

    Cursor defaultCursor;
    Cursor waitCursor;

    this(Window mainWindow, DeveloperSession session) {
        this.setTitle("Manage certificates");
        this.setTransientFor(mainWindow);
        this.setDefaultSize(500, 300);
        this.setModal(true);

        defaultCursor = this.getCursor();
        waitCursor = new Cursor("wait", defaultCursor);

        auto scroll = new ScrolledWindow();
        certificateListBox = new ListBox(); {
            // TODO teams
            setBusy(true);
            new Thread({
                auto team = session.listTeams().unwrap()[0];
                auto certificates = session.listAllDevelopmentCerts!iOS(team).unwrap();
                runInUIThread({
                    foreach (certificate; certificates) {
                        certificateListBox.append(new CertificateRow(this, session, team, certificate));
                    }
                    setBusy(false);
                });
            }).start();
        }
        scroll.setChild(certificateListBox);
        this.setChild(scroll);
    }

    void setBusy(bool val) {
        this.setSensitive(!val);
        this.setCursor(val ? waitCursor : defaultCursor);
    }

    class CertificateRow: ExpanderRow {
        this(ManageCertificatesWindow window, DeveloperSession session, DeveloperTeam team, DevelopmentCertificate certificate) {
            this.setTitle(certificate.name);
            this.setSubtitle(certificate.machineName);

            ActionRow revokeApplicationRow = new ActionRow();
            revokeApplicationRow.setTitle("Revoke");
            revokeApplicationRow.setActivatable(true);
            revokeApplicationRow.addOnActivated((_) {
                window.setBusy(true);
                new Thread({
                    session.revokeDevelopmentCert!iOS(team, certificate).unwrap();
                    runInUIThread({
                        window.setBusy(false);
                        this.unparent();
                    });
                }).start();
            });
            this.addRow(revokeApplicationRow);

            ActionRow dumpApplicationRow = new ActionRow();
            dumpApplicationRow.setTitle("Dump");
            dumpApplicationRow.setActivatable(true);
            dumpApplicationRow.addOnActivated((_) {
                auto fileChooser = new FileChooserNative(
                    "Save certificate",
                    window,
                    FileChooserAction.SAVE,
                    "_Save",
                    "_Cancel"
                );
                fileChooser.setTransientFor(window);
                fileChooser.setModal(true);
                auto mpFilter = new FileFilter();
                mpFilter.addPattern("*.der");
                mpFilter.addSuffix(".der");
                mpFilter.setName("X509 certificate");
                fileChooser.addFilter(mpFilter);
                fileChooser.setCurrentName(certificate.machineName ~ ".der");
                fileChooser.addOnResponse((response, _) {
                    if (response == ResponseType.ACCEPT) {
                        string path = fileChooser.getFile().getPath();
                        file.write(path, certificate.certContent);
                    }
                });
                fileChooser.show();
            });
            this.addRow(dumpApplicationRow);
        }
    }
}
