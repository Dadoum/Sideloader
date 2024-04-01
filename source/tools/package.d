module tools;

import imobiledevice;

abstract class Tool {
    iDevice device;
    LockdowndClient lockdowndClient;

    this(iDevice device, LockdowndClient lockdowndClient) {
        this.device = device;
        this.lockdowndClient = lockdowndClient;
    }

    /// Name of the tool
    abstract string name();

    /// Returns null if the action can be performed, otherwise gives a diagnostic on why it is not available.
    abstract string diagnostic();

    /// Returns true if cancelled
    abstract void run(bool delegate(string message, bool canCancel = true) notify);
}

Tool[] toolList(iDevice device) {
    import tools.sidestorepairingfile;
    return cast(Tool[]) [
        new SideStoreTool(device),
    ];
}
