module ui.utils;

import qt.widgets.layout;
import qt.widgets.layoutitem;
import qt.widgets.widget;

/++
    Empties a layout, widgets included.

    takeAt() only unmanages the item: the widget stays a child of the parent
    and keeps painting itself at its last geometry. Dropping it from the
    layout is not enough, it has to be reparented away too.
+/
void clearLayout(QLayout layout)
{
    while (QLayoutItem item = layout.takeAt(0))
    {
        if (QWidget widget = item.widget())
        {
            widget.hide();
            widget.setParent(null);
        }
        destroy(item);
    }
}
