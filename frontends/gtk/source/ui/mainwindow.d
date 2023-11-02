module ui.mainwindow;

import gdk.Cursor;

import gio.Menu;

import gtk.Box;
import gtk.Button;
import gtk.ComboBox;
import gtk.Entry;
import gtk.Label;
import gtk.MenuButton;

import adw.Clamp;
import adw.HeaderBar;
import adw.StatusPage;
import adw.Window;

import constants;
import imobiledevice;

import ui.devicewidget;
import ui.utils;

class MainWindow: Window {
    DeviceWidget[iDeviceInfo] deviceWidgets;
    private Box devicesBox;

    Label connectDeviceLabel;

    Cursor defaultCursor;
    Cursor waitCursor;

    this() {
        // setTitle(applicationName);
        setTitle("");
        setDefaultSize(600, 400);

        defaultCursor = this.getCursor();
        waitCursor = new Cursor("wait", defaultCursor);

        Box mainWindowBox = new Box(Orientation.VERTICAL, 4); {
            HeaderBar headerBar = new HeaderBar();
            headerBar.addCssClass("flat"); {
                auto hamburgerButton = new MenuButton(); {
                    hamburgerButton.setProperty("direction", ArrowType.NONE);

                    Menu menu = new Menu();

                    Menu accountActions = new Menu(); {
                        // accountActions.append("Log-in", "app.log-in");
                        accountActions.append("Manage App IDs", "app.manage-app-ids");
                        accountActions.append("Manage certificates", "app.manage-certificates");
                    }
                    menu.appendSection(null, accountActions);

                    Menu appActions = new Menu(); {
                        appActions.append("Settings", "app.settings");
                        appActions.append("Donate", "app.donate");
                        appActions.append("About " ~ applicationName, "app.about");
                    }
                    menu.appendSection(null, appActions);

                    hamburgerButton.setMenuModel(menu);
                }
                headerBar.packEnd(hamburgerButton);

                auto refreshDevicesButton = new Button("Refresh device list"); {
                    refreshDevicesButton.setIconName("view-refresh-symbolic");
                    refreshDevicesButton.addOnClicked((_) {
                        setBusy(true);
                        uiTry!({
                            scope(exit) setBusy(false);
                            foreach (k, dw; deviceWidgets) {
                                removeDeviceWidget(k);
                            }

                            foreach (dev; iDevice.deviceList()) {
                                addDeviceWidget(dev);
                            }
                        });
                    });
                }
                headerBar.packStart(refreshDevicesButton);
            }
            mainWindowBox.append(headerBar);

            StatusPage content = new StatusPage();
            content.setTitle(applicationName); {
                Clamp clamp = new Clamp(); {
                    devicesBox = new Box(Orientation.VERTICAL, 0); {
                        connectDeviceLabel = new Label("Please connect a device.");
                        devicesBox.append(connectDeviceLabel);
                    }
                    clamp.setChild(devicesBox);
                }
                content.setChild(clamp);
            }
            mainWindowBox.append(content);
        }
        setChild(mainWindowBox);
    }

    void setBusy(bool val) {
        this.setSensitive(!val);
        this.setCursor(val ? waitCursor : defaultCursor);
    }

    void addDeviceWidget(iDeviceInfo deviceInfo) {
        if (deviceInfo !in deviceWidgets) {
            connectDeviceLabel.hide();
            auto deviceWidget = new DeviceWidget(deviceInfo);
            deviceWidgets[deviceInfo] = deviceWidget;
            devicesBox.append(deviceWidgets[deviceInfo]);
        }
    }

    void removeDeviceWidget(iDeviceInfo deviceId) {
        if (deviceId in deviceWidgets) {
            auto deviceWidget = deviceWidgets[deviceId];
            deviceWidget.unparent();
            deviceWidget.closeWindows();
            deviceWidgets.remove(deviceId);
            if (deviceWidgets.length == 0) {
                connectDeviceLabel.show();
            }
        }
    }
}
