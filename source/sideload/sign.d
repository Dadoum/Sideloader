module sideload.sign;

import std.algorithm;
import std.exception;
import std.format;
import file = std.file;
import std.mmfile;
import std.parallelism;
import std.path;
import std.range;
import std.string;
import std.typecons;

import slf4d;

import botan.hash.mdx_hash;
import botan.libstate.lookup;

import plist;

import cms.cms_dec;

import server.developersession;

import sideload.bundle;
import sideload.certificateidentity;
import sideload.macho;

import utils;

Tuple!(PlistDict, PlistDict) sign(
    Bundle bundle,
    CertificateIdentity identity,
    ProvisioningProfile[string] provisioningProfiles,
    void delegate(double progress) addProgress,
    bool isMultithreaded = true,
    string teamId = null,
    MDxHashFunction sha1Hasher = null,
    MDxHashFunction sha2Hasher = null,
) {
    auto log = getLogger();

    auto bundleFolder = bundle.bundleDir;
    enum fairPlayDir = "SC_Info";
    auto fairPlayFolder = bundleFolder.buildPath(fairPlayDir);
    if (file.exists(fairPlayFolder)) {
        file.rmdirRecurse(fairPlayFolder);
    }

    auto bundleId =  bundle.bundleIdentifier();

    PlistDict files = new PlistDict();
    PlistDict files2 = new PlistDict();

    static import sse2;
    sse2.register();

    if (!sha1Hasher) {
        sha1Hasher = cast(MDxHashFunction) retrieveHash("SHA-1");
    }
    if (!sha2Hasher) {
        sha2Hasher = cast(MDxHashFunction) retrieveHash("SHA-256");
    }

    auto sha1HasherParallel = taskPool().workerLocalStorage!MDxHashFunction(cast(MDxHashFunction) sha1Hasher.clone());
    auto sha2HasherParallel = taskPool().workerLocalStorage!MDxHashFunction(cast(MDxHashFunction) sha2Hasher.clone());

    auto lprojFinder = boyerMooreFinder(".lproj");

    string infoPlist = bundle.appInfo.toBin();

    auto profile = bundle.bundleIdentifier() in provisioningProfiles;
    ubyte[] profileData;
    Plist profilePlist;

    if (profile) {
        profileData = profile.encodedProfile;
        file.write(bundleFolder.buildPath("embedded.mobileprovision"), profileData);
        profilePlist = Plist.fromMemory(dataFromCMS(profileData));
        teamId = profilePlist["TeamIdentifier"].array[0].str().native();
    }

    auto subBundles = bundle.subBundles();

    size_t stepCount = subBundles.length + 2;
    const double stepSize = 1.0 / stepCount;

    void signSubBundles() {
        foreach (subBundle; maybeParallel(subBundles, isMultithreaded)) {
            auto bundleFiles = subBundle.sign(
                identity,
                provisioningProfiles,
                    (double progress) => addProgress(progress * stepSize),
                isMultithreaded,
                teamId,
                sha1HasherParallel.get(),
                sha2HasherParallel.get()
            );
            auto subBundlePath = subBundle.bundleDir;

            auto bundleFiles1 = bundleFiles[0];
            auto bundleFiles2 = bundleFiles[1];

            auto subFolder = subBundlePath.relativePath(/+ base +/ bundleFolder);

            void reroot(ref PlistDict dict, ref PlistDict subDict) {
                auto iter = subDict.iter();

                string key;
                Plist element;

                synchronized {
                    while (iter.next(element, key)) {
                        dict[subFolder.buildPath(key)] = element.copy();
                    }
                }
            }
            reroot(files, bundleFiles1);
            reroot(files2, bundleFiles2);

            void addFile(string subRelativePath) {
                ubyte[] sha1 = new ubyte[](20);
                ubyte[] sha2 = new ubyte[](32);

                auto localHasher1 = sha1HasherParallel.get();
                auto localHasher2 = sha2HasherParallel.get();

                auto hashPairs = [tuple(localHasher1, sha1), tuple(localHasher2, sha2)];

                scope MmFile memoryFile = new MmFile(subBundle.bundleDir.buildPath(subRelativePath));
                ubyte[] fileData = cast(ubyte[]) memoryFile[];

                foreach (hashCouple; maybeParallel(hashPairs, isMultithreaded)) {
                    auto localHasher = hashCouple[0];
                    auto sha = hashCouple[1];
                    sha[] = localHasher.process(fileData)[];
                }

                synchronized {
                    files[subFolder.buildPath(subRelativePath)] = sha1.pl;
                    files2[subFolder.buildPath(subRelativePath)] = dict(
                        "hash", sha1,
                        "hash2", sha2
                    );
                }
            }
            addFile("_CodeSignature".buildPath("CodeResources"));
            addFile(subBundle.appInfo["CFBundleExecutable"].str().native());
        }
    }

    typeof(task(&signSubBundles)) subBundlesTask;
    if (isMultithreaded) {
        subBundlesTask = task(&signSubBundles);
        subBundlesTask.executeInNewThread();
    }

    log.debugF!"Signing bundle %s..."(baseName(bundleFolder));

    string executable = bundle.appInfo["CFBundleExecutable"].str().native();

    string codeSignatureFolder = bundleFolder.buildPath("_CodeSignature");
    string codeResourcesFile = codeSignatureFolder.buildPath("CodeResources");

    if (file.exists(codeSignatureFolder)) {
        if (file.exists(codeResourcesFile)) {
            file.remove(codeResourcesFile);
        }
    } else {
        file.mkdir(codeSignatureFolder);
    }

    file.write(bundleFolder.buildPath("Info.plist"), infoPlist);

    log.debug_("Hashing files...");

    auto bundleFiles = file.dirEntries(bundleFolder, file.SpanMode.breadth);
    // double fileStepSize = stepSize / bundleFiles.length; TODO

    // TODO re-use the original CodeResources if it already existed.
    if (bundleFolder[$ - 1] == '/' || bundleFolder[$ - 1] == '\\') bundleFolder.length -= 1;
    foreach(idx, absolutePath; maybeParallel(bundleFiles, isMultithreaded)) {
        // scope(exit) addProgress(fileStepSize);

        string basename = baseName(absolutePath);
        string relativePath = absolutePath[bundleFolder.length + 1..$];

        enum frameworksDir = "Frameworks/";
        enum plugInsDir = "PlugIns/";

        if (
            // if it's a folder don't sign it
            !file.isFile(absolutePath)
            // if it's the executable skip it (it will be modified in the next step)
            || relativePath == executable
            // if it's a file from a framework folder, skip it as it is processed by some other thread.
            || (relativePath.startsWith(frameworksDir) && relativePath[frameworksDir.length..$].toForwardSlashes().canFind('/'))
            // if it's a file from a plugins folder, skip it as it is processed by some other thread.
            || (relativePath.startsWith(plugInsDir) && relativePath[plugInsDir.length..$].toForwardSlashes().canFind('/'))
            // if it's a fairplay file, it should not exist anymore anyway.
            || (relativePath.startsWith(fairPlayDir))
        ) {
            continue;
        }

        ubyte[] sha1 = new ubyte[](20);
        ubyte[] sha2 = new ubyte[](32);

        auto localHasher1 = sha1HasherParallel.get();
        auto localHasher2 = sha2HasherParallel.get();

        auto hashPairs = [tuple(localHasher1, sha1), tuple(localHasher2, sha2)];

        if (file.getSize(absolutePath) > 0) {
            scope MmFile memoryFile = new MmFile(absolutePath);
            ubyte[] fileData = cast(ubyte[]) memoryFile[];

            foreach (hashCouple; maybeParallel(hashPairs, isMultithreaded)) {
                auto localHasher = hashCouple[0];
                auto sha = hashCouple[1];
                sha[] = localHasher.process(fileData)[];
            }
        } else {
            foreach (hashCouple; maybeParallel(hashPairs, isMultithreaded)) {
                auto localHasher = hashCouple[0];
                auto sha = hashCouple[1];
                sha[] = localHasher.process(cast(ubyte[]) [])[];
            }
        }

        Plist hashes1 = sha1.pl;

        PlistDict hashes2 = dict(
            "hash", sha1,
            "hash2", sha2
        );

        if (lprojFinder.beFound(relativePath) != null) {
            hashes1 = dict(
                "hash", hashes1,
                "optional", true
            );

            hashes2["optional"] = true.pl;
        }

        synchronized {
            files[relativePath] = hashes1;
            files2[relativePath] = hashes2;
        }
    }
    // too lazy yet to add better progress tracking
    addProgress(stepSize);

    if (isMultithreaded) {
        subBundlesTask.yieldForce();
    }

    log.debug_("Making CodeResources...");
    string codeResources = dict(
        "files", files.copy(),
        "files2", files2.copy(),
        // Rules have been copied from zsign
        "rules", rules(),
        "rules2", rules2()
    ).toXml();
    file.write(codeResourcesFile, codeResources);

    string executablePath = bundleFolder.buildPath(executable);
    PlistDict profileEntitlements = profilePlist ? profilePlist["Entitlements"].dict : new PlistDict();

    auto fatMachOs = (executable ~ bundle.libraries()).map!((f) {
        auto path = bundleFolder.buildPath(f);
        return tuple!("path", "machO")(path, MachO.parse(cast(ubyte[]) file.read(path)));
    });

    double machOStepSize = stepSize / fatMachOs.length;

    foreach (idx, fatMachOPair; maybeParallel(fatMachOs, isMultithreaded)) {
        scope(exit) addProgress(machOStepSize);
        auto path = fatMachOPair.path;
        auto fatMachO = fatMachOPair.machO;
        log.debugF!"Signing executable %s..."(path[bundleFolder.dirName.length + 1..$]);

        auto requirementsBlob = new RequirementsBlob();

        foreach (machO; fatMachO) {
            CodeDirectoryBlob codeDir1;
            CodeDirectoryBlob codeDir2;

            PlistDict entitlements;

            if (idx == 0) {
                entitlements = profileEntitlements;
                codeDir1 = new CodeDirectoryBlob(sha1HasherParallel.get(), bundleId, teamId, machO, entitlements, infoPlist, codeResources);
                codeDir2 = new CodeDirectoryBlob(sha2HasherParallel.get(), bundleId, teamId, machO, entitlements, infoPlist, codeResources, true);
            } else {
                entitlements = new PlistDict();
                codeDir1 = new CodeDirectoryBlob(sha1HasherParallel.get(), baseName(path), teamId, machO, entitlements, null, null);
                codeDir2 = new CodeDirectoryBlob(sha2HasherParallel.get(), baseName(path), teamId, machO, entitlements, null, null, true);
            }

            auto embeddedSignature = new EmbeddedSignature();
            embeddedSignature.blobs = cast(Blob[]) [
                requirementsBlob,
                new EntitlementsBlob(entitlements.toXml())
            ];

            if (machO.filetype == MH_EXECUTE) {
                embeddedSignature.blobs ~= new DerEntitlementsBlob(entitlements);
            }

            embeddedSignature.blobs ~= cast(Blob[]) [
                codeDir1,
                codeDir2,
                new SignatureBlob(identity, [null, sha1HasherParallel.get(), sha2HasherParallel.get()])
            ];

            machO.replaceCodeSignature(new ubyte[](embeddedSignature.length()));

            auto encodedBlob = embeddedSignature.encode();
            enforce(!machO.replaceCodeSignature(encodedBlob));
        }

        file.write(path, makeMachO(fatMachO));
    }

    return tuple(files, files2);
}

Plist rules() {
    return dict(
        "^.*", true,
        "^.*\\.lproj/", dict(
            "optional", true,
            "weight", 1000.
        ),
        "^.*\\.lproj/locversion.plist$", dict(
            "omit", true,
            "weight", 1100.
        ),
        "^Base\\.lproj/", dict(
            "weight", 1010.
        ),
        "^version.plist$", true
    );
}

Plist rules2() {
    return dict(
        ".*\\.dSYM($|/)", dict(
            "weight", 11.
        ),
        "^(.*/)?\\.DS_Store$", dict(
            "omit", true,
            "weight", 2000.
        ),
        "^.*", true,
        "^.*\\.lproj/", dict(
            "optional", true,
            "weight", 1000.
        ),
        "^.*\\.lproj/locversion.plist$", dict(
            "omit", true,
            "weight", 1100.
        ),
        "^Base\\.lproj/", dict(
            "weight", 1010.
        ),
        "^Info\\.plist$", dict(
            "omit", true,
            "weight", 20.
        ),
        "^PkgInfo$", dict(
            "omit", true,
            "weight", 20.
        ),
        "^embedded\\.provisionprofile$", dict(
            "weight", 20.
        ),
        "^version\\.plist$", dict(
            "weight", 20.
        )
    );
}

class InvalidApplicationException: Exception {
    this(string message, string file = __FILE__, size_t line = __LINE__) {
        super(format!"Cannot sign the application : %s"(message));
    }
}
