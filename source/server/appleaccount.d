module server.appleaccount;

import std.algorithm.iteration;
import std.array;
import std.base64;
import std.datetime;
import std.datetime.systime;
import std.digest.sha;
import std.digest.hmac;
import std.net.curl;
import std.sumtype;
import std.typecons;

import slf4d;

import provision;

import crypto.aes;
import crypto.padding;

import plist;

import constants;
import server.applicationinformation;
import server.applesrpsession;
import utils;

enum AppleLoginErrorCode {
    mismatchedSRP = 1,
    misformattedEncryptedToken = 2,
    no2FAAttempt = 3,
    accountLocked = -20209,
    invalidValidationCode = -21669,
    invalidPassword = -22406,
    unableToSignIn = -36607
}

struct AppleLoginError {
    AppleLoginErrorCode code;
    string description;

    alias code this;
}

alias AppleLoginResponse = SumType!(AppleAccount, AppleLoginError);

struct Success {}
alias AppleTFAResponse = SumType!(Success, AppleLoginError);
alias TFAHandlerDelegate = void delegate(bool delegate() send, AppleTFAResponse delegate(string code) submit);

package class AppleAccount {
    private const Device device;
    private const ADI adi;

    private const ApplicationInformation appInfo;

    private const string adsid;
    private const string token;

    string[string] urls;

    private this(Device device, ADI adi, ApplicationInformation appInfo, string[string] urlBag, string adsid, string token) {
        this.device = device;
        this.adi = adi;
        this.appInfo = appInfo;
        this.urls = urlBag;
        this.adsid = adsid;
        this.token = token;
    }

    package static AppleLoginResponse login(ApplicationInformation applicationInformation, Device device, ADI adi, string appleId, string password, TFAHandlerDelegate tfaHandler) {
        auto log = getLogger();

        log.info("Logging in...");
        HTTP httpClient = HTTP();

        // Anisette information
        httpClient.addRequestHeader("X-Mme-Device-Id", device.uniqueDeviceIdentifier);
        // on macOS, MMe for the Client-Info header is written with 2 caps, while on Windows it is Mme...
        // and HTTP headers are supposed to be case-insensitive in the HTTP spec...
        httpClient.addRequestHeader("X-MMe-Client-Info", device.serverFriendlyDescription);
        httpClient.addRequestHeader("X-Apple-I-MD-LU", device.localUserUUID);

        // Application information
        httpClient.setUserAgent(applicationInformation.applicationName);
        foreach (header; applicationInformation.headers.byKeyValue) {
            httpClient.addRequestHeader(header.key, header.value);
        }

        httpClient.handle.set(CurlOption.ssl_verifypeer, 1);
        httpClient.handle.setBlob(CURLOPT_CAINFO_BLOB, appleAuthCA);

        // Fetch URLs from Apple servers
        auto urlsPlist = Plist.fromXml(cast(string) get("https://gsa.apple.com/grandslam/GsService2/lookup", httpClient))
            .dict()["urls"]
            .dict().native();

        string[string] urls;
        foreach (key, url; urlsPlist) {
            urls[key] = url.str().native();
        }

        // Apple auht protocol is a slightly modified GSA, see AppleSRPSession code for details
        auto srpSession = new AppleSRPSession();
        auto A = srpSession.step1();

        Plist request1 = [
            "Header": [
                "Version": "1.0.1".pl
            ].pl,
            "Request": [
                "A2k": A.pl, // [SRP] A, 2048
                "cpd": clientProvidedData(applicationInformation, device, adi),
                "o": "init".pl,
                "ps": [ // protocols supported
                    "s2k".pl,
                    "s2k_fo".pl
                ].pl,
                "u": appleId.pl // username
            ].pl
        ].pl;

        string request1Str = request1.toXml();
        log.trace(request1Str);

        auto response1Str = cast(string) post(urls["gsService"], request1Str, httpClient);
        log.trace(response1Str);
        auto response1 = Plist.fromXml(response1Str).dict()["Response"].dict();

        auto error1 = response1["Status"].dict().validateStatus();
        if (!error1.isNull()) {
            return AppleLoginResponse(error1.get());
        }

        auto iterations = response1["i"].uinteger().native();
        auto salt = response1["s"].data().native();
        auto selectedProtocol = response1["sp"].str().native();
        auto cookie = response1["c"].str().native();
        auto B = response1["B"].data().native();

        auto M1 = srpSession.step2(appleId, password, selectedProtocol == "s2k_fo", B, salt, iterations);

        Plist request2 = [
            "Header": [
                "Version": "1.0.1".pl
            ].pl,
            "Request": [
                "M1": M1.pl,
                "c": cookie.pl,
                "cpd": clientProvidedData(applicationInformation, device, adi),
                "o": "complete".pl,
                "u": appleId.pl
            ].pl
        ].pl;

        string request2Str = request2.toXml();
        log.trace(request2Str);

        auto response2Str = cast(string) post(urls["gsService"], request2Str, httpClient);
        log.trace(response2Str);

        auto response2 = Plist.fromXml(response2Str).dict()["Response"].dict();
        auto status2 = response2["Status"].dict();
        auto error2 = status2.validateStatus();
        if (!error2.isNull()) {
            return AppleLoginResponse(error2.get());
        }

        auto spd = response2["spd"].data().native();
        // auto np = response2["np"].str().native(); // we assume that the negociation was well performed, too lazy to check for real
        auto M2 = response2["M2"].data().native();

        if (!srpSession.step3(M2)) {
            return AppleLoginResponse(AppleLoginError(AppleLoginErrorCode.mismatchedSRP, "Cannot log-in to the Apple server. Negociation failed."));
        }

        auto K = srpSession.K();
        auto extraDataKeyHmac = HMAC!SHA256(K);
        extraDataKeyHmac.put(cast(ubyte[]) "extra data key:");
        auto extraDataKey = extraDataKeyHmac.finish();

        auto extraDataIvHmac = HMAC!SHA256(K);
        extraDataIvHmac.put(cast(ubyte[]) "extra data iv:");
        auto extraDataIv = extraDataIvHmac.finish().dup[0..16];

        auto decryptedSpd = cast(string) AESUtils.decrypt!AES256(
            cast(ubyte[]) spd,
            cast(char[]) extraDataKey,
            extraDataIv,
            PaddingMode.PKCS7
        );
        log.traceF!"spd: %s"(decryptedSpd);

        auto serverProvidedData = Plist.fromXml(decryptedSpd).dict();

        string idmsToken = serverProvidedData["GsIdmsToken"].str().native();
        string adsid = serverProvidedData["adsid"].str().native();

        if (status2["au"] && status2["au"].str().native() == "trustedDeviceSecondaryAuth") {
            // 2FA is needed
            auto otp = adi.requestOTP(-2);
            httpClient.addRequestHeader("X-Apple-I-MD", Base64.encode(otp.oneTimePassword));
            httpClient.addRequestHeader("X-Apple-I-MD-M", Base64.encode(otp.machineIdentifier));
            httpClient.addRequestHeader("X-Apple-I-MD-RINFO", "17106176");

            auto time = Clock.currTime();
            httpClient.addRequestHeader("X-Apple-I-Client-Time", time.stripMilliseconds().toISOExtString());
            httpClient.addRequestHeader("X-Apple-Locale", locale());
            httpClient.addRequestHeader("X-Apple-I-TimeZone", time.timezone.dstName);

            string identityToken = Base64.encode(cast(ubyte[]) (adsid ~ ":" ~ idmsToken));
            httpClient.addRequestHeader("X-Apple-Identity-Token", identityToken);

            // sends code to the trusted devices
            bool delegate() sendCode = () {
                int code;
                httpClient.onReceiveStatusLine = (HTTP.StatusLine line) {
                    code = line.code;
                };
                get(urls["trustedDeviceSecondaryAuth"], httpClient);
                httpClient.onReceiveStatusLine = null;
                return code == 200;
            };

            // submits the given code to Apple servers
            AppleTFAResponse response = AppleTFAResponse(AppleLoginError(AppleLoginErrorCode.no2FAAttempt, "2FA has not been completed."));
            AppleTFAResponse delegate(string) submitCode = (string code) {
                httpClient.addRequestHeader("security-code", code);
                auto codeValidationPlist = Plist.fromXml(cast(string) get(urls["validateCode"], httpClient)).dict();
                log.traceF!"2FA response: %s"(codeValidationPlist.toXml());
                auto resultCode = codeValidationPlist["ec"].uinteger().native();

                if (resultCode == 0) {
                    response = AppleTFAResponse(Success());
                } else {
                    response = AppleTFAResponse(AppleLoginError(cast(AppleLoginErrorCode) resultCode, codeValidationPlist["em"].str().native()));
                }

                return response;
            };

            tfaHandler(sendCode, submitCode);

            return response.match!(
                (AppleLoginError error) => AppleLoginResponse(error),
                (Success) => login(applicationInformation, device, adi, appleId, password, tfaHandler),
            );
        } else {
            ubyte[] sessionKey = serverProvidedData["sk"].data().native();
            ubyte[] c = serverProvidedData["c"].data().native();

            auto appTokens = HMAC!SHA256(sessionKey);
            appTokens.put(cast(ubyte[]) "apptokens");
            appTokens.put(cast(ubyte[]) adsid);
            appTokens.put(cast(ubyte[]) applicationInformation.applicationId);
            auto checksum = appTokens.finish();

            Plist request3 = [
                "Header": [
                    "Version": "1.0.1".pl
                ].pl,
                "Request": [
                    "u": adsid.pl,
                    "app": [
                        applicationInformation.applicationId.pl
                    ].pl,
                    "c": c.pl,
                    "t": idmsToken.pl,
                    "checksum": checksum.pl,
                    "cpd": clientProvidedData(applicationInformation, device, adi),
                    "o": "apptokens".pl,
                ].pl
            ].pl;

            string request3Str = request3.toXml();
            log.trace(request3Str);

            auto response3Str = cast(string) post(urls["gsService"], request3Str, httpClient);
            log.trace(response3Str);

            auto response3 = Plist.fromXml(response3Str).dict()["Response"].dict();
            auto error3 = response3["Status"].dict().validateStatus();
            if (!error3.isNull()) {
                return AppleLoginResponse(error3.get());
            }

            ubyte[] encryptedToken = response3["et"].data().native();
            char[3] header = cast(char[]) encryptedToken[0..3];

            if (header != "XYZ") {
                return AppleLoginResponse(AppleLoginError(AppleLoginErrorCode.misformattedEncryptedToken, "Encrypted token is in an unknown format."));
            }

            import crypto.aesgcm; // almost openssl-less... almost...
            auto decryptedEt = cast(string) decryptGCM(sessionKey, encryptedToken[3..3 + 16], encryptedToken[0..3], encryptedToken[16 + 3..$ - 16]);
            log.traceF!"et: %s"(decryptedEt);
            auto decryptedToken = Plist.fromXml(decryptedEt).dict();

            auto token = decryptedToken["t"].dict()[applicationInformation.applicationId].dict()["token"].str().native();

            return AppleLoginResponse(new AppleAccount(device, adi, applicationInformation, urls, adsid, token));
        }
    }

    private static Plist clientProvidedData(ApplicationInformation applicationInformation, Device device, ADI adi) {
        auto otp = adi.requestOTP(-2);

        return [
            // Time
            "X-Apple-I-Client-Time": Clock.currTime(UTC()).stripMilliseconds().toISOExtString().pl,
            // Anisette headers
            "X-Apple-I-MD": Base64.encode(otp.oneTimePassword).pl,
            "X-Apple-I-MD-LU": device.localUserUUID.pl,
            "X-Apple-I-MD-M": Base64.encode(otp.machineIdentifier).pl,
            "X-Apple-I-MD-RINFO": "17106176".pl,
            // Device UUID
            "X-Mme-Device-Id": device.uniqueDeviceIdentifier.pl,
            // Miscellaneous headers took from a real request
            "bootstrap": true.pl,
            "capp": applicationInformation.applicationName.pl,
            "ckgen": true.pl,
            "icscrec": true.pl,
            "loc": locale().pl,
            "pbe": false.pl,
            "prkgen": true.pl,
            "svct": "iCloud".pl,
        ].pl;
    }
}

Nullable!AppleLoginError validateStatus(PlistDict status) {
    long errorCode = cast(long) status["ec"].uinteger().native();
    if (!errorCode) {
        return Nullable!AppleLoginError.init;
    }

    return Nullable!AppleLoginError(AppleLoginError(cast(AppleLoginErrorCode) errorCode, status["em"].str().native()));
}
