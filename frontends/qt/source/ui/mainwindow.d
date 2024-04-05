module ui.mainwindow;

import core.stdcpp.new_: cpp_new;

import std.algorithm;
import std.conv;
import file = std.file;
import std.format;
import std.process;

import slf4d;

import plist;

import provision;

import qt.config;
import qt.core.coreevent;
import qt.core.namespace;
import qt.core.object;
import qt.core.objectdefs;
import qt.core.string;
import qt.core.thread;
import qt.core.translator;
import qt.core.variant;
import qt.gui.cursor;
import qt.helpers;
import qt.widgets.action;
import qt.widgets.combobox;
import qt.widgets.filedialog;
import qt.widgets.label;
import qt.widgets.lineedit;
import qt.widgets.mainwindow;
import qt.widgets.messagebox;
import qt.widgets.pushbutton;
import qt.widgets.stackedwidget;
import qt.widgets.ui;
import qt.widgets.widget;

import imobiledevice;

import constants;
import sideload;
import tools;
import utils;

import ui.utils;

alias MainWindowUI = UIStruct!"mainwindow.ui";

class MainWindow: QMainWindow {
    mixin(Q_OBJECT_D);

    MainWindowUI* ui;

    iDevice selectedDevice;
    LockdowndClient lockdowndClient;

    Application selectedApplication;

    this(string configurationPath, Device device, ADI adi) {
        ui = cpp_new!MainWindowUI();
        ui.setupUi(this);

        auto log = getLogger();
        QObject.connect(this.signal!"deviceAdded", this.slot!"addDevice");
        QObject.connect(this.signal!"deviceRemoved", this.slot!"removeDevice");
        QObject.connect(ui.deviceComboBox.signal!"currentIndexChanged", this.slot!"refreshView");
        QObject.connect(ui.actionRefresh_device_list.signal!"triggered", this.slot!"refreshDevices");
        QObject.connect(ui.actionDonate.signal!"triggered", delegate() => browse("https://github.com/sponsors/Dadoum"));
        QObject.connect(ui.ipaLine.signal!"editingFinished", this.slot!"checkApplication");
        QObject.connect(
            ui.actionAbout.signal!"triggered",
            delegate() =>
                QMessageBox.about(
                    this,
                    *cpp_new!QString("About Sideloader"),
                    *cpp_new!QString(format!rawAboutText(versionStr, "Qt"))
                )
        );
        QObject.connect(this.signal!"sideloadProcedureTriggered", this.slot!"setSideloadTabEnabled");
        QObject.connect(
            ui.selectIpaButton.signal!"clicked",
            delegate() {
                QString filename = QFileDialog.getOpenFileName(
                    this,
                    *cpp_new!QString("Open application"),
                    globalInitVar!QString,
                    *cpp_new!QString("iOS application bundle (*.ipa)")
                );

                if (!filename.isNull() && !filename.isEmpty()) {
                    ui.ipaLine.setText(filename);
                    checkApplication();
                }
            }
        );
        QObject.connect(ui.installButton.signal!"clicked",
            delegate() {
                log.info("Installing...");
                this.sideloadProcedureTriggered(false);
            }
        );

        ui.bundleInfos.hide();
        iDevice.subscribeEvent((ref const(iDeviceEvent) event) {
            with (iDeviceEventType) switch (event.event) {
                case add:
                    deviceAdded(*cpp_new!QString(event.udid));
                    log.infoF!"Device with UDID %s has been added."(event.udid);
                    break;
                case remove:
                    deviceRemoved(*cpp_new!QString(event.udid));
                    log.infoF!"Device with UDID %s has been removed."(event.udid);
                    break;
                case paired:
                    log.infoF!"Device with UDID %s has been paired."(event.udid);
                    break;
                default:
                    log.infoF!"Device with UDID %s has been ???? (%s)."(event.udid, event.event);
                    break;
            }
        });
        // auto stackedWidget = new QStackedWidget();
        // ui.tabWidget.sizePolicy().setRetainSizeWhenHidden(true);
        // ui.tabWidget.setVisible(false);
    }

    @QSignal final void sideloadProcedureTriggered(bool isSideloadTabEnabled) { mixin(Q_SIGNAL_IMPL_D); }
    @QSignal final void deviceAdded(ref const(QString) udid) { mixin(Q_SIGNAL_IMPL_D); }
    @QSignal final void deviceRemoved(ref const(QString) udid) { mixin(Q_SIGNAL_IMPL_D); }

    // @QSignal final bool showDialog(ref const(QMessageBox) udid) { mixin(Q_SIGNAL_IMPL_D); }

    @QSlot
    final void addDevice(ref const(QString) udid) {
        assert(QThread.currentThread() == this.thread());

        QComboBox deviceComboBox = ui.deviceComboBox;
        if (deviceComboBox.findData(QVariant(udid)) != -1) {
            return;
        }

        string udidStr = udid.toConstWString().to!string();
        scope device = new iDevice(udidStr);

        string deviceName = "???";
        try {
            scope lockdown = new LockdowndClient(device, "sideloader.name-fetcher");
            deviceName = lockdown.deviceName();
        } catch (iMobileDeviceException!lockdownd_error_t) { }

        auto deviceDisplayName = cpp_new!QString(format!"%s (%s)"(deviceName, udidStr));

        deviceComboBox.addItem(*deviceDisplayName, QVariant(udid));
    }

    @QSlot
    final void removeDevice(ref const(QString) udid) {
        assert(QThread.currentThread() == this.thread());
        if (iDevice.deviceList().canFind!(elem => elem.udid == udid.toConstWString().to!string())) {
            return;
        }

        QComboBox deviceComboBox = ui.deviceComboBox;
        auto deviceIndex = deviceComboBox.findData(QVariant(udid));
        assert(deviceIndex != -1);
        deviceComboBox.removeItem(deviceIndex);
    }

    @QSlot
    final void refreshDevices() {
        assert(QThread.currentThread() == this.thread());
        QComboBox deviceComboBox = ui.deviceComboBox;
        deviceComboBox.clear();
        foreach (deviceInfo; iDevice.deviceList()) {
            deviceAdded(*cpp_new!QString(deviceInfo.udid));
        }
    }

    @QSlot
    final void refreshView(int index) {
        if (index == -1) {
            ui.stackedWidget.setCurrentIndex(0);
            return;
        }

        if (selectedDevice) {
            object.destroy(selectedDevice);
        }
        if (lockdowndClient) {
            object.destroy(lockdowndClient);
        }

        QComboBox deviceComboBox = ui.deviceComboBox;

        string deviceUdid =
            deviceComboBox
                .itemData(index)
                .toString()
                .toConstWString()
                .to!string();

        selectedDevice = new iDevice(deviceUdid);

        try {
            lockdowndClient = new LockdowndClient(selectedDevice, "sideloader.device-info");
            Plist deviceInfo = lockdowndClient[null, null];

            string deviceName = deviceInfo["DeviceName"].str().native();
            string modelName = format!"%s (%s)"(
                deviceInfo["ProductType"].str().native(),
                deviceInfo["HardwareModel"].str().native()
            );
            string iosVersion = format!"%s (%s)"(
                deviceInfo["ProductVersion"].str().native(),
                deviceInfo["BuildVersion"].str().native()
            );

            ui.nameLine.setText(*cpp_new!QString(deviceName));
            ui.modelLine.setText(*cpp_new!QString(modelName));
            ui.versionLine.setText(*cpp_new!QString(iosVersion));

            ui.additionalToolsLayout.clearLayout();

            foreach (tool; toolList(selectedDevice)) {
                auto button = cpp_new!QPushButton(QString(tool.name));
                auto toolDiag = tool.diagnostic;
                button.setEnabled(tool.diagnostic == null);
                if (toolDiag) {
                    button.setToolTip(*cpp_new!QString(toolDiag));
                }

                QObject.connect(button.signal!"clicked", () => tool.run((message, canCancel) {
                    alias StandardButton = QMessageBox.StandardButton;
                    alias StandardButtons = QMessageBox.StandardButtons;

                    StandardButton button = QMessageBox.question(
                        this,
                        *cpp_new!QString(tool.name),
                        *cpp_new!QString(message),
                        StandardButtons(StandardButton.Ok | (canCancel ? StandardButton.Cancel : StandardButton.NoButton))
                    );

                    return button == StandardButton.Cancel;
                }));

                ui.additionalToolsLayout.addWidget(button);
            }

            // ui.tabWidget.setCurrentIndex(0);
            ui.stackedWidget.setCurrentIndex(1);
        } catch (iMobileDeviceException!lockdownd_error_t ex) {
            lockdowndClient = null;
            string message;
            with (lockdownd_error_t) switch (ex.underlyingError) {
                case LOCKDOWN_E_PASSWORD_PROTECTED:
                    message = "Please unlock your phone.";
                    break;
                case LOCKDOWN_E_PAIRING_DIALOG_RESPONSE_PENDING:
                    message = "Please trust the computer.";
                    break;
                case LOCKDOWN_E_USER_DENIED_PAIRING:
                    message = "The computer has not been trusted.";
                    break;
                default:
                    message = format!"Can't connect to the device (%d).\nTry to plug the device again, unlock it and refresh."(ex.underlyingError);
                    break;
            }

            ui.deviceConnectionErrorLabel.setText(*cpp_new!QString(format!"%s\n(refresh to try again)"(message)));
            ui.stackedWidget.setCurrentIndex(2);
        }
    }

    @QSlot
    void checkApplication() {
        void setErrorLabel(string s) {
            ui.appParsingErrorLabel.setText(*cpp_new!QString(format!`<span style="color:#e01b24;">%s</span>`(s)));
        }

        string ipaFile =
            ui.ipaLine.text()
                .toConstWString()
                .to!string();

        ui.bundleInfos.setVisible(false);
        ui.installButton.setEnabled(false);
        selectedApplication = null;

        if (!file.exists(ipaFile)) {
            setErrorLabel("No such file or directory");
            return;
        }

        if (!file.isFile(ipaFile)) {
            setErrorLabel("Is not a file");
            return;
        }

        auto log = getLogger();

        try {
            Application app = new Application(ipaFile);
            ui.bundleNameLine.setText(*cpp_new!QString(app.appInfo["CFBundleName"].str().native()));
            ui.bundleIdentifierLine.setText(*cpp_new!QString(app.appInfo["CFBundleIdentifier"].str().native()));
            selectedApplication = app;
            setErrorLabel("");
            ui.bundleInfos.setVisible(true);
            ui.installButton.setEnabled(true);
        } catch (Exception ex) {
            log.infoF!"%s"(ex);
            setErrorLabel(ex.msg);
        }
    }

    @QSlot
    void setSideloadTabEnabled(bool enabled) {
        ui.sideloadTab.setEnabled(enabled);
        if (enabled) {
            ui.sideloadTab.unsetCursor();
        } else {
            ui.sideloadTab.setCursor(*cpp_new!QCursor(CursorShape.WaitCursor));
        }
    }
}
