module imobiledevice;

public import imobiledevice.libimobiledevice;
public import imobiledevice.lockdown;
import std.array;
import std.algorithm.iteration;
import std.format;
import std.string;
import std.traits;

class iDeviceException: Exception {
    this(T)(T error, string file = __FILE__, int line = __LINE__) {
        super(format!"error %s"(error), file, line);
    }
}

void assertSuccess(alias U)(Parameters!U u) if (is(ReturnType!U == idevice_error_t)) {
    auto error = U(u);
    if (error != 0)
        throw new iDeviceException(error);
}

class LockdowndException: Exception {
    this(T)(T error, string file = __FILE__, int line = __LINE__) {
        super(format!"error %s"(error), file, line);
    }
}

void assertSuccess(alias U)(Parameters!U u) if (is(ReturnType!U == lockdownd_error_t)) {
    auto error = U(u);
    if (error != 0)
        throw new LockdowndException(error);
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

        assertSuccess!idevice_event_subscribe(&func, new UserData(callback));
    }

    public static @property iDeviceInfo[] deviceList() {
        int len;
        idevice_info_t* names;
        assertSuccess!idevice_get_device_list_extended(&names, &len);
        return names[0..len].map!((s) => iDeviceInfo(cast(string) s.udid.fromStringz, cast(iDeviceConnectionType) s.conn_type)).array;
    }

    public @property string udid() {
        char* udid;
        handle.assertSuccess!idevice_get_udid(&udid);
        return cast(string) udid.fromStringz();
    }

    public this(string udid) {
        assertSuccess!idevice_new_with_options(&handle, udid.toStringz, idevice_options.IDEVICE_LOOKUP_USBMUX | idevice_options.IDEVICE_LOOKUP_NETWORK);
    }

    ~this() {
        assertSuccess!idevice_free(handle);
    }
}

public class LockdowndClient {
    lockdownd_client_t handle;

    public this(iDevice device, string serviceName) {
        assertSuccess!lockdownd_client_new_with_handshake(device.handle, &handle, cast(const(char)*) serviceName.toStringz);
    }

    public @property string deviceName() {
        char* name;
        assertSuccess!lockdownd_get_device_name(handle, &name);
        return cast(string) name.fromStringz;
    }

    ~this() {
        if (handle) { // it may be null if an exception has been thrown TODO: switch from a constructor to a static function to fix that.
            assertSuccess!lockdownd_client_free(handle);
        }
    }
}
