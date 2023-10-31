module ui.mainframe;

import core.thread;

import std.algorithm;
import std.array;
import std.concurrency;
import std.conv;
import std.format;

import slf4d;

import dlangui;
import dlangui.dialogs.filedlg;

import plist;

import imobiledevice;

import constants;
import sideload;
import tools;

import ui.utils;

class MainFrame: VerticalLayout/+, MenuItemClickHandler, MenuItemActionHandler+/ {
    string[] devices;
    ComboBox deviceBox;
    FrameLayout actionsFrame;
    VerticalLayout toolsFrame;

    EditLine deviceNameLine;
    EditLine modelLine;
    EditLine versionLine;

    Application app;

    Observer!string path;

    this() {
        auto log = getLogger();

        layoutWidth = FILL_PARENT;
        layoutHeight = FILL_PARENT;

        MenuItem menuItems = new MenuItem();
        {
            MenuItem fileItem = new MenuItem(new Action(0, "Account"d));
            {
                auto logInAction = new Action(1, "Log-in"d);
                logInAction.state = ACTION_STATE_DISABLE;
                MenuItem logInItem = new MenuItem(logInAction);
                fileItem.add(logInItem);

                MenuItem sep1 = new MenuItem();
                sep1.type = MenuItemType.Separator;
                fileItem.add(sep1);

                MenuItem appIdsItem = new MenuItem(new Action(2, "Manage App IDs"d)); // TODO
                fileItem.add(appIdsItem);

                MenuItem certificatesItem = new MenuItem(new Action(3, "Manage certificates"d)); // TODO
                fileItem.add(certificatesItem);
            }
            menuItems.add(fileItem);

            MenuItem deviceItem = new MenuItem(new Action(10, "Devices"d));
            {
                MenuItem refreshItem = new MenuItem(new Action(11, "Refresh device list"d));
                refreshItem.menuItemAction.connect((_) {
                    refreshDeviceList();
                    return true;
                });
                deviceItem.add(refreshItem);
            }
            menuItems.add(deviceItem);

            MenuItem helpItem = new MenuItem(new Action(20, "Help"d));
            {
                MenuItem donateItem = new MenuItem(new Action(21, "Donate"d));
                donateItem.menuItemAction.connect((_) {
                    import std.process;
                    browse("https://github.com/sponsors/Dadoum");
                    return true;
                });
                helpItem.add(donateItem);

                MenuItem aboutItem = new MenuItem(new Action(22, "About"d));
                aboutItem.menuItemAction.connect((_) {
                    window.showMessageBox(
                        UIString.fromRaw("About Sideloader"d),
                        UIString.fromRaw(format!(rawAboutText.to!dstring())(versionStr, "dlangui"))
                    );
                    return true;
                });
                helpItem.add(aboutItem);
            }
            menuItems.add(helpItem);
        }
        addChild(new MainMenu(menuItems));

        auto body = new VerticalLayout();
        body.layoutWidth = FILL_PARENT;
        body.layoutHeight = FILL_PARENT;
        {
            deviceBox = new ComboBox();
            deviceBox.itemClick = (_, index) {
                string udid = devices[index];
                new Thread({
                    auto device = new iDevice(udid);
                    try {
                        auto lockdown = new LockdowndClient(device, "sideloader.trust-client");
                        setUpTools(device);
                        updateDeviceInfo(lockdown);
                        actionsFrame.showChild("ACTIONS");
                    } catch (iMobileDeviceException!lockdownd_error_t err) {
                        log.infoF!"Can't connect to the device: %s"(err.underlyingError);
                        actionsFrame.showChild("TRUST");
                    } catch (Exception ex) {
                        log.infoF!"Can't connect to the device: %s"(ex);
                    }
                    window().invalidate();
                }).start();
                return true;
            };
            deviceBox.layoutWidth = FILL_PARENT;
            body.addChild(deviceBox);

            actionsFrame = new FrameLayout();
            actionsFrame.layoutWidth = FILL_PARENT;
            actionsFrame.layoutHeight = FILL_PARENT;
            {
                auto trustLabel = new TextWidget("TRUST", "Please unlock your device and trust the computer"d);
                trustLabel.alignment = Align.Center;
                actionsFrame.addChild(trustLabel);

                auto actions = new TabWidget("ACTIONS");
                actions.layoutWidth = FILL_PARENT;
                actions.layoutHeight = FILL_PARENT;
                actions.visibility = Visibility.Invisible;
                {
                    auto deviceInfoTable = new TableLayout("INFO");
                    deviceInfoTable.layoutWidth = FILL_PARENT;
                    deviceInfoTable.colCount = 2;
                    {
                        deviceInfoTable.addChild(new TextWidget(null, "Device name:"d));

                        deviceNameLine = new EditLine(null, ""d);
                        deviceNameLine.alignment = Align.VCenter;
                        deviceNameLine.enabled = false;
                        deviceNameLine.layoutWidth = FILL_PARENT;
                        deviceInfoTable.addChild(deviceNameLine);

                        deviceInfoTable.addChild(new TextWidget(null, "Device model:"d));

                        modelLine = new EditLine(null, ""d);
                        modelLine.alignment = Align.VCenter;
                        modelLine.enabled = false;
                        modelLine.layoutWidth = FILL_PARENT;
                        deviceInfoTable.addChild(modelLine);

                        deviceInfoTable.addChild(new TextWidget(null, "iOS version:"d));

                        versionLine = new EditLine(null, ""d);
                        versionLine.alignment = Align.VCenter;
                        versionLine.enabled = false;
                        versionLine.layoutWidth = FILL_PARENT;
                        deviceInfoTable.addChild(versionLine);
                    }
                    actions.addTab(deviceInfoTable, "Informations"d);

                    auto installFrame = new VerticalLayout("INSTALL");
                    installFrame.layoutWidth = FILL_PARENT;
                    installFrame.layoutHeight = FILL_PARENT;
                    {
                        Button installButton;

                        auto fileSelectionLayout = new HorizontalLayout();
                        fileSelectionLayout.layoutWidth = FILL_PARENT;
                        {
                            auto editLine = new EditLine();
                            editLine.alignment = Align.VCenter;
                            editLine.enabled = false;
                            editLine.layoutWidth = FILL_PARENT;
                            editLine.text = "Please select an IPA";
                            fileSelectionLayout.addChild(editLine);

                            auto selectFileButton = new Button(null, "..."d);
                            selectFileButton.click = (source) {
                                FileDialog dlg = new FileDialog(UIString.fromRaw("Select IPA"d), window());
                                dlg.addFilter(FileFilterEntry(UIString.fromRaw("iOS application package (*.ipa)"d), "*.ipa"));
                                dlg.dialogResult = (_, result) {
                                    if (result.id != ACTION_OPEN.id) return;

                                    string selectedPath = dlg.filename();
                                    editLine.text = selectedPath.to!dstring();
                                    path = selectedPath;
                                };
                                dlg.show();
                                return true;
                            };
                            fileSelectionLayout.addChild(selectFileButton);
                        }
                        installFrame.addChild(fileSelectionLayout);

                        auto errorLabel = new TextWidget("IPA_ERROR", "Please select an IPA"d);
                        errorLabel.alignment = Align.Center;
                        errorLabel.textColor = Color.firebrick;
                        errorLabel.visibility = Visibility.Invisible;
                        installFrame.addChild(errorLabel);

                        auto appInfoTable = new TableLayout();
                        appInfoTable.layoutWidth = FILL_PARENT;
                        appInfoTable.colCount = 2;
                        {
                            appInfoTable.addChild(new TextWidget(null, "Bundle name:"d));

                            auto nameLine = new EditLine(null, ""d);
                            nameLine.alignment = Align.VCenter;
                            nameLine.enabled = false;
                            nameLine.layoutWidth = FILL_PARENT;
                            appInfoTable.addChild(nameLine);

                            appInfoTable.addChild(new TextWidget(null, "Bundle identifier:"d));

                            auto identifierLine = new EditLine(null, ""d);
                            identifierLine.alignment = Align.VCenter;
                            identifierLine.enabled = false;
                            identifierLine.layoutWidth = FILL_PARENT;
                            appInfoTable.addChild(identifierLine);

                            path.connect((newPath) {
                                try {
                                    app = new Application(newPath);
                                    nameLine.text = app.appInfo["CFBundleName"].str().native().to!dstring();
                                    identifierLine.text = app.appInfo["CFBundleIdentifier"].str().native().to!dstring();
                                    errorLabel.visibility = Visibility.Invisible;
                                    installButton.enabled = true;
                                } catch (Exception ex) {
                                    log.errorF!"Cannot load the app: %s"(ex);
                                    nameLine.text = ""d;
                                    identifierLine.text = ""d;
                                    errorLabel.text = format!"invalid app: %s"d(ex.msg);
                                    errorLabel.visibility = Visibility.Visible;
                                    installButton.enabled = false;
                                }
                            });
                        }
                        installFrame.addChild(appInfoTable);

                        installFrame.addChild(new VSpacer());

                        installButton = new Button(new Action(101, "Install"d));
                        installButton.layoutWidth = FILL_PARENT;
                        installButton.layoutHeight = WRAP_CONTENT;
                        installButton.enabled = false;
                        installFrame.addChild(installButton);

                        auto installProgressBar = new ProgressBarWidget();
                        installProgressBar.layoutWidth = FILL_PARENT;
                        installProgressBar.layoutHeight = WRAP_CONTENT;
                        installFrame.addChild(installProgressBar);

                        auto installProgressLabel = new TextWidget();
                        installProgressLabel.text = "Idle"d;
                        installProgressLabel.alignment = Align.Center;
                        installProgressLabel.layoutWidth = FILL_PARENT;
                        installProgressLabel.layoutHeight = WRAP_CONTENT;
                        installFrame.addChild(installProgressLabel);
                    }
                    actions.addTab(installFrame, "Sideload"d);

                    toolsFrame = new VerticalLayout("TOOLS");
                    toolsFrame.layoutWidth = FILL_PARENT;
                    toolsFrame.layoutHeight = WRAP_CONTENT;
                    actions.addTab(toolsFrame, "Additional tools"d);
                }
                actionsFrame.addChild(actions);
            }
            body.addChild(actionsFrame);
        }
        addChild(body);

        iDevice.subscribeEvent((ref const(iDeviceEvent) event) {
            with (iDeviceEventType) switch (event.event) {
                case iDeviceEventType.add:
                    log.infoF!"Device with UDID %s has been added."(event.udid);
                    break;
                case iDeviceEventType.remove:
                    log.infoF!"Device with UDID %s has been removed."(event.udid);
                    break;
                case iDeviceEventType.paired:
                    log.infoF!"Device with UDID %s has been paired."(event.udid);
                    break;
                default:
                    log.infoF!"Device with UDID %s has been ???? (%s)."(event.udid, event.event);
                    break;
            }

            refreshDeviceList();
        });
    }

    void refreshDeviceList() {
        devices = iDevice.deviceList().map!((device) => device.udid).array();
        auto uiDevices = devices.map!((device) => device.to!dstring()).array();
        deviceBox.executeInUiThread({
            deviceBox.items = uiDevices;

            if (uiDevices.length == 0) {
                actionsFrame.visibility = Visibility.Invisible;
            } else {
                actionsFrame.visibility = Visibility.Visible;
            }
        });
    }

    void updateDeviceInfo(scope LockdowndClient client) {
        Plist deviceInfo = client[null, null];

        deviceNameLine.executeInUiThread({
            deviceNameLine.text = deviceInfo["DeviceName"].str().native().to!dstring();
        });

        modelLine.executeInUiThread({
            modelLine.text = deviceInfo["HardwareModel"].str().native().to!dstring();
        });

        versionLine.executeInUiThread({
            versionLine.text = deviceInfo["ProductVersion"].str().native().to!dstring();
        });
    }

    void setUpTools(iDevice device) {
        toolsFrame.executeInUiThread({
            toolsFrame.removeAllChildren();
            foreach (tool; toolList(device)) {
                auto toolButton = new Button(null, tool.name().to!dstring());
                toolButton.click = (source) {
                    new Thread({
                        auto window = window();
                        window.uiTry!({
                            tool.run((string message, bool canCancel = true) {
                                Tid parentTid = thisTid();
                                const(Action)[] actions = [ACTION_OK];
                                if (canCancel) {
                                    actions ~= ACTION_CANCEL;
                                }

                                window.executeInUiThread({
                                    window.showMessageBox(""d, message.to!dstring(), actions, 0, (res) {
                                        parentTid.send((res.id != StandardAction.Ok) || !canCancel);
                                        return true;
                                    });
                                });
                                return receiveOnly!bool();
                            });
                        });
                    }).start();
                    return true;
                };
                toolButton.layoutWidth = FILL_PARENT;
                string diag = tool.diagnostic();
                if (diag) {
                    toolButton.enabled = false;
                    toolButton.tooltipText = diag.to!dstring();
                }

                toolsFrame.addChild(toolButton);
            }
        });
    }
}
