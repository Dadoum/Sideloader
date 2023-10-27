module imobiledevice.userpref;

// Bindings done manually
import plist.c;

import imobiledevice.libimobiledevice;

import dynamicloader;

mixin makeBindings;
@libimobiledevice extern(C):

enum userpref_error_t {
    USERPREF_E_SUCCESS       =  0,
    USERPREF_E_INVALID_ARG   = -1,
    USERPREF_E_NOENT         = -2,
    USERPREF_E_INVALID_CONF  = -3,
    USERPREF_E_SSL_ERROR     = -4,
    USERPREF_E_READ_ERROR    = -5,
    USERPREF_E_WRITE_ERROR   = -6,
    USERPREF_E_UNKNOWN_ERROR = -256
}

userpref_error_t userpref_read_pair_record(const char* udid, plist_t* pair_record);

userpref_error_t pair_record_get_host_id(plist_t pair_record, char** host_id);
