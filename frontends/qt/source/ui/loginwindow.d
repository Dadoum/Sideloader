/++
    Apple ID sign-in.

    Runs on the UI thread on purpose. Signing in can trigger a two-factor
    prompt, which needs a dialog, and driving a dialog from the worker thread
    would mean marshalling both ways and blocking it while the user types.
    Only the install itself is threaded, and it needs no interaction.

    Credentials are handed straight to DeveloperSession.login, which talks to
    Apple. Nothing is stored or logged here.
+/
module ui.loginwindow;

import core.stdcpp.new_: cpp_new;

import std.conv;
import std.sumtype;

import slf4d;

import provision;

import server.appleaccount;
import server.developersession;

import qt.core.namespace;
import qt.core.object;
import qt.core.objectdefs;
import qt.core.string;
import qt.helpers;
import qt.widgets.boxlayout;
import qt.widgets.dialog;
import qt.widgets.inputdialog;
import qt.widgets.label;
import qt.widgets.lineedit;
import qt.widgets.messagebox;
import qt.widgets.pushbutton;
import qt.widgets.widget;

import ui.chrome;

/++
    Asks for an Apple ID and signs in.

    Returns null if the user cancels or if Apple rejects the credentials; in
    the latter case the error has already been shown.
+/
DeveloperSession promptLogin(QWidget parent, Device device, ADI adi) {
    auto log = getLogger();

    auto dialog = cpp_new!QDialog(parent);
    dialog.setWindowTitle(*cpp_new!QString("Sign in to Apple"));
    dialog.setMinimumWidth(400);
    // The dialog is a separate native window, so it needs the dark title bar
    // asked for on its own handle. Flags first: changing them recreates the
    // native window, which would discard the attribute.
    dialog.setWindowFlags(WindowType.Dialog | WindowType.WindowTitleHint
        | WindowType.WindowCloseButtonHint);
    applyDarkTitleBar(cast(size_t) dialog.winId());

    auto layout = cpp_new!QVBoxLayout(dialog);
    layout.setContentsMargins(22, 20, 22, 18);
    layout.setSpacing(10);

    auto title = cpp_new!QLabel(*cpp_new!QString("Sign in to Apple"));
    title.setObjectName(*cpp_new!QString("dialogTitle"));
    layout.addWidget(title);

    auto blurb = cpp_new!QLabel(*cpp_new!QString(
        "Sideloader needs a developer session to sign the app.\n"
        ~ "Your credentials are only ever sent to Apple."));
    blurb.setObjectName(*cpp_new!QString("dialogHint"));
    blurb.setWordWrap(true);
    layout.addWidget(blurb);

    auto appleIdLine = cpp_new!QLineEdit(dialog);
    appleIdLine.setPlaceholderText(*cpp_new!QString("Apple ID"));
    layout.addWidget(appleIdLine);

    auto passwordLine = cpp_new!QLineEdit(dialog);
    passwordLine.setPlaceholderText(*cpp_new!QString("Password"));
    passwordLine.setEchoMode(QLineEdit.EchoMode.Password);
    layout.addWidget(passwordLine);

    auto buttonRow = cpp_new!QHBoxLayout();
    buttonRow.addStretch(1);
    auto cancelButton = cpp_new!QPushButton(*cpp_new!QString("Cancel"));
    auto signInButton = cpp_new!QPushButton(*cpp_new!QString("Sign in"));
    signInButton.setObjectName(*cpp_new!QString("installButton")); // accent styling
    signInButton.setDefault(true);
    buttonRow.addWidget(cancelButton);
    buttonRow.addWidget(signInButton);
    layout.addLayout(buttonRow);

    QObject.connect(signInButton.signal!"clicked", dialog.slot!"accept");
    QObject.connect(cancelButton.signal!"clicked", dialog.slot!"reject");

    if (dialog.exec() != QDialog.DialogCode.Accepted)
        return null;

    string appleId = appleIdLine.text().toConstWString().to!string();
    string password = passwordLine.text().toConstWString().to!string();

    DeveloperSession session = DeveloperSession.login(
        device, adi, appleId, password,
        (Send2FADelegate send, Submit2FADelegate submit) {
            if (!send()) {
                log.error("Could not send the two-factor code.");
                return;
            }

            bool accepted;
            QString code = QInputDialog.getText(
                parent,
                *cpp_new!QString("Two-factor authentication"),
                *cpp_new!QString("Enter the code sent to your devices:"),
                QLineEdit.EchoMode.Normal,
                globalInitVar!QString,
                &accepted);

            if (!accepted)
                return;

            submit(code.toConstWString().to!string());
        }
    ).match!(
        (DeveloperSession session) => session,
        (AppleLoginError error) {
            log.errorF!"Apple sign-in failed: %s (%d)"(error.description, error);
            QMessageBox.critical(
                parent,
                *cpp_new!QString("Sign-in failed"),
                *cpp_new!QString(error.description));
            return null;
        }
    );

    return session;
}
