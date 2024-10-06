module app_id;

import std.algorithm;
import std.array;
import std.exception;
import file = std.file;
import std.stdio;
import std.sumtype;
import std.typecons;

import slf4d;
import slf4d.default_provider;

import argparse;

import server.developersession;

import cli_frontend;

@(Command("app-id").Description("Manage App IDs."))
struct AppIdCommand
{
    int opCall()
    {
        return cmd.match!(
            (ListAppIds cmd) => cmd(),
            (AddAppId cmd) => cmd(),
            (DeleteAppId cmd) => cmd(),
            (DownloadProvision cmd) => cmd()
        );
    }

    @SubCommands
    SumType!(ListAppIds, AddAppId, DeleteAppId, DownloadProvision) cmd;
}

@(Command("list").Description("List App IDs."))
struct ListAppIds
{
    mixin LoginCommand;

    @(NamedArgument("team").Description("Team ID"))
    string teamId = null;

    int opCall()
    {
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

        string teamId = this.teamId;
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

@(Command("add").Description("Add a new App ID."))
struct AddAppId
{
    mixin LoginCommand;

    @(NamedArgument("team").Description("Team ID"))
    string teamId = null;

    @(PositionalArgument(0).Description("app name"))
    string name;

    @(PositionalArgument(1).Description("app identifier"))
    string identifier;

    int opCall()
    {
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

        string teamId = this.teamId;
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

@(Command("delete").Description("Delete an App ID (it won't let you create more App IDs though)."))
struct DeleteAppId
{
    mixin LoginCommand;

    @(NamedArgument("team").Description("Team ID"))
    string teamId = null;

    @(PositionalArgument(0).Description("app identifier"))
    string identifier;

    int opCall()
    {
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

@(Command("download").Description("Download the provisioning profile for an App ID"))
struct DownloadProvision
{
    mixin LoginCommand;

    @(NamedArgument("team").Description("Team ID"))
    string teamId = null;

    @(NamedArgument("o", "output").Description("Output file").Required())
    string outputPath;

    @(PositionalArgument(0).Description("app identifier"))
    string identifier;

    int opCall()
    {
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

        string teamId = this.teamId;
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

