module device;

import std.algorithm;
import std.array;
import std.exception;
import std.stdio;
import std.sumtype;
import std.typecons;

import slf4d;
import slf4d.default_provider;

import botan.cert.x509.pkcs10;
import botan.filters.data_src;

import argparse;

import server.developersession;

import cli_frontend;

@(Command("device").Description("Manage registered devices."))
struct DeviceCommand
{
    int opCall()
    {
        return cmd.match!(
                (ListDevices cmd) => cmd(),
                (AddDevice cmd) => cmd(),
                (DeleteDevice cmd) => cmd()
        );
    }

    @SubCommands
    SumType!(ListDevices, AddDevice, DeleteDevice) cmd;
}

@(Command("list").Description("List registered devices."))
struct ListDevices
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

        auto devices = appleAccount.listDevices!iOS(team).unwrap();

        writefln!"You have %d devices registered."(devices.length);
        writeln("Currently registered devices:");
        foreach (device; devices) {
            writefln!" - Device `%s` of UDID `%s` with the identifier `%s`"(device.name, device.deviceNumber, device.deviceId);
        }

        return 0;
    }
}

@(Command("add").Description("Register device."))
struct AddDevice
{
    mixin LoginCommand;

    @(NamedArgument("team").Description("Team ID"))
    string teamId = null;

    @(PositionalArgument(0).Description("Device name"))
    string name = void;

    @(PositionalArgument(1).Description("Device UDID"))
    string udid = void;

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

        auto devices = appleAccount.addDevice!iOS(team, name, udid).unwrap();
        log.info("Success!");

        return 0;
    }
}

@(Command("delete").Description("Unregister device."))
struct DeleteDevice
{
    mixin LoginCommand;

    @(NamedArgument("team").Description("Team ID"))
    string teamId = null;

    @(PositionalArgument(0).Description("Apple device's identifier (not UDID, check device list)."))
    string deviceId = void;

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

        auto devices = appleAccount.deleteDevice!iOS(team, deviceId).unwrap();
        log.info("Success!");

        return 0;
    }
}

