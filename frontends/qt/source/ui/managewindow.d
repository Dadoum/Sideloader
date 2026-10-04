/++
    App ID and certificate management.

    Both are the same screen: a list of things held by the developer account,
    and a way to remove one. Apple caps free accounts at ten App IDs and a
    handful of certificates, so removing stale entries is the difference
    between installing and being stuck.

    Requests run on the UI thread, like sign-in: these are short, modal
    operations, and threading them would buy a frozen dialog nobody can
    interact with anyway. The wait cursor covers the pause.
+/
module ui.managewindow;

import core.stdcpp.new_: cpp_new;

import std.algorithm : map;
import std.array : array;
import std.conv;
import std.format;

import slf4d;

import server.developersession;

import qt.core.namespace;
import qt.core.object;
import qt.core.objectdefs;
import qt.core.string;
import qt.core.stringlist;
import qt.gui.cursor;
import qt.helpers;
import qt.widgets.application;
import qt.widgets.boxlayout;
import qt.widgets.dialog;
import qt.widgets.label;
import qt.widgets.listwidget;
import qt.widgets.messagebox;
import qt.widgets.pushbutton;
import qt.widgets.widget;

import ui.chrome;

/// What the dialog manages; the two differ only in wording and in the two
/// portal calls used.
enum ManagedKind {
    appIds,
    certificates,
}

/++
    Shows the account's App IDs or certificates, with a way to remove one.

    Does nothing if the session is null: the caller is expected to have signed
    in first.
+/
void showManageDialog(QWidget parent, DeveloperSession session, ManagedKind kind) {
    if (!session) {
        QMessageBox.information(
            parent,
            *cpp_new!QString("Not signed in"),
            *cpp_new!QString("Sign in to your Apple account first."));
        return;
    }

    auto log = getLogger();

    immutable bool isAppIds = kind == ManagedKind.appIds;
    string title = isAppIds ? "App IDs" : "Certificates";

    auto dialog = cpp_new!QDialog(parent);
    dialog.setWindowTitle(*cpp_new!QString(title));
    dialog.setMinimumSize(520, 420);
    // Explicit flags drop Qt's context-help "?" button, which does nothing
    // here. Set before winId(), since changing flags recreates the native
    // window and would discard the DWM attribute.
    dialog.setWindowFlags(WindowType.Dialog | WindowType.WindowTitleHint
        | WindowType.WindowCloseButtonHint);
    applyDarkTitleBar(cast(size_t) dialog.winId());

    auto layout = cpp_new!QVBoxLayout(dialog);
    layout.setContentsMargins(22, 20, 22, 18);
    layout.setSpacing(10);

    auto heading = cpp_new!QLabel(*cpp_new!QString(title));
    heading.setObjectName(*cpp_new!QString("dialogTitle"));
    layout.addWidget(heading);

    auto quota = cpp_new!QLabel(*cpp_new!QString(""));
    quota.setObjectName(*cpp_new!QString("dialogHint"));
    quota.setWordWrap(true);
    layout.addWidget(quota);

    auto list = cpp_new!QListWidget(dialog);
    layout.addWidget(list);

    auto buttonRow = cpp_new!QHBoxLayout();
    auto removeButton = cpp_new!QPushButton(
        *cpp_new!QString(isAppIds ? "Delete" : "Revoke"));
    removeButton.setEnabled(false);
    buttonRow.addWidget(removeButton);
    buttonRow.addStretch(1);
    auto closeButton = cpp_new!QPushButton(*cpp_new!QString("Close"));
    buttonRow.addWidget(closeButton);
    layout.addLayout(buttonRow);

    // Kept alongside the rows so a selection maps back to a portal object.
    AppId[] appIds;
    DevelopmentCertificate[] certificates;

    void reload() {
        QApplication.setOverrideCursor(*cpp_new!QCursor(CursorShape.WaitCursor));
        scope(exit) QApplication.restoreOverrideCursor();

        list.clear();
        appIds = null;
        certificates = null;

        try {
            auto team = session.listTeams().unwrap()[0];

            if (isAppIds) {
                auto response = session.listAppIds!iOS(team).unwrap();
                appIds = response.appIds;

                foreach (appId; appIds)
                    list.addItem(*cpp_new!QString(
                        format!"%s  —  %s"(appId.name, appId.identifier)));

                quota.setText(*cpp_new!QString(format!
                    "%d of %d used. Apple frees a slot only when an App ID expires, so delete what you no longer install."
                    (response.maxQuantity - response.availableQuantity, response.maxQuantity)));
            } else {
                certificates = session.listAllDevelopmentCerts!iOS(team).unwrap();

                foreach (certificate; certificates)
                    list.addItem(*cpp_new!QString(
                        format!"%s  —  %s"(certificate.name, certificate.machineName)));

                quota.setText(*cpp_new!QString(
                    "Revoking a certificate breaks every app already signed with it; they stop launching until reinstalled."));
            }
        } catch (Exception ex) {
            log.errorF!"Could not list %s: %s"(title, ex);
            QMessageBox.critical(
                dialog,
                *cpp_new!QString("Request failed"),
                *cpp_new!QString(ex.msg));
        }
    }

    QObject.connect(list.signal!"itemSelectionChanged", delegate() {
        removeButton.setEnabled(list.currentRow() >= 0);
    });

    QObject.connect(removeButton.signal!"clicked", delegate() {
        int row = list.currentRow();
        if (row < 0)
            return;

        string what = isAppIds
            ? format!"Delete the App ID \"%s\"?"(appIds[row].identifier)
            : format!"Revoke the certificate \"%s\"?"(certificates[row].name);

        auto answer = QMessageBox.question(
            dialog,
            *cpp_new!QString(isAppIds ? "Delete App ID" : "Revoke certificate"),
            *cpp_new!QString(what));

        if (answer != QMessageBox.StandardButton.Yes)
            return;

        QApplication.setOverrideCursor(*cpp_new!QCursor(CursorShape.WaitCursor));
        scope(exit) QApplication.restoreOverrideCursor();

        try {
            auto team = session.listTeams().unwrap()[0];
            if (isAppIds)
                session.deleteAppId!iOS(team, appIds[row]).unwrap();
            else
                session.revokeDevelopmentCert!iOS(team, certificates[row]).unwrap();
        } catch (Exception ex) {
            log.errorF!"Removal failed: %s"(ex);
            QMessageBox.critical(
                dialog,
                *cpp_new!QString("Removal failed"),
                *cpp_new!QString(ex.msg));
        }

        reload();
    });

    QObject.connect(closeButton.signal!"clicked", dialog.slot!"accept");

    reload();
    dialog.exec();
}
