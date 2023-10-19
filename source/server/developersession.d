module server.developersession;

import std.array;
import std.algorithm.iteration;
import std.datetime;
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

struct None {}

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
    string description;
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
            appender ~= "\t";
            appender ~= member;
            appender ~= " = ";
            appender ~= to!string(__traits(getMember, err, member));
            appender ~= "\n";
        }
        appender ~= "}";
        super(appender[], fileName, line);
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
     alias appleAccount this;

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

    DeveloperPortalResponse!None viewDeveloper() {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict();

        return sendRequest(developerPortal!"viewDeveloper.action", request).match!(
                (PlistDict dict) => DeveloperPortalResponse(None()),
            (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!(DeveloperTeam[]) listTeams() {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict();

        return sendRequest(developerPortal!"listTeams.action", request).match!(
                (PlistDict dict) => DeveloperPortalResponse(dict["teams"].array().native().map!(
                        (Plist teamPlist) =>
                    DeveloperTeam(teamPlist["name"].str().native(), teamPlist["teamId"].str().native())
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
                        devicePlist["deviceId"].str().native(),
                        devicePlist["name"].str().native(),
                        devicePlist["deviceNumber"].str().native()
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
            "name", deviceName,
            "deviceNumber", udid,
        );

        return sendRequest(developerPortal!("addDevice.action", deviceType), request).match!(
                (PlistDict dict) {
                    auto devicePlist = dict["device"].dict();

                    return DeveloperPortalResponse(DeveloperDevice(
                        devicePlist["deviceId"].str().native(),
                        devicePlist["name"].str().native(),
                        devicePlist["deviceNumber"].str().native()
                    ));
                },
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!None deleteDevice(DeveloperDeviceType deviceType)(DeveloperTeam team, string deviceId) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "teamId", team.teamId,
            "deviceId", deviceId,
        );

        return sendRequest(developerPortal!("deleteDevice.action", deviceType), request).match!(
                (PlistDict d) => DeveloperPortalResponse(None()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
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
                            certPlist["name"].str().native(),
                            certPlist["certificateId"].str().native(),
                            certPlist["serialNumber"].str().native(),
                            certPlist["certContent"].data().native(),
                            certPlist["machineName"].str().native(),
                        )
                ).array()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!None revokeDevelopmentCert(DeveloperDeviceType deviceType)(DeveloperTeam team, DevelopmentCertificate certificate) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "teamId", team.teamId,
            "serialNumber", certificate.serialNumber
        );

        return sendRequest(developerPortal!("revokeDevelopmentCert.action", deviceType), request).match!(
                (PlistDict d) => DeveloperPortalResponse(None()),
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
                (PlistDict dict) => DeveloperPortalResponse(dict["certRequest"]["certRequestId"].str().native()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!ListAppIdsResponse listAppIds(DeveloperDeviceType deviceType)(DeveloperTeam team) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "teamId", team.teamId
        );

        return sendRequest(developerPortal!("listAppIds.action", deviceType), request).match!(
                (PlistDict dict) => DeveloperPortalResponse(ListAppIdsResponse(
                        dict["appIds"].array().native().map!(
                            (Plist appIdPlist) {
                                auto appId = appIdPlist.dict();
                                return AppId(
                                    appId["appIdId"].str().native(),
                                    appId["identifier"].str().native(),
                                    appId["name"].str().native(),
                                    appId["features"].dict(),
                                    appId["expirationDate"].date().native(),
                                );
                            }
                        ).array(),
                        dict["maxQuantity"].uinteger().native(),
                        dict["availableQuantity"].uinteger().native(),
                )),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!None addAppId(DeveloperDeviceType deviceType)(DeveloperTeam team, string appIdentifier, string appName) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "identifier", appIdentifier,
            // entitlements, [].pl,
            "name", appName,
            "teamId", team.teamId,
        );

        return sendRequest(developerPortal!("addAppId.action", deviceType), request).match!(
                (PlistDict dict) => DeveloperPortalResponse(None()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!PlistDict updateAppId(DeveloperDeviceType deviceType)(DeveloperTeam team, AppId appId, PlistDict features) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "appIdId", appId.appIdId,
            "teamId", team.teamId,
        );

        request.merge(features);

        return sendRequest(developerPortal!("updateAppId.action", deviceType), request).match!(
                (PlistDict dict) => DeveloperPortalResponse(dict["appId"]["features"].dict()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!None deleteAppId(DeveloperDeviceType deviceType)(DeveloperTeam team, AppId appId) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "appIdId", appId.appIdId,
            "teamId", team.teamId,
        );

        return sendRequest(developerPortal!("deleteAppId.action", deviceType), request).match!(
                (PlistDict dict) => DeveloperPortalResponse(None()),
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
                        appGroupPlist["applicationGroup"].str().native(),
                        appGroupPlist["name"].str().native(),
                        appGroupPlist["identifier"].str().native(),
                    )
                ).array()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!ApplicationGroup addApplicationGroup(DeveloperDeviceType deviceType)(DeveloperTeam team, string groupIdentifier, string name) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "identifier", groupIdentifier,
            "name", name,
            "teamId", team.teamId,
        );

        return sendRequest(developerPortal!("addApplicationGroup.action", deviceType), request).match!(
                (PlistDict dict) {
                    auto appGroupPlist = dict["applicationGroup"].dict();
                    return DeveloperPortalResponse(ApplicationGroup(
                        appGroupPlist["applicationGroup"].str().native(),
                        appGroupPlist["name"].str().native(),
                        appGroupPlist["identifier"].str().native(),
                    ));
                },
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!None assignApplicationGroupToAppId(DeveloperDeviceType deviceType)(DeveloperTeam team, AppId appId, ApplicationGroup appGroup) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "appIdId", appId.appIdId,
            "applicationGroups", appGroup.applicationGroup,
            "teamId", team.teamId,
        );

        return sendRequest(developerPortal!("assignApplicationGroupToAppId.action", deviceType), request).match!(
                (PlistDict dict)  => DeveloperPortalResponse(None()),
                (DeveloperPortalError err) => DeveloperPortalResponse(err)
        );
    }

    DeveloperPortalResponse!ProvisioningProfile downloadTeamProvisioningProfile(DeveloperDeviceType deviceType)(DeveloperTeam team, AppId appId) {
        alias DeveloperPortalResponse = typeof(return);
        auto log = getLogger();

        auto request = dict(
            "appIdId", appId.appIdId,
            "teamId", team.teamId,
        );

        return sendRequest(developerPortal!("downloadTeamProvisioningProfile.action", deviceType), request).match!(
                (PlistDict dict) {
                    auto provisioningProfile = dict["provisioningProfile"].dict();
                    return DeveloperPortalResponse(
                        ProvisioningProfile(
                            provisioningProfile["provisioningProfileId"].str().native(),
                            provisioningProfile["name"].str().native(),
                            provisioningProfile["encodedProfile"].data().native(),
                        )
                    );
                },
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
        auto statusCode = response["resultCode"] ? response["resultCode"].uinteger().native() : 0;

        if (statusCode != 0) {
            return DeveloperPortalResponse!PlistDict(
                DeveloperPortalError(statusCode,
                    response["userString"] ? response["userString"].str().native :
                    response["resultString"] ? response["resultString"].str().native :
                    "(null)"
                )
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
    AppId[] appIds;
    ulong maxQuantity;
    ulong availableQuantity;
}

// props to https://github.com/iMokhles/IMPortal/blob/master/src/Helpers/Apple/AppServicesHelper.php
enum AppIdFeatures: string {
    push = "push",
    iCloud = "iCloud",
    inAppPurchase = "inAppPurchase",
    gameCenter = "gameCenter",
    // ??? = "LPLF93JG7M",
    passbook = "pass",
    interAppAudio = "IAD53UNK2F",
    vpnConfiguration = "V66P55NK2I",
    dataProtection = "dataProtection",
    associatedDomains = "SKC3T5S89Y",
    appGroup = "APG3427HIY",
    healthKit = "HK421J6T7P",
    homeKit = "homeKit",
    wirelessAccessory = "WC421J6T7P",
    cloudKitVersion = "cloudKitVersion",
}

struct AppId {
    string appIdId;
    string identifier;
    string name;
    PlistDict features;
    DateTime expirationDate;
}

struct ApplicationGroup {
    string applicationGroup;
    string name;
    string identifier;
}

struct ProvisioningProfile {
    string provisioningProfileId;
    string name;
    ubyte[] encodedProfile;
}
