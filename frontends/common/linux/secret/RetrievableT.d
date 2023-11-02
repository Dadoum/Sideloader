module secret.RetrievableT;

public  import gio.AsyncResultIF;
public  import gio.Cancellable;
public  import glib.ErrorG;
public  import glib.GException;
public  import glib.HashTable;
public  import glib.Str;
public  import glib.c.functions;
public  import gobject.ObjectG;
public  import secret.Value;
public  import secret.c.functions;
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
public template RetrievableT(TStruct)
{
    /** Get the main Gtk struct */
    public SecretRetrievable* getRetrievableStruct(bool transferOwnership = false)
    {
        if (transferOwnership)
            ownedRef = false;
        return cast(SecretRetrievable*)getStruct();
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
    public HashTable getAttributes()
    {
        auto __p = secret_retrievable_get_attributes(getRetrievableStruct());

        if(__p is null)
        {
            return null;
        }

        return new HashTable(cast(GHashTable*) __p, true);
    }

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
    public ulong getCreated()
    {
        return secret_retrievable_get_created(getRetrievableStruct());
    }

    /**
     * Get the label of this item.
     *
     * Returns: the label, which should be freed with [func@GLib.free]
     *
     * Since: 0.19.0
     */
    public string getLabel()
    {
        auto retStr = secret_retrievable_get_label(getRetrievableStruct());

        scope(exit) Str.freeString(retStr);
        return Str.toString(retStr);
    }

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
    public ulong getModified()
    {
        return secret_retrievable_get_modified(getRetrievableStruct());
    }

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
	public void retrieveSecret(Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_retrievable_retrieve_secret(getRetrievableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

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
	public Value retrieveSecretFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_retrievable_retrieve_secret_finish(getRetrievableStruct(), (result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Value)(cast(SecretValue*) __p, true);
	}

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
	public Value retrieveSecretSync(Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_retrievable_retrieve_secret_sync(getRetrievableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Value)(cast(SecretValue*) __p, true);
	}
}
