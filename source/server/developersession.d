module server.developersession;

import std.sumtype;

import slf4d;

import provision;

import server.appleaccount;
import server.applicationinformation;

alias DeveloperLoginResponse = SumType!(DeveloperSession, AppleLoginError);
enum XcodeApplicationInformation = ApplicationInformation("Xcode", "com.apple.gs.xcode.auth", [
    "X-Xcode-Version": "14.2 (14C18)",
    "X-Apple-App-Info": "com.apple.gs.xcode.auth"
]);

class DeveloperSession {
    AppleAccount appleAccount;

    private this(AppleAccount appleAccount) {
        this.appleAccount = appleAccount;
    }

    static DeveloperLoginResponse login(Device device, ADI adi, string appleId, string password, TFAHandlerDelegate tfaHandler) {
        auto log = getLogger();
        log.infoF!"Creating DeveloperSession for %s..."(appleId);
        return AppleAccount.login(XcodeApplicationInformation, device, adi, appleId, password, tfaHandler).match!(
            (AppleAccount appleAccount) {
                log.info("DeveloperSession created successfully.");
                return DeveloperLoginResponse(new DeveloperSession(appleAccount));
            },
            (AppleLoginError err) {
                log.errorF!"DeveloperSession creation failed: %s"(err.description);
                return DeveloperLoginResponse(err);
            }
        );
    }
}
