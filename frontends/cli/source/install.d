module install;

import slf4d;
import slf4d.default_provider;

import argparse;
import progress;

import imobiledevice;

import sideload;
import sideload.application;

import cli_frontend;

@(Command("install").Description("Install an application on the device (renames the app, register the identifier, sign and install automatically)."))
struct InstallCommand
{
    mixin LoginCommand;

    @(PositionalArgument(0, "app path").Description("The path of the IPA file to sideload."))
    string appPath;

    @(NamedArgument("udid").Description("UDID of the device (if multiple are available)."))
    string udid = null;

    @(NamedArgument("singlethread").Description("Run the signature process on a single thread. Sacrifices speed for more consistency."))
    bool singlethreaded;

    int opCall()
    {
        Application app = openApp(appPath);

        auto log = getLogger();

        string configurationPath = systemConfigurationPath();

        scope provisioningData = initializeADI(configurationPath);
        scope adi = provisioningData.adi;
        scope akDevice = provisioningData.device;

        auto appleAccount = login(akDevice, adi);

        if (!appleAccount) {
            return 1;
        }

        auto devices = iDevice.deviceList();
        string udid = this.udid;
        if (!udid) {
            if (devices.length == 1) {
                udid = devices[0].udid;
            } else {
                if (!devices.length) {
                    log.error("No device connected.");
                    return 1;
                }
                if (!this.udid) {
                    log.error("Multiple devices are connected. Please select one with --udid.");
                }
            }
        }

        log.infoF!"Initiating connection the device (UUID: %s)"(udid);
        auto device = new iDevice(udid);
        Bar progressBar = new Bar();
        string message;
        progressBar.message = () => message;
        sideloadFull(configurationPath, device, appleAccount, app, (progress, action) {
            message = action;
            progressBar.index = cast(int) (progress * 100);
            progressBar.update();
        }, !singlethreaded);
        progressBar.finish();

        return 0;
    }
}
