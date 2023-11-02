module secret.BackendT;

public  import gio.AsyncResultIF;
public  import gio.Cancellable;
public  import glib.ErrorG;
public  import glib.GException;
public  import gobject.ObjectG;
public  import secret.BackendIF;
public  import secret.c.functions;
public  import secret.c.types;


/**
 * #SecretBackend represents a backend implementation of password
 * storage.
 *
 * Since: 0.19.0
 */
public template BackendT(TStruct)
{
    /** Get the main Gtk struct */
    public SecretBackend* getBackendStruct(bool transferOwnership = false)
    {
        if (transferOwnership)
            ownedRef = false;
        return cast(SecretBackend*)getStruct();
    }

}
