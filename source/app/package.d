module app;

import file = std.file;
import std.math;
import std.path;
import std.zip;

import slf4d;

import requests;

import provision;

import constants;

struct ProvisioningData {
    Device device;
    ADI adi;
}

bool downloadAndInstallDeps(string configurationPath, bool delegate(float progress) downloadCallback) {
    auto log = getLogger();

    log.info("Downloading APK...");
    Request request = Request();
    request.sslSetVerifyPeer(false);
    request.useStreaming = true;

    auto response = request.get(nativesUrl);
    auto responseStream = response.receiveAsRange();

    auto size = cast(float) response.contentLength;
    size = size ? size : 150_000_000.0 /+ Rough estimate if we don't know the exact size. +/;

    ubyte[] apkData;
    while(!responseStream.empty) {
        if (downloadCallback(cast(float) response.contentReceived / size))
            return false;
        apkData ~= responseStream.front;
        responseStream.popFront();
    }
    downloadCallback(1.);

    auto apk = new ZipArchive(apkData);
    auto dir = apk.directory();

    string libPath = configurationPath.buildPath("lib");
    if (!file.exists(libPath)) {
        file.mkdir(libPath);
    }

    version (X86_64) {
        enum string architectureIdentifier = "x86_64";
    } else version (X86) {
        enum string architectureIdentifier = "x86";
    } else version (AArch64) {
        enum string architectureIdentifier = "arm64-v8a";
    } else version (ARM) {
        enum string architectureIdentifier = "armeabi-v7a";
    } else {
        static assert(false, "Architecture not supported :(");
    }
    file.write(libPath.buildPath("libCoreADI.so"), apk.expand(dir["lib/" ~ architectureIdentifier ~ "/libCoreADI.so"]));
    file.write(libPath.buildPath("libstoreservicescore.so"), apk.expand(dir["lib/" ~ architectureIdentifier ~ "/libstoreservicescore.so"]));
    log.info("Extracted successfully!");
    return true;
}

ProvisioningData initializeADI(string configurationPath) {
    auto log = getLogger();
    auto device = new Device(configurationPath.buildPath("device.json"));

    if (!device.initialized) {
        log.info("Creating device...");

        import std.digest;
        import std.random;
        import std.range;
        import std.uni;
        import std.uuid;
        device.serverFriendlyDescription = "<MacBookPro13,2> <macOS;13.1;22C65> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>";
        device.uniqueDeviceIdentifier = randomUUID().toString().toUpper();
        device.adiIdentifier = (cast(ubyte[]) rndGen.take(2).array()).toHexString().toLower();
        device.localUserUUID = (cast(ubyte[]) rndGen.take(8).array()).toHexString().toUpper();
        log.info("Device created successfully.");
    }
    log.debug_("Device OK.");

    auto adi = new ADI(configurationPath.buildPath("lib"));
    adi.provisioningPath = configurationPath;
    adi.identifier = device.adiIdentifier;

    if (!adi.isMachineProvisioned(-2)) {
        log.info("Provisioning device...");

        ProvisioningSession provisioningSession = new ProvisioningSession(adi, device);
        provisioningSession.provision(-2);
        log.info("Device provisioned successfully.");
    }
    log.debug_("Provisioning OK.");

    return ProvisioningData(device, adi);
}
