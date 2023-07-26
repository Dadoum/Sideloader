module ui.authentication.loginslide;

import core.thread;

import std.concurrency;
import std.format;
import std.sumtype;

import slf4d;

import glib.Timeout;

import gtk.Box;
import gtk.Entry;
import gtk.Label;
import gtk.Widget;

import server.appleaccount;
import server.developersession;

import ui.authentication.assistantslide;
import ui.authentication.authenticationassistant;
import ui.authentication.tfaslide;
import ui.sideloadergtkapplication;

import ui.utils;

class LoginSlide: Box, AssistantSlide {
    string title() => "Log-in to your Apple account";
    string nextButtonLabel() => "Log-in";

    Entry appleIdEntry;
    Entry passwordEntry;

    Label errorLabel;

    AuthenticationAssistant authAssistant;
    DeveloperAction action;

    this(AuthenticationAssistant authAssistant, DeveloperAction action) {
        this.authAssistant = authAssistant;
        this.action = action;

        super(Orientation.VERTICAL, 4);
        setMarginTop(6);
        setMarginBottom(6);
        setMarginStart(6);
        setMarginEnd(6);

        errorLabel = new Label("");
        append(errorLabel);
        errorLabel.setMarginBottom(4);
        errorLabel.setUseMarkup(true);
        errorLabel.setSelectable(true);
        errorLabel.setWrap(true);
        errorLabel.hide();

        auto credBox = new Box(Orientation.VERTICAL, 4); {
            appleIdEntry = new Entry();
            appleIdEntry.setPlaceholderText("Apple ID");
            appleIdEntry.addOnChanged((_) => checkNextButton());
            credBox.append(appleIdEntry);

            passwordEntry = new Entry();
            passwordEntry.setVisibility(false);
            passwordEntry.setPlaceholderText("Password");
            passwordEntry.addOnChanged((_) => checkNextButton());
            passwordEntry.addOnActivate((_) {
                if (authAssistant.getCanNext()) {
                    executeSlide();
                }
            });
            credBox.append(passwordEntry);
        }
        append(credBox);

        Label label = new Label("<small>your credentials are <b>only</b> sent to Apple</small>");
        label.setUseMarkup(true);
        append(label);

        checkNextButton();
    }

    void checkNextButton() {
        authAssistant.setCanNext(appleIdEntry.getText() != "" && passwordEntry.getText() != "");
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
        string appleId = appleIdEntry.getText();
        string password = passwordEntry.getText();

        authAssistant.setSensitive(false);
        authAssistant.setCursor(authAssistant.waitCursor);

        new Thread({
            uiTry({
                DeveloperSession appleAccount = DeveloperSession.login(
                    runningApplication.device,
                    runningApplication.adi,
                    appleId,
                    password,
                        (sendCode, submitCode) {

                        auto tid = thisTid;
                        runInUIThread({
                            authAssistant.next(new TFASlide(authAssistant, tid, sendCode, submitCode));
                        });

                        receive((bool) {});
                    }).match!(
                        (DeveloperSession session) => session,
                        (AppleLoginError error) {
                        auto errorStr = format!"%s (%d)"(error.description, error);
                        getLogger().errorF!"Apple auth error: %s"(errorStr);
                        runInUIThread({
                            errorLabel.show();
                            errorLabel.setMarkup(format!`<span foreground="red">%s</span>`(errorStr));
                            authAssistant.setSensitive(true);
                            authAssistant.setCursor(authAssistant.defaultCursor);
                        });
                        return null;
                    }
                );

                if (appleAccount) {
                    runInUIThread({
                        authAssistant.close();
                        action(appleAccount);
                    });
                }
            });
        }).start();
    }

    void cancelSlide() {}
}
