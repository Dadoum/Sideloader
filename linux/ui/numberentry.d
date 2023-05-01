module ui.numberentry;

import std.algorithm;

import slf4d;

import gtk.EditableIF;
import gtk.EditableT;
import gtk.Entry;
import gtk.Text;

import gtk.Implement;
import gobject.c.functions : g_object_newv;

import gobject.Signals;

class NumberEntry: Entry {
    // mixin ImplementClass!GtkText;
    // mixin ImplementInterface!(GtkEntry, GtkEditableInterface);

    // mixin EditableT!(GtkEntry);

    this() {
        // super(cast(GtkEntry*)g_object_newv(getType(), 0, null), true);
        setWidthChars(1);
        setAlignment(0.5);

        auto font = getPangoContext().getFontDescription();
        font.setAbsoluteSize(font.getSize() * 3);
        getPangoContext().setFontDescription(font);

        setSizeRequest(0, 30);
        setMaxLength(1);

        Signals.connect(this, "insert-text", () {
            // it doesn't work :(
        });
    }
}
