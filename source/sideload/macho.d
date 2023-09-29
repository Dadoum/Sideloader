module sideload.macho;

public import core.sys.darwin.mach.loader;
public import core.sys.darwin.mach.nlist;

import core.bitop;
import core.stdc.config;
import core.stdc.stdint;

import std.algorithm;
import std.algorithm.iteration;
import std.bitmanip;
import std.format;
import std.range;
import std.traits;

import botan.asn1.asn1_obj;
import botan.asn1.asn1_str;
import botan.asn1.der_enc;
import botan.hash.mdx_hash;
import botan.hash.sha160;
import botan.hash.sha2_32;

import memutils.vector;

import plist;

version (BigEndian) {
    static assert(false, "Big endian systems are not supported");
}

/// Will only parse little-endian on little-endian
/// I have code which is more versatile, but since it's useless (almost everything is little-endian now),
/// and is way more complex I won't put it here for now.
class MachO {
    int cputype;
    int cpusubtype;
    uint ncmds;
    uint sizeofcmds;
    uint filetype;

    load_command*[] commands;
    ubyte[] data;

    uint64_t execSegBase;
    uint64_t execSegLimit;

    uint64_t execFlags(PlistDict entitlements) {
        return computeEntitlementsExecSegFlags(entitlements) | (filetype == MH_EXECUTE ? CS_EXECSEG_MAIN_BINARY : 0);
    }

    private this(ubyte[] data, size_t headersize, int cputype, int cpusubtype, uint ncmds, uint sizeofcmds, uint filetype) {
        this.cputype = cputype;
        this.cpusubtype = cpusubtype;
        this.ncmds = ncmds;
        this.sizeofcmds = sizeofcmds;
        this.data = data;
        this.filetype = filetype;

        size_t loc = headersize;
        for (int i = 0; i < ncmds; i++) {
            auto command = cast(load_command*) data[loc..$].ptr;
            loc += command.cmdsize;

            if (command.cmd == LC_SEGMENT_64) { // 32-bit support?
                segment_command_64* segmentCmd = cast(segment_command_64*) command;

                if (segmentCmd.segname[0..6] == "__TEXT") {
                    execSegBase = segmentCmd.fileoff;
                    execSegLimit = segmentCmd.fileoff + segmentCmd.filesize;
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

    void replaceCodeSignature(EmbeddedSignature signature) {
        auto sig = signature.encode();
        linkedit_data_command* codeSigCmd;
        foreach (command; commands) {
            if (command.cmd == LC_CODE_SIGNATURE) {
                codeSigCmd = cast(linkedit_data_command*) command;
                break;
            }
        }

        if (!codeSigCmd) {
            throw new NeverSignedException();
        }

        if (sig.length < codeSigCmd.datasize) {
            // We can re-use the space.
            data[codeSigCmd.dataoff..codeSigCmd.dataoff + sig.length] = sig;
            data[codeSigCmd.dataoff + sig.length..codeSigCmd.dataoff + codeSigCmd.datasize] = 0;
            return;
        }

        if (codeSigCmd.dataoff + codeSigCmd.datasize == data.length) {
            // If the segment is at the end of the file, we can remove it without messing alignment
            data = data[0..$ - codeSigCmd.datasize];
        } else {
            // We will zero it and add new segment at the end.
            data[codeSigCmd.dataoff..codeSigCmd.dataoff + codeSigCmd.datasize] = 0;
        }

        codeSigCmd.dataoff = cast(uint) data.length;
        codeSigCmd.datasize = cast(uint) sig.length;
        data ~= sig;
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
        return machOs[0].data;
    } else if (nMachOs == 0) {
        return [];
    } else {
        // build a fat mach-o file.
        ubyte[] fatMachO = (cast(ubyte*) new fat_header(
            (cast(uint32_t) FAT_MAGIC).nativeToBigEndian(),
            (cast(uint32_t) nMachOs).nativeToBigEndian()
        ))[0..fat_header.sizeof];
        ubyte[] machOData;

        uint dataOffset = cast(uint) (fat_header.sizeof + nMachOs * fat_arch.sizeof);

        foreach (ref index, machO; machOs) {
            fatMachO ~= (cast(ubyte*) new fat_arch(
                machO.cputype.nativeToBigEndian(),
                machO.cpusubtype.nativeToBigEndian(),
                dataOffset.nativeToBigEndian(),
                (cast(uint32_t) machO.data.length).nativeToBigEndian(),
                PAGE_SIZE_LOG2.nativeToBigEndian()
            ))[0..fat_arch.sizeof];
            dataOffset += machO.data.length;
            machOData ~= machO.data;
        }

        return fatMachO ~ machOData;
    }
}

enum PAGE_SIZE_LOG2 = 14;

enum uint CSSLOT_CODEDIRECTORY = 0;
enum uint CSSLOT_REQUIREMENTS = 2;
enum uint CSSLOT_ENTITLEMENTS = 5;
enum uint CSSLOT_DER_ENTITLEMENTS = 7;
enum uint CSSLOT_ALTERNATE_CODEDIRECTORIES = 0x1000;
enum uint CSSLOT_SIGNATURESLOT = 0x10000;

enum uint CSMAGIC_BLOBWRAPPER = 0xfade0b01;
enum uint CSMAGIC_REQUIREMENTS = 0xfade0c01;
enum uint CSMAGIC_CODEDIRECTORY = 0xfade0c02;
enum uint CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0;
enum uint CSMAGIC_EMBEDDED_SIGNATURE_OLD = 0xfade0b02;
enum uint CSMAGIC_EMBEDDED_ENTITLEMENTS = 0xfade7171;
enum uint CSMAGIC_EMBEDDED_DER_ENTITLEMENTS = 0xfade7172;

interface Blob {
    uint type();
    ubyte[] encode();
}

enum CODEDIRECTORY_VERSION = 0x20400;

class CodeDirectoryBlob: Blob {
    uint type() => CSSLOT_CODEDIRECTORY;

    MDxHashFunction hashFunction;
    string teamId;
    uint64_t execSegBase;
    uint64_t execSegLimit;
    uint64_t execSegFlags;

    this(MDxHashFunction hash, string teamIdentifier, uint64_t execSegBase, uint64_t execSegLimit, uint64_t execSegFlags) {
        hashFunction = hash;
        teamId = teamIdentifier;
        this.execSegBase = execSegBase;
        this.execSegLimit = execSegLimit;
        this.execSegFlags = execSegFlags;
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

        /* followed by dynamic content flagsas located by offset fields above */
    }

    ubyte[] encode() {
        auto codeDir = new CS_CodeDirectory(
            CSMAGIC_CODEDIRECTORY,
            CS_CodeDirectory.sizeof + 0,
            CODEDIRECTORY_VERSION,
            0,
            0,
            0,
            0,
            0,
            0,
            cast(ubyte) hashFunction.hashBlockSize(),
            typeid(hashFunction) == typeid(SHA1) ? 1 : 2,
            0,
            PAGE_SIZE_LOG2,
            0,

            0, // we don't use scatter

            CS_CodeDirectory.sizeof, // we will set teamId

            0,
            0,

            execSegBase,
            execSegLimit,
            execSegFlags,
        );
        ubyte[] body = [];

        codeDir.teamOffset += body.length;
        body ~= cast(ubyte[]) teamId ~ '\0';

        codeDir.length = cast(uint) (codeDir.sizeof + body.length);
        return (cast(ubyte*) codeDir.nativeToBigEndian())[0..CS_CodeDirectory.sizeof];
    }
}

T* nativeToBigEndian(T)(return T* struc) if (is(T == struct)) {
    static foreach (field; __traits(allMembers, T)) {
        __traits(getMember, struc, field) = nativeToBigEndian(__traits(getMember, struc, field));
    }
    return struc;
}

public alias SHA1 = SHA160;
public alias SHA2 = SHA256;

class RequirementsBlob: Blob {
    uint type() => CSSLOT_REQUIREMENTS;

    ubyte[] encode() => std.bitmanip.nativeToBigEndian(CSMAGIC_REQUIREMENTS) ~ std.bitmanip.nativeToBigEndian(12) ~ std.bitmanip.nativeToBigEndian(0);
}

class EntitlementsBlob: Blob {
    string entitlements;

    this(string xmlEntitlements) {
        this.entitlements = xmlEntitlements;
    }

    uint type() => CSSLOT_ENTITLEMENTS;
    // magic + length (sizeof(magic) + sizeof(length) + length of the entitlements string) + entitlements string
    ubyte[] encode() => std.bitmanip.nativeToBigEndian(CSMAGIC_EMBEDDED_ENTITLEMENTS)
        ~ std.bitmanip.nativeToBigEndian(4 + 4 + cast(uint) entitlements.length)
        ~ cast(ubyte[]) entitlements;
}

class DerEntitlementsBlob: Blob {
    PlistDict entitlements;

    this(PlistDict entitlements) {
        this.entitlements = entitlements;
    }

    ref DEREncoder encodeEntitlements(Plist elem, return ref DEREncoder encoder) {
        if (PlistBoolean val = cast(PlistBoolean) elem) {
            encoder.encode(val.native());
        } else if (PlistUint val = cast(PlistUint) elem) {
            encoder.encode(val.native());
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
    ubyte[] encode() {
        auto encoder = DEREncoder();

        auto entitlementsDer = encodeEntitlements(entitlements, encoder).getContents()[].dup;

        return std.bitmanip.nativeToBigEndian(CSMAGIC_EMBEDDED_DER_ENTITLEMENTS)
        ~ std.bitmanip.nativeToBigEndian(4 + 4 + cast(uint) entitlementsDer.length)
        ~ entitlementsDer;
    }
}

class SignatureBlob: Blob {
    uint type() => CSSLOT_SIGNATURESLOT;
    ubyte[] encode() => std.bitmanip.nativeToBigEndian(CSMAGIC_BLOBWRAPPER)
    ~ std.bitmanip.nativeToBigEndian(4 + 4);
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

    void opOpAssign(string op: "~")(Blob rhs) { blobs ~= rhs; }
    void opOpAssign(string op: "~")(Blob[] rhs) { blobs ~= rhs; }

    ubyte[] encode() {
        uint offset = cast(uint) (SuperBlob.sizeof + blobs.length * BlobIndex.sizeof);

        ubyte[] blobsData;
        BlobIndex[] blobIndexes = new BlobIndex[blobs.length];

        foreach (index, blob; blobs) {
            auto blobData = blob.encode();
            blobIndexes[index] = BlobIndex(blob.type.nativeToBigEndian(), offset.nativeToBigEndian());
            blobsData ~= blobData;
            offset += blobData.length;
        }

        return
            (cast(ubyte*) new SuperBlob(
                CSMAGIC_EMBEDDED_SIGNATURE.nativeToBigEndian(),
                (cast(uint) (SuperBlob.sizeof + blobs.length * BlobIndex.sizeof + blobsData.length)).nativeToBigEndian(),
                (cast(uint) blobs.length).nativeToBigEndian()
            ))[0..SuperBlob.sizeof] ~
            (cast(ubyte[]) blobIndexes) ~
            blobsData;
    }
}

T bigEndianToNative(T)(T val) if (isIntegral!T) {
    version (LittleEndian) {
        return swapEndian(val);
    } else {
        return val;
    }
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

class UnsupportedEntitlementsException: Exception {
    this(string filename = __FILE__, size_t line = __LINE__) {
        super("The entitlements contains unsupported tags", filename, line);
    }
}

class NeverSignedException: Exception {
    this(string filename = __FILE__, size_t line = __LINE__) {
        super("The executable has never been signed before (cannot find any code signature command in the executable)", filename, line);
    }
}

class InvalidMachOException: Exception {
    this(string issue, string filename = __FILE__, size_t line = __LINE__) {
        super(format!"The executable cannot be loaded: %s"(issue), filename, line);
    }
}
