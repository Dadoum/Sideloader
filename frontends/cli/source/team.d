module team;

import std.algorithm;
import std.array;
import std.exception;
import std.stdio;
import std.typecons;

import slf4d;
import slf4d.default_provider;

import jcli;

import server.developersession;

import cli_frontend;

@Command("team list", "List teams.")
struct ListTeams
{
    mixin LoginCommand;

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

        writeln("Teams:");
        auto teams = appleAccount.listTeams().unwrap();
        foreach (team; teams) {
            writefln!" - `%s`, with ID `%s`."(team.name, team.teamId);
        }

        return 0;
    }
}
