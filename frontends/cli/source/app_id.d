module app_id;

import std.algorithm;
import std.array;
import std.exception;
import file = std.file;
import std.stdio;
import std.typecons;

import slf4d;
import slf4d.default_provider;

import jcli;

import server.developersession;

import cli_frontend;

// @Command("app-id", "Manage App IDs.")

@Command("app-id list", "List App IDs.")
struct ListAppIds
{
    mixin LoginCommand;

    @ArgNamed("team", "Team ID")
    Nullable!string teamId = null;

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

        auto teams = appleAccount.listTeams().unwrap();

        string teamId = this.teamId.get(null);
        if (teamId != null) {
            teams = teams.filter!((elem) => elem.teamId == teamId).array();
        }
        enforce(teams.length > 0, "No matching team found.");

        auto team = teams[0];

        auto appIds = appleAccount.listAppIds!iOS(team).unwrap();

        writefln!"You have %d App IDs available out of the %d you have at your disposal."(appIds.availableQuantity, appIds.maxQuantity);
        writeln("Currently registered App IDs:");
        foreach (appId; appIds.appIds) {
            writefln!" - `%s` for the app `%s`, expiring on %s."(appId.identifier, appId.name, appId.expirationDate);
        }

        return 0;
    }
}

@Command("app-id add", "Add a new App ID.")
struct AddAppId
{
    mixin LoginCommand;

    @ArgNamed("team", "Team ID")
    Nullable!string teamId = null;

    @ArgPositional("app name")
    string name;

    @ArgPositional("app identifier")
    string identifier;

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

        auto teams = appleAccount.listTeams().unwrap();

        string teamId = this.teamId.get(null);
        if (teamId != null) {
            teams = teams.filter!((elem) => elem.teamId == teamId).array();
        }
        enforce(teams.length > 0, "No matching team found.");

        auto team = teams[0];

        appleAccount.addAppId!iOS(team, identifier, name).unwrap();

        log.info("Done.");

        return 0;
    }
}

@Command("app-id delete", "Delete an App ID (it won't let you create more App IDs though).")
struct DeleteAppId
{
    mixin LoginCommand;

    @ArgNamed("team", "Team ID")
    Nullable!string teamId = null;

    @ArgPositional("app identifier")
    string identifier;

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

        auto teams = appleAccount.listTeams().unwrap();

        string teamId = this.teamId.get(null);
        if (teamId != null) {
            teams = teams.filter!((elem) => elem.teamId == teamId).array();
        }
        enforce(teams.length > 0, "No matching team found.");

        auto team = teams[0];

        auto appIds = appleAccount.listAppIds!iOS(team).unwrap().appIds;
        auto matchingAppIds = appIds.filter!((appId) => appId.identifier == identifier).array();

        if (matchingAppIds.length == 0) {
            log.error("No matching App ID found.");
            return 1;
        }

        enforce(matchingAppIds.length == 1, "Multiple App ID matched?? To prevent any issue, ignoring the request.");
        appleAccount.deleteAppId!iOS(team, matchingAppIds[0]).unwrap();

        log.info("Done.");

        return 0;
    }
}

@Command("app-id download", "Download the provisioning profile for an App ID")
struct DownloadProvision
{
    mixin LoginCommand;

    @ArgNamed("team", "Team ID")
    Nullable!string teamId = null;

    @ArgNamed("output|o", "Output file")
    string outputPath;

    @ArgPositional("app identifier")
    string identifier;

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

        auto teams = appleAccount.listTeams().unwrap();

        string teamId = this.teamId.get(null);
        if (teamId != null) {
            teams = teams.filter!((elem) => elem.teamId == teamId).array();
        }
        enforce(teams.length > 0, "No matching team found");

        auto team = teams[0];

        auto appIds = appleAccount.listAppIds!iOS(team).unwrap().appIds;
        auto matchingAppIds = appIds.filter!((appId) => appId.identifier == identifier).array();

        if (matchingAppIds.length == 0) {
            log.error("No matching App ID found.");
            return 1;
        }

        enforce(matchingAppIds.length == 1, "Multiple App ID matched?? To prevent any issue, ignoring the request.");

        log.info("Downloading the profile...");
        file.write(outputPath, appleAccount.downloadTeamProvisioningProfile!iOS(team, matchingAppIds[0]).unwrap().encodedProfile);
        log.info("Done.");

        return 0;
    }
}

