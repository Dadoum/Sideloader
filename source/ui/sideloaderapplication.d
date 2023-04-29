module ui.sideloaderapplication;

import file = std.file;
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

import ui.authenticationassistant;
import ui.dependencieswindow;
import ui.devicewidget;
import ui.mainwindow;

class SideloaderApplication: Application {
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
        if (!(file.exists(configurationPath.buildPath("lib/libstoreservicescore.so")) && file.exists(configurationPath.buildPath("lib/libCoreADI.so")))) {
            // Missing dependencies
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

        auto loginAction = new SimpleAction("login", null);
        loginAction.addOnActivate((_, __) {
            AuthenticationAssistant.authenticate(this);
        });
        this.addAction(loginAction);

        auto log = getLogger();
        iDevice.subscribeEvent((ref const(iDeviceEvent) event) {
            string udid = event.udid;
            switch (event.event) with (iDeviceEventType) {
                case add:
                    log.infoF!"A device with UDID %s has been connected."(event.udid);
                    mainWindow.addDeviceWidget(event.udid);
                    break;
                case remove:
                    log.infoF!"The device with UDID %s has been removed."(event.udid);
                    mainWindow.removeDeviceWidget(event.udid);
                    break;
                default:
                    log.warnF!"The device with UDID %s made something unknown, event number: %d"(event.udid, event.event);
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
