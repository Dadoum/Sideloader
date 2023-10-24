module winapp;

pragma(linkerDirective, "/SUBSYSTEM:WINDOWS");
static if (__VERSION__ >= 2091)
    pragma(linkerDirective, "/ENTRY:wmainCRTStartup");
else
    pragma(linkerDirective, "/ENTRY:mainCRTStartup");
