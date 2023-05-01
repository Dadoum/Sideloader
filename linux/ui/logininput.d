module ui.logininput;

import std.format;

import gtk.Box;
import gtk.Entry;
import gtk.Label;

class LoginInput: Box {
    void delegate(bool canContinue) onChanged;

    Entry appleIdEntry;
    Entry passwordEntry;

    Label errorLabel;

    this() {
        super(Orientation.VERTICAL, 4);
        setMarginTop(6);
        setMarginBottom(6);
        setMarginStart(6);
        setMarginEnd(6);

        errorLabel = new Label("");
        append(errorLabel);
        errorLabel.setMarginBottom(4);
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
            credBox.append(passwordEntry);
        }
        append(credBox);

        Label label = new Label("<small>your credentials are <b>only</b> sent to Apple</small>");
        label.setUseMarkup(true);
        append(label);
    }

    void checkNextButton() {
        bool complete = appleIdEntry.getText() != "" && passwordEntry.getText() != "";

        if (onChanged != null) {
            onChanged(complete);
        }
    }

    void setError(string error) {
        errorLabel.setMarkup(format!"<span foreground='red'>%s</span>"(error));
        errorLabel.show();
    }

    void hideError() {
        errorLabel.hide();
    }
}
