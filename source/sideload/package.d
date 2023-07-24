module sideload;

import std.algorithm.iteration;
import std.algorithm.searching;
import std.array;
import std.datetime;
import file = std.file;
import std.format;
import std.path;

import slf4d;

import plist;

import imobiledevice;

import server.developersession;

public import sideload.bundle;
public import sideload.application;
import sideload.certificateidentity;

import main;

void sign(DeveloperSession developer, Application app) {
    auto teams = developer.listTeams().unwrap();
    auto team = teams[0];
}

void sideloadFull(
    iDevice device,
    DeveloperSession developer,
    Application app,
    void delegate(double progress, string action) progressCallback,
) {
    enum STEP_COUNT = 20.0;
    auto log = getLogger();

    // select the first development team
    progressCallback(0 / STEP_COUNT, "Fetching development teams");
    auto team = developer.listTeams().unwrap()[0]; // TODO add a setting for that

    // list development devices from the account
    progressCallback(1 / STEP_COUNT, "List account's development devices");
    auto devices = developer.listDevices!iOS(team).unwrap();
    auto deviceUdid = device.udid();

    // if the current device is not registered as a development device for this account, do it!
    if (!devices.any!((device) => device.deviceNumber == deviceUdid)) {
        progressCallback(2 / STEP_COUNT, "Register the current device as a development device");
        scope lockdown = new LockdowndClient(device, "sideloader.developer");
        auto deviceName = lockdown.deviceName();
        developer.addDevice!iOS(team, deviceName, deviceUdid).unwrap();
    }

    // create a certificate for the developer
    progressCallback(3 / STEP_COUNT, "Generating a certificate for Sideloader");
    auto certIdentity = new CertificateIdentity(configurationPath, developer);

    // check if we registered an app id for it (if not create it)
    progressCallback(4 / STEP_COUNT, "Creating App IDs for the application");
    string mainAppBundleId = app.bundleIdentifier();
    string mainAppIdStr = mainAppBundleId ~ "." ~ team.teamId;
    string mainAppName = app.bundleName();
    auto listAppIdResponse = developer.listAppIds!iOS(team).unwrap();

    app.appId = mainAppIdStr;
    foreach (plugin; app.plugIns) {
        string pluginBundleIdentifier = plugin.bundleIdentifier();
        assertBundle(
            pluginBundleIdentifier.startsWith(mainAppBundleId) &&
            pluginBundleIdentifier.length > mainAppBundleId.length,
            "Plug-ins are not formed with the main app bundle identifier"
        );
        plugin.appId = mainAppIdStr ~ pluginBundleIdentifier[mainAppBundleId.length..$];
    }
    Bundle[] bundlesNeeded = [cast(Bundle) app] ~ app.plugIns;

    // Search which App IDs have to be registered (we don't want to start registering App IDs if we don't
    // have enough of them to register them all!! otherwise we will waste their precious App IDs)
    auto appIdsToRegister = bundlesNeeded.filter!((bundle) => !listAppIdResponse.appIds.canFind!((a) => a.identifier == bundle.appId)).array();

    if (appIdsToRegister.length > listAppIdResponse.availableQuantity) {
        auto minDate = listAppIdResponse.appIds.map!((appId) => appId.expirationDate).minElement();
        throw new NoAppIdRemainingException(minDate);
    }

    foreach (bundle; appIdsToRegister) {
        log.infoF!"Creating App ID `%s`..."(bundle.appId);
        developer.addAppId!iOS(team, bundle.appId, bundle.bundleName).unwrap();
    }
    listAppIdResponse = developer.listAppIds!iOS(team).unwrap();
    auto appIds = listAppIdResponse.appIds.filter!((appId) => bundlesNeeded.canFind!((bundle) => appId.identifier == bundle.appId)).array();
    auto mainAppId = appIds.find!((appId) => appId.identifier == mainAppIdStr)[0];

    foreach (ref appId; appIds) {
        if (!appId.features[AppIdFeatures.appGroup].boolean().native()) {
            // We need to enable app groups then !
            appId.features = developer.updateAppId!iOS(team, appId, dict(AppIdFeatures.appGroup, true)).unwrap();
        }
    }

    // create an app group for it if needed
    progressCallback(5 / STEP_COUNT, "Creating an application group");
    auto groupIdentifier = "group." ~ mainAppIdStr;
    auto appGroups = developer.listApplicationGroups!iOS(team).unwrap();
    auto matchingAppGroups = appGroups.find!((appGroup) => appGroup.identifier == groupIdentifier).array();
    ApplicationGroup appGroup;
    if (matchingAppGroups.empty) {
        appGroup = developer.addApplicationGroup!iOS(team, groupIdentifier, mainAppName).unwrap();
    } else {
        appGroup = matchingAppGroups[0];
    }

    progressCallback(6 / STEP_COUNT, "Assign App IDs to the application group");
    foreach (appId; appIds) {
        developer.assignApplicationGroupToAppId!iOS(team, appId, appGroup).unwrap();
    }

    // fetch the mobileprovision file for it
    progressCallback(7 / STEP_COUNT, "Fetching mobileprovision file for the application");
    auto profile = developer.downloadTeamProvisioningProfile!iOS(team, mainAppId).unwrap();

    // sign the app with all the retrieved material!
    progressCallback(8 / STEP_COUNT, "Signing the application bundle");
    file.write(app.appFolder.buildPath("embedded.mobileprovision"), profile.encodedProfile);

    auto signingProgressFactor = (15 - 8) / STEP_COUNT;


    // connect to the device's installation daemon and send to it the signed app
    progressCallback(15 / STEP_COUNT, "Installing the application on the device");

    progressCallback(1.0, "Done!");
}

class NoAppIdRemainingException: Exception {
    this(DateTime minExpirationDate, string file = __FILE__, int line = __LINE__) {
        super(format!"Cannot make any more app ID, you have to wait until %s to get a new App ID"(minExpirationDate.toSimpleString()), file, line);
    }
}
