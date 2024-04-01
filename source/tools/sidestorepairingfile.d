module tools.sidestorepairingfile;

import std.algorithm;
import std.array;
import std.format;

import slf4d;

import plist;

import imobiledevice;
import usbmuxd;

import tools;

class SideStoreTool: Tool {
    string[] sideStoreBundles;

    this(iDevice device) {
        super(device, new LockdowndClient(device, "sideloader.sidestore-trust"));

        scope installationProxyService = lockdowndClient.startService("com.apple.mobile.installation_proxy");
        scope installationProxyClient = new InstallationProxyClient(device, installationProxyService);

        sideStoreBundles = installationProxyClient.browse([
            "ApplicationType": "User".pl,
            "ReturnAttributes": [
                "CFBundleIdentifier".pl
            ].pl
        ].pl).array().native()
        .filter!((elem) => elem["CFBundleIdentifier"].str().native().startsWith("com.SideStore.SideStore"))
        .map!((elem) => elem["CFBundleIdentifier"].str().native())
        .array();
    }

    override string name() {
        return "Set-up SideStore's pairing file";
    }

    override string diagnostic() {
        return sideStoreBundles.length > 0 ? null : "SideStore is not installed on the device.";
    }

    override void run(bool delegate(string message, bool canCancel = true) notify) {
        auto log = getLogger();
        log.info("Placing SideStore pairing file.");

        assert(diagnostic() == null);
        {
            lockdownd_error_t error;
            do {
                error = lockdowndClient.pair();
                with(lockdownd_error_t) switch (error) {
                    case LOCKDOWN_E_SUCCESS:
                        break;
                    case LOCKDOWN_E_PASSWORD_PROTECTED:
                        if (notify("Please unlock your phone. (press OK to try again)")) {
                            return;
                        }
                        break;
                    case LOCKDOWN_E_PAIRING_DIALOG_RESPONSE_PENDING:
                        if (notify("Please trust the computer. (press OK to try again)")) {
                            return;
                        }
                        break;
                    case LOCKDOWN_E_USER_DENIED_PAIRING:
                        notify("You refused to trust the computer.", false);
                        return;
                    default:
                        notify("Unknown error, please check that the device is plugged correctly, unlocked and trusts the computer. (press OK to try again)");
                        return;
                }
            } while (error != lockdownd_error_t.LOCKDOWN_E_SUCCESS);
        }

        string udid = device.udid();
        ubyte[] pairingFile = readPairRecord(udid);
        log.debugF!"Pairing file fetched (is null: %s, length: %d)."(pairingFile == null, pairingFile == null ? 0 : pairingFile.length);
        scope pairRecord = Plist.fromMemory(pairingFile).dict();
        pairRecord["UDID"] = udid.pl;
        log.debug_("Pairing file ready.");

        string hostId = pairRecord["HostID"].str().native();
        // string sessionId = lockdowndClient.startSession(hostId);
        // scope(exit) lockdowndClient.stopSession(sessionId);

        lockdowndClient["com.apple.mobile.wireless_lockdown", "EnableWifiDebugging"] = true.pl;
        log.debug_("Wireless connections enabled");

        foreach (sideStoreBundleId; sideStoreBundles) {
            log.debugF!"Starting House Arrest for %s"(sideStoreBundleId);
            scope houseArrest = new HouseArrestClient(device);
            // We could only mount documents but that code snippet might be useful to clear caches in the future
            // so having all that code ready is cool
            houseArrest.sendCommand("VendContainer", sideStoreBundleId);
            Plist result = houseArrest.getResult();
            if (Plist error = "Error" in result.dict()) {
                log.errorF!"Error occured while House Arrest set-up: %s"(result);
                string value = error.str().native();
                if (notify(
                        format!"Cannot access to the app container for %s! Are you sure it's official SideStore app?"(sideStoreBundleId)
                        ~ (sideStoreBundleId.length > 1 ? " (press OK to do it for the others app bundles)" : ""), sideStoreBundleId.length > 1
                )) {
                    return;
                }
                continue;
            }

            log.debugF!"Starting AFC for %s"(sideStoreBundleId);
            scope afcClient = new AFCClient(houseArrest);

            log.debug_("Writing file");
            auto remoteFile = afcClient.open("/Documents/ALTPairingFile.mobiledevicepairing", AFCFileMode.AFC_FOPEN_WRONLY);
            scope(exit) afcClient.close(remoteFile);

            ubyte[] fileData = cast(ubyte[]) pairRecord.toXml();

            uint bytesWrote = 0;
            while (bytesWrote < fileData.length) {
                bytesWrote += afcClient.write(remoteFile, fileData);
            }
            log.debug_("Done!");
        }
        notify("The pairing file has been successfully set up for " ~ sideStoreBundles.join(", ") ~ ".", false);
    }
}
