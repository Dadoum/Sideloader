module ui.toolselectionwindow;

import core.thread;

import std.concurrency;

import adw.ActionRow;

import gdk.Cursor;

import gtk.Dialog;
import gtk.ListBox;
import gtk.MessageDialog;
import gtk.ScrolledWindow;
import gtk.Window;

import imobiledevice;

import tools;

import ui.utils;

class ToolSelectionWindow: Dialog {
    ListBox toolListBox;

    Cursor defaultCursor;
    Cursor waitCursor;

    this(Window parent, iDevice device) {
        this.setTitle("Additional tools");
        this.setTransientFor(parent);
        this.setDefaultSize(400, 400);
        this.setModal(true);

        defaultCursor = this.getCursor();
        waitCursor = new Cursor("wait", defaultCursor);

        auto scroll = new ScrolledWindow();

        Tool[] tools = toolList(device);

        toolListBox = new ListBox(); {
            foreach (tool; tools) {
                ActionRow toolRow = new ActionRow();
                toolRow.setTitle(tool.name());

                string diagnostic = tool.diagnostic();
                toolRow.setActivatable(diagnostic == null);
                if (diagnostic != null) {
                    toolRow.setTooltipText(diagnostic);
                }
                toolRow.addOnActivated((_) {
                    setBusy(true);
                    new Thread({
                        uiTry!(() => tool.run((string message, bool canCancel = true) {
                                Tid parentTid = thisTid();
                                runInUIThread({
                                    auto messageDialog = new MessageDialog(this, DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL, MessageType.INFO, canCancel ? ButtonsType.OK_CANCEL : ButtonsType.OK, message);
                                    messageDialog.addOnResponse((response, _) {
                                        if (canCancel) {
                                            parentTid.send(response != ResponseType.OK);
                                        } else {
                                            parentTid.send(true);
                                        }
                                        messageDialog.close();
                                    });
                                    messageDialog.show();
                                });
                                return receiveOnly!bool();
                            })
                        )(this);
                        runInUIThread({
                            setBusy(false);
                        });
                    }).start();
                });

                toolListBox.append(toolRow);
            }
        }

        scroll.setChild(toolListBox);
        this.setChild(scroll);
    }

    void setBusy(bool val) {
        this.setSensitive(!val);
        this.setCursor(val ? waitCursor : defaultCursor);
    }
}
