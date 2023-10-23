module tools.sidestorepairingfile;

import imobiledevice;

void askForTrust(iDevice device) {
    scope lockdownClient = new LockdowndClient(device, "sideloader.trust-service");
    scope pairing = lockdownClient.pair();
}

/// returns: success?
/// throws if sidestore isn't installed.
bool sendSideStorePairingFile(iDevice device) {
    return false;
}
