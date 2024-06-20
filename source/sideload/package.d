module sideload;

import std.algorithm.iteration;
import std.algorithm.searching;
import std.array;
import std.concurrency;
import std.datetime;
import file = std.file;
import std.format;
import std.path;

import slf4d;

import plist;

import imobiledevice;

import server.developersession;

public import sideload.application;
public import sideload.bundle;
import sideload.certificateidentity;
import sideload.sign;

import utils;

void sideloadFull(
    string configurationPath,
    iDevice device,
    DeveloperSession developer,
    Application app,
    void delegate(double progress, string action) progressCallback,
    bool isMultithreaded = false,
) {
    enum STEP_COUNT = 9.0;
    auto log = getLogger();

    bool isSideStore = app.bundleIdentifier() == "com.SideStore.SideStore";

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
    app.bundleIdentifier = mainAppIdStr;
    string mainAppName = app.bundleName();

    auto listAppIdResponse = developer.listAppIds!iOS(team).unwrap();

    auto appExtensions = app.appExtensions();

    foreach (ref plugin; appExtensions) {
        string pluginBundleIdentifier = plugin.bundleIdentifier();
        assertBundle(
            pluginBundleIdentifier.startsWith(mainAppBundleId) &&
            pluginBundleIdentifier.length > mainAppBundleId.length,
            "Plug-ins are not formed with the main app bundle identifier"
        );
        plugin.bundleIdentifier = mainAppIdStr ~ pluginBundleIdentifier[mainAppBundleId.length..$];
    }

    auto bundlesWithAppID = app ~ appExtensions;

    log.debugF!"App IDs needed: %-(%s, %)"(bundlesWithAppID.map!((b) => b.bundleIdentifier()).array());

    // Search which App IDs have to be registered (we don't want to start registering App IDs if we don't
    // have enough of them to register them all!! otherwise we will waste their precious App IDs)
    auto appIdsToRegister = bundlesWithAppID.filter!((bundle) => !listAppIdResponse.appIds.canFind!((a) => a.identifier == bundle.bundleIdentifier())).array();

    if (appIdsToRegister.length > listAppIdResponse.availableQuantity) {
        auto minDate = listAppIdResponse.appIds.map!((appId) => appId.expirationDate).minElement();
        throw new NoAppIdRemainingException(minDate);
    }

    foreach (bundle; appIdsToRegister) {
        log.infoF!"Creating App ID `%s`..."(bundle.bundleIdentifier);
        developer.addAppId!iOS(team, bundle.bundleIdentifier, bundle.bundleName).unwrap();
    }
    listAppIdResponse = developer.listAppIds!iOS(team).unwrap();
    auto appIds = listAppIdResponse.appIds.filter!((appId) => bundlesWithAppID.canFind!((bundle) => appId.identifier == bundle.bundleIdentifier())).array();
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

    if (isSideStore) {
        app.appInfo["ALTAppGroups"] = [groupIdentifier.pl].pl;
    }

    auto appGroups = developer.listApplicationGroups!iOS(team).unwrap();
    auto matchingAppGroups = appGroups.find!((appGroup) => appGroup.identifier == groupIdentifier).array();
    ApplicationGroup appGroup;
    if (matchingAppGroups.empty) {
        appGroup = developer.addApplicationGroup!iOS(team, groupIdentifier, mainAppName).unwrap();
    } else {
        appGroup = matchingAppGroups[0];
    }

    progressCallback(6 / STEP_COUNT, "Manage App IDs and groups");
    ProvisioningProfile[string] provisioningProfiles;
    foreach (appId; appIds) {
        developer.assignApplicationGroupToAppId!iOS(team, appId, appGroup).unwrap();
        provisioningProfiles[appId.identifier] = developer.downloadTeamProvisioningProfile!iOS(team, mainAppId).unwrap();
    }

    // sign the app with all the retrieved material!
    progressCallback(7 / STEP_COUNT, "Signing the application bundle");
    double accumulator = 0;
    sign(app, certIdentity, provisioningProfiles, (progress) => progressCallback((7 + (accumulator += progress)) / STEP_COUNT, "Signing the application bundle"));

    // connect to the device's installation daemon and send to it the signed app
    double progress = 8 / STEP_COUNT;
    progressCallback(progress, "Installing the application on the device");
    scope lockdownClient = new LockdowndClient(device, "sideloader.app_install");

    // set up clients and proxies
    auto installationProxyService = lockdownClient.startService("com.apple.mobile.installation_proxy");
    scope installationProxyClient = new InstallationProxyClient(device, installationProxyService);

    scope misagentService = lockdownClient.startService("com.apple.misagent");
    scope misagentClient = new MisagentClient(device, misagentService);

    scope afcService = lockdownClient.startService(AFC_SERVICE_NAME);
    scope afcClient = new AFCClient(device, afcService);

    string stagingDir = "PublicStaging";

    string[] props;
    if (afcClient.getFileInfo(stagingDir, props) == AFCError.AFC_E_SUCCESS) {
        // The directory already exists, there should not be any data in there, so let's delete it
        afcClient.removePathAndContents(stagingDir);
    }
    afcClient.makeDirectory(stagingDir).assertSuccess();

    auto options = dict(
        "PackageType", "Developer"
    );

    auto remoteAppFolder = stagingDir.buildPath(baseName(app.bundleDir)).toForwardSlashes();
    if (afcClient.getFileInfo(remoteAppFolder, props) != AFCError.AFC_E_SUCCESS) {
        // The directory does not exist, so let's create it!
        afcClient.makeDirectory(remoteAppFolder).assertSuccess();
    }

    auto files = file.dirEntries(app.bundleDir, file.SpanMode.breadth).array();
    // 75% of the last step is sending the files.
    auto transferStep = 3 / (STEP_COUNT * files.length * 4);

    foreach (f; files) {
        auto remotePath = remoteAppFolder.buildPath(f.asRelativePath(app.bundleDir).array()).toForwardSlashes();
        if (f.isDir()) {
            afcClient.makeDirectory(remotePath);
        } else {
            auto remoteFile = afcClient.open(remotePath, AFCFileMode.AFC_FOPEN_WRONLY);
            scope(exit) afcClient.close(remoteFile);

            ubyte[] fileData = cast(ubyte[]) file.read(f);
            uint bytesWrote = 0;
            while (bytesWrote < fileData.length) {
                bytesWrote += afcClient.write(remoteFile, fileData);
            }
        }
        progress += transferStep;
        progressCallback(progress, "Installing the application on the device (Transfer)");
    }

    // This is negligible in terms of time
    foreach (profile; provisioningProfiles.values()) {
        misagentClient.install(new PlistData(profile.encodedProfile));
    }

    Tid parentTid = thisTid();
    installationProxyClient.install(remoteAppFolder, options, (command, statusPlist) {
        try {
            auto status = statusPlist.dict();
            if (auto statusEntry = "Status" in status) {
                if (statusEntry.str().native() == "Complete") {
                    parentTid.send(null);
                    return;
                }

                progressCallback(
                    progress + (status["PercentComplete"].uinteger().native() / (400.0 * STEP_COUNT)),
                    format!"Installing the application on the device (%s)"(statusEntry.str().native())
                );
            } else {
                auto errorPlist = "Error" in status;
                auto descriptionPlist = "ErrorDescription" in status;
                auto detailPlist = "ErrorDetail" in status;
                throw new AppInstallationException(
                    errorPlist ? errorPlist.str().native() : "(null)",
                    descriptionPlist ? descriptionPlist.str().native() : "(null)",
                    detailPlist ? cast(long) detailPlist.uinteger().native() : -1
                );
            }
        } catch (Exception t) {
            parentTid.send(cast(immutable) t);
        }
    });
    receive(
            (immutable(Exception) t) => throw cast() t,
            (typeof(null)) {}
    );

    progressCallback(1.0, "Done!");
}

class NoAppIdRemainingException: Exception {
    this(DateTime minExpirationDate, string file = __FILE__, int line = __LINE__) {
        super(format!"Cannot make any more app ID, you have to wait until %s to get a new app ID"(minExpirationDate.toSimpleString()), file, line);
    }
}

class AppInstallationException: Exception {
    this(string error, string description, long detail, string file = __FILE__, int line = __LINE__) {
        super(format!"Cannot install the application on the device! %s: %s (%d)"(error, description, detail), file, line);
    }
}
