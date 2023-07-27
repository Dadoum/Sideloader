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
    enum STEP_COUNT = 10.0;
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

    import std.process;
    // auto codesignProcess = ["rcodesign", "sign", "--team-name", team.teamId, "--pem-source", certIdentity.keyFile, "--der-source", certIdentity.certFile, app.appFolder];
    auto codesignProcess = ["zsign", "-b", mainAppIdStr, "-m", app.appFolder.buildPath("embedded.mobileprovision"), "-k", certIdentity.keyFile, "-c", certIdentity.certFile, app.appFolder];
    log.debugF!"> %s"(codesignProcess.join(' '));
    wait(spawnProcess(codesignProcess));

    // connect to the device's installation daemon and send to it the signed app
    double progress = 9 / STEP_COUNT;
    progressCallback(progress, "Installing the application on the device");
    auto lockdownClient = new LockdowndClient(device, "sideloader.app_install");

    // set up clients and proxies
    auto installationProxyService = lockdownClient.startService("com.apple.mobile.installation_proxy");
    auto installationProxyClient = new InstallationProxyClient(device, installationProxyService);

    auto misagentService = lockdownClient.startService("com.apple.misagent");
    auto misagentClient = new MisagentClient(device, misagentService);

    auto afcService = lockdownClient.startService("com.apple.afc");
    auto afcClient = new AFCClient(device, afcService);

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

    auto remoteAppFolder = stagingDir.buildPath(baseName(app.appFolder));
    if (afcClient.getFileInfo(remoteAppFolder, props) != AFCError.AFC_E_SUCCESS) {
        // The directory does not exist, so let's create it!
        afcClient.makeDirectory(remoteAppFolder).assertSuccess();
    }

    auto files = file.dirEntries(app.appFolder, file.SpanMode.breadth).array();
    // 75% of the last step is sending the files.
    auto transferStep = 3 / (STEP_COUNT * files.length * 4);

    foreach (f; files) {
        auto remotePath = remoteAppFolder.buildPath(f.asRelativePath(app.appFolder).array());
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

    import std.concurrency;
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
                    progress + (status["PercentComplete"].uinteger() / 400.0),
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
        } catch (Throwable t) {
            parentTid.send(cast(immutable) t);
        }
    });
    receive(
        (immutable(Throwable) t) => throw t,
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
