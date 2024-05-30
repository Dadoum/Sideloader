module ui.authentication.tfaslide;

import core.thread;

import std.concurrency;
import std.format;
import std.sumtype;

import slf4d;

import glib.Timeout;

import gobject.Signals;

import gtk.Box;
import gtk.EditableIF;
import gtk.Entry;
import gtk.Label;
import gtk.LinkButton;
import gtk.Widget;

import server.appleaccount;

import ui.authentication.assistantslide;
import ui.authentication.authenticationassistant;
import ui.numberentry;
import ui.utils;

// I had code working for GTK+ 3 with 6 text inputs and all, but GTK4 broke it :(
// in the meantime, let's use a single Entry, people will be kind :)
class TFASlide: Box, AssistantSlide {
    string title() => "Log-in to your Apple account";
    string nextButtonLabel() => "Validate";

    Entry codeEntry;

    Label errorLabel;

    AuthenticationAssistant authAssistant;
    Tid mainThreadTid;
    Send2FADelegate sendCode;
    Submit2FADelegate submitCode;

    this(AuthenticationAssistant authAssistant, Tid mainThreadTid, Send2FADelegate sendCode, Submit2FADelegate submitCode) {
        this.authAssistant = authAssistant;
        this.mainThreadTid = mainThreadTid;
        this.sendCode = sendCode;
        this.submitCode = submitCode;

        super(Orientation.VERTICAL, 8);
        setMarginTop(6);
        setMarginBottom(6);
        setMarginStart(6);
        setMarginEnd(6);

        errorLabel = new Label("");
        append(errorLabel);
        errorLabel.setMarginBottom(4);
        errorLabel.setUseMarkup(true);
        errorLabel.hide();
        append(new Label("Please enter the code you received"));

        codeEntry = new Entry();
        codeEntry.setMaxLength(6);
        codeEntry.setAlignment(0.5);
        codeEntry.setValign(Align.CENTER);
        codeEntry.setHalign(Align.CENTER);
        codeEntry.addOnChanged((_) => checkNextButton());
        codeEntry.addOnActivate((_) {
            if (authAssistant.getCanNext()) {
                executeSlide();
            }
        });
        append(codeEntry);

        auto resendButton = new LinkButton("Re-send the code");
        resendButton.addOnActivateLink((_) { sendCode(); return true; }); // TODO: Show error if code isn't sent again
        append(resendButton);

        sendCode();
        checkNextButton();
    }

    void checkNextButton() {
        authAssistant.setCanNext(codeEntry.getText().length == 6);
    }

    void setError(string error) {
        errorLabel.setMarkup(format!"<span foreground='red'>%s</span>"(error));
        errorLabel.show();
    }

    void hideError() {
        errorLabel.hide();
    }

    Widget widget() {
        return this;
    }

    void executeSlide() {
        authAssistant.setSensitive(false);
        authAssistant.setCursor(authAssistant.waitCursor);

        new Thread({
            submitCode(
                codeEntry.getText()
            ).match!(
                    (AppleLoginError error) {
                    auto errorStr = format!"%s (%d)"(error.description, error);
                    getLogger().errorF!"Apple auth error: %s"(errorStr);

                    runInUIThread({
                        errorLabel.show();
                        errorLabel.setMarkup(format!`<span foreground="red">%s</span>`(errorStr));
                        authAssistant.setSensitive(true);
                        authAssistant.setCursor(authAssistant.defaultCursor);
                    });
                },
                (Success) {
                    // All right, resume auth thread!
                    send(mainThreadTid, true);
                }
            );
        }).start();
    }

    void cancelSlide() {
        send(mainThreadTid, true);
    }
}
