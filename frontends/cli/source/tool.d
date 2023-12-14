module tool;

import std.algorithm;
import std.array;
import std.exception;
import std.format;
import std.stdio;
import std.typecons;

import slf4d;
import slf4d.default_provider;

import jcli;

import imobiledevice;

import tools;

import cli_frontend;

@Command("tool list", "List tools.")
struct ListTools
{
    @ArgNamed("udid", "iDevice UDID")
    Nullable!string udid = null;

    int onExecute()
    {
        configureLoggingProvider(new shared DefaultProvider(true, Levels.INFO));

        string deviceId;

        if (auto udid = udid.get()) {
            deviceId = udid;
        } else {
            auto deviceList = iDevice.deviceList();
            if (deviceList.length == 0) {
                getLogger().error("Please connect a device.");
                return 1;
            } else if (deviceList.length > 1) {
                getLogger().error("Too many devices connected, please use --udid to select the target device.");
                return 1;
            }

            deviceId = deviceList[0].udid;
        }

        iDevice device = new iDevice(deviceId);

        writeln("Available tools:");
        auto tools = toolList(device);
        foreach (idx, tool; tools) {
            string diag = tool.diagnostic();
            if (diag == null) {
                writefln!" - [%d] `%s` tool."(idx, tool.name);
            } else {
                writefln!" - \033[9m\033[90m[%d] `%s` tool.\033[0m (unavailable: %s)"(idx, tool.name, diag);
            }
        }

        return 0;
    }
}

@Command("tool run", "Run a tool.")
struct RunTool
{
    @ArgPositional("tool index", "The index of the tool to run (use `tool list` to see these indexes).")
    int toolIndex;

    @ArgNamed("udid", "iDevice UDID.")
    Nullable!string udid = null;

    int onExecute()
    {
        configureLoggingProvider(new shared DefaultProvider(true, Levels.INFO));

        string deviceId;

        if (auto udid = udid.get()) {
            deviceId = udid;
        } else {
            auto deviceList = iDevice.deviceList();
            if (deviceList.length == 0) {
                getLogger().error("Please connect a device.");
                return 1;
            } else if (deviceList.length > 1) {
                getLogger().error("Too many devices connected, please use --udid to select the target device.");
                return 1;
            }

            deviceId = deviceList[0].udid;
        }

        iDevice device = new iDevice(deviceId);

        auto tool = toolList(device)[toolIndex];
        if (tool.diagnostic != null) {
            getLogger().errorF!"The tool cannot be run: %s"(tool.diagnostic);
            return 1;
        }

        tool.run((message, canCancel) {
            message = format!"%s [press return to continue]%s"(message, canCancel ? " [press ^C to quit]" : "");
            stdout.writeln(message);
            readln();
            return true;
        });

        return 0;
    }
}
