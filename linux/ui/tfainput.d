module ui.tfainput;

import std.format;

import gobject.Signals;

import gtk.Box;
import gtk.EditableIF;
import gtk.Entry;
import gtk.Label;

import ui.numberentry;

// I had code working for GTK+ 3 with 6 text inputs and all, but GTK4 broke it :(
// in the meantime, let's use a single Entry, people will be kind :)
class TFAInput: Box {
    void delegate(bool canContinue) onChanged;
    Entry codeEntry;

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
        append(new Label("Please enter the code you received"));

        codeEntry = new Entry();
        codeEntry.setMaxLength(6);
        codeEntry.setAlignment(0.5);
        codeEntry.setValign(Align.CENTER);
        codeEntry.setHalign(Align.CENTER);
        codeEntry.addOnChanged((_) {
            checkNextButton();
        });
        append(codeEntry);
    }

    void checkNextButton() {
        bool complete = codeEntry.getText().length == 6;

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
