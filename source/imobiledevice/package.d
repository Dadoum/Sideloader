module imobiledevice;

public import imobiledevice.afc;
public import imobiledevice.house_arrest;
public import imobiledevice.installation_proxy;
public import imobiledevice.libimobiledevice;
public import imobiledevice.lockdown;
public import imobiledevice.misagent;

import core.memory;

import std.array;
import std.algorithm.iteration;
import std.format;
import std.string;
import std.traits;

import plist;
import plist.c;

class iMobileDeviceException(T): Exception {
    T underlyingError;

    this(T error, string file = __FILE__, int line = __LINE__) {
        super(format!"error %s"(error), file, line);
        underlyingError = error;
    }
}

void assertSuccess(T)(T err) {
    if (err != 0)
        throw new iMobileDeviceException!T(err);
}

enum iDeviceEventType
{
    add = 1,
    remove = 2,
    paired = 3
}

enum iDeviceConnectionType
{
    usbmuxd = 1,
    network = 2
}

struct iDeviceEvent {
    iDeviceEventType event; /**< The event type. */
    string udid; /**< The device unique id. */
    iDeviceConnectionType connType; /**< The connection type. */
}

struct iDeviceInfo {
    string udid;
    iDeviceConnectionType connType;
}

public class iDevice {
    alias iDeviceEventCallback = void delegate(ref const(iDeviceEvent) event);

    idevice_t handle;

    public static void subscribeEvent(iDeviceEventCallback callback) {
        struct UserData {
            iDeviceEventCallback callback;
        }

        extern(C) void func(const(idevice_event_t)* event, void* user_data) {
            auto del = cast(UserData*) user_data;
            iDeviceEvent eventD = {
                event: cast(iDeviceEventType) event.event,
                udid: cast(string) event.udid.fromStringz(),
                connType: cast(iDeviceConnectionType) event.conn_type,
            };
            del.callback(eventD);
        }

        auto userData = new UserData(callback);
        GC.addRoot(userData);
        idevice_event_subscribe(&func, userData).assertSuccess();
    }

    public static @property iDeviceInfo[] deviceList() {
        int len;
        idevice_info_t* names;
        auto res = idevice_get_device_list_extended(&names, &len);
        if (res == idevice_error_t.IDEVICE_E_NO_DEVICE) {
            return [];
        }
        res.assertSuccess();
        return names[0..len].map!((s) => iDeviceInfo(cast(string) s.udid.fromStringz, cast(iDeviceConnectionType) s.conn_type)).array;
    }

    public @property string udid() {
        char* udid;
        handle.idevice_get_udid(&udid).assertSuccess();
        return cast(string) udid.fromStringz();
    }

    public this(string udid) {
        idevice_new_with_options(&handle, udid.toStringz, idevice_options.IDEVICE_LOOKUP_USBMUX | idevice_options.IDEVICE_LOOKUP_NETWORK).assertSuccess();
    }

    ~this() {
        if (handle) { // it could have been partially initialized
            idevice_free(handle).assertSuccess();
        }
    }
}

public class LockdowndClient {
    lockdownd_client_t handle;

    public this(iDevice device, string serviceName) {
        lockdownd_client_new_with_handshake(device.handle, &handle, cast(const(char)*) serviceName.toStringz).assertSuccess();
    }

    public @property string deviceName() {
        char* name;
        lockdownd_get_device_name(handle, &name).assertSuccess();
        return cast(string) name.fromStringz;
    }

    public LockdowndServiceDescriptor startService(string identifier) {
        lockdownd_service_descriptor_t descriptor;
        lockdownd_start_service(handle, identifier.toStringz, &descriptor).assertSuccess();
        return new LockdowndServiceDescriptor(descriptor);
    }

    public string startSession(string hostId) {
        char* sessionId;
        lockdownd_start_session(handle, hostId.toStringz(), &sessionId, null).assertSuccess();
        return cast(string) sessionId.fromStringz();
    }

    public void stopSession(string sessionId) {
        lockdownd_stop_session(handle, sessionId.toStringz()).assertSuccess();
    }

    public Plist opIndexAssign(Plist value, string domain, string key) {
        if (!value.owns) {
            value = value.copy();
        }
        lockdownd_set_value(handle, domain.toStringz(), key.toStringz(), value.handle).assertSuccess();
        value.owns = false;
        return value;
    }

    public Plist opIndex(string domain, string key) {
        plist_t ret;
        lockdownd_get_value(handle, domain ? domain.toStringz() : null, key ? key.toStringz() : null, &ret).assertSuccess();
        return Plist.wrap(ret);
    }

    public lockdownd_error_t pair() {
        return lockdownd_pair(handle, null); // note: the error is expected within the normal execution flow, so no throw
    }

    ~this() {
        if (handle) { // it may be null if an exception has been thrown TODO: switch from a constructor to a static function to fix that.
            lockdownd_client_free(handle).assertSuccess();
        }
    }
}

public class LockdowndServiceDescriptor {
    lockdownd_service_descriptor_t handle;
    alias handle this;

    this(lockdownd_service_descriptor_t handle) {
        this.handle = handle;
    }

    ~this() {
        lockdownd_service_descriptor_free(handle).assertSuccess();
    }
}

public class InstallationProxyClient {
    instproxy_client_t handle;

    public this(iDevice device, LockdowndServiceDescriptor service) {
        instproxy_client_new(device.handle, service, &handle).assertSuccess();
    }

    alias StatusCallback = void delegate(Plist command, Plist status);
    public void install(string packagePath, Plist clientOptions, StatusCallback statusCallback) {
        struct CallbackC {
            StatusCallback cb;
        }

        auto cb = new CallbackC(statusCallback);
        GC.addRoot(cb);
        instproxy_install(handle, packagePath.toStringz(), clientOptions.handle, (command_c, status_c, data) {
            auto cb = (cast(CallbackC*) data);
            GC.removeRoot(cb);
            cb.cb(Plist.wrap(command_c, false), Plist.wrap(status_c, false));
        }, cb).assertSuccess();
    }

    Plist browse(Plist options = null) {
        plist_t result;
        instproxy_browse(handle, options ? options.handle : null, &result).assertSuccess();
        return Plist.wrap(result);
    }

    ~this() {
        if (handle) { // it may be null if an exception has been thrown TODO: switch from a constructor to a static function to fix that.
            instproxy_client_free(handle).assertSuccess();
        }
    }
}

alias AFCError = afc_error_t;
alias AFCFileMode = afc_file_mode_t;

public class AFCClient {
    afc_client_t handle;

    public this(iDevice device, LockdowndServiceDescriptor service) {
        afc_client_new(device.handle, service, &handle).assertSuccess();
    }

    public this(HouseArrestClient houseArrestClient) {
        afc_client_new_from_house_arrest_client(houseArrestClient.handle, &handle).assertSuccess();
    }

    ~this() {
        if (handle) { // it may be null if an exception has been thrown TODO: switch from a constructor to a static function to fix that.
            afc_client_free(handle).assertSuccess();
        }
    }

    AFCError getFileInfo(string path, out string[] fileInfo) {
        char** fileInfoC;
        auto ret = afc_get_file_info(handle, path.toStringz(), &fileInfoC);

        if (fileInfoC) {
            while (*fileInfoC) {
                fileInfo ~= cast(string) (*fileInfoC).fromStringz().dup;
                ++fileInfoC;
            }
            afc_dictionary_free(fileInfoC - fileInfo.length);
        }
        return ret;
    }

    AFCError makeDirectory(string path) {
        return afc_make_directory(handle, path.toStringz());
    }

    ulong open(string path, AFCFileMode fileMode) {
        ulong fileHandle;
        afc_file_open(handle, path.toStringz(), fileMode, &fileHandle).assertSuccess();
        return fileHandle;
    }

    void close(ulong fileHandle) {
        afc_file_close(handle, fileHandle).assertSuccess();
    }

    uint write(ulong fileHandle, ubyte[] data) {
        uint ret;
        afc_file_write(handle, fileHandle, cast(const(char)*) data.ptr, cast(uint) data.length, &ret).assertSuccess();
        return ret;
    }

    void removePath(string path) {
        afc_remove_path(handle, path.toStringz()).assertSuccess();
    }

    void removePathAndContents(string path) {
        afc_remove_path_and_contents(handle, path.toStringz()).assertSuccess();
    }
}

public class MisagentClient {
    misagent_client_t handle;

    public this(iDevice device, LockdowndServiceDescriptor service) {
        misagent_client_new(device.handle, service, &handle).assertSuccess();
    }

    void install(Plist profile) {
        misagent_install(handle, profile.handle).assertSuccess();
    }

    ~this() {
        if (handle) { // it may be null if an exception has been thrown TODO: switch from a constructor to a static function to fix that.
            misagent_client_free(handle).assertSuccess();
        }
    }
}

public class HouseArrestClient {
    house_arrest_client_t handle;

    public this(iDevice device, LockdowndServiceDescriptor service) {
        house_arrest_client_new(device.handle, service, &handle).assertSuccess();
    }

    public this(iDevice device, string label = null) {
        house_arrest_client_start_service(device.handle, &handle, label.toStringz()).assertSuccess();
    }

    void sendCommand(string command, string appId) {
        house_arrest_send_command(handle, command.toStringz(), appId.toStringz()).assertSuccess();
    }

    Plist getResult() {
        plist_t ret;
        house_arrest_get_result(handle, &ret).assertSuccess();
        return Plist.wrap(ret);
    }

    ~this() {
        if (handle) { // it may be null if an exception has been thrown TODO: switch from a constructor to a static function to fix that.
            house_arrest_client_free(handle).assertSuccess();
        }
    }
}
