/++
    Record of what has been installed, and when.

    A free Apple account signs with a certificate that Apple expires after
    seven days: sideloaded apps simply stop launching. Renewing means signing
    and installing the same package again, so the only thing worth keeping is
    enough information to repeat the operation unattended.

    Stored as JSON next to the rest of the configuration. Nothing here is
    secret: paths and bundle identifiers only, with the credentials left in
    the Credential Manager.
+/
module ui.installtracker;

import std.algorithm : filter, remove, sort;
import std.array : array;
import std.datetime;
import std.file;
import std.json;
import std.path : buildPath;

import slf4d;

/// Apple's validity window for a free development certificate.
enum certificateLifetime = 7;

struct TrackedInstall {
    string bundleIdentifier;
    string bundleName;
    /// Package to sign again. A renewal is impossible once this is gone.
    string ipaPath;
    string deviceUdid;
    /// Unix seconds, so the file survives a locale or timezone change.
    long installedAt;

    /// Whole days left before the signature lapses; negative once expired.
    int daysRemaining() const {
        auto installed = SysTime.fromUnixTime(installedAt);
        auto age = (Clock.currTime() - installed).total!"days";
        return cast(int) (certificateLifetime - age);
    }

    bool expired() const {
        return daysRemaining() <= 0;
    }

    /// True once renewal is worth doing: Apple only re-issues near the end.
    bool needsRenewal() const {
        return daysRemaining() <= 2;
    }

    /// Whether the package is still where it was installed from.
    bool renewable() const {
        return ipaPath.length > 0 && ipaPath.exists();
    }
}

/++
    The install list, persisted as a JSON file.

    Keyed on bundle identifier plus device: reinstalling an app replaces its
    entry rather than piling up duplicates.
+/
struct InstallTracker {
    private string path;
    private TrackedInstall[] entries;

    this(string configurationPath) {
        this.path = configurationPath.buildPath("installs.json");
        load();
    }

    TrackedInstall[] installs() {
        return entries;
    }

    /// Records an install, replacing any previous entry for the same app on
    /// the same device.
    void record(string bundleIdentifier, string bundleName, string ipaPath, string deviceUdid) {
        foreach (ref entry; entries) {
            if (entry.bundleIdentifier == bundleIdentifier && entry.deviceUdid == deviceUdid) {
                entry.bundleName = bundleName;
                entry.ipaPath = ipaPath;
                entry.installedAt = Clock.currTime().toUnixTime();
                save();
                return;
            }
        }

        entries ~= TrackedInstall(
            bundleIdentifier, bundleName, ipaPath, deviceUdid,
            Clock.currTime().toUnixTime());
        save();
    }

    void forget(string bundleIdentifier, string deviceUdid) {
        entries = entries
            .filter!(e => !(e.bundleIdentifier == bundleIdentifier && e.deviceUdid == deviceUdid))
            .array();
        save();
    }

    private void load() {
        entries = null;

        if (!path.exists())
            return;

        try {
            foreach (item; parseJSON(readText(path)).array) {
                entries ~= TrackedInstall(
                    item["bundleIdentifier"].str,
                    item["bundleName"].str,
                    item["ipaPath"].str,
                    item["deviceUdid"].str,
                    item["installedAt"].integer,
                );
            }
        } catch (Exception ex) {
            // A corrupt list is not worth failing over; the worst outcome is
            // losing the renewal reminders, and installing rebuilds it.
            getLogger().warnF!"Install list unreadable, starting a fresh one: %s"(ex.msg);
            entries = null;
        }
    }

    private void save() {
        try {
            JSONValue[] items;
            foreach (entry; entries) {
                items ~= JSONValue([
                    "bundleIdentifier": JSONValue(entry.bundleIdentifier),
                    "bundleName": JSONValue(entry.bundleName),
                    "ipaPath": JSONValue(entry.ipaPath),
                    "deviceUdid": JSONValue(entry.deviceUdid),
                    "installedAt": JSONValue(entry.installedAt),
                ]);
            }
            std.file.write(path, JSONValue(items).toPrettyString());
        } catch (Exception ex) {
            getLogger().warnF!"Could not save the install list: %s"(ex.msg);
        }
    }
}
