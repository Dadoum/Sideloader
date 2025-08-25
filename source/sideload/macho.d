module sideload.macho;

public import core.sys.darwin.mach.loader;
public import core.sys.darwin.mach.nlist;

import core.bitop;
import core.stdc.config;
import core.stdc.stdint;

import std.algorithm;
import std.algorithm.iteration;
import std.bitmanip; alias readBE = std.bitmanip.bigEndianToNative;
import std.datetime;
import std.datetime.systime;
import std.exception;
import std.format;
import std.parallelism;
import std.range;
import std.traits;
import std.typecons;

import botan.asn1.asn1_obj;
import botan.asn1.asn1_str;
import botan.asn1.asn1_time;
import botan.asn1.der_enc;
import botan.asn1.oids;
import botan.cert.x509.x509_obj;
import botan.cert.x509.x509cert;
import botan.hash.mdx_hash;
import botan.hash.sha160;
import botan.hash.sha2_32;
import botan.math.bigint.bigint;
import botan.pubkey.pubkey;

import memutils.vector;

import plist;

import sideload.applecert;
import sideload.certificateidentity;

version (BigEndian) {
    static assert(false, "Big endian systems are not supported");
}

/// Will only parse little-endian on little-endian
/// I have code which is more versatile, but since it's useless (almost everything is little-endian now),
/// and is way more complex I won't put it here for now.
class MachO {
    size_t headersize;
    int cputype;
    int cpusubtype;
    uint ncmds;
    uint sizeofcmds;
    uint filetype;

    load_command*[] commands;
    ubyte[] data;

    uint64_t execSegBase;
    uint64_t execSegLimit;
    load_command* linkeditCommand;

    uint64_t execFlags(PlistDict entitlements) {
        return computeEntitlementsExecSegFlags(entitlements) | (filetype == MH_EXECUTE ? CS_EXECSEG_MAIN_BINARY : 0);
    }

    private this(ubyte[] data, size_t headersize, int cputype, int cpusubtype, uint ncmds, uint sizeofcmds, uint filetype) {
        this.headersize = headersize;
        this.cputype = cputype;
        this.cpusubtype = cpusubtype;
        this.ncmds = ncmds;
        this.sizeofcmds = sizeofcmds;
        this.data = data;
        this.filetype = filetype;

        size_t loc = headersize;
        linkedit_data_command* codeSigCmd;
        for (int i = 0; i < ncmds; i++) {
            auto command = cast(load_command*) data[loc..$].ptr;
            loc += command.cmdsize;

            if (command.cmd == LC_SEGMENT_64) {
                segment_command_64* segmentCmd = cast(segment_command_64*) command;

                if (segmentCmd.segname[0..6] == "__TEXT") {
                    execSegBase = segmentCmd.fileoff;
                    execSegLimit = segmentCmd.fileoff + segmentCmd.filesize;
                } else if (segmentCmd.segname[0..10] == "__LINKEDIT") {
                    linkeditCommand = command;
                }
            } else if (command.cmd == LC_SEGMENT) {
                segment_command* segmentCmd = cast(segment_command*) command;

                if (segmentCmd.segname[0..6] == "__TEXT") {
                    execSegBase = segmentCmd.fileoff;
                    execSegLimit = segmentCmd.fileoff + segmentCmd.filesize;
                } else if (segmentCmd.segname[0..10] == "__LINKEDIT") {
                    linkeditCommand = command;
                }
            }

            commands ~= command;
        }
    }

    static MachO[] parse(ubyte[] data, Architecture arch = Architecture.all) {
        uint magic = *cast(uint*) data[0..4].ptr;
        if (magic == FAT_CIGAM) {
            auto fatFileHeader = cast(fat_header*) data[0..fat_header.sizeof].ptr;
            auto fatArchs = data[fat_header.sizeof..fat_header.sizeof + fatFileHeader.nfat_arch.bigEndianToNative() * fat_arch.sizeof]
                .chunks(fat_arch.sizeof)
                .map!((fatArch) => cast(fat_arch*) fatArch.ptr);
            MachO[] machOs = [];
            foreach (fatArch; fatArchs) {
                MachO[] machO = parse(data[fatArch.offset.bigEndianToNative()..fatArch.offset.bigEndianToNative() + fatArch.size.bigEndianToNative()]);
                if (arch == machO[0].cputype) {
                    return machO;
                } else if (arch == Architecture.all) {
                    machOs ~= machO;
                }
            }

            if (arch != Architecture.all) {
                throw new InvalidMachOException(format!"The executable does not contain the right architecture (%s wanted)"(arch));
            }

            return machOs;
        } else if (magic == MH_MAGIC_64) {
            auto header = *cast(mach_header_64*) data.ptr;
            if (arch != Architecture.all && header.cputype != arch) {
                throw new InvalidMachOException(format!"The executable is not in the right architecture (%s wanted, but got %s)"(arch, cast(Architecture) header.cputype));
            }

            return [new MachO(data, mach_header_64.sizeof, header.cputype, header.cpusubtype, header.ncmds, header.sizeofcmds, header.filetype)];
        } else if (magic == MH_MAGIC) {
            auto header = *cast(mach_header*) data.ptr;
            if (arch != Architecture.all && header.cputype != arch) {
                throw new InvalidMachOException(format!"The executable is not in the right architecture (%s wanted, but got %s)"(arch, cast(Architecture) header.cputype));
            }

            return [new MachO(data, mach_header.sizeof, header.cputype, header.cpusubtype, header.ncmds, header.sizeofcmds, header.filetype)];
        }
        throw new InvalidMachOException(format!"magic: %x"(magic));
    }

    size_t codeSignatureOffset() {
        linkedit_data_command* codeSigCmd;
        foreach (command; commands) {
            if (command.cmd == LC_CODE_SIGNATURE) {
                codeSigCmd = cast(linkedit_data_command*) command;
                break;
            }
        }

        if (!codeSigCmd) {
            return data.length;
        }

        return codeSigCmd.dataoff;
    }


    /// Returns whether the segment had to be extended
    bool replaceCodeSignature(EmbeddedSignature signature) {
        auto sig = signature.encode();
        return replaceCodeSignature(sig);
    }

    /// ditto
    bool replaceCodeSignature(ubyte[] sig) {
        size_t sectionSize = pageCeil(sig.length);

        linkedit_data_command* codeSigCmd;
        foreach (command; commands) {
            if (command.cmd == LC_CODE_SIGNATURE) {
                codeSigCmd = cast(linkedit_data_command*) command;
                break;
            }
        }

        if (!codeSigCmd) {
            auto endCommandsLocation = headersize + sizeofcmds;

            // If adding a linkedit_data_command doesn't cross the page boundary.
            if ((pageFloor(endCommandsLocation + linkedit_data_command.sizeof)) > endCommandsLocation) {
                throw new SegmentAllocationFailedException();
            }

            codeSigCmd = cast(linkedit_data_command*) data[endCommandsLocation..$].ptr;
            commands ~= cast(load_command*) codeSigCmd;

            codeSigCmd.cmd = LC_CODE_SIGNATURE;
            codeSigCmd.cmdsize = linkedit_data_command.sizeof;
            codeSigCmd.dataoff = cast(uint) data.length;
            codeSigCmd.datasize = 0;

            sizeofcmds += linkedit_data_command.sizeof;
            ncmds += 1;
        }

        if (sig.length <= codeSigCmd.datasize) {
            // We can re-use the space.
            data[codeSigCmd.dataoff..codeSigCmd.dataoff + sig.length] = sig;
            data[codeSigCmd.dataoff + sig.length..codeSigCmd.dataoff + codeSigCmd.datasize] = 0;
            return false;
        }

        // The section should be at the end of the file.
        enforce (codeSigCmd.dataoff + codeSigCmd.datasize >= data.length);
        data = data[0..codeSigCmd.dataoff];

        size_t extraVmSize = sectionSize - pageFloor(codeSigCmd.datasize);
        size_t extraFileSize = sig.length - codeSigCmd.datasize;

        if (linkeditCommand.cmd == LC_SEGMENT_64) {
            // 64-bit
            auto linkedit = cast(segment_command_64*) linkeditCommand;
            linkedit.filesize += extraFileSize;
            linkedit.vmsize += extraVmSize;
        } else {
            auto linkedit = cast(segment_command*) linkeditCommand;
            linkedit.filesize += extraFileSize;
            linkedit.vmsize += extraVmSize;
        }

        codeSigCmd.dataoff = cast(uint) data.length;
        codeSigCmd.datasize = cast(uint) sig.length;

        data ~= sig;
        updateHeader();

        return true;
    }

    void updateHeader() {
        if (cputype & CPU_ARCH_ABI64) {
            auto header = cast(mach_header_64*) data.ptr;
            header.cputype = cputype;
            header.cpusubtype = cpusubtype;
            header.ncmds = ncmds;
            header.sizeofcmds = sizeofcmds;
            header.filetype = filetype;
        } else {
            auto header = cast(mach_header*) data.ptr;
            header.cputype = cputype;
            header.cpusubtype = cpusubtype;
            header.ncmds = ncmds;
            header.sizeofcmds = sizeofcmds;
            header.filetype = filetype;
        }
    }
}

// credits: rcodesign
enum CS_EXECSEG_MAIN_BINARY = 0x1;
enum CS_EXECSEG_ALLOW_UNSIGNED = 0x10;
enum CS_EXECSEG_DEBUGGER = 0x20;
enum CS_EXECSEG_JIT = 0x40;
enum CS_EXECSEG_SKIP_LV = 0x80;
enum CS_EXECSEG_CAN_LOAD_CDHASH = 0x100;
enum CS_EXECSEG_CAN_EXEC_CDHASH = 0x200;

uint64_t computeEntitlementsExecSegFlags(PlistDict entitlements) {
    uint64_t flags = 0;
    if (auto entitlement = "get-task-allow" in entitlements) {
        if (entitlement.boolean().native()) {
            flags |= CS_EXECSEG_ALLOW_UNSIGNED;
        }
    }
    if (auto entitlement = "run-unsigned-code" in entitlements) {
        if (entitlement.boolean().native()) {
            flags |= CS_EXECSEG_ALLOW_UNSIGNED;
        }
    }

    if (auto entitlement = "com.apple.private.cs.debugger" in entitlements) {
        if (entitlement.boolean().native()) {
            flags |= CS_EXECSEG_DEBUGGER;
        }
    }

    if (auto entitlement = "dynamic-codesigning" in entitlements) {
        if (entitlement.boolean().native()) {
            flags |= CS_EXECSEG_JIT;
        }
    }

    if (auto entitlement = "com.apple.private.skip-library-validation" in entitlements) {
        if (entitlement.boolean().native()) {
            flags |= CS_EXECSEG_SKIP_LV;
        }
    }

    if (auto entitlement = "com.apple.private.amfi.can-load-cdhash" in entitlements) {
        if (entitlement.boolean().native()) {
            flags |= CS_EXECSEG_CAN_LOAD_CDHASH;
        }
    }

    if (auto entitlement = "com.apple.private.amfi.can-execute-cdhash" in entitlements) {
        if (entitlement.boolean().native()) {
            flags |= CS_EXECSEG_CAN_EXEC_CDHASH;
        }
    }

    return flags;
}

enum Architecture {
    all = 0,
    armv7 = CPU_TYPE_ARM,
    aarch64 = CPU_TYPE_ARM64,
    x86_64 = CPU_TYPE_X86_64
}

ubyte[] makeMachO(MachO[] machOs) {
    auto nMachOs = machOs.length;
    if (nMachOs == 1) {
        auto machO = machOs[0];
        if (machO.cputype & CPU_ARCH_ABI64) {
            auto header = cast(mach_header_64*) machO.data.ptr;
            header.cputype = machO.cputype;
            header.cpusubtype = machO.cpusubtype;
            header.ncmds = machO.ncmds;
            header.sizeofcmds = machO.sizeofcmds;
            header.filetype = machO.filetype;
        } else {
            auto header = cast(mach_header*) machO.data.ptr;
            header.cputype = machO.cputype;
            header.cpusubtype = machO.cpusubtype;
            header.ncmds = machO.ncmds;
            header.sizeofcmds = machO.sizeofcmds;
            header.filetype = machO.filetype;
        }
        return machO.data;
    } else if (nMachOs == 0) {
        return [];
    } else {
        // build a fat mach-o file.
        ubyte[] fatMachO = (cast(ubyte*) new fat_header(
                (cast(uint32_t) FAT_MAGIC),
                (cast(uint32_t) nMachOs)
        ).nativeToBigEndian())[0..fat_header.sizeof];
        ubyte[] machOData;

        uint dataOffset = pageCeil(cast(uint) (fat_header.sizeof + nMachOs * fat_arch.sizeof));

        foreach (ref index, machO; machOs) {
            fatMachO ~= (cast(ubyte*) new fat_arch(
                machO.cputype,
                machO.cpusubtype,
                dataOffset,
                cast(uint32_t) machO.data.length,
                PAGE_SIZE_LOG2
            ).nativeToBigEndian())[0..fat_arch.sizeof];
            dataOffset += pageCeil(machO.data.length);
            machOData ~= machO.data;
            auto alignment = new ubyte[](pageCeil(machOData.length) - machOData.length);
            alignment[] = 0;
            machOData ~= alignment;
        }

        auto alignment = new ubyte[](pageCeil(fatMachO.length) - fatMachO.length);
        alignment[] = 0;
        return fatMachO ~ alignment ~ machOData;
    }
}

enum PAGE_SIZE_LOG2 = 14;
enum PAGE_SIZE = 1 << PAGE_SIZE_LOG2;

enum uint CSSLOT_CODEDIRECTORY = 0;
enum uint CSSLOT_REQUIREMENTS = 2;
enum uint CSSLOT_ENTITLEMENTS = 5;
enum uint CSSLOT_DER_ENTITLEMENTS = 7;
enum uint CSSLOT_ALTERNATE_CODEDIRECTORIES = 0x1000;
enum uint CSSLOT_SIGNATURESLOT = 0x10000;

enum uint CSMAGIC_BLOBWRAPPER = 0xfade0b01;
enum uint CSMAGIC_REQUIREMENT = 0xfade0c00;
enum uint CSMAGIC_REQUIREMENTS = 0xfade0c01;
enum uint CSMAGIC_CODEDIRECTORY = 0xfade0c02;
enum uint CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0;
enum uint CSMAGIC_EMBEDDED_SIGNATURE_OLD = 0xfade0b02;
enum uint CSMAGIC_EMBEDDED_ENTITLEMENTS = 0xfade7171;
enum uint CSMAGIC_EMBEDDED_DER_ENTITLEMENTS = 0xfade7172;

interface Blob {
    uint type();
    uint length();
    ubyte[] encode(ubyte[][] previousEncodedBlobs);
}

class RawBlob: Blob {
    uint _type;
    ubyte[] _data;

    this(uint type, ubyte[] data) {
        _type = type;
        _data = data[0..std.bitmanip.bigEndianToNative!uint(data[4..8])];
    }

    uint type() => _type;
    uint length() => cast(uint) _data.length;

    ubyte[] encode(ubyte[][] previousEncodedBlobs) {
        return _data;
    }
}

enum CODEDIRECTORY_VERSION = 0x20400;

class CodeDirectoryBlob: Blob {
    uint type() => isAlternate ? CSSLOT_ALTERNATE_CODEDIRECTORIES : CSSLOT_CODEDIRECTORY;

    enum PAGE_SIZE_CODEDIRECTORY_LOG2 = 12;
    enum PAGE_SIZE_CODEDIRECTORY = 1 << PAGE_SIZE_CODEDIRECTORY_LOG2;

    MDxHashFunction hashFunction;
    string bundleId;
    string teamId;

    MachO machO;
    PlistDict entitlements;

    string infoPlist;
    string codeResources;

    bool isAlternate;

    this(
        MDxHashFunction hash,
        string bundleIdentifier,
        string teamIdentifier,
        MachO machO,
        PlistDict entitlements,
        string infoPlist,
        string codeResources,
        bool isAlternate = false
    ) {
        hashFunction = hash;
        bundleId = bundleIdentifier;
        teamId = teamIdentifier;

        this.machO = machO;
        this.entitlements = entitlements;

        this.infoPlist = infoPlist;
        this.codeResources = codeResources;

        this.isAlternate = isAlternate;
    }

    struct CS_CodeDirectory {
        uint32_t magic;					/* magic number (CSMAGIC_CODEDIRECTORY) */
        uint32_t length;				/* total length of CodeDirectory blob */
        uint32_t version_;				/* compatibility version */
        uint32_t flags;					/* setup and mode flags */
        uint32_t hashOffset;			/* offset of hash slot element at index zero */
        uint32_t identOffset;			/* offset of identifier string */
        uint32_t nSpecialSlots;			/* number of special hash slots */
        uint32_t nCodeSlots;			/* number of ordinary (code) hash slots */
        uint32_t codeLimit;				/* limit to main image signature range */
        uint8_t hashSize;				/* size of each hash in bytes */
        uint8_t hashType;				/* type of hash (cdHashType* constants) */
        uint8_t platform;				/* platform identifier; zero if not platform binary */
        uint8_t	pageSize;				/* log2(page size in bytes); 0 => infinite */
        uint32_t spare2;				/* unused (must be zero) */
        //char end_earliest[0];

        /* Version 0x20100 */
        uint32_t scatterOffset;			/* offset of optional scatter vector */
        //char end_withScatter[0];

        /* Version 0x20200 */
        uint32_t teamOffset;			/* offset of optional team identifier */
        //char end_withTeam[0];

        /* Version 0x20300 */
        uint32_t spare3;				/* unused (must be zero) */
        uint64_t codeLimit64;			/* limit to main image signature range, 64 bits */
        //char end_withCodeLimit64[0];

        /* Version 0x20400 */
        uint64_t execSegBase;			/* offset of executable segment */
        uint64_t execSegLimit;			/* limit of executable segment */
        uint64_t execSegFlags;			/* executable segment flags */
        //char end_withExecSeg[0];

        /* Version 0x20500 */
        // uint32_t runtime;
        // uint32_t preEncryptOffset;
        //char end_withPreEncryptOffset[0];

        /* Version 0x20600, currently unsupported */
        // uint8_t linkageHashType;
        // uint8_t linkageTruncated;
        // uint16_t spare4;
        // uint32_t linkageOffset;
        // uint32_t linkageSize;
        //char end_withLinkage[0];

        /* followed by dynamic content flagsas located by offset fields above */
    }

    uint length() {
        auto hashOutputLength = hashFunction.outputLength();
        auto codeLimit = machO.codeSignatureOffset();

        return cast(uint) (
            CS_CodeDirectory.sizeof +
            bundleId.length + 1 +
            teamId.length + 1 +
            ((machO.filetype == MH_EXECUTE ? 2 : 0) + 5 + (codeLimit / 4096 + !!(codeLimit % 4096))) * hashOutputLength
        );
    }

    // HACK
    static CodeDirectoryBlob decode(const ubyte[] data) {
        CS_CodeDirectory codeDirectory = *(cast(CS_CodeDirectory*) data.dup.ptr).bigEndianToNative();
        enforce(codeDirectory.magic == CSMAGIC_CODEDIRECTORY, "Not a valid code directory!");

        // MDxHashFunction hash;
        // if (codeDirectory.hash == 1) {
        //     hash = cast(MDxHashFunction) retrieveHash("SHA-1");
        // } else if (codeDirectory.hash == 2) {
        //     hash = cast(MDxHashFunction) retrieveHash("SHA-256");
        // } else {
        //     enforce(false, "Unknown hash function.");
        // }
        import std.string;
        import std.stdio;
        string s = cast(string) data[codeDirectory.identOffset..codeDirectory.identOffset + 5];
        return new CodeDirectoryBlob(
            hash: null,
            bundleIdentifier: (cast(immutable(char)*) (data.ptr + codeDirectory.identOffset)).fromStringz(),
            teamIdentifier: (cast(immutable(char)*) (data.ptr + codeDirectory.teamOffset)).fromStringz(),
            machO: null,
            entitlements: null,
            infoPlist: null,
            codeResources: null,
            isAlternate: false,
        );
    }

    ubyte[] encode(ubyte[][] previousEncodedBlobs) {
        auto execSegBase = machO.execSegBase;
        auto execSegLimit = machO.execSegLimit;
        auto execFlags = machO.execFlags(entitlements);

        auto getTaskAllow = "get-task-allow" in entitlements;
        if (getTaskAllow && getTaskAllow.boolean().native()) {
            execFlags |= CS_EXECSEG_ALLOW_UNSIGNED;
        }

        auto codeLimit = machO.codeSignatureOffset();
        auto codeSlots = machO.data[0..codeLimit].chunks(4096).array();

        auto isExecute = machO.filetype == MH_EXECUTE;

        ubyte[] requirementsData;
        ubyte[] entitlementsData;
        ubyte[] derEntitlementsData;

        foreach (blob; previousEncodedBlobs) {
            uint magic = (cast(ubyte[4]) blob[0..4]).readBE!uint();
            if (magic == CSMAGIC_REQUIREMENTS) {
                requirementsData = blob;
                continue;
            }
            if (magic == CSMAGIC_EMBEDDED_ENTITLEMENTS) {
                entitlementsData = blob;
                continue;
            }
            if (magic == CSMAGIC_EMBEDDED_DER_ENTITLEMENTS) {
                derEntitlementsData = blob;
                continue;
            }
        }

        enforce(requirementsData, "Requirements have not been computed before CodeDir!");
        enforce(entitlementsData, "Entitlements have not been computed before CodeDir!");

        auto hashOutputLength = cast(ubyte) hashFunction.outputLength();

        auto codeDir = new CS_CodeDirectory(
            /+ magic +/ CSMAGIC_CODEDIRECTORY,
            /+ length +/ CS_CodeDirectory.sizeof,
            /+ version_ +/ CODEDIRECTORY_VERSION,
            /+ flags +/ 0,
            /+ hashOffset +/ CS_CodeDirectory.sizeof,
            /+ identOffset +/ CS_CodeDirectory.sizeof,
            /+ nSpecialSlots +/ 0,
            /+ nCodeSlots +/ 0,
            /+ codeLimit +/ codeLimit <= uint32_t.max ? cast(uint) codeLimit : 0,
            /+ hashSize +/ hashOutputLength,
            /+ hashType +/ hashFunction.hashType(),
            /+ platform +/ 0,
            /+ pageSize +/ PAGE_SIZE_CODEDIRECTORY_LOG2,
            /+ spare2 +/ 0,

            /+ scatterOffset +/ 0, // we don't use scatter

            /+ teamOffset +/ CS_CodeDirectory.sizeof, // we will set teamId

            /+ spare3 +/ 0,
            /+ codeLimit64 +/ codeLimit > uint32_t.max ? codeLimit : 0,

            /+ execSegBase +/ execSegBase,
            /+ execSegLimit +/ execSegLimit,
            /+ execSegFlags +/ execFlags,
        );

        ubyte[] body = [];

        codeDir.identOffset += body.length;
        body ~= bundleId ~ '\0';

        codeDir.teamOffset += body.length;
        body ~= teamId ~ '\0';

        // zsign copy tbh
        ubyte[][] specialSlots;

        auto emptyHash = new ubyte[](hashOutputLength);

        if (isExecute) {
            enforce(derEntitlementsData, "DerEntitlements have not been computed before CodeDir!");
            specialSlots ~= hashFunction.process(derEntitlementsData)[].dup;
            specialSlots ~= emptyHash;
        }
        specialSlots ~= hashFunction.process(entitlementsData)[].dup;
        specialSlots ~= emptyHash;
        specialSlots ~= codeResources ? hashFunction.process(codeResources)[].dup : emptyHash;
        specialSlots ~= hashFunction.process(requirementsData)[].dup;
        specialSlots ~= infoPlist ? hashFunction.process(infoPlist)[].dup : emptyHash;

        codeDir.nSpecialSlots = cast(uint) specialSlots.length;
        body ~= specialSlots[].join();

        codeDir.hashOffset += cast(uint) body.length;
        codeDir.nCodeSlots = cast(uint) codeSlots.length;

        ubyte[] slots = new ubyte[](codeSlots.length * hashOutputLength);

        auto hashFunctionLocal = taskPool().workerLocalStorage!MDxHashFunction(cast(MDxHashFunction) hashFunction.clone());

        foreach (idx, slot; parallel(codeSlots)) {
            auto index = idx * hashOutputLength;
            slots[index..index + hashOutputLength] = hashFunctionLocal.get().process(slot)[];
        }

        body ~= slots;

        codeDir.length += body.length;
        return (cast(ubyte*) codeDir.nativeToBigEndian())[0..CS_CodeDirectory.sizeof] ~ body;
    }
}

T* bigEndianToNative(T)(return T* struc) if (is(T == struct)) {
    static foreach (field; __traits(allMembers, T)) {
        __traits(getMember, struc, field) = bigEndianToNative(__traits(getMember, struc, field));
    }
    return struc;
}

class Requirement: Blob {
    uint type() => CSMAGIC_REQUIREMENT;
    uint length() => 0;

    ubyte[] encode(ubyte[][] previousEncodedBlobs) {
        return [];
    }
}

enum RequirementType: uint {
    host = 1,
    guest = 2,
    designated = 3,
    library = 4,
    plugin = 5,
}

// from rcodesign
class RequirementsBlob: Blob {
    uint type() => CSSLOT_REQUIREMENTS;

    uint length() => 4 + 4 + 4;

    // Empty requirements set,
    ubyte[] encode(ubyte[][] previousEncodedBlobs) => std.bitmanip.nativeToBigEndian(CSMAGIC_REQUIREMENTS)
    ~ std.bitmanip.nativeToBigEndian(length)
    ~ std.bitmanip.nativeToBigEndian(0);

    // Unfinished implementation of a real requirement set
    // Requirement[] requirements;
    //
    // ubyte[] encode(ubyte[][] previousEncodedBlobs) {
    //     ubyte[] data = std.bitmanip.nativeToBigEndian(cast(uint) requirements.length)
    //         ~ std.bitmanip.nativeToBigEndian(0x3)
    //         ~ std.bitmanip.nativeToBigEndian(0x14);
    //
    //     return std.bitmanip.nativeToBigEndian(CSMAGIC_REQUIREMENTS)
    //         ~ std.bitmanip.nativeToBigEndian(4 + 4 + data.length);
    // }
}

class EntitlementsBlob: Blob {
    string entitlements;

    this(string xmlEntitlements) {
        this.entitlements = xmlEntitlements;
    }

    uint type() => CSSLOT_ENTITLEMENTS;

    uint length() => 4 + 4 + cast(uint) entitlements.length;

    // magic + length (sizeof(magic) + sizeof(length) + length of the entitlements string) + entitlements string
    ubyte[] encode(ubyte[][] previousEncodedBlobs) => std.bitmanip.nativeToBigEndian(CSMAGIC_EMBEDDED_ENTITLEMENTS)
    ~ std.bitmanip.nativeToBigEndian(length)
    ~ cast(ubyte[]) entitlements;
}

class DerEntitlementsBlob: Blob {
    ubyte[] entitlementsDer;

    this(PlistDict entitlements) {
        auto encoder = DEREncoder();
        entitlementsDer = encodeEntitlements(entitlements, encoder).getContents()[].dup;
    }

    ref DEREncoder encodeEntitlements(Plist elem, return ref DEREncoder encoder) {
        if (PlistBoolean val = cast(PlistBoolean) elem) {
            encoder.encode(val.native());
        } else if (PlistUint val = cast(PlistUint) elem) {
            encoder.encode(cast(size_t) val);
        } else if (PlistString val = cast(PlistString) elem) {
            encoder.encode(ASN1String(val.native(), ASN1Tag.UTF8_STRING));
        } else if (PlistArray val = cast(PlistArray) elem) {
            encoder.startCons(ASN1Tag.SEQUENCE, ASN1Tag.CONSTRUCTED);
            auto iterator = val.iter();
            Plist child;
            while (iterator.next(child)) {
                encodeEntitlements(child, encoder);
            }

            encoder.endCons();
        } else if (PlistDict val = cast(PlistDict) elem) {
            encoder.startCons(ASN1Tag.SET, ASN1Tag.CONSTRUCTED);
            auto iterator = val.iter();

            Plist child;
            string key;
            while (iterator.next(child, key)) {
                encoder.startCons(ASN1Tag.SEQUENCE, ASN1Tag.CONSTRUCTED);
                encoder.encode(ASN1String(key, ASN1Tag.UTF8_STRING));
                encodeEntitlements(child, encoder);
                encoder.endCons();
            }

            encoder.endCons();
        } else {
            throw new UnsupportedEntitlementsException();
        }

        return encoder;
    }

    uint type() => CSSLOT_DER_ENTITLEMENTS;
    uint length() => 4 + 4 + cast(uint) entitlementsDer.length;

    ubyte[] encode(ubyte[][] previousEncodedBlobs) {
        return std.bitmanip.nativeToBigEndian(CSMAGIC_EMBEDDED_DER_ENTITLEMENTS)
        ~ std.bitmanip.nativeToBigEndian(length)
        ~ entitlementsDer;
    }
}

class DebugBlob: Blob {
    uint _type;
    ubyte[] _data;

    this(uint type, ubyte[] data) {
        _type = type;
        _data = data;
    }

    uint type() => _type;
    uint length() => cast(uint) _data.length;

    ubyte[] encode(ubyte[][] previousEncodedBlobs) => _data;
}

class SignatureBlob: Blob {
    uint type() => CSSLOT_SIGNATURESLOT;

    ubyte[] codeDirectory1;
    ubyte[] codeDirectory2;

    CertificateIdentity identity;

    MDxHashFunction[] hashers;

    this(CertificateIdentity identity, MDxHashFunction[] hashers) {
        this.identity = identity;

        this.hashers = hashers;
    }

    ref DEREncoder encodeBlob(return ref DEREncoder der, ubyte[][] codeDirectories) {
        // made to match as closely as possible zsign
        OIDS.setDefaults();

        auto rng = identity.rng;
        PKSigner signer = PKSigner(identity.privateKey, "EMSA3(SHA-256)");

        X509Certificate appleWWDRCert = X509Certificate(Vector!ubyte(appleWWDRG3));
        X509Certificate appleRootCA = X509Certificate(Vector!ubyte(appleRoot));

        enforce(identity.certificate, "Certificate is null!!");

        ubyte codeDirHashType(ubyte[] codeDir) pure {
            return (cast(CodeDirectoryBlob.CS_CodeDirectory*) codeDir.ptr).hashType;
        }

        auto signedAttrs = DEREncoder()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OIDS.lookup("PKCS9.ContentType"))
                    .startCons(ASN1Tag.SET)
                        .encode(OIDS.lookup("CMS.DataContent"))
                    .endCons()
                .endCons()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OID("1.2.840.113549.1.9.5")) // SigningTime
                    .startCons(ASN1Tag.SET)
                        .encode(X509Time(Clock.currTime(UTC())))
                    .endCons()
                .endCons()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OIDS.lookup("PKCS9.MessageDigest"))
                    .startCons(ASN1Tag.SET)
                        .encode(hashers[2].process(codeDirectories[0]), ASN1Tag.OCTET_STRING)
                    .endCons()
                .endCons()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OID("1.2.840.113635.100.9.2"))
                    .startCons(ASN1Tag.SET)
                        .startCons(ASN1Tag.SEQUENCE)
                            .encode(OIDS.lookup("SHA-256"))
                            // Don't ask me why I wrote that as is, I just want it to not crash...
                            .encode(hashers[2].process(codeDirectories.filter!((dir) => codeDirHashType(dir) == 2).array()[0]), ASN1Tag.OCTET_STRING)
                        .endCons()
                    .endCons()
                .endCons()
                // Attribute
                .startCons(ASN1Tag.SEQUENCE)
                    .encode(OID("1.2.840.113635.100.9.1"))
                    .startCons(ASN1Tag.SET)
                        .encode(
                            Vector!ubyte(
                                dict(
                                    "cdhashes", codeDirectories.map!(
                                        (codeDir) => hashers[codeDirHashType(codeDir)].process(codeDir)[0..20].dup.pl
                                    ).array().pl
                                ).toXml()[0..$-1]
                            ),
                            ASN1Tag.OCTET_STRING
                        )
                    .endCons()
                .endCons().getContents();

        auto attrToSign = DEREncoder()
            .startCons(ASN1Tag.SET)
                .rawBytes(signedAttrs)
            .endCons()
            .getContents();

        der
            .startCons(ASN1Tag.SEQUENCE).encode(OIDS.lookup("CMS.SignedData"))
                .startCons(ASN1Tag.UNIVERSAL, ASN1Tag.PRIVATE)
                    // SignedData
                    .startCons(ASN1Tag.SEQUENCE)
                        // CMSVersion
                        .encode(size_t(1))
                        // Digest algorithms
                        .startCons(ASN1Tag.SET)
                            // DigestAlgorithmIdentifier
                            .startCons(ASN1Tag.SEQUENCE)
                                .encode(OIDS.lookup("SHA-256"))
                            .endCons()
                        .endCons()
                        // Encapsulated Content Info
                        .startCons(ASN1Tag.SEQUENCE)
                            .encode(OIDS.lookup("CMS.DataContent"))
                        .endCons()
                        // CertificateList OPTIONAL tagged 0x01
                        .startCons(cast(ASN1Tag) 0x0, ASN1Tag.CONTEXT_SPECIFIC)
                            .encode(appleWWDRCert)
                            .encode(appleRootCA)
                            .encode(identity.certificate)
                        .endCons()
                        // SignerInfos
                        .startCons(ASN1Tag.SET)
                            .startCons(ASN1Tag.SEQUENCE)
                                // CMSVersion
                                .encode(size_t(1))
                                // IssuerAndSerialNumber ::= SignerIdentifier
                                .startCons(ASN1Tag.SEQUENCE)
                                    // Name
                                    .rawBytes(identity.certificate.rawIssuerDn())
                                    // Serial number
                                    .encode(BigInt.decode(identity.certificate.serialNumber()))
                                .endCons()
                                // DigestAlgorithmIdentifier
                                .startCons(ASN1Tag.SEQUENCE)
                                    // Serial number
                                    .encode(OIDS.lookup("SHA-256"))
                                .endCons()
                                // SignedAttributes
                                .startCons(cast(ASN1Tag) 0x0, ASN1Tag.CONTEXT_SPECIFIC)
                                    .rawBytes(signedAttrs)
                                .endCons()
                                // SignatureAlgorithmIdentifier
                                .encode(AlgorithmIdentifier("RSA", false))
                                // SignatureValue
                                .encode(signer.signMessage(attrToSign, rng), ASN1Tag.OCTET_STRING)
                            .endCons()
                        .endCons()
                    .endCons()
                .endCons()
            .endCons();
        return der;
    }

    uint length() => 5000;

    ubyte[] encode(ubyte[][] previousEncodedBlobs) {
        auto codeDirectories = previousEncodedBlobs
            .filter!((data) => cast(int) data.read!uint() == CSMAGIC_CODEDIRECTORY)
            .array();

        auto encoder = DEREncoder();

        auto signatureBlob = encodeBlob(encoder, codeDirectories).getContents()[].dup;

        return (
            std.bitmanip.nativeToBigEndian(CSMAGIC_BLOBWRAPPER)
            ~ std.bitmanip.nativeToBigEndian(4 + 4 + cast(uint) signatureBlob.length)
            ~ signatureBlob
        ).padRight(ubyte(0), length()).array();
    }
}

class EmbeddedSignature {
    Blob[] blobs;

    enum uint CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0;

    private struct SuperBlob {
        uint magic;
        uint length;
        uint count;
    }

    private struct BlobIndex {
        uint type;
        uint offset;
    }

    uint length() {
        return cast(uint) (
            SuperBlob.sizeof +
            BlobIndex.sizeof * blobs.length +
            blobs.map!((b) => b.length).sum()
        );
    }

    static EmbeddedSignature decode(ubyte[] data) {
        SuperBlob superBlob = *(cast(SuperBlob*) data.ptr).bigEndianToNative!SuperBlob();
        size_t end = SuperBlob.sizeof + BlobIndex.sizeof * superBlob.count;
        BlobIndex[] blobIndexes = (cast(BlobIndex[]) data[SuperBlob.sizeof..end]);
        Blob[] blobs = new Blob[](superBlob.count);
        foreach (index, ref blobIndex; blobIndexes) {
            bigEndianToNative!BlobIndex(&blobIndex);
            blobs[index] = new RawBlob(blobIndex.type, data[blobIndex.offset..$]);
        }
        EmbeddedSignature embeddedSignature = new EmbeddedSignature();
        embeddedSignature.blobs = blobs;
        return embeddedSignature;
    }

    ubyte[] encode() {
        uint offset = cast(uint) (SuperBlob.sizeof + blobs.length * BlobIndex.sizeof);

        ubyte[][] blobsData;
        BlobIndex[] blobIndexes = new BlobIndex[blobs.length];

        size_t codeDirIndex = -1;

        foreach (index, blob; blobs) {
            auto blobData = blob.encode(blobsData);
            auto announcedLength = blob.length();
            auto realLength = blobData.length;
            enforce(announcedLength == realLength, format!"%s is lying on its size!!! (announced %d but gave %d)"(blob, announcedLength, realLength));
            blobsData ~= blobData;

            if (codeDirIndex == -1 && blob.type() == CSSLOT_CODEDIRECTORY) {
                codeDirIndex = index;
            }
        }

        if (codeDirIndex != -1) {
            blobs.swapAt(0, codeDirIndex);
            blobsData.swapAt(0, codeDirIndex);
        }

        foreach (index, blobData; blobsData) {
            blobIndexes[index] = BlobIndex(blobs[index].type.nativeToBigEndian(), offset.nativeToBigEndian());
            offset += blobData.length;
        }

        auto data = blobsData.join;

        return
            (cast(ubyte*) new SuperBlob(
                CSMAGIC_EMBEDDED_SIGNATURE,
                cast(uint) (SuperBlob.sizeof + blobs.length * BlobIndex.sizeof + data.length),
                cast(uint) blobs.length
        ).nativeToBigEndian())[0..SuperBlob.sizeof] ~
            (cast(ubyte[]) blobIndexes) ~
            data;
    }
}

ubyte hashType(MDxHashFunction hashFunction) {
    if (cast(SHA160) hashFunction) {
        return 1;
    } else if (cast(SHA256) hashFunction) {
        return 2;
    }
    throw new UnknownHashFunction();
}

T bigEndianToNative(T)(T val) if (isIntegral!T) {
    version (LittleEndian) {
        return swapEndian(val);
    } else {
        return val;
    }
}

pragma(inline, true)
T pageCeil(T)(T val) {
    return (val + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
}

pragma(inline, true)
T pageFloor(T)(T val) {
    return (val) & ~(PAGE_SIZE - 1);
}

alias nativeToBigEndian = bigEndianToNative;

enum CPU_ARCH_ABI64 = 0x1000000;
enum CPU_TYPE_X86 = 7; // 0x00000111
enum CPU_TYPE_I386 = CPU_TYPE_X86; // For compatibility
enum CPU_TYPE_X86_64 = CPU_TYPE_X86 | CPU_ARCH_ABI64;
enum CPU_TYPE_ARM = 12;
enum CPU_TYPE_ARM64 = CPU_TYPE_ARM | CPU_ARCH_ABI64;
enum CPU_TYPE_POWERPC = 18;
enum CPU_TYPE_POWERPC64 = CPU_TYPE_POWERPC | CPU_ARCH_ABI64;

enum FAT_MAGIC = 0xcafebabe;
enum FAT_CIGAM = bswap(FAT_MAGIC);

alias cpu_type_t = int32_t;
alias cpu_subtype_t = int32_t;

struct fat_header {
    uint32_t magic;
    uint32_t nfat_arch;
}

struct fat_arch {
    cpu_type_t cputype;
    cpu_subtype_t cpusubtype;
    uint32_t offset;
    uint32_t size;
    uint32_t align_;
}

class UnknownHashFunction: Exception {
    this(string filename = __FILE__, size_t line = __LINE__) {
        super("An unknown hash function has been provided", filename, line);
    }
}

class UnsupportedEntitlementsException: Exception {
    this(string filename = __FILE__, size_t line = __LINE__) {
        super("The entitlements contains unsupported tags", filename, line);
    }
}

class SegmentAllocationFailedException: Exception {
    this(string filename = __FILE__, size_t line = __LINE__) {
        super("Cannot allocate a code signature segment in the binary", filename, line);
    }
}

class InvalidMachOException: Exception {
    this(string issue, string filename = __FILE__, size_t line = __LINE__) {
        super(format!"The executable cannot be loaded: %s"(issue), filename, line);
    }
}
