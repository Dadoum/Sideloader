module ui.sideloaderapplication;

import adw.Application;
import adw.HeaderBar;
import adw.ApplicationWindow;

static import gtk.Application;
import gtk.Builder;

static import gio.Application;

import ui.mainwindow;

class SideloaderApplication: Application {
    MainWindow mainWindow;

    this() {
        super("dev.dadoum.Sideloader", GApplicationFlags.FLAGS_NONE);

        addOnActivate(&onActivate);
    }

    void onActivate(gio.Application.Application _) {
        mainWindow = new MainWindow();
        addWindow(mainWindow);
        mainWindow.show();
    }
}
