module ui.sideloaderform;

import file = std.file;
import std.format;
import std.path;

import slf4d;

import dfl;

import constants;
import main;
import version_string;

import ui.dependenciesform;

class SideloaderForm: Form {
    private MainMenu mainMenuStrip;
    private MenuItem accountMenuItem;
    private MenuItem deviceMenuItem;
    private MenuItem helpMenuItem;
    private MenuItem aboutSideloaderMenuItem;
    private MenuItem refreshDevicesMenuItem;
    private MenuItem loginMenuItem;
    private MenuItem toolStripSeparator1;
    private MenuItem manageAppIDsMenuItem;
    private MenuItem manageCertificatesMenuItem;
    private Button installAppButton;
    private ImageList deviceImageList;
    private ListView deviceListView;
    private Button deviceInfoButton;

    this() {
        this.mainMenuStrip = new MainMenu();
        this.accountMenuItem = new MenuItem();
        this.deviceMenuItem = new MenuItem();
        this.helpMenuItem = new MenuItem();
        this.aboutSideloaderMenuItem = new MenuItem();
        this.refreshDevicesMenuItem = new MenuItem();
        this.loginMenuItem = new MenuItem();
        this.toolStripSeparator1 = new MenuItem();
        this.manageAppIDsMenuItem = new MenuItem();
        this.manageCertificatesMenuItem = new MenuItem();
        this.installAppButton = new Button();
        this.deviceImageList = new ImageList();
        this.deviceListView = new ListView();
        this.deviceInfoButton = new Button();
        this.suspendLayout();
        //
        // mainMenuStrip
        //
        this.mainMenuStrip.menuItems.addRange([
            this.accountMenuItem,
            this.deviceMenuItem,
            this.helpMenuItem
        ]);
        //
        // accountMenuItem
        //
        this.accountMenuItem.menuItems.addRange([
            this.loginMenuItem,
            this.toolStripSeparator1,
            this.manageAppIDsMenuItem,
            this.manageCertificatesMenuItem
        ]);
        this.accountMenuItem.text = "Account";
        //
        // deviceMenuItem
        //
        this.deviceMenuItem.menuItems.addRange([
            this.refreshDevicesMenuItem
        ]);
        this.deviceMenuItem.text = "Device";
        //
        // helpMenuItem
        //
        this.helpMenuItem.menuItems.addRange([
            this.aboutSideloaderMenuItem
        ]);
        this.helpMenuItem.text = "Help";
        //
        // aboutSideloaderMenuItem
        //
        this.aboutSideloaderMenuItem.click ~= (MenuItem menuItem, EventArgs ea) {
            msgBox(this, format!`%s

Sideloader has been made by Dadoum, with the source code available on https://github.com/Dadoum/Sideloader.

Sideloader would not have been possible without the work of countless others on different projects.

Thanks to people behind: libimobiledevice, libplist, Botan, Botan D port, SideStore, AltStore, D Programming language, DFL (D Forms Library), dlang-requests, slf4d, Cydia Impactor, Apple team behind Apple Music for Android, and many others.`(versionStr)
            );
        };
        this.aboutSideloaderMenuItem.text = "About Sideloader";
        //
        // refreshDevicesMenuItem
        //
        this.refreshDevicesMenuItem.text = "Refresh device list";
        //
        // loginMenuItem
        //
        this.loginMenuItem.text = "Log-in";
        //
        // toolStripSeparator1
        //
        this.toolStripSeparator1.text = "-";
        //
        // manageAppIDsMenuItem
        //
        this.manageAppIDsMenuItem.text = "Manage App IDs";
        this.manageAppIDsMenuItem.enabled = false;
        //
        // manageCertificatesMenuItem
        //
        this.manageCertificatesMenuItem.text = "Manage certificates";
        this.manageCertificatesMenuItem.enabled = false;
        //
        // installAppButton
        //
        // this.installAppButton.anchor = (cast(AnchorStyles)((AnchorStyles.TOP | AnchorStyles.RIGHT)));
        this.installAppButton.enabled = false;
        this.installAppButton.location = Point(652, 12);
        this.installAppButton.name = "installAppButton";
        this.installAppButton.size = Size(140, 32);
        // this.installAppButton.tabIndex = 1;
        this.installAppButton.text = "Install application";
        // this.installAppButton.useVisualStyleBackColor = true;
        //
        // deviceImageList
        //
        // this.deviceListView.anchor = (cast(AnchorStyles)((((AnchorStyles.TOP | AnchorStyles.BOTTOM)
        // | AnchorStyles.LEFT)
        // | AnchorStyles.RIGHT)));
        // this.deviceListView.largeImageList = deviceImageList;
        // this.deviceListView.smallImageList = deviceImageList;
        this.deviceListView.hideSelection = false;
        this.deviceListView.location = Point(12, 12);
        this.deviceListView.multiSelect = false;
        this.deviceListView.name = "deviceImageList";
        this.deviceListView.size = Size(632, 458);
        // this.deviceListView.tabIndex = 2;
        //
        // deviceInfoButton
        //
        // this.deviceInfoButton.anchor = (cast(AnchorStyles)((AnchorStyles.TOP | AnchorStyles.RIGHT)));
        this.deviceInfoButton.enabled = false;
        this.deviceInfoButton.location = Point(652, 52);
        this.deviceInfoButton.name = "deviceInfoButton";
        this.deviceInfoButton.size = Size(140, 32);
        // this.deviceInfoButton.tabIndex = 3;
        this.deviceInfoButton.text = "Device infomations";
        // this.deviceInfoButton.useVisualStyleBackColor = true;
        //
        // SideloaderForm
        //
        // this.autoScaleDimensions = SizeF(6F, 12F);
        // this.autoScaleMode = AutoScaleMode.Font;
        this.clientSize = Size(800, 500);
        this.controls.add(this.deviceInfoButton);
        this.controls.add(this.deviceListView);
        this.controls.add(this.installAppButton);
        this.formBorderStyle = FormBorderStyle.FIXED_DIALOG;
        this.menu = this.mainMenuStrip;
        this.name = "SideloaderForm";
        this.resizeRedraw = true;
        this.text = "Sideloader";
        this.resumeLayout(false);
        this.performLayout();
    }

    override void onLoad(EventArgs ea) {
        super.onLoad(ea);
        if (!(file.exists(frontend.configurationPath.buildPath("lib/libstoreservicescore.so")) && file.exists(frontend.configurationPath.buildPath("lib/libCoreADI.so")))) {
            // Missing dependencies
            getLogger().info("Cannot find Apple libraries. Prompting the user to download them. ");
            new DependenciesForm().showDialog(this);
        } else {
            frontend.initializeADI();
        }
    }
}
