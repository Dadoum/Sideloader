module frontend;

import slf4d;
import slf4d.default_provider;
import slf4d.provider;

import app.frontend;

version = X509;
shared class CLIFrontend: Frontend {
    override string configurationPath() {
        getLogger().error("Not implemented.");
        return "";
    }

    override int run(string[] args) {
        import std.algorithm;
        import std.array;
        import std.datetime;
        import std.path;
        import std.typecons;
        import file = std.file;

        import slf4d;

        import plist;

        import imobiledevice;

        import server.developersession;

        import sideload.bundle;
        import sideload.application;
        import sideload.certificateidentity;

        import main;

        auto log = getLogger();
        // auto app = new Application("~/Téléchargements/SideStore.ipa".expandTilde());
        auto app = new Application("~/Téléchargements/appux/packages/com.yourcompany.appux_0.0.1-1+debug.ipa".expandTilde());

        // create a certificate for the developer
        // auto certIdentity = new CertificateIdentity(configurationPath, null);

        auto team = DeveloperTeam("iOS devel.", "TEAMID");

        // check if we registered an app id for it (if not create it)
        string mainAppBundleId = app.bundleIdentifier();
        string mainAppIdStr = mainAppBundleId ~ "." ~ team.teamId;
        string mainAppName = app.bundleName();

        app.appId = mainAppIdStr;
        foreach (plugin; app.plugIns) {
            string pluginBundleIdentifier = plugin.bundleIdentifier();
            assertBundle(
                pluginBundleIdentifier.startsWith(mainAppBundleId) &&
                pluginBundleIdentifier.length > mainAppBundleId.length,
                "Plug-ins are not formed with the main app bundle identifier"
            );
            plugin.appId = mainAppIdStr ~ pluginBundleIdentifier[mainAppBundleId.length..$];
        }
        Bundle[] bundlesNeeded = [cast(Bundle) app] ~ app.plugIns;

        // Search which App IDs have to be registered (we don't want to start registering App IDs if we don't
        // have enough of them to register them all!! otherwise we will waste their precious App IDs)
        auto appIdsToRegister = bundlesNeeded;

        foreach (bundle; appIdsToRegister) {
            log.infoF!"Creating App ID `%s`..."(bundle.appId);
        }

        auto bundles = bundlesNeeded.map!((bundle) => tuple(bundle, AppId("", bundle.appId, "ApplicationName", null, DateTime()))).array();
        auto mainBundle = bundles[0];

        // sign the app with all the retrieved material!
        foreach (bundlePair; bundles) {
            import core.sys.darwin.mach.loader;
            import sideload.macho;

            auto bundle = bundlePair[0];
            auto appId = bundlePair[1];

            auto bundlePath = bundle.bundleDir;

            // set the bundle identifier to the one with the team id to match the provisioning profile
            bundle.appInfo["CFBundleIdentifier"] = appId.identifier.pl;

            string executablePath = bundlePath.buildPath(bundle.appInfo["CFBundleExecutable"].str().native());
            MachO[] machOs = MachO.parse(cast(ubyte[]) file.read(executablePath), Architecture.aarch64);
            log.infoF!"Mach-Os: %s"(machOs);

            import cms.cms_dec;
            auto provisioningProfilePlist = Plist.fromMemory(dataFromCMS(
                cast(ubyte[]) file.read("/home/dadoum/Téléchargements/com.SideStore.SideStore.MK7ZNLPN7B.AltWidget.mobileprovision")
            ));

            auto entitlements = provisioningProfilePlist["Entitlements"].dict;

            foreach (machO; machOs) {
                auto execSegBase = machO.execSegBase;
                auto execSegLimit = machO.execSegLimit;
                auto execFlags = machO.execFlags(entitlements);

                auto embeddedSignature = new EmbeddedSignature();
                embeddedSignature ~= cast(Blob[]) [
                    new CodeDirectoryBlob(new SHA1(), team.teamId, execSegBase, execSegLimit, execFlags),
                    new RequirementsBlob(),
                    new EntitlementsBlob(entitlements.toXml()),
                    new DerEntitlementsBlob(entitlements),
                    new CodeDirectoryBlob(new SHA2(), team.teamId, execSegBase, execSegLimit, execFlags),
                    new SignatureBlob(),
                ];
                machO.replaceCodeSignature(embeddedSignature);
            }

            file.write("/home/dadoum/Téléchargements/Salut", makeMachO(machOs));

            /*
            // fabricate entitlements file!!!
            string executablePath = bundlePath.buildPath(bundle.appInfo["CFBundleExecutable"].str().native());
            MachO[] machOs = MachO.parse(cast(ubyte[]) file.read(executablePath));

            // here is the real signing logic:
            // we will sign each of the mach-o contained
            // and rebuild them.
            foreach (machO; machOs) {
                linkedit_data_command signatureCommand = void;
                symtab_command symtabCommand = void;

                foreach (command; machO.loadCommands) {
                    switch (command.cmd) {
                        case LC_CODE_SIGNATURE:
                            signatureCommand = command.read!linkedit_data_command(0);
                            break;
                        case LC_SYMTAB:
                            symtabCommand = command.read!symtab_command(0);
                            break;
                        default:
                            break;
                    }
                }

                string entitlementsStr = "";
                if (signatureCommand.cmd) {
                    // get entitlements!!
                    SuperBlobHeader superBlob = machO.read!SuperBlobHeader(signatureCommand.dataoff);
                    auto blobArrayStart = signatureCommand.dataoff + SuperBlobHeader.sizeof;
                    auto blobArrayEnd = blobArrayStart + superBlob.count * BlobIndex.sizeof;

                    for (auto blobArrayIndex = blobArrayStart; blobArrayIndex < blobArrayEnd; blobArrayIndex += BlobIndex.sizeof) {
                        auto currentBlob = machO.read!BlobIndex(signatureCommand.dataoff + blobArrayIndex);
                        if (currentBlob.type == CSSLOT_ENTITLEMENTS) {
                            Blob entitlementsBlob = machO.read!Blob(currentBlob.offset);
                            entitlementsStr = cast(string) machO.data[signatureCommand.dataoff + currentBlob.offset + Blob.sizeof..signatureCommand.dataoff + currentBlob.offset + entitlementsBlob.length];
                            if (entitlementsStr.length) {
                                log.infoF!"Entitlements: %s"(entitlementsStr);
                            }
                        }
                    }
                }
            }

            /*
            auto entitlements = Plist.fromMemory(cast(ubyte[]) entitlementsStr).dict();
            entitlements["application-identifier"] = appId.identifier;
            entitlements["com.apple.developer.team-identifier"] = team.teamId;

            // create app groups for it if needed
            if (auto bundleAppGroups = "com.apple.security.application-groups" in entitlements) {
                if (!appId.features[AppIdFeatures.appGroup].boolean().native()) {
                    // We need to enable app groups then !
                    log.infoF!"Updating the app id %s to enable app groups."(appId.identifier);
                    appId.features = developer.updateAppId!iOS(team, appId, dict(AppIdFeatures.appGroup, true)).unwrap();
                }

                auto appGroups = developer.listApplicationGroups!iOS(team).unwrap();
                foreach (bundleAppGroup; bundleAppGroups.array()) {
                    string bundleGroupId = bundleAppGroup.str().native();
                    auto matchingAppGroups = appGroups.find!((appGroup) => appGroup.identifier == bundleGroupId).array();
                    ApplicationGroup appGroup;
                    if (matchingAppGroups.empty) {
                        log.infoF!"Creating the app group %s."(bundleGroupId);
                        appGroup = developer.addApplicationGroup!iOS(team, bundleGroupId, mainAppName).unwrap();
                    } else {
                        appGroup = matchingAppGroups[0];
                    }
                }
            }

            // Write the updated Info.plist with the new bundle identifier.
            file.write(bundlePath.buildPath("Info.plist"), bundle.appInfo.toXml());
            file.write(bundlePath.buildPath("embedded.mobileprovision"), profile.encodedProfile);
            // */
        }

        return 0;
    }
}

Frontend makeFrontend() => new CLIFrontend();
shared(LoggingProvider) makeLoggingProvider(Level rootLoggingLevel) => new shared DefaultProvider(true, rootLoggingLevel);
