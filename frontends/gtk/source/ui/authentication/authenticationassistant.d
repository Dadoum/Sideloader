module ui.authentication.authenticationassistant;

import glib.Timeout;

import gdk.Cursor;

import gtk.Box;
import gtk.Button;
import gtk.Dialog;
import gtk.Entry;
import gtk.Label;
import gtk.Stack;
import gtk.Window;

import adw.HeaderBar;

import server.developersession;

import ui.authentication.assistantslide;
import ui.authentication.loginslide;
import ui.sideloadergtkapplication;

alias DeveloperAction = void delegate(DeveloperSession);

class AuthenticationAssistant: Dialog {
    SideloaderGtkApplication app;
    Stack stack;

    AssistantSlide[] slides;

    Button nextButton;
    Button backButton;

    Cursor defaultCursor;
    Cursor waitCursor;

    this(SideloaderGtkApplication app, DeveloperAction action) {
        super();
        this.setResizable(false);
        this.setDefaultSize(410, 1);
        this.setTransientFor(app.mainWindow);
        this.setModal(true);

        defaultCursor = this.getCursor();
        waitCursor = new Cursor("wait", defaultCursor);

        auto headerBar = new HeaderBar();
        headerBar.addCssClass("flat"); {
            nextButton = new Button("");

            backButton = new Button("");
            backButton.addOnClicked((_) => back());
            backButton.setIconName("go-previous-symbolic");
            backButton.setHalign(Align.START);
            headerBar.packStart(backButton);
            backButton.hide();

            nextButton.addOnClicked((_) {
                slides[$-1].executeSlide();
            });
            nextButton.addCssClass("suggested-action");
            nextButton.setHalign(Align.END);
            headerBar.packEnd(nextButton);
        }
        this.setTitlebar(headerBar);

        stack = new Stack();
        stack.setTransitionType(StackTransitionType.SLIDE_LEFT_RIGHT);
        this.setChild(stack);

        next(new LoginSlide(this, action));
        addOnClose((_) => slides[$-1].cancelSlide());
    }

    void setCanNext(bool val) {
        nextButton.setSensitive(val);
    }

    bool getCanNext() {
        return nextButton.getSensitive();
    }

    void next(AssistantSlide slide) {
        slides ~= slide;
        if (slides.length > 1) {
            backButton.show();
        }
        auto w = slide.widget();
        stack.addChild(w);
        stack.setVisibleChild(w);
        setTitle(slide.title());
        nextButton.setLabel(slide.nextButtonLabel());
        this.setSensitive(true);
        this.setCursor(defaultCursor);
    }

    void back() {
        auto lastPage = slides[$-1];
        slides.length -= 1;
        if (slides.length <= 1) {
            backButton.hide();
        }
        auto newPage = slides[$-1];
        stack.setVisibleChild(newPage.widget());
        setTitle(newPage.title());
        nextButton.setLabel(newPage.nextButtonLabel());
        stack.remove(lastPage.widget());
    }

    static void authenticate(SideloaderGtkApplication app, DeveloperAction action) {
        AuthenticationAssistant authenticationAssistant = new AuthenticationAssistant(app, action);
        authenticationAssistant.show();
    }
}
