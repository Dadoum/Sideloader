module windows.win32.security.credentials;

import core.sys.windows.basetyps;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;

version (Windows):
extern (Windows):

alias CRED_FLAGS = uint;
enum : uint
{
    CRED_FLAGS_PASSWORD_FOR_CERT    = 0x00000001,
    CRED_FLAGS_PROMPT_NOW           = 0x00000002,
    CRED_FLAGS_USERNAME_TARGET      = 0x00000004,
    CRED_FLAGS_OWF_CRED_BLOB        = 0x00000008,
    CRED_FLAGS_REQUIRE_CONFIRMATION = 0x00000010,
    CRED_FLAGS_WILDCARD_MATCH       = 0x00000020,
    CRED_FLAGS_VSM_PROTECTED        = 0x00000040,
    CRED_FLAGS_NGC_CERT             = 0x00000080,
    CRED_FLAGS_VALID_FLAGS          = 0x0000f0ff,
    CRED_FLAGS_VALID_INPUT_FLAGS    = 0x0000f09f,
}

alias CRED_TYPE = uint;
enum : uint
{
    CRED_TYPE_GENERIC                 = 0x00000001,
    CRED_TYPE_DOMAIN_PASSWORD         = 0x00000002,
    CRED_TYPE_DOMAIN_CERTIFICATE      = 0x00000003,
    CRED_TYPE_DOMAIN_VISIBLE_PASSWORD = 0x00000004,
    CRED_TYPE_GENERIC_CERTIFICATE     = 0x00000005,
    CRED_TYPE_DOMAIN_EXTENDED         = 0x00000006,
    CRED_TYPE_MAXIMUM                 = 0x00000007,
    CRED_TYPE_MAXIMUM_EX              = 0x000003ef,
}

alias CRED_PERSIST = uint;
enum : uint
{
    CRED_PERSIST_NONE          = 0x00000000,
    CRED_PERSIST_SESSION       = 0x00000001,
    CRED_PERSIST_LOCAL_MACHINE = 0x00000002,
    CRED_PERSIST_ENTERPRISE    = 0x00000003,
}

alias CREDUI_FLAGS = uint;
enum : uint
{
    CREDUI_FLAGS_ALWAYS_SHOW_UI              = 0x00000080,
    CREDUI_FLAGS_COMPLETE_USERNAME           = 0x00000800,
    CREDUI_FLAGS_DO_NOT_PERSIST              = 0x00000002,
    CREDUI_FLAGS_EXCLUDE_CERTIFICATES        = 0x00000008,
    CREDUI_FLAGS_EXPECT_CONFIRMATION         = 0x00020000,
    CREDUI_FLAGS_GENERIC_CREDENTIALS         = 0x00040000,
    CREDUI_FLAGS_INCORRECT_PASSWORD          = 0x00000001,
    CREDUI_FLAGS_KEEP_USERNAME               = 0x00100000,
    CREDUI_FLAGS_PASSWORD_ONLY_OK            = 0x00000200,
    CREDUI_FLAGS_PERSIST                     = 0x00001000,
    CREDUI_FLAGS_REQUEST_ADMINISTRATOR       = 0x00000004,
    CREDUI_FLAGS_REQUIRE_CERTIFICATE         = 0x00000010,
    CREDUI_FLAGS_REQUIRE_SMARTCARD           = 0x00000100,
    CREDUI_FLAGS_SERVER_CREDENTIAL           = 0x00004000,
    CREDUI_FLAGS_SHOW_SAVE_CHECK_BOX         = 0x00000040,
    CREDUI_FLAGS_USERNAME_TARGET_CREDENTIALS = 0x00080000,
    CREDUI_FLAGS_VALIDATE_USERNAME           = 0x00000400,
}

alias SCARD_SCOPE = uint;
enum : uint
{
    SCARD_SCOPE_USER   = 0x00000000,
    SCARD_SCOPE_SYSTEM = 0x00000002,
}

alias CRED_ENUMERATE_FLAGS = uint;
enum : uint
{
    CRED_ENUMERATE_ALL_CREDENTIALS = 0x00000001,
}

alias CREDUIWIN_FLAGS = uint;
enum : uint
{
    CREDUIWIN_GENERIC                = 0x00000001,
    CREDUIWIN_CHECKBOX               = 0x00000002,
    CREDUIWIN_AUTHPACKAGE_ONLY       = 0x00000010,
    CREDUIWIN_IN_CRED_ONLY           = 0x00000020,
    CREDUIWIN_ENUMERATE_ADMINS       = 0x00000100,
    CREDUIWIN_ENUMERATE_CURRENT_USER = 0x00000200,
    CREDUIWIN_SECURE_PROMPT          = 0x00001000,
    CREDUIWIN_PREPROMPTING           = 0x00002000,
    CREDUIWIN_PACK_32_WOW            = 0x10000000,
}

alias SCARD_STATE = uint;
enum : uint
{
    SCARD_STATE_UNAWARE     = 0x00000000,
    SCARD_STATE_IGNORE      = 0x00000001,
    SCARD_STATE_UNAVAILABLE = 0x00000008,
    SCARD_STATE_EMPTY       = 0x00000010,
    SCARD_STATE_PRESENT     = 0x00000020,
    SCARD_STATE_ATRMATCH    = 0x00000040,
    SCARD_STATE_EXCLUSIVE   = 0x00000080,
    SCARD_STATE_INUSE       = 0x00000100,
    SCARD_STATE_MUTE        = 0x00000200,
    SCARD_STATE_CHANGED     = 0x00000002,
    SCARD_STATE_UNKNOWN     = 0x00000004,
}

alias CRED_PACK_FLAGS = uint;
enum : uint
{
    CRED_PACK_PROTECTED_CREDENTIALS   = 0x00000001,
    CRED_PACK_WOW_BUFFER              = 0x00000002,
    CRED_PACK_GENERIC_CREDENTIALS     = 0x00000004,
    CRED_PACK_ID_PROVIDER_CREDENTIALS = 0x00000008,
}

HRESULT KeyCredentialManagerGetOperationErrorStates(KeyCredentialManagerOperationType, BOOL*, KeyCredentialManagerOperationErrorStates*);
HRESULT KeyCredentialManagerShowUIOperation(HWND, KeyCredentialManagerOperationType);
HRESULT KeyCredentialManagerGetInformation(KeyCredentialManagerInfo**);
void KeyCredentialManagerFreeInformation(KeyCredentialManagerInfo*);
BOOL CredWriteW(CREDENTIALW*, uint);
BOOL CredWriteA(CREDENTIALA*, uint);
BOOL CredReadW(const(wchar)*, CRED_TYPE, uint, CREDENTIALW**);
BOOL CredReadA(const(char)*, CRED_TYPE, uint, CREDENTIALA**);
BOOL CredEnumerateW(const(wchar)*, CRED_ENUMERATE_FLAGS, uint*, CREDENTIALW***);
BOOL CredEnumerateA(const(char)*, CRED_ENUMERATE_FLAGS, uint*, CREDENTIALA***);
BOOL CredWriteDomainCredentialsW(CREDENTIAL_TARGET_INFORMATIONW*, CREDENTIALW*, uint);
BOOL CredWriteDomainCredentialsA(CREDENTIAL_TARGET_INFORMATIONA*, CREDENTIALA*, uint);
BOOL CredReadDomainCredentialsW(CREDENTIAL_TARGET_INFORMATIONW*, uint, uint*, CREDENTIALW***);
BOOL CredReadDomainCredentialsA(CREDENTIAL_TARGET_INFORMATIONA*, uint, uint*, CREDENTIALA***);
BOOL CredDeleteW(const(wchar)*, CRED_TYPE, uint);
BOOL CredDeleteA(const(char)*, CRED_TYPE, uint);
BOOL CredRenameW(const(wchar)*, const(wchar)*, CRED_TYPE, uint);
BOOL CredRenameA(const(char)*, const(char)*, CRED_TYPE, uint);
BOOL CredGetTargetInfoW(const(wchar)*, uint, CREDENTIAL_TARGET_INFORMATIONW**);
BOOL CredGetTargetInfoA(const(char)*, uint, CREDENTIAL_TARGET_INFORMATIONA**);
BOOL CredMarshalCredentialW(CRED_MARSHAL_TYPE, void*, PWSTR*);
BOOL CredMarshalCredentialA(CRED_MARSHAL_TYPE, void*, PSTR*);
BOOL CredUnmarshalCredentialW(const(wchar)*, CRED_MARSHAL_TYPE*, void**);
BOOL CredUnmarshalCredentialA(const(char)*, CRED_MARSHAL_TYPE*, void**);
BOOL CredIsMarshaledCredentialW(const(wchar)*);
BOOL CredIsMarshaledCredentialA(const(char)*);
BOOL CredUnPackAuthenticationBufferW(CRED_PACK_FLAGS, void*, uint, PWSTR, uint*, PWSTR, uint*, PWSTR, uint*);
BOOL CredUnPackAuthenticationBufferA(CRED_PACK_FLAGS, void*, uint, PSTR, uint*, PSTR, uint*, PSTR, uint*);
BOOL CredPackAuthenticationBufferW(CRED_PACK_FLAGS, PWSTR, PWSTR, ubyte*, uint*);
BOOL CredPackAuthenticationBufferA(CRED_PACK_FLAGS, PSTR, PSTR, ubyte*, uint*);
BOOL CredProtectW(BOOL, PWSTR, uint, PWSTR, uint*, CRED_PROTECTION_TYPE*);
BOOL CredProtectA(BOOL, PSTR, uint, PSTR, uint*, CRED_PROTECTION_TYPE*);
BOOL CredUnprotectW(BOOL, PWSTR, uint, PWSTR, uint*);
BOOL CredUnprotectA(BOOL, PSTR, uint, PSTR, uint*);
BOOL CredIsProtectedW(PWSTR, CRED_PROTECTION_TYPE*);
BOOL CredIsProtectedA(PSTR, CRED_PROTECTION_TYPE*);
BOOL CredFindBestCredentialW(const(wchar)*, uint, uint, CREDENTIALW**);
BOOL CredFindBestCredentialA(const(char)*, uint, uint, CREDENTIALA**);
BOOL CredGetSessionTypes(uint, uint*);
void CredFree(void*);
uint CredUIPromptForCredentialsW(CREDUI_INFOW*, const(wchar)*, SecHandle*, uint, PWSTR, uint, PWSTR, uint, BOOL*, CREDUI_FLAGS);
uint CredUIPromptForCredentialsA(CREDUI_INFOA*, const(char)*, SecHandle*, uint, PSTR, uint, PSTR, uint, BOOL*, CREDUI_FLAGS);
uint CredUIPromptForWindowsCredentialsW(CREDUI_INFOW*, uint, uint*, const(void)*, uint, void**, uint*, BOOL*, CREDUIWIN_FLAGS);
uint CredUIPromptForWindowsCredentialsA(CREDUI_INFOA*, uint, uint*, const(void)*, uint, void**, uint*, BOOL*, CREDUIWIN_FLAGS);
uint CredUIParseUserNameW(const(wchar)*, PWSTR, uint, PWSTR, uint);
uint CredUIParseUserNameA(const(char)*, PSTR, uint, PSTR, uint);
uint CredUICmdLinePromptForCredentialsW(const(wchar)*, SecHandle*, uint, PWSTR, uint, PWSTR, uint, BOOL*, CREDUI_FLAGS);
uint CredUICmdLinePromptForCredentialsA(const(char)*, SecHandle*, uint, PSTR, uint, PSTR, uint, BOOL*, CREDUI_FLAGS);
uint CredUIConfirmCredentialsW(const(wchar)*, BOOL);
uint CredUIConfirmCredentialsA(const(char)*, BOOL);
uint CredUIStoreSSOCredW(const(wchar)*, const(wchar)*, const(wchar)*, BOOL);
uint CredUIReadSSOCredW(const(wchar)*, PWSTR*);
int SCardEstablishContext(SCARD_SCOPE, const(void)*, const(void)*, ulong*);
int SCardReleaseContext(ulong);
int SCardIsValidContext(ulong);
int SCardListReaderGroupsA(ulong, PSTR, uint*);
int SCardListReaderGroupsW(ulong, PWSTR, uint*);
int SCardListReadersA(ulong, const(char)*, PSTR, uint*);
int SCardListReadersW(ulong, const(wchar)*, PWSTR, uint*);
int SCardListCardsA(ulong, ubyte*, const(GUID)*, uint, PSTR, uint*);
int SCardListCardsW(ulong, ubyte*, const(GUID)*, uint, PWSTR, uint*);
int SCardListInterfacesA(ulong, const(char)*, GUID*, uint*);
int SCardListInterfacesW(ulong, const(wchar)*, GUID*, uint*);
int SCardGetProviderIdA(ulong, const(char)*, GUID*);
int SCardGetProviderIdW(ulong, const(wchar)*, GUID*);
int SCardGetCardTypeProviderNameA(ulong, const(char)*, uint, PSTR, uint*);
int SCardGetCardTypeProviderNameW(ulong, const(wchar)*, uint, PWSTR, uint*);
int SCardIntroduceReaderGroupA(ulong, const(char)*);
int SCardIntroduceReaderGroupW(ulong, const(wchar)*);
int SCardForgetReaderGroupA(ulong, const(char)*);
int SCardForgetReaderGroupW(ulong, const(wchar)*);
int SCardIntroduceReaderA(ulong, const(char)*, const(char)*);
int SCardIntroduceReaderW(ulong, const(wchar)*, const(wchar)*);
int SCardForgetReaderA(ulong, const(char)*);
int SCardForgetReaderW(ulong, const(wchar)*);
int SCardAddReaderToGroupA(ulong, const(char)*, const(char)*);
int SCardAddReaderToGroupW(ulong, const(wchar)*, const(wchar)*);
int SCardRemoveReaderFromGroupA(ulong, const(char)*, const(char)*);
int SCardRemoveReaderFromGroupW(ulong, const(wchar)*, const(wchar)*);
int SCardIntroduceCardTypeA(ulong, const(char)*, const(GUID)*, const(GUID)*, uint, ubyte*, ubyte*, uint);
int SCardIntroduceCardTypeW(ulong, const(wchar)*, const(GUID)*, const(GUID)*, uint, ubyte*, ubyte*, uint);
int SCardSetCardTypeProviderNameA(ulong, const(char)*, uint, const(char)*);
int SCardSetCardTypeProviderNameW(ulong, const(wchar)*, uint, const(wchar)*);
int SCardForgetCardTypeA(ulong, const(char)*);
int SCardForgetCardTypeW(ulong, const(wchar)*);
int SCardFreeMemory(ulong, const(void)*);
HANDLE SCardAccessStartedEvent();
void SCardReleaseStartedEvent();
int SCardLocateCardsA(ulong, const(char)*, SCARD_READERSTATEA*, uint);
int SCardLocateCardsW(ulong, const(wchar)*, SCARD_READERSTATEW*, uint);
int SCardLocateCardsByATRA(ulong, SCARD_ATRMASK*, uint, SCARD_READERSTATEA*, uint);
int SCardLocateCardsByATRW(ulong, SCARD_ATRMASK*, uint, SCARD_READERSTATEW*, uint);
int SCardGetStatusChangeA(ulong, uint, SCARD_READERSTATEA*, uint);
int SCardGetStatusChangeW(ulong, uint, SCARD_READERSTATEW*, uint);
int SCardCancel(ulong);
int SCardConnectA(ulong, const(char)*, uint, uint, ulong*, uint*);
int SCardConnectW(ulong, const(wchar)*, uint, uint, ulong*, uint*);
int SCardReconnect(ulong, uint, uint, uint, uint*);
int SCardDisconnect(ulong, uint);
int SCardBeginTransaction(ulong);
int SCardEndTransaction(ulong, uint);
int SCardState(ulong, uint*, uint*, ubyte*, uint*);
int SCardStatusA(ulong, PSTR, uint*, uint*, uint*, ubyte*, uint*);
int SCardStatusW(ulong, PWSTR, uint*, uint*, uint*, ubyte*, uint*);
int SCardTransmit(ulong, SCARD_IO_REQUEST*, ubyte*, uint, SCARD_IO_REQUEST*, ubyte*, uint*);
int SCardGetTransmitCount(ulong, uint*);
int SCardControl(ulong, uint, const(void)*, uint, void*, uint, uint*);
int SCardGetAttrib(ulong, uint, ubyte*, uint*);
int SCardSetAttrib(ulong, uint, ubyte*, uint);
int SCardUIDlgSelectCardA(OPENCARDNAME_EXA*);
int SCardUIDlgSelectCardW(OPENCARDNAME_EXW*);
int GetOpenCardNameA(OPENCARDNAMEA*);
int GetOpenCardNameW(OPENCARDNAMEW*);
int SCardDlgExtendedError();
int SCardReadCacheA(ulong, GUID*, uint, PSTR, ubyte*, uint*);
int SCardReadCacheW(ulong, GUID*, uint, PWSTR, ubyte*, uint*);
int SCardWriteCacheA(ulong, GUID*, uint, PSTR, ubyte*, uint);
int SCardWriteCacheW(ulong, GUID*, uint, PWSTR, ubyte*, uint);
int SCardGetReaderIconA(ulong, const(char)*, ubyte*, uint*);
int SCardGetReaderIconW(ulong, const(wchar)*, ubyte*, uint*);
int SCardGetDeviceTypeIdA(ulong, const(char)*, uint*);
int SCardGetDeviceTypeIdW(ulong, const(wchar)*, uint*);
int SCardGetReaderDeviceInstanceIdA(ulong, const(char)*, PSTR, uint*);
int SCardGetReaderDeviceInstanceIdW(ulong, const(wchar)*, PWSTR, uint*);
int SCardListReadersWithDeviceInstanceIdA(ulong, const(char)*, PSTR, uint*);
int SCardListReadersWithDeviceInstanceIdW(ulong, const(wchar)*, PWSTR, uint*);
int SCardAudit(ulong, uint);
enum CRED_MAX_CREDENTIAL_BLOB_SIZE = 0x00000a00;
enum CRED_MAX_USERNAME_LENGTH = 0x00000201;
enum CRED_MAX_DOMAIN_TARGET_NAME_LENGTH = 0x00000151;
enum FILE_DEVICE_SMARTCARD = 0x00000031;
enum GUID_DEVINTERFACE_SMARTCARD_READER = GUID(0x50dd5230, 0xba8a, 0x11d1, [0xbf, 0x5d, 0x0, 0x0, 0xf8, 0x5, 0xf5, 0x30]);
enum SCARD_ATR_LENGTH = 0x00000021;
enum SCARD_PROTOCOL_UNDEFINED = 0x00000000;
enum SCARD_PROTOCOL_T0 = 0x00000001;
enum SCARD_PROTOCOL_T1 = 0x00000002;
enum SCARD_PROTOCOL_RAW = 0x00010000;
enum SCARD_PROTOCOL_DEFAULT = 0x80000000;
enum SCARD_PROTOCOL_OPTIMAL = 0x00000000;
enum SCARD_POWER_DOWN = 0x00000000;
enum SCARD_COLD_RESET = 0x00000001;
enum SCARD_WARM_RESET = 0x00000002;
enum MAXIMUM_ATTR_STRING_LENGTH = 0x00000020;
enum MAXIMUM_SMARTCARD_READERS = 0x0000000a;
enum SCARD_CLASS_VENDOR_INFO = 0x00000001;
enum SCARD_CLASS_COMMUNICATIONS = 0x00000002;
enum SCARD_CLASS_PROTOCOL = 0x00000003;
enum SCARD_CLASS_POWER_MGMT = 0x00000004;
enum SCARD_CLASS_SECURITY = 0x00000005;
enum SCARD_CLASS_MECHANICAL = 0x00000006;
enum SCARD_CLASS_VENDOR_DEFINED = 0x00000007;
enum SCARD_CLASS_IFD_PROTOCOL = 0x00000008;
enum SCARD_CLASS_ICC_STATE = 0x00000009;
enum SCARD_CLASS_PERF = 0x00007ffe;
enum SCARD_CLASS_SYSTEM = 0x00007fff;
enum SCARD_T0_HEADER_LENGTH = 0x00000007;
enum SCARD_T0_CMD_LENGTH = 0x00000005;
enum SCARD_T1_PROLOGUE_LENGTH = 0x00000003;
enum SCARD_T1_EPILOGUE_LENGTH = 0x00000002;
enum SCARD_T1_EPILOGUE_LENGTH_LRC = 0x00000001;
enum SCARD_T1_MAX_IFS = 0x000000fe;
enum SCARD_UNKNOWN = 0x00000000;
enum SCARD_ABSENT = 0x00000001;
enum SCARD_PRESENT = 0x00000002;
enum SCARD_SWALLOWED = 0x00000003;
enum SCARD_POWERED = 0x00000004;
enum SCARD_NEGOTIABLE = 0x00000005;
enum SCARD_SPECIFIC = 0x00000006;
enum SCARD_READER_SWALLOWS = 0x00000001;
enum SCARD_READER_EJECTS = 0x00000002;
enum SCARD_READER_CONFISCATES = 0x00000004;
enum SCARD_READER_CONTACTLESS = 0x00000008;
enum SCARD_READER_TYPE_SERIAL = 0x00000001;
enum SCARD_READER_TYPE_PARALELL = 0x00000002;
enum SCARD_READER_TYPE_KEYBOARD = 0x00000004;
enum SCARD_READER_TYPE_SCSI = 0x00000008;
enum SCARD_READER_TYPE_IDE = 0x00000010;
enum SCARD_READER_TYPE_USB = 0x00000020;
enum SCARD_READER_TYPE_PCMCIA = 0x00000040;
enum SCARD_READER_TYPE_TPM = 0x00000080;
enum SCARD_READER_TYPE_NFC = 0x00000100;
enum SCARD_READER_TYPE_UICC = 0x00000200;
enum SCARD_READER_TYPE_NGC = 0x00000400;
enum SCARD_READER_TYPE_EMBEDDEDSE = 0x00000800;
enum SCARD_READER_TYPE_VENDOR = 0x000000f0;
enum STATUS_LOGON_FAILURE = 0xffffffffc000006d;
enum STATUS_WRONG_PASSWORD = 0xffffffffc000006a;
enum STATUS_PASSWORD_EXPIRED = 0xffffffffc0000071;
enum STATUS_PASSWORD_MUST_CHANGE = 0xffffffffc0000224;
enum STATUS_DOWNGRADE_DETECTED = 0xffffffffc0000388;
enum STATUS_AUTHENTICATION_FIREWALL_FAILED = 0xffffffffc0000413;
enum STATUS_ACCOUNT_DISABLED = 0xffffffffc0000072;
enum STATUS_ACCOUNT_RESTRICTION = 0xffffffffc000006e;
enum STATUS_ACCOUNT_LOCKED_OUT = 0xffffffffc0000234;
enum STATUS_ACCOUNT_EXPIRED = 0xffffffffc0000193;
enum STATUS_LOGON_TYPE_NOT_GRANTED = 0xffffffffc000015b;
enum STATUS_NO_SUCH_LOGON_SESSION = 0xffffffffc000005f;
enum STATUS_NO_SUCH_USER = 0xffffffffc0000064;
enum CRED_MAX_STRING_LENGTH = 0x00000100;
enum CRED_MAX_GENERIC_TARGET_NAME_LENGTH = 0x00007fff;
enum CRED_MAX_TARGETNAME_NAMESPACE_LENGTH = 0x00000100;
enum CRED_MAX_TARGETNAME_ATTRIBUTE_LENGTH = 0x00000100;
enum CRED_MAX_VALUE_SIZE = 0x00000100;
enum CRED_MAX_ATTRIBUTES = 0x00000040;
enum CRED_SESSION_WILDCARD_NAME_W = "*Session";
enum CRED_SESSION_WILDCARD_NAME_A = "*Session";
enum CRED_TARGETNAME_DOMAIN_NAMESPACE_W = "Domain";
enum CRED_TARGETNAME_DOMAIN_NAMESPACE_A = "Domain";
enum CRED_TARGETNAME_LEGACYGENERIC_NAMESPACE_W = "LegacyGeneric";
enum CRED_TARGETNAME_LEGACYGENERIC_NAMESPACE_A = "LegacyGeneric";
enum CRED_TARGETNAME_ATTRIBUTE_TARGET_W = "target";
enum CRED_TARGETNAME_ATTRIBUTE_TARGET_A = "target";
enum CRED_TARGETNAME_ATTRIBUTE_NAME_W = "name";
enum CRED_TARGETNAME_ATTRIBUTE_NAME_A = "name";
enum CRED_TARGETNAME_ATTRIBUTE_BATCH_W = "batch";
enum CRED_TARGETNAME_ATTRIBUTE_BATCH_A = "batch";
enum CRED_TARGETNAME_ATTRIBUTE_INTERACTIVE_W = "interactive";
enum CRED_TARGETNAME_ATTRIBUTE_INTERACTIVE_A = "interactive";
enum CRED_TARGETNAME_ATTRIBUTE_SERVICE_W = "service";
enum CRED_TARGETNAME_ATTRIBUTE_SERVICE_A = "service";
enum CRED_TARGETNAME_ATTRIBUTE_NETWORK_W = "network";
enum CRED_TARGETNAME_ATTRIBUTE_NETWORK_A = "network";
enum CRED_TARGETNAME_ATTRIBUTE_NETWORKCLEARTEXT_W = "networkcleartext";
enum CRED_TARGETNAME_ATTRIBUTE_NETWORKCLEARTEXT_A = "networkcleartext";
enum CRED_TARGETNAME_ATTRIBUTE_REMOTEINTERACTIVE_W = "remoteinteractive";
enum CRED_TARGETNAME_ATTRIBUTE_REMOTEINTERACTIVE_A = "remoteinteractive";
enum CRED_TARGETNAME_ATTRIBUTE_CACHEDINTERACTIVE_W = "cachedinteractive";
enum CRED_TARGETNAME_ATTRIBUTE_CACHEDINTERACTIVE_A = "cachedinteractive";
enum CRED_SESSION_WILDCARD_NAME = "*Session";
enum CRED_TARGETNAME_DOMAIN_NAMESPACE = "Domain";
enum CRED_TARGETNAME_ATTRIBUTE_NAME = "name";
enum CRED_TARGETNAME_ATTRIBUTE_TARGET = "target";
enum CRED_TARGETNAME_ATTRIBUTE_BATCH = "batch";
enum CRED_TARGETNAME_ATTRIBUTE_INTERACTIVE = "interactive";
enum CRED_TARGETNAME_ATTRIBUTE_SERVICE = "service";
enum CRED_TARGETNAME_ATTRIBUTE_NETWORK = "network";
enum CRED_TARGETNAME_ATTRIBUTE_NETWORKCLEARTEXT = "networkcleartext";
enum CRED_TARGETNAME_ATTRIBUTE_REMOTEINTERACTIVE = "remoteinteractive";
enum CRED_TARGETNAME_ATTRIBUTE_CACHEDINTERACTIVE = "cachedinteractive";
enum CRED_LOGON_TYPES_MASK = 0x0000f000;
enum CRED_TI_SERVER_FORMAT_UNKNOWN = 0x00000001;
enum CRED_TI_DOMAIN_FORMAT_UNKNOWN = 0x00000002;
enum CRED_TI_ONLY_PASSWORD_REQUIRED = 0x00000004;
enum CRED_TI_USERNAME_TARGET = 0x00000008;
enum CRED_TI_CREATE_EXPLICIT_CRED = 0x00000010;
enum CRED_TI_WORKGROUP_MEMBER = 0x00000020;
enum CRED_TI_DNSTREE_IS_DFS_SERVER = 0x00000040;
enum CRED_TI_VALID_FLAGS = 0x0000f07f;
enum CERT_HASH_LENGTH = 0x00000014;
enum CREDUI_MAX_MESSAGE_LENGTH = 0x00000400;
enum CREDUI_MAX_CAPTION_LENGTH = 0x00000080;
enum CREDUI_MAX_GENERIC_TARGET_LENGTH = 0x00007fff;
enum CREDUI_MAX_DOMAIN_TARGET_LENGTH = 0x00000151;
enum CREDUI_MAX_USERNAME_LENGTH = 0x00000201;
enum CREDUIWIN_IGNORE_CLOUDAUTHORITY_NAME = 0x00040000;
enum CREDUIWIN_DOWNLEVEL_HELLO_AS_SMART_CARD = 0x80000000;
enum CRED_PRESERVE_CREDENTIAL_BLOB = 0x00000001;
enum CRED_CACHE_TARGET_INFORMATION = 0x00000001;
enum CRED_ALLOW_NAME_RESOLUTION = 0x00000001;
enum CRED_PROTECT_AS_SELF = 0x00000001;
enum CRED_PROTECT_TO_SYSTEM = 0x00000002;
enum CRED_UNPROTECT_AS_SELF = 0x00000001;
enum CRED_UNPROTECT_ALLOW_TO_SYSTEM = 0x00000002;
enum SCARD_SCOPE_TERMINAL = 0x00000001;
enum SCARD_ALL_READERS = "SCard$AllReaders\000";
enum SCARD_DEFAULT_READERS = "SCard$DefaultReaders\000";
enum SCARD_LOCAL_READERS = "SCard$LocalReaders\000";
enum SCARD_SYSTEM_READERS = "SCard$SystemReaders\000";
enum SCARD_PROVIDER_PRIMARY = 0x00000001;
enum SCARD_PROVIDER_CSP = 0x00000002;
enum SCARD_PROVIDER_KSP = 0x00000003;
enum SCARD_STATE_UNPOWERED = 0x00000400;
enum SCARD_SHARE_EXCLUSIVE = 0x00000001;
enum SCARD_SHARE_SHARED = 0x00000002;
enum SCARD_SHARE_DIRECT = 0x00000003;
enum SCARD_LEAVE_CARD = 0x00000000;
enum SCARD_RESET_CARD = 0x00000001;
enum SCARD_UNPOWER_CARD = 0x00000002;
enum SCARD_EJECT_CARD = 0x00000003;
enum SC_DLG_MINIMAL_UI = 0x00000001;
enum SC_DLG_NO_UI = 0x00000002;
enum SC_DLG_FORCE_UI = 0x00000004;
enum SCERR_NOCARDNAME = 0x00004000;
enum SCERR_NOGUIDS = 0x00008000;
enum SCARD_AUDIT_CHV_FAILURE = 0x00000000;
enum SCARD_AUDIT_CHV_SUCCESS = 0x00000001;
enum CREDSSP_NAME = "CREDSSP";
enum TS_SSP_NAME_A = "TSSSP";
enum TS_SSP_NAME = "TSSSP";
enum szOID_TS_KP_TS_SERVER_AUTH = "1.3.6.1.4.1.311.54.1.2";
enum CREDSSP_SERVER_AUTH_NEGOTIATE = 0x00000001;
enum CREDSSP_SERVER_AUTH_CERTIFICATE = 0x00000002;
enum CREDSSP_SERVER_AUTH_LOOPBACK = 0x00000004;
enum SECPKG_ALT_ATTR = 0x80000000;
enum SECPKG_ATTR_C_FULL_IDENT_TOKEN = 0x80000085;
enum CREDSSP_CRED_EX_VERSION = 0x00000000;
enum CREDSSP_FLAG_REDIRECT = 0x00000001;
alias KeyCredentialManagerOperationErrorStates = int;
enum : int
{
    KeyCredentialManagerOperationErrorStateNone                 = 0x00000000,
    KeyCredentialManagerOperationErrorStateDeviceJoinFailure    = 0x00000001,
    KeyCredentialManagerOperationErrorStateTokenFailure         = 0x00000002,
    KeyCredentialManagerOperationErrorStateCertificateFailure   = 0x00000004,
    KeyCredentialManagerOperationErrorStateRemoteSessionFailure = 0x00000008,
    KeyCredentialManagerOperationErrorStatePolicyFailure        = 0x00000010,
    KeyCredentialManagerOperationErrorStateHardwareFailure      = 0x00000020,
    KeyCredentialManagerOperationErrorStatePinExistsFailure     = 0x00000040,
}

alias KeyCredentialManagerOperationType = int;
enum : int
{
    KeyCredentialManagerProvisioning = 0x00000000,
    KeyCredentialManagerPinChange    = 0x00000001,
    KeyCredentialManagerPinReset     = 0x00000002,
}

struct KeyCredentialManagerInfo
{
    GUID containerId;
}
struct SecHandle
{
    ulong dwLower;
    ulong dwUpper;
}
struct CREDENTIAL_ATTRIBUTEA
{
    PSTR Keyword;
    uint Flags;
    uint ValueSize;
    ubyte* Value;
}
struct CREDENTIAL_ATTRIBUTEW
{
    PWSTR Keyword;
    uint Flags;
    uint ValueSize;
    ubyte* Value;
}
struct CREDENTIALA
{
    CRED_FLAGS Flags;
    CRED_TYPE Type;
    PSTR TargetName;
    PSTR Comment;
    FILETIME LastWritten;
    uint CredentialBlobSize;
    ubyte* CredentialBlob;
    CRED_PERSIST Persist;
    uint AttributeCount;
    CREDENTIAL_ATTRIBUTEA* Attributes;
    PSTR TargetAlias;
    PSTR UserName;
}
struct CREDENTIALW
{
    CRED_FLAGS Flags;
    CRED_TYPE Type;
    PWSTR TargetName;
    PWSTR Comment;
    FILETIME LastWritten;
    uint CredentialBlobSize;
    ubyte* CredentialBlob;
    CRED_PERSIST Persist;
    uint AttributeCount;
    CREDENTIAL_ATTRIBUTEW* Attributes;
    PWSTR TargetAlias;
    PWSTR UserName;
}
struct CREDENTIAL_TARGET_INFORMATIONA
{
    PSTR TargetName;
    PSTR NetbiosServerName;
    PSTR DnsServerName;
    PSTR NetbiosDomainName;
    PSTR DnsDomainName;
    PSTR DnsTreeName;
    PSTR PackageName;
    uint Flags;
    uint CredTypeCount;
    uint* CredTypes;
}
struct CREDENTIAL_TARGET_INFORMATIONW
{
    PWSTR TargetName;
    PWSTR NetbiosServerName;
    PWSTR DnsServerName;
    PWSTR NetbiosDomainName;
    PWSTR DnsDomainName;
    PWSTR DnsTreeName;
    PWSTR PackageName;
    uint Flags;
    uint CredTypeCount;
    uint* CredTypes;
}
struct CERT_CREDENTIAL_INFO
{
    uint cbSize;
    ubyte[20] rgbHashOfCert;
}
struct USERNAME_TARGET_CREDENTIAL_INFO
{
    PWSTR UserName;
}
struct BINARY_BLOB_CREDENTIAL_INFO
{
    uint cbBlob;
    ubyte* pbBlob;
}
alias CRED_MARSHAL_TYPE = int;
enum : int
{
    CertCredential               = 0x00000001,
    UsernameTargetCredential     = 0x00000002,
    BinaryBlobCredential         = 0x00000003,
    UsernameForPackedCredentials = 0x00000004,
    BinaryBlobForSystem          = 0x00000005,
}

alias CRED_PROTECTION_TYPE = int;
enum : int
{
    CredUnprotected         = 0x00000000,
    CredUserProtection      = 0x00000001,
    CredTrustedProtection   = 0x00000002,
    CredForSystemProtection = 0x00000003,
}

struct CREDUI_INFOA
{
    uint cbSize;
    HWND hwndParent;
    const(char)* pszMessageText;
    const(char)* pszCaptionText;
    HBITMAP hbmBanner;
}
struct CREDUI_INFOW
{
    uint cbSize;
    HWND hwndParent;
    const(wchar)* pszMessageText;
    const(wchar)* pszCaptionText;
    HBITMAP hbmBanner;
}
struct SCARD_IO_REQUEST
{
    uint dwProtocol;
    uint cbPciLength;
}
struct SCARD_T0_COMMAND
{
    ubyte bCla;
    ubyte bIns;
    ubyte bP1;
    ubyte bP2;
    ubyte bP3;
}
struct SCARD_T0_REQUEST
{
    SCARD_IO_REQUEST ioRequest;
    ubyte bSw1;
    ubyte bSw2;
    union
    {
        SCARD_T0_COMMAND CmdBytes;
        ubyte[5] rgbHeader;
    }
}
struct SCARD_T1_REQUEST
{
    SCARD_IO_REQUEST ioRequest;
}
struct SCARD_READERSTATEA
{
    const(char)* szReader;
    void* pvUserData;
    SCARD_STATE dwCurrentState;
    SCARD_STATE dwEventState;
    uint cbAtr;
    ubyte[36] rgbAtr;
}
struct SCARD_READERSTATEW
{
    const(wchar)* szReader;
    void* pvUserData;
    SCARD_STATE dwCurrentState;
    SCARD_STATE dwEventState;
    uint cbAtr;
    ubyte[36] rgbAtr;
}
struct SCARD_ATRMASK
{
    uint cbAtr;
    ubyte[36] rgbAtr;
    ubyte[36] rgbMask;
}
alias LPOCNCONNPROCA = ulong function(ulong, PSTR, PSTR, void*);
alias LPOCNCONNPROCW = ulong function(ulong, PWSTR, PWSTR, void*);
alias LPOCNCHKPROC = BOOL function(ulong, ulong, void*);
alias LPOCNDSCPROC = void function(ulong, ulong, void*);
struct OPENCARD_SEARCH_CRITERIAA
{
    uint dwStructSize;
    PSTR lpstrGroupNames;
    uint nMaxGroupNames;
    const(GUID)* rgguidInterfaces;
    uint cguidInterfaces;
    PSTR lpstrCardNames;
    uint nMaxCardNames;
    LPOCNCHKPROC lpfnCheck;
    LPOCNCONNPROCA lpfnConnect;
    LPOCNDSCPROC lpfnDisconnect;
    void* pvUserData;
    uint dwShareMode;
    uint dwPreferredProtocols;
}
struct OPENCARD_SEARCH_CRITERIAW
{
    uint dwStructSize;
    PWSTR lpstrGroupNames;
    uint nMaxGroupNames;
    const(GUID)* rgguidInterfaces;
    uint cguidInterfaces;
    PWSTR lpstrCardNames;
    uint nMaxCardNames;
    LPOCNCHKPROC lpfnCheck;
    LPOCNCONNPROCW lpfnConnect;
    LPOCNDSCPROC lpfnDisconnect;
    void* pvUserData;
    uint dwShareMode;
    uint dwPreferredProtocols;
}
struct OPENCARDNAME_EXA
{
    uint dwStructSize;
    ulong hSCardContext;
    HWND hwndOwner;
    uint dwFlags;
    const(char)* lpstrTitle;
    const(char)* lpstrSearchDesc;
    HICON hIcon;
    OPENCARD_SEARCH_CRITERIAA* pOpenCardSearchCriteria;
    LPOCNCONNPROCA lpfnConnect;
    void* pvUserData;
    uint dwShareMode;
    uint dwPreferredProtocols;
    PSTR lpstrRdr;
    uint nMaxRdr;
    PSTR lpstrCard;
    uint nMaxCard;
    uint dwActiveProtocol;
    ulong hCardHandle;
}
struct OPENCARDNAME_EXW
{
    uint dwStructSize;
    ulong hSCardContext;
    HWND hwndOwner;
    uint dwFlags;
    const(wchar)* lpstrTitle;
    const(wchar)* lpstrSearchDesc;
    HICON hIcon;
    OPENCARD_SEARCH_CRITERIAW* pOpenCardSearchCriteria;
    LPOCNCONNPROCW lpfnConnect;
    void* pvUserData;
    uint dwShareMode;
    uint dwPreferredProtocols;
    PWSTR lpstrRdr;
    uint nMaxRdr;
    PWSTR lpstrCard;
    uint nMaxCard;
    uint dwActiveProtocol;
    ulong hCardHandle;
}
alias READER_SEL_REQUEST_MATCH_TYPE = int;
enum : int
{
    RSR_MATCH_TYPE_READER_AND_CONTAINER = 0x00000001,
    RSR_MATCH_TYPE_SERIAL_NUMBER        = 0x00000002,
    RSR_MATCH_TYPE_ALL_CARDS            = 0x00000003,
}

struct READER_SEL_REQUEST
{
    uint dwShareMode;
    uint dwPreferredProtocols;
    READER_SEL_REQUEST_MATCH_TYPE MatchType;
    union
    {
        struct _ReaderAndContainerParameter_e__Struct
        {
            uint cbReaderNameOffset;
            uint cchReaderNameLength;
            uint cbContainerNameOffset;
            uint cchContainerNameLength;
            uint dwDesiredCardModuleVersion;
            uint dwCspFlags;
        }
        struct _SerialNumberParameter_e__Struct
        {
            uint cbSerialNumberOffset;
            uint cbSerialNumberLength;
            uint dwDesiredCardModuleVersion;
        }
    }
}
struct READER_SEL_RESPONSE
{
    uint cbReaderNameOffset;
    uint cchReaderNameLength;
    uint cbCardNameOffset;
    uint cchCardNameLength;
}
struct OPENCARDNAMEA
{
    uint dwStructSize;
    HWND hwndOwner;
    ulong hSCardContext;
    PSTR lpstrGroupNames;
    uint nMaxGroupNames;
    PSTR lpstrCardNames;
    uint nMaxCardNames;
    const(GUID)* rgguidInterfaces;
    uint cguidInterfaces;
    PSTR lpstrRdr;
    uint nMaxRdr;
    PSTR lpstrCard;
    uint nMaxCard;
    const(char)* lpstrTitle;
    uint dwFlags;
    void* pvUserData;
    uint dwShareMode;
    uint dwPreferredProtocols;
    uint dwActiveProtocol;
    LPOCNCONNPROCA lpfnConnect;
    LPOCNCHKPROC lpfnCheck;
    LPOCNDSCPROC lpfnDisconnect;
    ulong hCardHandle;
}
struct OPENCARDNAMEW
{
    uint dwStructSize;
    HWND hwndOwner;
    ulong hSCardContext;
    PWSTR lpstrGroupNames;
    uint nMaxGroupNames;
    PWSTR lpstrCardNames;
    uint nMaxCardNames;
    const(GUID)* rgguidInterfaces;
    uint cguidInterfaces;
    PWSTR lpstrRdr;
    uint nMaxRdr;
    PWSTR lpstrCard;
    uint nMaxCard;
    const(wchar)* lpstrTitle;
    uint dwFlags;
    void* pvUserData;
    uint dwShareMode;
    uint dwPreferredProtocols;
    uint dwActiveProtocol;
    LPOCNCONNPROCW lpfnConnect;
    LPOCNCHKPROC lpfnCheck;
    LPOCNDSCPROC lpfnDisconnect;
    ulong hCardHandle;
}
struct SecPkgContext_ClientCreds
{
    uint AuthBufferLen;
    ubyte* AuthBuffer;
}
alias CREDSPP_SUBMIT_TYPE = int;
enum : int
{
    CredsspPasswordCreds       = 0x00000002,
    CredsspSchannelCreds       = 0x00000004,
    CredsspCertificateCreds    = 0x0000000d,
    CredsspSubmitBufferBoth    = 0x00000032,
    CredsspSubmitBufferBothOld = 0x00000033,
    CredsspCredEx              = 0x00000064,
}

struct CREDSSP_CRED
{
    CREDSPP_SUBMIT_TYPE Type;
    void* pSchannelCred;
    void* pSpnegoCred;
}
struct CREDSSP_CRED_EX
{
    CREDSPP_SUBMIT_TYPE Type;
    uint Version;
    uint Flags;
    uint Reserved;
    CREDSSP_CRED Cred;
}
