module ui.sideloadergtkapplication;

import file = std.file;
import std.format;
import std.path;

import adw.Application;
import adw.HeaderBar;
import adw.ApplicationWindow;

static import gtk.Application;
import gtk.Builder;
import gtk.Window;

static import gio.Application;
import gio.SimpleAction;

import slf4d;

import provision;

import imobiledevice;

import ui.authentication.authenticationassistant;
import ui.dependencieswindow;
import ui.devicewidget;
import ui.mainwindow;

// TODO REMOVE THAT AND USE SOMETHING NOT TIED TO THE GTK FRONTEND
__gshared static SideloaderGtkApplication runningApplication;

class SideloaderGtkApplication: Application {
    string configurationPath;
    Device device;
    ADI adi;

    MainWindow mainWindow;

    this(string configurationPath) {
        super("dev.dadoum.Sideloader", ApplicationFlags.FLAGS_NONE);

        this.configurationPath = configurationPath;
        addOnActivate(&onActivate);
    }

    void onActivate(gio.Application.Application _) {
        runningApplication = this;

        if (!(file.exists(configurationPath.buildPath("lib/libstoreservicescore.so")) && file.exists(configurationPath.buildPath("lib/libCoreADI.so")))) {
            // Missing dependencies
            getLogger().info("Saluod");
            DependenciesWindow depWindow = new DependenciesWindow(this);
            addWindow(depWindow);
            depWindow.show();
        } else {
            configureMainWindow();
        }
    }

    void configureMainWindow() {
        mainWindow = new MainWindow();
        addWindow(mainWindow);
        mainWindow.show();

        auto log = getLogger();
        iDevice.subscribeEvent((ref const(iDeviceEvent) event) {
            string udid = event.udid;
            string deviceId = format!"%s (%s)"(udid, event.connType == iDeviceConnectionType.network ? "Network" : "USB");
            switch (event.event) with (iDeviceEventType) {
                case add:
                    log.infoF!"Device %s has been connected."(deviceId);
                    mainWindow.addDeviceWidget(deviceId, event.udid);
                    break;
                case remove:
                    log.infoF!"Device %s has been removed."(deviceId);
                    mainWindow.removeDeviceWidget(deviceId);
                    break;
                default:
                    log.warnF!"Device %s made something unknown, event number: %d"(deviceId, event.event);
                    break;
            }
        });

        device = new Device(configurationPath.buildPath("device.json"));

        if (!device.initialized) {
            log.info("Creating device...");

            import std.digest;
            import std.random;
            import std.range;
            import std.uni;
            import std.uuid;
            device.serverFriendlyDescription = "<MacBookPro13,2> <macOS;13.1;22C65> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>";
            device.uniqueDeviceIdentifier = randomUUID().toString().toUpper();
            device.adiIdentifier = (cast(ubyte[]) rndGen.take(2).array()).toHexString().toLower();
            device.localUserUUID = (cast(ubyte[]) rndGen.take(8).array()).toHexString().toUpper();
            log.info("Device created successfully.");
        }
        log.debug_("Device OK.");

        adi = new ADI(configurationPath.buildPath("lib"));
        adi.provisioningPath = configurationPath;
        adi.identifier = device.adiIdentifier;

        if (!adi.isMachineProvisioned(-2)) {
            log.info("Provisioning device...");

            ProvisioningSession provisioningSession = new ProvisioningSession(adi, device);
            provisioningSession.provision(-2);
            log.info("Device provisioned successfully.");
        }
        log.debug_("Provisioning OK.");
    }
}
