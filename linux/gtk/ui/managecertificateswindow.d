module ui.managecertificateswindow;

import core.thread;

import adw.ActionRow;
import adw.ExpanderRow;

import gdk.Cursor;

import gtk.Dialog;
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

        }
    }
}
