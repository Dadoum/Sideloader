module server.developersession;

import std.array;
import std.algorithm.iteration;
import std.conv;
import file = std.file;
import std.format;
import std.meta;
import std.sumtype;
import std.traits;
import std.uni;
import std.uuid;

import slf4d;

import provision;

import plist;

import constants;
import server.appleaccount;
import server.applicationinformation;
import utils;

alias DeveloperLoginResponse = SumType!(DeveloperSession, AppleLoginError);
enum XcodeApplicationInformation = ApplicationInformation("Xcode", "com.apple.gs.xcode.auth", [
    "X-Xcode-Version": "14.2 (14C18)",
    "X-Apple-App-Info": "com.apple.gs.xcode.auth"
]);

enum clientId = "XABBG36SBA";
enum protocolVersion = "QH65B2";
template developerPortal(string service, DeveloperDeviceType tag = DeveloperDeviceType.any) {
    enum developerPortal = format!"https://developerservices2.apple.com/services/QH65B2/%s%s?clientId=XABBG36SBA"(tag.urlSegment(), service);
}

struct DeveloperPortalError {
    ulong statusCode;
}
private alias DeveloperPortalResponse(T) = SumType!(T, DeveloperPortalError);

template field(alias elem) {
    template field(string overload) {
        alias field = __traits(getMember, elem, overload);
    }
}

class ExceptionType(T): Exception {
    this(T err, string fileName = __FILE__, size_t line = __LINE__) {
        auto appender = appender!string;
        appender ~= T.stringof;
        appender ~= " {\n";
        static foreach (member; __traits(allMembers, T)) {
            appender ~= member;
            appender ~= " = ";
            appender ~= to!string(__traits(getMember, err, member));
            appender ~= "\n";
        }
        appender ~= "}\n";
        super(appender.toString(), fileName, line);
    }
}

auto unwrap(T)(T response) {
    return response.match!(
        (TemplateArgsOf!T[0] t) => t,
        (TemplateArgsOf!T[1] err) => throw new ExceptionType!DeveloperPortalError(err)
    );
}

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

    DeveloperPortalResponse!(DeveloperTeam[]) listTeams() {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict();

        return sendRequest(developerPortal!"listTeams.action", request).match!(
                (PlistDict dict) => DeveloperPortalResponse(dict["teams"].array().native().map!(
                        (Plist teamPlist) =>
                    DeveloperTeam(teamPlist.dict()["name"].str().native(), teamPlist.dict()["teamId"].str().native())
                ).array()),
            (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!(DeveloperDevice[]) listDevices(DeveloperDeviceType deviceType)(DeveloperTeam team) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "teamId", team.teamId,
        );

        return sendRequest(developerPortal!("listDevices.action", deviceType), request).match!(
                (PlistDict dict) => DeveloperPortalResponse(dict["devices"].array().native().map!(
                        (Plist devicePlist) => DeveloperDevice(
                        devicePlist.dict()["deviceId"].str().native(),
                        devicePlist.dict()["name"].str().native(),
                        devicePlist.dict()["deviceNumber"].str().native()
                    )
                ).array()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!DeveloperDevice addDevice(DeveloperDeviceType deviceType)(DeveloperTeam team, string deviceName, string udid) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "teamId", team.teamId,
            "name", team.teamId,
            "deviceNumber", udid,
        );

        return sendRequest(developerPortal!("addDevice.action", deviceType), request).match!(
                (PlistDict dict) {
                    auto devicePlist = dict["device"].dict();

                    return DeveloperPortalResponse(DeveloperDevice(
                        devicePlist.dict()["deviceId"].str().native(),
                        devicePlist.dict()["name"].str().native(),
                        devicePlist.dict()["deviceNumber"].str().native()
                    ));
                },
                (DeveloperPortalError err) => err
        );
    }

    DeveloperPortalResponse!(DevelopmentCertificate[]) listAllDevelopmentCerts(DeveloperDeviceType deviceType)(DeveloperTeam team) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "teamId", team.teamId,
        );

        return sendRequest(developerPortal!("listAllDevelopmentCerts.action", deviceType), request).match!(
                (PlistDict dict) => DeveloperPortalResponse(dict["certificates"].array().native().map!(
                        (Plist certPlist) => DevelopmentCertificate(
                            certPlist.dict()["name"].str().native(),
                            certPlist.dict()["certificateId"].str().native(),
                            certPlist.dict()["serialNumber"].str().native(),
                            certPlist.dict()["certContent"].data().native(),
                            certPlist.dict()["machineName"].str().native(),
                        )
                ).array()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!void revokeDevelopmentCert(DeveloperDeviceType deviceType)(DeveloperTeam team, DevelopmentCertificate certificate) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "teamId", team.teamId,
            "serialNumber", certificate.serialNumber
        );

        return sendRequest(developerPortal!("revokeDevelopmentCert.action", deviceType), request).match!(
                (PlistDict) => DeveloperPortalResponse(void),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!string submitDevelopmentCSR(DeveloperDeviceType deviceType)(DeveloperTeam team, string csr) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();
        auto machineId = randomUUID().toString().toUpper();

        auto request = dict(
            "teamId", team.teamId,
            "machineId", machineId,
            "machineName", applicationName,
            "csrContent", csr
        );

        return sendRequest(developerPortal!("submitDevelopmentCSR.action", deviceType), request).match!(
                (PlistDict dict) => DeveloperPortalResponse(dict["certRequest"].dict()["certRequestId"].str().native()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!ListAppIdsResponse listAppIds(DeveloperDeviceType deviceType)(DeveloperTeam team) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();
        auto machineId = randomUUID().toString().toUpper();

        auto request = dict(
            "teamId", team.teamId
        );

        return sendRequest(developerPortal!("listAppIds.action", deviceType), request).match!(
                (PlistDict dict) => DeveloperPortalResponse(ListAppIdsResponse(
                        dict["appIds"].array().native().map!(
                            (Plist appIdPlist) => AppId(
                                // appIdPlist.dict()[""].str().native(),
                            )
                        ).array(),
                        dict["maxQuantity"].uinteger().native(),
                        dict["availableQuantity"].uinteger().native(),
                )),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!(ApplicationGroup[]) listApplicationGroups(DeveloperDeviceType deviceType)(DeveloperTeam team) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();
        auto machineId = randomUUID().toString().toUpper();

        auto request = dict(
            "teamId", team.teamId
        );

        return sendRequest(developerPortal!("listApplicationGroups.action", deviceType), request).match!(
                (PlistDict dict) => DeveloperPortalResponse(dict["applicationGroupList"].array().native().map!(
                    (Plist appGroupPlist) => ApplicationGroup(
                        // appGroupPlist.dict()[""].str().native(),
                    )
                ).array()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!PlistDict sendRequest(string url, PlistDict requestParameters) {
        auto log = getLogger();
        auto requestId = randomUUID().toString().toUpper();

        auto request = dict(
            "clientId", clientId,
            "protocolVersion", protocolVersion,
            "requestId", requestId,
            "userLocale", [locale().pl],
        );

        request.merge(requestParameters);
        auto response = appleAccount.sendRequest(url, request).dict();
        auto statusCode = response["statusCode"] ? response["statusCode"].uinteger().native() : 0;

        if (statusCode != 0) {
            return DeveloperPortalResponse!PlistDict(
                DeveloperPortalError(statusCode)
            );
        }

        return DeveloperPortalResponse!PlistDict(response);
    }
}

enum DeveloperDeviceType {
    any,
    iOS,
    tvOS,
    watchOS
}

enum iOS = DeveloperDeviceType.iOS;
enum tvOS = DeveloperDeviceType.tvOS;
enum watchOS = DeveloperDeviceType.watchOS;

string urlSegment(DeveloperDeviceType deviceType) {
    final switch (deviceType) {
        case DeveloperDeviceType.any:
            return "";
        case iOS:
            return "ios/";
        case tvOS:
            return "tvos/";
        case watchOS:
            return "watchos/";
    }
}

struct DeveloperTeam {
    string name;
    string teamId;
}

struct DeveloperDevice {
    string deviceId;
    string name;
    string deviceNumber;
}

struct DevelopmentCertificate {
    string name;
    string certificateId;
    string serialNumber;
    ubyte[] certContent;
    string machineName;
}

struct ListAppIdsResponse {
    AppId[] array;
    ulong maxQuantity;
    ulong availableQuantity;
}

struct AppId {

}

struct ApplicationGroup {

}
