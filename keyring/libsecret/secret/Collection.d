module secret.Collection;

private import gio.AsyncInitableIF;
private import gio.AsyncInitableT;
private import gio.AsyncResultIF;
private import gio.Cancellable;
private import gio.DBusInterfaceIF;
private import gio.DBusInterfaceT;
private import gio.DBusProxy;
private import gio.InitableIF;
private import gio.InitableT;
private import glib.ConstructionException;
private import glib.ErrorG;
private import glib.GException;
private import glib.HashTable;
private import glib.ListG;
private import glib.Str;
private import glib.c.functions;
private import gobject.ObjectG;
private import secret.Schema;
private import secret.Service;
private import secret.c.functions;
public  import secret.c.types;


/**
 * A proxy object representing a collection of secrets in the Secret Service.
 * 
 * #SecretCollection represents a collection of secret items stored in the
 * Secret Service.
 * 
 * A collection can be in a locked or unlocked state. Use
 * [method@SecretService.lock] or [method@SecretService.unlock] to lock or
 * unlock the collection.
 * 
 * Use the [property@SecretCollection:items] property or
 * [method@SecretCollection.get_items] to lookup the items in the collection.
 * There may not be any items exposed when the collection is locked.
 */
public class Collection : DBusProxy
{
	/** the main Gtk struct */
	protected SecretCollection* secretCollection;

	/** Get the main Gtk struct */
	public SecretCollection* getCollectionStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return secretCollection;
	}

	/** the main Gtk struct as a void* */
	protected override void* getStruct()
	{
		return cast(void*)secretCollection;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (SecretCollection* secretCollection, bool ownedRef = false)
	{
		this.secretCollection = secretCollection;
		super(cast(GDBusProxy*)secretCollection, ownedRef);
	}


	/** */
	public static GType getType()
	{
		return secret_collection_get_type();
	}

	/**
	 * Finish asynchronous operation to get a new collection proxy for a
	 * collection in the secret service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: the new collection, which should be unreferenced
	 *     with [method@GObject.Object.unref]
	 *
	 * Throws: GException on failure.
	 * Throws: ConstructionException GTK+ fails to create the object.
	 */
	public this(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_collection_new_for_dbus_path_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			throw new ConstructionException("null returned by new_for_dbus_path_finish");
		}

		this(cast(SecretCollection*) __p, true);
	}

	/**
	 * Get a new collection proxy for a collection in the secret service.
	 *
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     service = a secret service object
	 *     collectionPath = the D-Bus path of the collection
	 *     flags = options for the collection initialization
	 *     cancellable = optional cancellation object
	 *
	 * Returns: the new collection, which should be unreferenced
	 *     with [method@GObject.Object.unref]
	 *
	 * Throws: GException on failure.
	 * Throws: ConstructionException GTK+ fails to create the object.
	 */
	public this(Service service, string collectionPath, SecretCollectionFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_collection_new_for_dbus_path_sync((service is null) ? null : service.getServiceStruct(), Str.toStringz(collectionPath), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			throw new ConstructionException("null returned by new_for_dbus_path_sync");
		}

		this(cast(SecretCollection*) __p, true);
	}

	/**
	 * Create a new collection in the secret service.
	 *
	 * This method returns immediately and completes asynchronously. The secret
	 * service may prompt the user. [method@Service.prompt] will be used to handle
	 * any prompts that are required.
	 *
	 * An @alias is a well-known tag for a collection, such as 'default' (ie: the
	 * default collection to store items in). This allows other applications to
	 * easily identify and share a collection. If you specify an @alias, and a
	 * collection with that alias already exists, then a new collection will not
	 * be created. The previous one will be returned instead.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get the
	 * default [class@Service] proxy.
	 *
	 * Params:
	 *     service = a secret service object
	 *     label = label for the new collection
	 *     alias_ = alias to assign to the collection
	 *     flags = currently unused
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public static void create(Service service, string label, string alias_, SecretCollectionCreateFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_collection_create((service is null) ? null : service.getServiceStruct(), Str.toStringz(label), Str.toStringz(alias_), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish operation to create a new collection in the secret service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: the new collection, which should be unreferenced
	 *     with [method@GObject.Object.unref]
	 *
	 * Throws: GException on failure.
	 */
	public static Collection createFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_collection_create_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Collection)(cast(SecretCollection*) __p, true);
	}

	/**
	 * Create a new collection in the secret service.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads. The secret service may prompt the user. [method@Service.prompt]
	 * will be used to handle any prompts that are required.
	 *
	 * An @alias is a well-known tag for a collection, such as `default` (ie: the
	 * default collection to store items in). This allows other applications to
	 * easily identify and share a collection. If you specify an @alias, and a
	 * collection with that alias already exists, then a new collection will not
	 * be created. The previous one will be returned instead.
	 *
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get the
	 * default [class@Service] proxy.
	 *
	 * Params:
	 *     service = a secret service object
	 *     label = label for the new collection
	 *     alias_ = alias to assign to the collection
	 *     flags = currently unused
	 *     cancellable = optional cancellation object
	 *
	 * Returns: the new collection, which should be unreferenced
	 *     with [method@GObject.Object.unref]
	 *
	 * Throws: GException on failure.
	 */
	public static Collection createSync(Service service, string label, string alias_, SecretCollectionCreateFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_collection_create_sync((service is null) ? null : service.getServiceStruct(), Str.toStringz(label), Str.toStringz(alias_), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Collection)(cast(SecretCollection*) __p, true);
	}

	/**
	 * Lookup which collection is assigned to this alias. Aliases help determine
	 * well known collections, such as 'default'.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get the
	 * default [class@Service] proxy.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     service = a secret service object
	 *     alias_ = the alias to lookup
	 *     flags = options for the collection initialization
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public static void forAlias(Service service, string alias_, SecretCollectionFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_collection_for_alias((service is null) ? null : service.getServiceStruct(), Str.toStringz(alias_), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish an asynchronous operation to lookup which collection is assigned
	 * to an alias.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: the collection, or %NULL if none assigned to the alias
	 *
	 * Throws: GException on failure.
	 */
	public static Collection forAliasFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_collection_for_alias_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Collection)(cast(SecretCollection*) __p, true);
	}

	/**
	 * Lookup which collection is assigned to this alias. Aliases help determine
	 * well known collections, such as `default`.
	 *
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get the
	 * default [class@Service] proxy.
	 *
	 * This method may block and should not be used in user interface threads.
	 *
	 * Params:
	 *     service = a secret service object
	 *     alias_ = the alias to lookup
	 *     flags = options for the collection initialization
	 *     cancellable = optional cancellation object
	 *
	 * Returns: the collection, or %NULL if none assigned to the alias
	 *
	 * Throws: GException on failure.
	 */
	public static Collection forAliasSync(Service service, string alias_, SecretCollectionFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_collection_for_alias_sync((service is null) ? null : service.getServiceStruct(), Str.toStringz(alias_), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Collection)(cast(SecretCollection*) __p, true);
	}

	/**
	 * Get a new collection proxy for a collection in the secret service.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     service = a secret service object
	 *     collectionPath = the D-Bus path of the collection
	 *     flags = options for the collection initialization
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public static void newForDbusPath(Service service, string collectionPath, SecretCollectionFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_collection_new_for_dbus_path((service is null) ? null : service.getServiceStruct(), Str.toStringz(collectionPath), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	alias delet = delete_;
	/**
	 * Delete this collection.
	 *
	 * This method returns immediately and completes asynchronously. The secret
	 * service may prompt the user. [method@Service.prompt] will be used to handle
	 * any prompts that show up.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void delete_(Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_collection_delete(secretCollection, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete operation to delete this collection.
	 *
	 * Params:
	 *     result = asynchronous result passed to the callback
	 *
	 * Returns: whether the collection was successfully deleted or not
	 *
	 * Throws: GException on failure.
	 */
	public bool deleteFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_collection_delete_finish(secretCollection, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Delete this collection.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads. The secret service may prompt the user. [method@Service.prompt] will
	 * be used to handle any prompts that show up.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the collection was successfully deleted or not
	 *
	 * Throws: GException on failure.
	 */
	public bool deleteSync(Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_collection_delete_sync(secretCollection, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Get the created date and time of the collection.
	 *
	 * The return value is the number of seconds since the unix epoch, January 1st
	 * 1970.
	 *
	 * Returns: the created date and time
	 */
	public ulong getCreated()
	{
		return secret_collection_get_created(secretCollection);
	}

	/**
	 * Get the flags representing what features of the #SecretCollection proxy
	 * have been initialized.
	 *
	 * Use [method@Collection.load_items] to initialize further features and change
	 * the flags.
	 *
	 * Returns: the flags for features initialized
	 */
	public SecretCollectionFlags getFlags()
	{
		return secret_collection_get_flags(secretCollection);
	}
	alias getFlags = DBusProxy.getFlags;

	/**
	 * Get the list of items in this collection.
	 *
	 * Returns: a list of items, when
	 *     done, the list should be freed with [func@GLib.List.free], and each item
	 *     should be released with [method@GObject.Object.unref]
	 */
	public ListG getItems()
	{
		auto __p = secret_collection_get_items(secretCollection);

		if(__p is null)
		{
			return null;
		}

		return new ListG(cast(GList*) __p, true);
	}

	/**
	 * Get the label of this collection.
	 *
	 * Returns: the label, which should be freed with
	 *     [func@GLib.free]
	 */
	public string getLabel()
	{
		auto retStr = secret_collection_get_label(secretCollection);

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Get whether the collection is locked or not.
	 *
	 * Use [method@Service.lock] or [method@Service.unlock] to lock or unlock the
	 * collection.
	 *
	 * Returns: whether the collection is locked or not
	 */
	public bool getLocked()
	{
		return secret_collection_get_locked(secretCollection) != 0;
	}

	/**
	 * Get the modified date and time of the collection.
	 *
	 * The return value is the number of seconds since the unix epoch, January 1st
	 * 1970.
	 *
	 * Returns: the modified date and time
	 */
	public ulong getModified()
	{
		return secret_collection_get_modified(secretCollection);
	}

	/**
	 * Get the Secret Service object that this collection was created with.
	 *
	 * Returns: the Secret Service object
	 */
	public Service getService()
	{
		auto __p = secret_collection_get_service(secretCollection);

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Service)(cast(SecretService*) __p);
	}

	/**
	 * Ensure that the #SecretCollection proxy has loaded all the items present
	 * in the Secret Service.
	 *
	 * This affects the result of [method@Collection.get_items].
	 *
	 * For collections returned from [method@Service.get_collections] the items will
	 * have already been loaded.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void loadItems(Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_collection_load_items(secretCollection, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete an asynchronous operation to ensure that the #SecretCollection proxy
	 * has loaded all the items present in the Secret Service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: whether the load was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool loadItemsFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_collection_load_items_finish(secretCollection, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Ensure that the #SecretCollection proxy has loaded all the items present
	 * in the Secret Service. This affects the result of
	 * [method@Collection.get_items].
	 *
	 * For collections returned from [method@Service.get_collections] the items
	 * will have already been loaded.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the load was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool loadItemsSync(Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_collection_load_items_sync(secretCollection, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Refresh the properties on this collection. This fires off a request to
	 * refresh, and the properties will be updated later.
	 *
	 * Calling this method is not normally necessary, as the secret service
	 * will notify the client when properties change.
	 */
	public void refresh()
	{
		secret_collection_refresh(secretCollection);
	}

	/**
	 * Search for items matching the @attributes in the @collection.
	 * The @attributes should be a table of string keys and string values.
	 *
	 * If %SECRET_SEARCH_ALL is set in @flags, then all the items matching the
	 * search will be returned. Otherwise only the first item will be returned.
	 * This is almost always the unlocked item that was most recently stored.
	 *
	 * If %SECRET_SEARCH_UNLOCK is set in @flags, then items will be unlocked
	 * if necessary. In either case, locked and unlocked items will match the
	 * search and be returned. If the unlock fails, the search does not fail.
	 *
	 * If %SECRET_SEARCH_LOAD_SECRETS is set in @flags, then the items will have
	 * their secret values loaded and available via [method@Item.get_secret].
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = search for items matching these attributes
	 *     flags = search option flags
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void search(Schema schema, HashTable attributes, SecretSearchFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_collection_search(secretCollection, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to search for items in a collection.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: a list of items that matched the search
	 *
	 * Throws: GException on failure.
	 */
	public ListG searchFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_collection_search_finish(secretCollection, (result is null) ? null : result.getAsyncResultStruct(), &err);

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
	 * Search for items in @collection matching the @attributes, and return their
	 * DBus object paths.
	 *
	 * Only the specified collection is searched. The @attributes should be a table
	 * of string keys and string values.
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * When your callback is called use [method@Collection.search_for_dbus_paths_finish]
	 * to get the results of this function. Only the DBus object paths of the
	 * items will be returned. If you would like [class@Item] objects to be returned
	 * instead, then use the [method@Collection.search] function.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = search for items matching these attributes
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void searchForDbusPaths(Schema schema, HashTable attributes, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_collection_search_for_dbus_paths(secretCollection, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to search for items in a collection.
	 *
	 * DBus object paths of the items will be returned. If you would to have
	 * [class@Item] objects to be returned instead, then use the
	 * [method@Collection.search] and [method@Collection.search_finish] functions.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: an array of DBus object
	 *     paths for matching items.
	 *
	 * Throws: GException on failure.
	 */
	public string[] searchForDbusPathsFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto retStr = secret_collection_search_for_dbus_paths_finish(secretCollection, (result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeStringArray(retStr);
		return Str.toStringArray(retStr);
	}

	/**
	 * Search for items matching the @attributes in @collection, and return their
	 * DBus object paths.
	 *
	 * The @attributes should be a table of string keys and string values.
	 *
	 * This function may block indefinitely. Use the asynchronous version
	 * in user interface threads.
	 *
	 * DBus object paths of the items will be returned. If you would to have
	 * [class@Item] objects to be returned instead, then use the
	 * [method@Collection.search_sync] function.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = search for items matching these attributes
	 *     cancellable = optional cancellation object
	 *
	 * Returns: an array of DBus object
	 *     paths for matching items.
	 *
	 * Throws: GException on failure.
	 */
	public string[] searchForDbusPathsSync(Schema schema, HashTable attributes, Cancellable cancellable)
	{
		GError* err = null;

		auto retStr = secret_collection_search_for_dbus_paths_sync(secretCollection, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeStringArray(retStr);
		return Str.toStringArray(retStr);
	}

	/**
	 * Search for items matching the @attributes in the @collection.
	 * The @attributes should be a table of string keys and string values.
	 *
	 * If %SECRET_SEARCH_ALL is set in @flags, then all the items matching the
	 * search will be returned. Otherwise only the first item will be returned.
	 * This is almost always the unlocked item that was most recently stored.
	 *
	 * If %SECRET_SEARCH_UNLOCK is set in @flags, then items will be unlocked
	 * if necessary. In either case, locked and unlocked items will match the
	 * search and be returned. If the unlock fails, the search does not fail.
	 *
	 * If %SECRET_SEARCH_LOAD_SECRETS is set in @flags, then the items will have
	 * their secret values loaded and available via [method@Item.get_secret].
	 *
	 * This function may block indefinitely. Use the asynchronous version
	 * in user interface threads.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = search for items matching these attributes
	 *     flags = search option flags
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a list of items that matched the search
	 *
	 * Throws: GException on failure.
	 */
	public ListG searchSync(Schema schema, HashTable attributes, SecretSearchFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_collection_search_sync(secretCollection, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

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
	 * Set the label of this collection.
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * Params:
	 *     label = a new label
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void setLabel(string label, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_collection_set_label(secretCollection, Str.toStringz(label), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to set the label of this collection.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: whether the change was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool setLabelFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_collection_set_label_finish(secretCollection, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Set the label of this collection.
	 *
	 * This function may block indefinitely. Use the asynchronous version
	 * in user interface threads.
	 *
	 * Params:
	 *     label = a new label
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the change was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool setLabelSync(string label, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_collection_set_label_sync(secretCollection, Str.toStringz(label), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}
}
