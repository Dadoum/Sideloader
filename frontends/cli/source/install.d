module install;

import slf4d;
import slf4d.default_provider;

import jcli;
import progress;

import imobiledevice;

import sideload;
import sideload.application;

import cli_frontend;

@Command("install", "Install an application on the device (renames the app, register the identifier, sign and install automatically).")
struct InstallCommand
{
    mixin LoginCommand;

    @ArgPositional("app path", "The path of the IPA file to sideload.")
    @BindWith!openApp
    Application app;

    int onExecute()
    {
        version (linux) {
            import core.stdc.locale;
            setlocale(LC_ALL, "");
        }

        configureLoggingProvider(new shared DefaultProvider(true, Levels.INFO));

        auto log = getLogger();

        string configurationPath = systemConfigurationPath();

        scope provisioningData = initializeADI(configurationPath);
        scope adi = provisioningData.adi;
        scope akDevice = provisioningData.device;

        auto appleAccount = login(akDevice, adi);

        if (!appleAccount) {
            return 1;
        }

        string udid = iDevice.deviceList()[0].udid;
        log.infoF!"Initiating connection the device (UUID: %s)"(udid);
        auto device = new iDevice(udid);
        Bar progressBar = new Bar();
        string message;
        progressBar.message = () => message;
        sideloadFull(configurationPath, device, appleAccount, app, (progress, action) {
            message = action;
            progressBar.index = cast(int) (progress * 100);
            progressBar.update();
        });
        progressBar.finish();

        return 0;
    }
}
