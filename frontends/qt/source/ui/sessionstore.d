/++
    Persistence of the Apple developer session.

    Bridges DeveloperSession's snapshot to the platform secret store: JSON in,
    JSON out, with the storage details left to ui.credentials.
+/
module ui.sessionstore;

import std.json;

import slf4d;

import provision;

import server.developersession;

import ui.credentials;

/// Credential Manager entry name. Stable, since it is also what the user
/// sees if they go looking for it in Windows.
private enum credentialTarget = "Sideloader:AppleDeveloperSession";

/// Stores the session so the next launch does not ask for a password.
void rememberSession(DeveloperSession session) {
    auto log = getLogger();
    log.info("Saving the developer session...");

    // Everything here runs inside a Qt slot, and an exception cannot cross
    // back into C++: it would be swallowed, leaving no session saved and no
    // trace of why. Catching it keeps the failure visible.
    try {
        rememberSessionImpl(session);
    } catch (Exception ex) {
        log.errorF!"Could not save the session: %s"(ex);
    }
}

private void rememberSessionImpl(DeveloperSession session) {
    auto saved = session.save();

    JSONValue document = [
        "appleId": JSONValue(saved.appleId),
        "adsid": JSONValue(saved.adsid),
        "token": JSONValue(saved.token),
    ];

    string payload = document.toString();
    getLogger().infoF!"Session payload built for %s (%d bytes)."(saved.appleId, payload.length);

    if (storeSecret(credentialTarget, saved.appleId, payload))
        getLogger().infoF!"Session saved for %s."(saved.appleId);
    else
        getLogger().warn("Credential Manager refused the session; sign-in will be asked again.");
}

/++
    Rebuilds the stored session, or returns null if there is none.

    A malformed entry is dropped rather than reported: the only sensible
    recovery is to sign in again, and a stale blob would otherwise fail on
    every launch.
+/
DeveloperSession recallSession(Device device, ADI adi) {
    string stored = loadSecret(credentialTarget);
    if (!stored)
        return null;

    try {
        auto document = parseJSON(stored);

        auto saved = SavedDeveloperSession(
            document["appleId"].str,
            document["adsid"].str,
            document["token"].str,
        );

        getLogger().infoF!"Restoring saved session for %s."(saved.appleId);
        return DeveloperSession.restore(device, adi, saved);
    } catch (Exception ex) {
        getLogger().warnF!"Stored session is unreadable, discarding it: %s"(ex.msg);
        forgetSession();
        return null;
    }
}

/// Drops the stored session, so the next install asks to sign in again.
void forgetSession() {
    forgetSecret(credentialTarget);
}
