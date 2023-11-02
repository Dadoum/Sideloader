module ui.loginframe;

import core.thread;

import std.conv;
import std.format;
import std.sumtype;

import dlangui;

import provision;

import server.appleaccount;
import server.developersession;

import ui.tfaframe;

class LoginFrame: VerticalLayout {
    EditLine usernameLine;
    EditLine passwordLine;

    this(Device device, ADI adi, void delegate(DeveloperSession) onCompletion) {
        auto errorLabel = new TextWidget("LOGIN_ERROR", ""d);
        errorLabel.alignment = Align.Center;
        errorLabel.textColor = Color.firebrick;
        errorLabel.visibility = Visibility.Invisible;
        addChild(errorLabel);

        auto credentialsTable = new TableLayout("CREDS");
        credentialsTable.layoutWidth = FILL_PARENT;
        credentialsTable.colCount = 2;
        {
            credentialsTable.addChild(new TextWidget(null, "Apple ID:"d));

            usernameLine = new EditLine("USERNAME", ""d);
            usernameLine.alignment = Align.VCenter;
            usernameLine.layoutWidth = FILL_PARENT;
            credentialsTable.addChild(usernameLine);

            credentialsTable.addChild(new TextWidget(null, "Password:"d));

            passwordLine = new EditLine("PASSWORD", ""d);
            passwordLine.passwordChar = '\u2022';
            passwordLine.alignment = Align.VCenter;
            passwordLine.layoutWidth = FILL_PARENT;
            credentialsTable.addChild(passwordLine);
        }
        addChild(credentialsTable);

        auto onlyToAppleLabel = new TextWidget(null, "your credentials are only sent to Apple"d);
        onlyToAppleLabel.alignment = Align.Center;
        addChild(onlyToAppleLabel);

        auto loginBox = new HorizontalLayout();
        loginBox.layoutWidth = FILL_PARENT;
        {
            loginBox.addChild(new HSpacer());

            auto button = new Button(null, "Log-in"d);
            button.click = (_) {
                string username = usernameLine.text().to!string();
                string password = passwordLine.text().to!string();

                setBusy(true);

                new Thread({
                    DeveloperSession session = DeveloperSession.login(
                        device,
                        adi,
                        username,
                        password,
                            (sendCode, submitCode) {
                            import slf4d;
                            getLogger().error("Cannot handle 2FA yet");
                            auto window = window();
                            window.executeInUiThread({
                                TFAFrame.tfa(window.parentWindow(), sendCode, submitCode);
                                window.close();
                            });
                            // sendCode();
                            // stdout.flush();
                            // string code = readln();
                            // submitCode(code);
                        }).match!(
                            (DeveloperSession session) => session,
                            (AppleLoginError error) {
                            errorLabel.executeInUiThread({
                                errorLabel.text = format!"%s (%d)"d(error.description, error);
                                errorLabel.visibility = Visibility.Visible;

                                setBusy(false);
                            });
                            return null;
                        });

                    if (session) {
                        auto window = window();
                        window.executeInUiThread({
                            window.close();
                            onCompletion(session);
                        });
                    }
                }).start();
                return true;
            };
            loginBox.addChild(button);
        }
        addChild(loginBox);
        setBusy(true);
    }

    void setBusy(bool val) {
        window().overrideCursorType(val ? CursorType.WaitArrow : CursorType.NotSet);
        // usernameLine.enabled = val;
        // passwordLine.enabled = val;
        enabled = !val;
    }

    static void login(Device device, ADI adi, Window parentWindow, void delegate(DeveloperSession) onCompletion) {
        auto loginWindow = Platform.instance.createWindow("Log-in to Apple", parentWindow, WindowFlag.ExpandSize, 1, 1);
        loginWindow.mainWidget = new LoginFrame(device, adi, onCompletion);
        loginWindow.windowOrContentResizeMode = WindowOrContentResizeMode.resizeWindow;
        loginWindow.show();
    }
}
