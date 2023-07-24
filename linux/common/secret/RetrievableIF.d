module secret.RetrievableIF;

private import gio.AsyncResultIF;
private import gio.Cancellable;
private import glib.ErrorG;
private import glib.GException;
private import glib.HashTable;
private import glib.Str;
private import glib.c.functions;
private import gobject.ObjectG;
private import secret.Value;
private import secret.c.functions;
public  import secret.c.types;


/**
 * A read-only view of a secret item in the Secret Service.
 * 
 * #SecretRetrievable provides a read-only view of a secret item
 * stored in the Secret Service.
 * 
 * Each item has a value, represented by a [struct@Value], which can be
 * retrieved by [method@Retrievable.retrieve_secret] and
 * [method@Retrievable.retrieve_secret_finish].
 *
 * Since: 0.19.0
 */
public interface RetrievableIF{
    /** Get the main Gtk struct */
    public SecretRetrievable* getRetrievableStruct(bool transferOwnership = false);

    /** the main Gtk struct as a void* */
    protected void* getStruct();


    /** */
    public static GType getType()
    {
        return secret_retrievable_get_type();
    }

    /**
     * Get the attributes of this object.
     *
     * The attributes are a mapping of string keys to string values.
     * Attributes are used to search for items. Attributes are not stored
     * or transferred securely by the secret service.
     *
     * Do not modify the attribute returned by this method.
     *
     * Returns: a new reference
     *     to the attributes, which should not be modified, and
     *     released with [func@GLib.HashTable.unref]
     *
     * Since: 0.19.0
     */
    public HashTable getAttributes();

    /**
     * Get the created date and time of the object.
     *
     * The return value is the number of seconds since the unix epoch, January 1st
     * 1970.
     *
     * Returns: the created date and time
     *
     * Since: 0.19.0
     */
    public ulong getCreated();

    /**
     * Get the label of this item.
     *
     * Returns: the label, which should be freed with [func@GLib.free]
     *
     * Since: 0.19.0
     */
    public string getLabel();

    /**
     * Get the modified date and time of the object.
     *
     * The return value is the number of seconds since the unix epoch, January 1st
     * 1970.
     *
     * Returns: the modified date and time
     *
     * Since: 0.19.0
     */
    public ulong getModified();

    /**
     * Retrieve the secret value of this object.
     *
     * Each retrievable object has a single secret which might be a
     * password or some other secret binary value.
     *
     * This function returns immediately and completes asynchronously.
     *
     * Params:
     *     cancellable = optional cancellation object
     *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 *
	 * Since: 0.19.0
	 */
	public void retrieveSecret(Cancellable cancellable, GAsyncReadyCallback callback, void* userData);

	/**
	 * Complete asynchronous operation to retrieve the secret value of this object.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: the secret value which should be
	 *     released with [method@Value.unref], or %NULL
	 *
	 * Since: 0.19.0
	 *
	 * Throws: GException on failure.
	 */
	public Value retrieveSecretFinish(AsyncResultIF result);

	/**
	 * Retrieve the secret value of this object synchronously.
	 *
	 * Each retrievable object has a single secret which might be a
	 * password or some other secret binary value.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *
	 * Returns: the secret value which should be
	 *     released with [method@Value.unref], or %NULL
	 *
	 * Since: 0.19.0
	 *
	 * Throws: GException on failure.
	 */
	public Value retrieveSecretSync(Cancellable cancellable);
}
