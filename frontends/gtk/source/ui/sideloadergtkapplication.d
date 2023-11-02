module ui.sideloadergtkapplication;

import core.thread;

import file = std.file;
import std.format;
import std.path;
import std.process;

import adw.Application;
import adw.ApplicationWindow;
import adw.HeaderBar;

import gtk.AboutDialog;
static import gtk.Application;
import gtk.Builder;
import gtk.MessageDialog;
import gtk.Window;

static import gio.Application;
import gio.SimpleAction;

import slf4d;

import provision;

import app;
import constants;
import imobiledevice;

import ui.authentication.authenticationassistant;
import ui.dependencieswindow;
import ui.devicewidget;
import ui.mainwindow;
import ui.manageappidwindow;
import ui.managecertificateswindow;
import ui.utils;

// TODO REMOVE THAT
__gshared static SideloaderGtkApplication runningApplication;

class SideloaderGtkApplication: Application {
    string configurationPath;

    MainWindow mainWindow;

    Device _device;
    ADI _adi;

    auto device() => _device;
    auto adi() => _adi;

    this(string configurationPath) {
        super("dev.dadoum.Sideloader", ApplicationFlags.FLAGS_NONE);

        this.configurationPath = configurationPath;
        addOnActivate(&onActivate);

        auto aboutAction = new SimpleAction("about", null);
        aboutAction.addOnActivate((_, __) {
            // TODO: switch libadwaita
            AboutDialog aboutDialog = new AboutDialog();
            aboutDialog.setTransientFor(mainWindow);
            aboutDialog.setModal(true);

            aboutDialog.setProgramName(applicationName);
            aboutDialog.setAuthors(["Dadoum"]);
            aboutDialog.setVersion(versionStr);
            aboutDialog.setWebsite(appWebsite);
            aboutDialog.setWebsiteLabel("GitHub repository");

            // TODO add more credits!! There are so much more people here!!
            aboutDialog.addCreditSection("libimobiledevice, libplist", ["Nikias Bassen"]);
            aboutDialog.addCreditSection("Botan (cryptography)", [`Etienne "etcimon" Cimon`, `Jack "randombit" Lloyd`]);
            aboutDialog.addCreditSection("dlang-requests (networking)", [`ikod`]);
            aboutDialog.addCreditSection("slf4d (logging)", [`Andrew Lalis`]);
            aboutDialog.addCreditSection("The D programming language", [`The D Language Foundation`]);
            aboutDialog.addCreditSection("GTK 4", [`The GNOME Foundation`]);
            aboutDialog.addCreditSection("SideStore contributors (no shared code)", ["Riley Testut", "Kabir Oberai", `Joelle "Lonkelle"`,
            `Nick "nythepegasus"`, `James "JJTech"`, `Joss "bogotesr"`, `naturecodevoid`,
            `many other, open a GH issue if needed`]);
            aboutDialog.addCreditSection("Help on app signature", [`DebianArch`, `zhlynn (zsign)`, `Jay "saurik" Freeman (ldid)`]);
            aboutDialog.addCreditSection("Apple Music for Android libraries", [`Apple`]);

            aboutDialog.setComments("Don't hesitate to reach me out if I forgot someone in the credits! \n"
                ~ "Note: most of them are not involved in the development of this software whatsoever. Do not report any issue to them!!");

            aboutDialog.show();
        });
        this.addAction(aboutAction);

        auto appIdsAction = new SimpleAction("manage-app-ids", null);
        appIdsAction.addOnActivate((_, __) {
            uiTry!({
                AuthenticationAssistant.authenticate(this, (developer) {
                    auto window = new ManageAppIdWindow(mainWindow, developer);
                    scope(failure) window.close();
                    window.show();
                });
            });
        });
        this.addAction(appIdsAction);

        auto certificatesAction = new SimpleAction("manage-certificates", null);
        certificatesAction.addOnActivate((_, __) {
            uiTry!({
                AuthenticationAssistant.authenticate(this, (developer) {
                    auto window = new ManageCertificatesWindow(mainWindow, developer);
                    scope(failure) window.close();
                    window.show();
                });
            });
        });
        this.addAction(certificatesAction);

        auto donateAction = new SimpleAction("donate", null);
        donateAction.addOnActivate((_, __) {
            browse("https://github.com/sponsors/Dadoum");
        });
        this.addAction(donateAction);
    }

    void onActivate(gio.Application.Application _) {
        runningApplication = this;

        if (!(file.exists(configurationPath.buildPath("lib/libstoreservicescore.so")) && file.exists(configurationPath.buildPath("lib/libCoreADI.so")))) {
            // Missing dependencies
            getLogger().info("Cannot find Apple libraries. Prompting the user to download them. ");
            DependenciesWindow depWindow = new DependenciesWindow(this);
            addWindow(depWindow);
            depWindow.show();
        } else {
            configureMainWindow();
        }
    }

    void configureMainWindow() {
        auto provisioningData = initializeADI(configurationPath);
        _adi = provisioningData.adi;
        _device = provisioningData.device;

        mainWindow = new MainWindow();
        addWindow(mainWindow);
        mainWindow.show();

        auto log = getLogger();
        iDevice.subscribeEvent((ref const(iDeviceEvent) eventRef) {
            iDeviceEvent event = eventRef;
            iDeviceInfo deviceInfo = iDeviceInfo(event.udid.dup, event.connType);
            runInUIThread({
                switch (event.event) with (iDeviceEventType) {
                    case add:
                        log.infoF!"Device %s (%s) has been connected."(deviceInfo.udid, deviceInfo.connType);
                        mainWindow.addDeviceWidget(deviceInfo);
                        break;
                    case remove:
                        log.infoF!"Device %s (%s) has been removed."(deviceInfo.udid, deviceInfo.connType);
                        mainWindow.removeDeviceWidget(deviceInfo);
                        break;
                    default:
                        log.warnF!"Device %s (%s) triggered an unknown event (event number: %d)."(deviceInfo, deviceInfo.connType, event.event);
                        break;
                }
            });
        });
    }
}
