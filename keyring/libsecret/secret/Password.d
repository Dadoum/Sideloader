module secret.Password;

private import gio.AsyncResultIF;
private import gio.Cancellable;
private import glib.ErrorG;
private import glib.GException;
private import glib.HashTable;
private import glib.ListG;
private import glib.Str;
private import glib.c.functions;
private import gobject.ObjectG;
private import secret.Schema;
private import secret.Value;
private import secret.c.functions;
public  import secret.c.types;


/** */
public struct Password
{

	/**
	 * Finish an asynchronous operation to remove passwords from the secret
	 * service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: whether any passwords were removed
	 *
	 * Throws: GException on failure.
	 */
	public static bool clearFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_password_clear_finish((result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Remove unlocked matching passwords from the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * All unlocked items that match the attributes will be deleted.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = the attribute keys and values
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public static void clearv(Schema schema, HashTable attributes, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_password_clearv((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Remove unlocked matching passwords from the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * All unlocked items that match the attributes will be deleted.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = the attribute keys and values
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether any passwords were removed
	 *
	 * Throws: GException on failure.
	 */
	public static bool clearvSync(Schema schema, HashTable attributes, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_password_clearv_sync((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Clear the memory used by a password, and then free it.
	 *
	 * This function must be used to free nonpageable memory returned by
	 * [func@password_lookup_nonpageable_finish],
	 * [func@password_lookup_nonpageable_sync] or
	 * [func@password_lookupv_nonpageable_sync].
	 *
	 * Params:
	 *     password = password to free
	 */
	public static void free(string password)
	{
		secret_password_free(Str.toStringz(password));
	}

	/**
	 * Finish an asynchronous operation to lookup a password in the secret service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a newly allocated [struct@Value], which should be
	 *     released with [method@Value.unref], or %NULL if no secret found
	 *
	 * Since: 0.19.0
	 *
	 * Throws: GException on failure.
	 */
	public static Value lookupBinaryFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_password_lookup_binary_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

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
	 * Finish an asynchronous operation to lookup a password in the secret service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a new password string which should be freed with
	 *     [func@password_free] or may be freed with [func@GLib.free] when done
	 *
	 * Throws: GException on failure.
	 */
	public static string lookupFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto retStr = secret_password_lookup_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Finish an asynchronous operation to lookup a password in the secret service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a new password string stored in nonpageable memory
	 *     which must be freed with [func@password_free] when done
	 *
	 * Throws: GException on failure.
	 */
	public static string lookupNonpageableFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto retStr = secret_password_lookup_nonpageable_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Lookup a password in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If no secret is found then %NULL is returned.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public static void lookupv(Schema schema, HashTable attributes, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_password_lookupv((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Lookup a password in the secret service.
	 *
	 * This is similar to [func@password_lookupv_sync], but returns a
	 * [struct@Value] instead of a null-terminated password.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a newly allocated [struct@Value], which should be
	 *     released with [method@Value.unref], or %NULL if no secret found
	 *
	 * Since: 0.19.0
	 *
	 * Throws: GException on failure.
	 */
	public static Value lookupvBinarySync(Schema schema, HashTable attributes, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_password_lookupv_binary_sync((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

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
	 * Lookup a password in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If no secret is found then %NULL is returned.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a new password string stored in non pageable memory
	 *     which should be freed with [func@password_free] when done
	 *
	 * Throws: GException on failure.
	 */
	public static string lookupvNonpageableSync(Schema schema, HashTable attributes, Cancellable cancellable)
	{
		GError* err = null;

		auto retStr = secret_password_lookupv_nonpageable_sync((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Lookup a password in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If no secret is found then %NULL is returned.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a new password string which should be freed with
	 *     [func@password_free] or may be freed with [func@GLib.free] when done
	 *
	 * Throws: GException on failure.
	 */
	public static string lookupvSync(Schema schema, HashTable attributes, Cancellable cancellable)
	{
		GError* err = null;

		auto retStr = secret_password_lookupv_sync((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Finish an asynchronous operation to search for items in the secret service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a list of
	 *     [iface@Retrievable] containing attributes of the matched items
	 *
	 * Since: 0.19.0
	 *
	 * Throws: GException on failure.
	 */
	public static ListG searchFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_password_search_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return new ListG(cast(GList*) __p, true);
	}

	/**
	 * Search for items in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     flags = search option flags
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 *
	 * Since: 0.19.0
	 */
	public static void searchv(Schema schema, HashTable attributes, SecretSearchFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_password_searchv((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Search for items in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If no secret is found then %NULL is returned.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     flags = search option flags
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a list of
	 *     [iface@Retrievable] containing attributes of the matched items
	 *
	 * Since: 0.19.0
	 *
	 * Throws: GException on failure.
	 */
	public static ListG searchvSync(Schema schema, HashTable attributes, SecretSearchFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_password_searchv_sync((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return new ListG(cast(GList*) __p, true);
	}

	/**
	 * Finish asynchronous operation to store a password in the secret service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: whether the storage was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public static bool storeFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_password_store_finish((result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Store a password in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If the attributes match a secret item already stored in the collection, then
	 * the item will be updated with these new values.
	 *
	 * If @collection is %NULL, then the default collection will be
	 * used. Use [const@COLLECTION_SESSION] to store the password in the session
	 * collection, which doesn't get stored across login sessions.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     collection = a collection alias, or D-Bus object path of the
	 *         collection where to store the secret
	 *     label = label for the secret
	 *     password = the null-terminated password to store
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public static void storev(Schema schema, HashTable attributes, string collection, string label, string password, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_password_storev((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), Str.toStringz(collection), Str.toStringz(label), Str.toStringz(password), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Store a password in the secret service.
	 *
	 * This is similar to [func@password_storev], but takes a
	 * [struct@Value] as the argument instead of a null-terminated password.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     collection = a collection alias, or D-Bus object path of the
	 *         collection where to store the secret
	 *     label = label for the secret
	 *     value = a [struct@Value]
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 *
	 * Since: 0.19.0
	 */
	public static void storevBinary(Schema schema, HashTable attributes, string collection, string label, Value value, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_password_storev_binary((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), Str.toStringz(collection), Str.toStringz(label), (value is null) ? null : value.getValueStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Store a password in the secret service.
	 *
	 * This is similar to [func@password_storev_sync], but takes a [struct@Value] as
	 * the argument instead of a null-terminated passwords.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     collection = a collection alias, or D-Bus object path of the
	 *         collection where to store the secret
	 *     label = label for the secret
	 *     value = a [struct@Value]
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the storage was successful or not
	 *
	 * Since: 0.19.0
	 *
	 * Throws: GException on failure.
	 */
	public static bool storevBinarySync(Schema schema, HashTable attributes, string collection, string label, Value value, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_password_storev_binary_sync((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), Str.toStringz(collection), Str.toStringz(label), (value is null) ? null : value.getValueStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Store a password in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If the attributes match a secret item already stored in the collection, then
	 * the item will be updated with these new values.
	 *
	 * If @collection is %NULL, then the default collection will be
	 * used. Use [const@COLLECTION_SESSION] to store the password in the session
	 * collection, which doesn't get stored across login sessions.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for attributes
	 *     attributes = the attribute keys and values
	 *     collection = a collection alias, or D-Bus object path of the
	 *         collection where to store the secret
	 *     label = label for the secret
	 *     password = the null-terminated password to store
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the storage was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public static bool storevSync(Schema schema, HashTable attributes, string collection, string label, string password, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_password_storev_sync((schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), Str.toStringz(collection), Str.toStringz(label), Str.toStringz(password), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Clear the memory used by a password.
	 *
	 * Params:
	 *     password = password to clear
	 */
	public static void wipe(string password)
	{
		secret_password_wipe(Str.toStringz(password));
	}
}
