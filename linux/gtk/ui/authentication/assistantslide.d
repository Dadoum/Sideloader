module ui.authentication.assistantslide;

import gtk.Widget;

interface AssistantSlide {
    string title();
    string nextButtonLabel();

    Widget widget();
    void executeSlide();

    void cancelSlide();
}
