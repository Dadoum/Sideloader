module tool;

import std.algorithm;
import std.array;
import std.exception;
import std.format;
import std.stdio;
import std.sumtype;
import std.typecons;

import slf4d;
import slf4d.default_provider;

import argparse;

import imobiledevice;

import tools;

import cli_frontend;

@(Command("tool").Description("Run Sideloader's tools."))
struct ToolCommand
{
    int opCall()
    {
        return cmd.match!(
                (ListTools cmd) => cmd(),
                (RunTool cmd) => cmd(),
        );
    }

    @SubCommands
    SumType!(ListTools, RunTool) cmd;
}

@(Command("list").Description("List tools."))
struct ListTools
{
    @(NamedArgument("udid").Description("iDevice UDID"))
    string udid = null;

    int opCall()
    {
        string deviceId;

        if (auto udid = udid) {
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

@(Command("run").Description("Run a tool."))
struct RunTool
{
    @(PositionalArgument(0, "tool index").Description("The index of the tool to run (use `tool list` to see these indexes)."))
    size_t toolIndex;

    @(NamedArgument("udid").Description("iDevice UDID."))
    string udid = null;

    int opCall()
    {
        string deviceId;

        if (udid) {
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

        auto tool = toolList(device)[cast(size_t) toolIndex];
        if (tool.diagnostic != null) {
            getLogger().errorF!"The tool cannot be run: %s"(tool.diagnostic);
            return 1;
        }

        tool.run((message, canCancel) {
            message = format!"%s [OK = return]%s"(message, canCancel ? " [exit = ^C]" : "");
            stdout.writeln(message);
            readln();
            return false;
        });

        return 0;
    }
}
