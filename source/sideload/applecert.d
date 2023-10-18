module sideload.applecert;

enum ubyte[] appleWWDRG3 = cast(ubyte[]) import("AppleWWDRCAG3.cer");
enum ubyte[] appleRoot = cast(ubyte[]) import("AppleIncRootCertificate.cer");
