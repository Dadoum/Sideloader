module ui.authenticationassistant;

import glib.Timeout;

import gtk.Box;
import gtk.Button;
import gtk.Dialog;
import gtk.Entry;
import gtk.Label;
import gtk.Stack;
import gtk.Window;

import adw.HeaderBar;

import server.developersession;

import ui.logininput;
import ui.sideloaderapplication;
import ui.tfainput;

// Terrible code written at 2:00 AM
class AuthenticationAssistant: Dialog {
    SideloaderApplication app;
    Stack stack;

    LoginInput loginInput;
    TFAInput tfaInput;

    this(SideloaderApplication app) {
        super();
        this.setResizable(false);
        this.setDefaultSize(410, 1);
        this.setTransientFor(app.mainWindow);
        this.setModal(true);
        this.setTitle("Log-in to your Apple account.");

        Button loginButton;
        Button backButton;

        auto headerBar = new HeaderBar();
        /+ headerBar.addCssClass("flat"); +/ {
            loginButton = new Button("Log in");

            backButton = new Button("Back");
            backButton.addOnClicked((_) {
                backButton.hide();
                loginButton.setLabel("Log in");
                loginButton.setSensitive(true);
                loginInput.setSensitive(true);
                loginInput.hideError();
                stack.setVisibleChild(loginInput);
                loginInput.grabFocus();
            });
            backButton.setIconName("go-previous-symbolic");
            backButton.setHalign(Align.START);
            headerBar.packStart(backButton);
            backButton.hide();

            loginButton.addOnClicked((_) {
                loginButton.setSensitive(false);
                loginInput.setSensitive(false);
                tfaInput.setSensitive(false);


            });
            loginButton.addCssClass("suggested-action");
            loginButton.setHalign(Align.END);
            headerBar.packEnd(loginButton);
        }
        this.setTitlebar(headerBar);

        stack = new Stack();
        stack.setTransitionType(StackTransitionType.SLIDE_LEFT_RIGHT); {
            loginInput = new LoginInput();
            loginInput.onChanged = (canContinue) {
                loginButton.setSensitive(canContinue);
            };
            loginInput.checkNextButton();
            stack.addChild(loginInput);

            tfaInput = new TFAInput();
            tfaInput.onChanged = (canContinue) {
                loginButton.setSensitive(canContinue);
            };
            stack.addChild(tfaInput);
        }
        this.setChild(stack);
    }

    static DeveloperSession authenticate(SideloaderApplication app) {
        AuthenticationAssistant authenticationAssistant = new AuthenticationAssistant(app);
        authenticationAssistant.show();

        return null;
    }
}
