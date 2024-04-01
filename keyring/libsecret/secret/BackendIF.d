module secret.BackendIF;

private import gio.AsyncResultIF;
private import gio.Cancellable;
private import glib.ErrorG;
private import glib.GException;
private import gobject.ObjectG;
private import secret.BackendIF;
private import secret.c.functions;
public  import secret.c.types;


/**
 * #SecretBackend represents a backend implementation of password
 * storage.
 *
 * Since: 0.19.0
 */
public interface BackendIF{
	/** Get the main Gtk struct */
	public SecretBackend* getBackendStruct(bool transferOwnership = false);

	/** the main Gtk struct as a void* */
	protected void* getStruct();


	/** */
	public static GType getType()
	{
		return secret_backend_get_type();
	}

	/**
	 * Get a #SecretBackend instance.
	 *
	 * If such a backend already exists, then the same backend is returned.
	 *
	 * If @flags contains any flags of which parts of the secret backend to
	 * ensure are initialized, then those will be initialized before completing.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     flags = flags for which service functionality to ensure is initialized
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 *
	 * Since: 0.19.0
	 */
	public static void get(SecretBackendFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_backend_get(flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete an asynchronous operation to get a #SecretBackend.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a new reference to a #SecretBackend proxy, which
	 *     should be released with [method@GObject.Object.unref].
	 *
	 * Since: 0.19.0
	 *
	 * Throws: GException on failure.
	 */
	public static BackendIF getFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_backend_get_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(BackendIF)(cast(SecretBackend*) __p, true);
	}
}
