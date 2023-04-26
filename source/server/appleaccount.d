module server.appleaccount;

import std.base64;
import std.datetime;
import std.datetime.systime;
import std.net.curl;
import std.sumtype;
import std.typecons;

import botan.block.aes;
import botan.block.aes_ni;
import botan.block.aes_ssse3;
import botan.hash.sha2_32;
import botan.mac.hmac;
import botan.stream.ctr;
import botan.utils.cpuid;

import slf4d;

import provision;

import plist;

import constants;
import server.applicationinformation;
import server.applesrpsession;
import utils;

enum AppleLoginErrorCode {
    mismatchedSRP = 1,
    accountLocked = -20209,
    invalidPassword = -22406,
    unableToSignIn = -36607
}

struct AppleLoginError {
    AppleLoginErrorCode code;
    string description;

    alias code this;
}

alias AppleLoginResponse = SumType!(AppleAccount, AppleLoginError);

package class AppleAccount {
    private this() {}

    package static AppleLoginResponse login(ApplicationInformation applicationInformation, Device device, ADI adi, string appleId, string password, int tfaCode = -1) {
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

        // get anisette data
        auto srpSession = new AppleSRPSession();
        auto A = srpSession.step1();

        Plist request1 = [
            "Header": [
                "Version": "1.0.1".pl
            ].pl,
            "Request": [
                "A2k": A.pl, // A, 2048
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

        auto response1Str = cast(string) post("https://gsa.apple.com/grandslam/GsService2", request1Str, httpClient);
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

        auto response2Str = cast(string) post("https://gsa.apple.com/grandslam/GsService2", request2Str, httpClient);
        log.trace(response2Str);

        auto response2 = Plist.fromXml(response2Str).dict()["Response"].dict();
        auto error2 = response2["Status"].dict().validateStatus();
        if (!error2.isNull()) {
            return AppleLoginResponse(error2.get());
        }

        auto spd = response2["spd"].data().native();
        // auto np = response2["np"].str().native(); // we assume that the negociation was well performed.
        auto M2 = response2["M2"].data().native();

        if (!srpSession.step3(M2)) {
            return AppleLoginResponse(AppleLoginError(AppleLoginErrorCode.mismatchedSRP, "Cannot log-in to the Apple server. Negociation failed."));
        }

        auto hmac = new HMAC(new SHA256());
        hmac.update("extra data key:");
        auto extraDataKey = SymmetricKey(hmac.finished());

        hmac.update("extra data iv:");
        auto extraDataIv = hmac.finished()[].dup;

        import  botan.filters.pipe;
        import botan.libstate.lookup;

        auto aesDecryptor = Pipe(getCipher("AES-256/CBC/NoPadding", extraDataKey, InitializationVector(extraDataIv.ptr, 16), DECRYPTION));
        aesDecryptor.processMsg(spd.ptr, spd.length);

        log.infoF!"Decrypted spd: %s"(cast(string) aesDecryptor.readAll()[].dup);
        // auto decryptedSpd = Plist.fromXml(cast(string) spdSecureVec[].dup).dict();

        return AppleLoginResponse(null);
    }

    private static Plist clientProvidedData(ApplicationInformation applicationInformation, Device device, ADI adi) {
        auto otp = adi.requestOTP(-2);

        return [
            "X-Apple-I-Client-Time": Clock.currTime(UTC()).stripMilliseconds().toISOExtString().pl,
            "X-Apple-I-MD": Base64.encode(otp.oneTimePassword).pl,
            "X-Apple-I-MD-LU": device.localUserUUID.pl,
            "X-Apple-I-MD-M": Base64.encode(otp.machineIdentifier).pl,
            "X-Apple-I-MD-RINFO": "17106176".pl,
            "X-Mme-Device-Id": device.uniqueDeviceIdentifier.pl,
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
