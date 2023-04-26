module ui.mainwindow;

import gio.Menu;

import gtk.Box;
import gtk.ComboBox;
import gtk.Entry;
import gtk.MenuButton;
import gtk.ScrolledWindow;

import adw.Clamp;
import adw.HeaderBar;
import adw.Window;

import constants;

class MainWindow: Window {
    this() {
        setTitle(applicationName);

        Box mainWindowBox = new Box(Orientation.VERTICAL, 4); {
            HeaderBar headerBar = new HeaderBar();
            headerBar.getStyleContext().addClass("flat"); {
                auto hamburgerButton = new MenuButton();
                hamburgerButton.setProperty("direction", ArrowType.NONE);

                Menu menu = new Menu();
                Menu appleActions = new Menu();
                appleActions.append("Delete App ID", "app.delete-app-id");
                appleActions.append("Revoke certificates", "app.revoke-certificates");
                menu.appendSection(null, appleActions);
                Menu optionsMenu = new Menu();
                optionsMenu.append("Enable app debugging", "app.enable-debug");
                menu.appendSection(null, optionsMenu);
                Menu appActions = new Menu();
                appActions.append("About " ~ applicationName, "app.about");
                menu.appendSection(null, appActions);

                hamburgerButton.setMenuModel(menu);

                headerBar.packEnd(hamburgerButton);
            }
            mainWindowBox.append(headerBar);

            ScrolledWindow content = new ScrolledWindow(); {
                Clamp clamp = new Clamp();

                content.setChild(clamp);
            }
            mainWindowBox.append(content);
        }
        setChild(mainWindowBox);
    }
}
