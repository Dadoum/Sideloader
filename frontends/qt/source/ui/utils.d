module ui.utils;

import qt.widgets.layout;
import qt.widgets.layoutitem;

void clearLayout(QLayout layout)
{
    while (QLayoutItem item = layout.takeAt(0))
        destroy(item);
}
