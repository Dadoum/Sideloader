module secret.Service;

private import gio.AsyncInitableIF;
private import gio.AsyncInitableT;
private import gio.AsyncResultIF;
private import gio.Cancellable;
private import gio.DBusInterfaceIF;
private import gio.DBusInterfaceT;
private import gio.DBusProxy;
private import gio.InitableIF;
private import gio.InitableT;
private import glib.ErrorG;
private import glib.GException;
private import glib.HashTable;
private import glib.ListG;
private import glib.Str;
private import glib.Variant;
private import glib.VariantType;
private import glib.c.functions;
private import gobject.ObjectG;
private import secret.BackendIF;
private import secret.BackendT;
private import secret.Collection;
private import secret.Prompt;
private import secret.Schema;
private import secret.Value;
private import secret.c.functions;
public  import secret.c.types;


/**
 * A proxy object representing the Secret Service.
 * 
 * A #SecretService object represents the Secret Service implementation which
 * runs as a D-Bus service.
 * 
 * Normally a single #SecretService object can be shared between multiple
 * callers. The [func@Service.get] method is used to access this #SecretService
 * object. If a new independent #SecretService object is required, use
 * [func@Service.open].
 * 
 * In order to securely transfer secrets to the Sercret Service, a session
 * is established. This session can be established while initializing a
 * #SecretService object by passing the %SECRET_SERVICE_OPEN_SESSION flag
 * to the [func@Service.get] or [func@Service.open] functions. In order to
 * establish a session on an already existing #SecretService, use the
 * [method@Service.ensure_session] function.
 * 
 * To search for items, use the [method@Service.search] method.
 * 
 * Multiple collections can exist in the Secret Service, each of which contains
 * secret items. In order to instantiate [class@Collection] objects which
 * represent those collections while initializing a #SecretService then pass
 * the %SECRET_SERVICE_LOAD_COLLECTIONS flag to the [func@Service.get] or
 * [func@Service.open] functions. In order to establish a session on an already
 * existing #SecretService, use the [method@Service.load_collections] function.
 * To access the list of collections use [method@Service.get_collections].
 * 
 * Certain actions on the Secret Service require user prompting to complete,
 * such as creating a collection, or unlocking a collection. When such a prompt
 * is necessary, then a [class@Prompt] object is created by this library, and
 * passed to the [method@Service.prompt] method. In this way it is handled
 * automatically.
 * 
 * In order to customize prompt handling, override the
 * [vfunc@Service.prompt_async] and [vfunc@Service.prompt_finish] virtual
 * methods of the #SecretService class.
 */
public class Service : DBusProxy, BackendIF
{
	/** the main Gtk struct */
	protected SecretService* secretService;

	/** Get the main Gtk struct */
	public SecretService* getServiceStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return secretService;
	}

	/** the main Gtk struct as a void* */
	protected override void* getStruct()
	{
		return cast(void*)secretService;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (SecretService* secretService, bool ownedRef = false)
	{
		this.secretService = secretService;
		super(cast(GDBusProxy*)secretService, ownedRef);
	}

	// add the Backend capabilities
	mixin BackendT!(SecretService);


	/** */
	public static GType getType()
	{
		return secret_service_get_type();
	}

	/**
	 * Disconnect the default #SecretService proxy returned by [func@Service.get]
	 * and [func@Service.get_sync].
	 *
	 * It is not necessary to call this function, but you may choose to do so at
	 * program exit. It is useful for testing that memory is not leaked.
	 *
	 * This function is safe to call at any time. But if other objects in this
	 * library are still referenced, then this will not result in all memory
	 * being freed.
	 */
	public static void disconnect()
	{
		secret_service_disconnect();
	}

	/**
	 * Get a #SecretService proxy for the Secret Service.
	 *
	 * If such a proxy object already exists, then the same proxy is returned.
	 *
	 * If @flags contains any flags of which parts of the secret service to
	 * ensure are initialized, then those will be initialized before completing.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     flags = flags for which service functionality to ensure is initialized
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public static void get(SecretServiceFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_get(flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete an asynchronous operation to get a #SecretService proxy for the
	 * Secret Service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a new reference to a #SecretService proxy, which
	 *     should be released with [method@GObject.Object.unref].
	 *
	 * Throws: GException on failure.
	 */
	public static Service getFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_get_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Service)(cast(SecretService*) __p, true);
	}

	/**
	 * Get a #SecretService proxy for the Secret Service.
	 *
	 * If such a proxy object already exists, then the same proxy is returned.
	 *
	 * If @flags contains any flags of which parts of the secret service to
	 * ensure are initialized, then those will be initialized before returning.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     flags = flags for which service functionality to ensure is initialized
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a new reference to a #SecretService proxy, which
	 *     should be released with [method@GObject.Object.unref].
	 *
	 * Throws: GException on failure.
	 */
	public static Service getSync(SecretServiceFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_get_sync(flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Service)(cast(SecretService*) __p, true);
	}

	/**
	 * Create a new #SecretService proxy for the Secret Service.
	 *
	 * This function is rarely used, see [func@Service.get] instead.
	 *
	 * The @service_gtype argument should be set to %SECRET_TYPE_SERVICE or a the type
	 * of a derived class.
	 *
	 * If @flags contains any flags of which parts of the secret service to
	 * ensure are initialized, then those will be initialized before returning.
	 *
	 * If @service_bus_name is %NULL then the default is used.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     serviceGtype = the GType of the new secret service
	 *     serviceBusName = the D-Bus service name of the secret service
	 *     flags = flags for which service functionality to ensure is initialized
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public static void open(GType serviceGtype, string serviceBusName, SecretServiceFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_open(serviceGtype, Str.toStringz(serviceBusName), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete an asynchronous operation to create a new #SecretService proxy for
	 * the Secret Service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a new reference to a #SecretService proxy, which
	 *     should be released with [method@GObject.Object.unref].
	 *
	 * Throws: GException on failure.
	 */
	public static Service openFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_open_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Service)(cast(SecretService*) __p, true);
	}

	/**
	 * Create a new #SecretService proxy for the Secret Service.
	 *
	 * This function is rarely used, see [func@Service.get_sync] instead.
	 *
	 * The @service_gtype argument should be set to %SECRET_TYPE_SERVICE or a the
	 * type of a derived class.
	 *
	 * If @flags contains any flags of which parts of the secret service to
	 * ensure are initialized, then those will be initialized before returning.
	 *
	 * If @service_bus_name is %NULL then the default is used.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     serviceGtype = the GType of the new secret service
	 *     serviceBusName = the D-Bus service name of the secret service
	 *     flags = flags for which service functionality to ensure is initialized
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a new reference to a #SecretService proxy, which
	 *     should be released with [method@GObject.Object.unref].
	 *
	 * Throws: GException on failure.
	 */
	public static Service openSync(GType serviceGtype, string serviceBusName, SecretServiceFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_open_sync(serviceGtype, Str.toStringz(serviceBusName), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Service)(cast(SecretService*) __p, true);
	}

	/**
	 * Remove unlocked items which match the attributes from the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get
	 * the default [class@Service] proxy.
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
	public void clear(Schema schema, HashTable attributes, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_clear(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish asynchronous operation to remove items from the secret
	 * service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: whether items were removed or not
	 *
	 * Throws: GException on failure.
	 */
	public bool clearFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_clear_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Remove unlocked items which match the attributes from the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = the attribute keys and values
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether items were removed or not
	 *
	 * Throws: GException on failure.
	 */
	public bool clearSync(Schema schema, HashTable attributes, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_clear_sync(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Create a new collection in the secret service, and return its path.
	 *
	 * Using this method requires that you setup a correct hash table of D-Bus
	 * properties for the new collection. You may prefer to use
	 * [func@Collection.create] which does handles this for you.
	 *
	 * An @alias is a well-known tag for a collection, such as 'default' (ie: the
	 * default collection to store items in). This allows other applications to
	 * easily identify and share a collection. If a collection with the @alias
	 * already exists, then instead of creating a new collection, the existing
	 * collection will be returned. If no collection with this alias exists, then a
	 * new collection will be created and this alias will be assigned to it.
	 *
	 * @properties is a set of properties for the new collection. The keys in the
	 * hash table should be interface.property strings like
	 * `org.freedesktop.Secret.Collection.Label`. The values
	 * in the hash table should be [struct@GLib.Variant] values of the properties.
	 *
	 * If you wish to have a
	 *
	 * This method will return immediately and complete asynchronously. The secret
	 * service may prompt the user. [method@Service.prompt] will be used to handle
	 * any prompts that are required.
	 *
	 * Params:
	 *     properties = hash table of properties for
	 *         the new collection
	 *     alias_ = an alias to check for before creating the new
	 *         collection, or to assign to the new collection
	 *     flags = not currently used
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void createCollectionDbusPath(HashTable properties, string alias_, SecretCollectionCreateFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_create_collection_dbus_path(secretService, (properties is null) ? null : properties.getHashTableStruct(), Str.toStringz(alias_), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish asynchronous operation to create a new collection in the secret
	 * service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a new string containing the D-Bus object path
	 *     of the collection
	 *
	 * Throws: GException on failure.
	 */
	public string createCollectionDbusPathFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto retStr = secret_service_create_collection_dbus_path_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Create a new collection in the secret service and return its path.
	 *
	 * Using this method requires that you setup a correct hash table of D-Bus
	 * properties for the new collection. You may prefer to use
	 * [func@Collection.create] which does handles this for you.
	 *
	 * An @alias is a well-known tag for a collection, such as 'default' (ie: the
	 * default collection to store items in). This allows other applications to
	 * easily identify and share a collection. If a collection with the @alias
	 * already exists, then instead of creating a new collection, the existing
	 * collection will be returned. If no collection with this alias exists, then
	 * a new collection will be created and this alias will be assigned to it.
	 *
	 * @properties is a set of properties for the new collection. The keys in the
	 * hash table should be interface.property strings like
	 * `org.freedesktop.Secret.Collection.Label`. The values
	 * in the hash table should be [struct@GLib.Variant] values of the properties.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads. The secret service may prompt the user. [method@Service.prompt]
	 * will be used to handle any prompts that are required.
	 *
	 * Params:
	 *     properties = hash table of D-Bus properties
	 *         for the new collection
	 *     alias_ = an alias to check for before creating the new
	 *         collection, or to assign to the new collection
	 *     flags = not currently used
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a new string containing the D-Bus object path
	 *     of the collection
	 *
	 * Throws: GException on failure.
	 */
	public string createCollectionDbusPathSync(HashTable properties, string alias_, SecretCollectionCreateFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto retStr = secret_service_create_collection_dbus_path_sync(secretService, (properties is null) ? null : properties.getHashTableStruct(), Str.toStringz(alias_), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Create a new item in a secret service collection and return its D-Bus
	 * object path.
	 *
	 * It is often easier to use [func@password_store] or [func@Item.create]
	 * rather than using this function. Using this method requires that you setup
	 * a correct hash table of D-Bus @properties for the new collection.
	 *
	 * If the @flags contains %SECRET_ITEM_CREATE_REPLACE, then the secret
	 * service will search for an item matching the @attributes, and update that item
	 * instead of creating a new one.
	 *
	 * @properties is a set of properties for the new collection. The keys in the
	 * hash table should be interface.property strings like
	 * `org.freedesktop.Secret.Item.Label`. The values
	 * in the hash table should be [struct@GLib.Variant] values of the properties.
	 *
	 * This method will return immediately and complete asynchronously. The secret
	 * service may prompt the user. [method@Service.prompt] will be used to handle
	 * any prompts that are required.
	 *
	 * Params:
	 *     collectionPath = the D-Bus object path of the collection in which to create item
	 *     properties = hash table of D-Bus properties
	 *         for the new collection
	 *     value = the secret value to store in the item
	 *     flags = flags for the creation of the new item
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void createItemDbusPath(string collectionPath, HashTable properties, Value value, SecretItemCreateFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_create_item_dbus_path(secretService, Str.toStringz(collectionPath), (properties is null) ? null : properties.getHashTableStruct(), (value is null) ? null : value.getValueStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish asynchronous operation to create a new item in the secret
	 * service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a new string containing the D-Bus object path
	 *     of the item
	 *
	 * Throws: GException on failure.
	 */
	public string createItemDbusPathFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto retStr = secret_service_create_item_dbus_path_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Create a new item in a secret service collection and return its D-Bus
	 * object path.
	 *
	 * It is often easier to use [func@password_store_sync] or [func@Item.create_sync]
	 * rather than using this function. Using this method requires that you setup
	 * a correct hash table of D-Bus @properties for the new collection.
	 *
	 * If the @flags contains %SECRET_ITEM_CREATE_REPLACE, then the secret
	 * service will search for an item matching the @attributes, and update that item
	 * instead of creating a new one.
	 *
	 * @properties is a set of properties for the new collection. The keys in the
	 * hash table should be interface.property strings like
	 * `org.freedesktop.Secret.Item.Label`. The values
	 * in the hash table should be [struct@GLib.Variant] values of the properties.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads. The secret service may prompt the user. [method@Service.prompt]
	 * will be used to handle any prompts that are required.
	 *
	 * Params:
	 *     collectionPath = the D-Bus path of the collection in which to create item
	 *     properties = hash table of D-Bus properties
	 *         for the new collection
	 *     value = the secret value to store in the item
	 *     flags = flags for the creation of the new item
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a new string containing the D-Bus object path
	 *     of the item
	 *
	 * Throws: GException on failure.
	 */
	public string createItemDbusPathSync(string collectionPath, HashTable properties, Value value, SecretItemCreateFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto retStr = secret_service_create_item_dbus_path_sync(secretService, Str.toStringz(collectionPath), (properties is null) ? null : properties.getHashTableStruct(), (value is null) ? null : value.getValueStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Decode a [struct@Value] into [struct@GLib.Variant] received with the Secret Service
	 * DBus API.
	 *
	 * The [struct@GLib.Variant] should have a `(oayays)` signature.
	 *
	 * A session must have already been established by the [class@Service], and
	 * the encoded secret must be valid for that session.
	 *
	 * Params:
	 *     value = the encoded secret
	 *
	 * Returns: the decoded secret value
	 */
	public Value decodeDbusSecret(Variant value)
	{
		auto __p = secret_service_decode_dbus_secret(secretService, (value is null) ? null : value.getVariantStruct());

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Value)(cast(SecretValue*) __p, true);
	}

	/**
	 * Delete a secret item from the secret service.
	 *
	 * The item is represented by its D-Bus object path. If you already have a
	 * [class@Item] proxy objects, use use [method@Item.delete] instead.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     itemPath = the D-Bus path of item to delete
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void deleteItemDbusPath(string itemPath, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_delete_item_dbus_path(secretService, Str.toStringz(itemPath), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete an asynchronous operation to delete a secret item from the secret
	 * service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: whether the deletion was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool deleteItemDbusPathFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_delete_item_dbus_path_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Delete a secret item from the secret service.
	 *
	 * The item is represented by its D-Bus object path. If you already have a
	 * [class@Item] proxy objects, use use [method@Item.delete_sync] instead.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     itemPath = the D-Bus path of item to delete
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the deletion was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool deleteItemDbusPathSync(string itemPath, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_delete_item_dbus_path_sync(secretService, Str.toStringz(itemPath), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Encodes a [struct@Value] into [struct@GLib.Variant] for use with the Secret
	 * Service DBus API.
	 *
	 * The resulting [struct@GLib.Variant] will have a `(oayays)` signature.
	 *
	 * A session must have already been established by the [class@Service].
	 *
	 * Params:
	 *     value = the secret value
	 *
	 * Returns: the encoded secret
	 */
	public Variant encodeDbusSecret(Value value)
	{
		auto __p = secret_service_encode_dbus_secret(secretService, (value is null) ? null : value.getValueStruct());

		if(__p is null)
		{
			return null;
		}

		return new Variant(cast(GVariant*) __p);
	}

	/**
	 * Ensure that the #SecretService proxy has established a session with the
	 * Secret Service.
	 *
	 * This session is used to transfer secrets.
	 *
	 * It is not normally necessary to call this method, as the session is
	 * established as necessary. You can also pass the %SECRET_SERVICE_OPEN_SESSION
	 * to [func@Service.get] in order to ensure that a session has been established
	 * by the time you get the #SecretService proxy.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void ensureSession(Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_ensure_session(secretService, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish an asynchronous operation to ensure that the #SecretService proxy
	 * has established a session with the Secret Service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: whether a session is established or not
	 *
	 * Throws: GException on failure.
	 */
	public bool ensureSessionFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_ensure_session_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Ensure that the #SecretService proxy has established a session with the
	 * Secret Service.
	 *
	 * This session is used to transfer secrets.
	 *
	 * It is not normally necessary to call this method, as the session is
	 * established as necessary. You can also pass the %SECRET_SERVICE_OPEN_SESSION
	 * to [func@Service.get_sync] in order to ensure that a session has been
	 * established by the time you get the #SecretService proxy.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether a session is established or not
	 *
	 * Throws: GException on failure.
	 */
	public bool ensureSessionSync(Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_ensure_session_sync(secretService, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Get the GObject type for collections instantiated by this service.
	 *
	 * This will always be either [class@Collection] or derived from it.
	 *
	 * Returns: the gobject type for collections
	 */
	public GType getCollectionGtype()
	{
		return secret_service_get_collection_gtype(secretService);
	}

	/**
	 * Get a list of [class@Collection] objects representing all the collections
	 * in the secret service.
	 *
	 * If the %SECRET_SERVICE_LOAD_COLLECTIONS flag was not specified when
	 * initializing #SecretService proxy object, then this method will return
	 * %NULL. Use [method@Service.load_collections] to load the collections.
	 *
	 * Returns: a
	 *     list of the collections in the secret service
	 */
	public ListG getCollections()
	{
		auto __p = secret_service_get_collections(secretService);

		if(__p is null)
		{
			return null;
		}

		return new ListG(cast(GList*) __p, true);
	}

	/**
	 * Get the flags representing what features of the #SecretService proxy
	 * have been initialized.
	 *
	 * Use [method@Service.ensure_session] or [method@Service.load_collections]
	 * to initialize further features and change the flags.
	 *
	 * Returns: the flags for features initialized
	 */
	public SecretServiceFlags getFlags()
	{
		return secret_service_get_flags(secretService);
	}
	alias getFlags = DBusProxy.getFlags;

	/**
	 * Get the GObject type for items instantiated by this service.
	 *
	 * This will always be either [class@Item] or derived from it.
	 *
	 * Returns: the gobject type for items
	 */
	public GType getItemGtype()
	{
		return secret_service_get_item_gtype(secretService);
	}

	/**
	 * Get the secret value for a secret item stored in the service.
	 *
	 * The item is represented by its D-Bus object path. If you already have a
	 * [class@Item] proxy object, use use [method@Item.get_secret] to more simply
	 * get its secret value.
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * Params:
	 *     itemPath = the D-Bus path to item to retrieve secret for
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void getSecretForDbusPath(string itemPath, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_get_secret_for_dbus_path(secretService, Str.toStringz(itemPath), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to get the secret value for an
	 * secret item stored in the service.
	 *
	 * Will return %NULL if the item is locked.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: the newly allocated secret value
	 *     for the item, which should be released with [method@Value.unref]
	 *
	 * Throws: GException on failure.
	 */
	public Value getSecretForDbusPathFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_get_secret_for_dbus_path_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err);

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
	 * Get the secret value for a secret item stored in the service.
	 *
	 * The item is represented by its D-Bus object path. If you already have a
	 * [class@Item] proxy object, use use [method@Item.load_secret_sync] to more simply
	 * get its secret value.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Will return %NULL if the item is locked.
	 *
	 * Params:
	 *     itemPath = the D-Bus path to item to retrieve secret for
	 *     cancellable = optional cancellation object
	 *
	 * Returns: the newly allocated secret value
	 *     the item, which should be released with [method@Value.unref]
	 *
	 * Throws: GException on failure.
	 */
	public Value getSecretForDbusPathSync(string itemPath, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_get_secret_for_dbus_path_sync(secretService, Str.toStringz(itemPath), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

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
	 * Get the secret values for a secret item stored in the service.
	 *
	 * The items are represented by their D-Bus object paths. If you already have
	 * [class@Item] proxy objects, use use [func@Item.load_secrets] to more simply
	 * get their secret values.
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * Params:
	 *     itemPaths = the D-Bus paths to items to retrieve secrets for
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void getSecretsForDbusPaths(string[] itemPaths, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_get_secrets_for_dbus_paths(secretService, Str.toStringzArray(itemPaths), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to get the secret values for an
	 * secret items stored in the service.
	 *
	 * Items that are locked will not be included the results.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: a newly
	 *     allocated hash table of item path keys to [struct@Value]
	 *     values.
	 *
	 * Throws: GException on failure.
	 */
	public HashTable getSecretsForDbusPathsFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_get_secrets_for_dbus_paths_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return new HashTable(cast(GHashTable*) __p, true);
	}

	/**
	 * Get the secret values for a secret item stored in the service.
	 *
	 * The items are represented by their D-Bus object paths. If you already have
	 * [class@Item] proxy objects, use use [func@Item.load_secrets_sync] to more
	 * simply get their secret values.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Items that are locked will not be included the results.
	 *
	 * Params:
	 *     itemPaths = the D-Bus paths to items to retrieve secrets for
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a newly
	 *     allocated hash table of item_path keys to [struct@Value]
	 *     values.
	 *
	 * Throws: GException on failure.
	 */
	public HashTable getSecretsForDbusPathsSync(string[] itemPaths, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_get_secrets_for_dbus_paths_sync(secretService, Str.toStringzArray(itemPaths), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return new HashTable(cast(GHashTable*) __p, true);
	}

	/**
	 * Get the set of algorithms being used to transfer secrets between this
	 * secret service proxy and the Secret Service itself.
	 *
	 * This will be %NULL if no session has been established. Use
	 * [method@Service.ensure_session] to establish a session.
	 *
	 * Returns: a string representing the algorithms for transferring
	 *     secrets
	 */
	public string getSessionAlgorithms()
	{
		return Str.toString(secret_service_get_session_algorithms(secretService));
	}

	/**
	 * Get the D-Bus object path of the session object being used to transfer
	 * secrets between this secret service proxy and the Secret Service itself.
	 *
	 * This will be %NULL if no session has been established. Use
	 * [method@Service.ensure_session] to establish a session.
	 *
	 * Returns: a string representing the D-Bus object path of the
	 *     session
	 */
	public string getSessionDbusPath()
	{
		return Str.toString(secret_service_get_session_dbus_path(secretService));
	}

	/**
	 * Ensure that the #SecretService proxy has loaded all the collections present
	 * in the Secret Service.
	 *
	 * This affects the result of [method@Service.get_collections].
	 *
	 * You can also pass the %SECRET_SERVICE_LOAD_COLLECTIONS to
	 * [func@Service.get_sync] in order to ensure that the collections have been
	 * loaded by the time you get the #SecretService proxy.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void loadCollections(Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_load_collections(secretService, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete an asynchronous operation to ensure that the #SecretService proxy
	 * has loaded all the collections present in the Secret Service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: whether the load was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool loadCollectionsFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_load_collections_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Ensure that the #SecretService proxy has loaded all the collections present
	 * in the Secret Service.
	 *
	 * This affects the result of [method@Service.get_collections].
	 *
	 * You can also pass the %SECRET_SERVICE_LOAD_COLLECTIONS to
	 * [func@Service.get_sync] in order to ensure that the collections have been
	 * loaded by the time you get the #SecretService proxy.
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
	public bool loadCollectionsSync(Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_load_collections_sync(secretService, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Lock items or collections in the secret service.
	 *
	 * The secret service may not be able to lock items individually, and may
	 * lock an entire collection instead.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method returns immediately and completes asynchronously. The secret
	 * service may prompt the user. [method@Service.prompt] will be used to handle
	 * any prompts that show up.
	 *
	 * Params:
	 *     objects = the items or collections to lock
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void lock(ListG objects, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_lock(secretService, (objects is null) ? null : objects.getListGStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Lock items or collections in the secret service.
	 *
	 * The items or collections are represented by their D-Bus object paths. If you
	 * already have [class@Item] and [class@Collection] proxy objects, use use
	 * [method@Service.lock] instead.
	 *
	 * The secret service may not be able to lock items individually, and may
	 * lock an entire collection instead.
	 *
	 * This method returns immediately and completes asynchronously. The secret
	 * service may prompt the user. [method@Service.prompt] will be used to handle
	 * any prompts that show up.
	 *
	 * Params:
	 *     paths = the D-Bus paths for items or collections to lock
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void lockDbusPaths(string[] paths, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_lock_dbus_paths(secretService, Str.toStringzArray(paths), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to lock items or collections in the secret
	 * service.
	 *
	 * The secret service may not be able to lock items individually, and may
	 * lock an entire collection instead.
	 *
	 * Params:
	 *     result = asynchronous result passed to the callback
	 *     locked = location to place array of D-Bus paths of items or collections
	 *         that were locked
	 *
	 * Returns: the number of items or collections that were locked
	 *
	 * Throws: GException on failure.
	 */
	public int lockDbusPathsFinish(AsyncResultIF result, out string[] locked)
	{
		char** outlocked = null;
		GError* err = null;

		auto __p = secret_service_lock_dbus_paths_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &outlocked, &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		locked = Str.toStringArray(outlocked);

		return __p;
	}

	/**
	 * Lock items or collections in the secret service.
	 *
	 * The items or collections are represented by their D-Bus object paths. If you
	 * already have [class@Item] and [class@Collection] proxy objects, use use
	 * [method@Service.lock_sync] instead.
	 *
	 * The secret service may not be able to lock items individually, and may
	 * lock an entire collection instead.
	 *
	 * This method may block indefinitely and should not be used in user
	 * interface threads. The secret service may prompt the user.
	 * [method@Service.prompt] will be used to handle any prompts that show up.
	 *
	 * Params:
	 *     paths = the D-Bus object paths of the items or collections to lock
	 *     cancellable = optional cancellation object
	 *     locked = location to place array of D-Bus paths of items or collections
	 *         that were locked
	 *
	 * Returns: the number of items or collections that were locked
	 *
	 * Throws: GException on failure.
	 */
	public int lockDbusPathsSync(string[] paths, Cancellable cancellable, out string[] locked)
	{
		char** outlocked = null;
		GError* err = null;

		auto __p = secret_service_lock_dbus_paths_sync(secretService, Str.toStringzArray(paths), (cancellable is null) ? null : cancellable.getCancellableStruct(), &outlocked, &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		locked = Str.toStringArray(outlocked);

		return __p;
	}

	/**
	 * Complete asynchronous operation to lock items or collections in the secret
	 * service.
	 *
	 * The secret service may not be able to lock items individually, and may
	 * lock an entire collection instead.
	 *
	 * Params:
	 *     result = asynchronous result passed to the callback
	 *     locked = location to place list of items or collections that were locked
	 *
	 * Returns: the number of items or collections that were locked
	 *
	 * Throws: GException on failure.
	 */
	public int lockFinish(AsyncResultIF result, out ListG locked)
	{
		GList* outlocked = null;
		GError* err = null;

		auto __p = secret_service_lock_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &outlocked, &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		locked = new ListG(outlocked);

		return __p;
	}

	/**
	 * Lock items or collections in the secret service.
	 *
	 * The secret service may not be able to lock items individually, and may
	 * lock an entire collection instead.
	 *
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method may block indefinitely and should not be used in user
	 * interface threads. The secret service may prompt the user.
	 * [method@Service.prompt] will be used to handle any prompts that show up.
	 *
	 * Params:
	 *     objects = the items or collections to lock
	 *     cancellable = optional cancellation object
	 *     locked = location to place list of items or collections that were locked
	 *
	 * Returns: the number of items or collections that were locked
	 *
	 * Throws: GException on failure.
	 */
	public int lockSync(ListG objects, Cancellable cancellable, out ListG locked)
	{
		GList* outlocked = null;
		GError* err = null;

		auto __p = secret_service_lock_sync(secretService, (objects is null) ? null : objects.getListGStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &outlocked, &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		locked = new ListG(outlocked);

		return __p;
	}

	/**
	 * Lookup a secret value in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get
	 * the default [class@Service] proxy.
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
	public void lookup(Schema schema, HashTable attributes, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_lookup(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish asynchronous operation to lookup a secret value in the secret service.
	 *
	 * If no secret is found then %NULL is returned.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: a newly allocated [struct@Value], which should be
	 *     released with [method@Value.unref], or %NULL if no secret found
	 *
	 * Throws: GException on failure.
	 */
	public Value lookupFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_lookup_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err);

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
	 * Lookup a secret value in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = the attribute keys and values
	 *     cancellable = optional cancellation object
	 *
	 * Returns: a newly allocated [struct@Value], which should be
	 *     released with [method@Value.unref], or %NULL if no secret found
	 *
	 * Throws: GException on failure.
	 */
	public Value lookupSync(Schema schema, HashTable attributes, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_lookup_sync(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

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
	 * Perform prompting for a [class@Prompt].
	 *
	 * This function is called by other parts of this library to handle prompts
	 * for the various actions that can require prompting.
	 *
	 * Override the #SecretServiceClass [vfunc@Service.prompt_async] virtual method
	 * to change the behavior of the prompting. The default behavior is to simply
	 * run [method@Prompt.perform] on the prompt.
	 *
	 * Params:
	 *     prompt = the prompt
	 *     returnType = the variant type of the prompt result
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void prompt(Prompt prompt, VariantType returnType, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_prompt(secretService, (prompt is null) ? null : prompt.getPromptStruct(), (returnType is null) ? null : returnType.getVariantTypeStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Perform prompting for a [class@Prompt].
	 *
	 * This function is called by other parts of this library to handle prompts
	 * for the various actions that can require prompting.
	 *
	 * Override the #SecretServiceClass [vfunc@Service.prompt_async] virtual method
	 * to change the behavior of the propmting. The default behavior is to simply
	 * run [method@Prompt.perform] on the prompt.
	 *
	 * Params:
	 *     promptPath = the D-Bus object path of the prompt
	 *     returnType = the variant type of the prompt result
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void promptAtDbusPath(string promptPath, VariantType returnType, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_prompt_at_dbus_path(secretService, Str.toStringz(promptPath), (returnType is null) ? null : returnType.getVariantTypeStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to perform prompting for a [class@Prompt].
	 *
	 * Returns a variant result if the prompt was completed and not dismissed. The
	 * type of result depends on the action the prompt is completing, and is defined
	 * in the Secret Service DBus API specification.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: %NULL if the prompt was dismissed or an
	 *     error occurred, a variant result if the prompt was successful
	 *
	 * Throws: GException on failure.
	 */
	public Variant promptAtDbusPathFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_prompt_at_dbus_path_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return new Variant(cast(GVariant*) __p, true);
	}

	/**
	 * Perform prompting for a [class@Prompt].
	 *
	 * Override the #SecretServiceClass [vfunc@Service.prompt_async] virtual method
	 * to change the behavior of the propmting. The default behavior is to simply
	 * run [method@Prompt.perform] on the prompt.
	 *
	 * Returns a variant result if the prompt was completed and not dismissed. The
	 * type of result depends on the action the prompt is completing, and is defined
	 * in the Secret Service DBus API specification.
	 *
	 * This method may block and should not be used in user interface threads.
	 *
	 * Params:
	 *     promptPath = the D-Bus object path of the prompt
	 *     cancellable = optional cancellation object
	 *     returnType = the variant type of the prompt result
	 *
	 * Returns: %NULL if the prompt was dismissed or an
	 *     error occurred, a variant result if the prompt was successful
	 *
	 * Throws: GException on failure.
	 */
	public Variant promptAtDbusPathSync(string promptPath, Cancellable cancellable, VariantType returnType)
	{
		GError* err = null;

		auto __p = secret_service_prompt_at_dbus_path_sync(secretService, Str.toStringz(promptPath), (cancellable is null) ? null : cancellable.getCancellableStruct(), (returnType is null) ? null : returnType.getVariantTypeStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return new Variant(cast(GVariant*) __p, true);
	}

	/**
	 * Complete asynchronous operation to perform prompting for a [class@Prompt].
	 *
	 * Returns a variant result if the prompt was completed and not dismissed. The
	 * type of result depends on the action the prompt is completing, and is defined
	 * in the Secret Service DBus API specification.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: %NULL if the prompt was dismissed or an error occurred,
	 *     a variant result if the prompt was successful
	 *
	 * Throws: GException on failure.
	 */
	public Variant promptFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_prompt_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return new Variant(cast(GVariant*) __p, true);
	}

	/**
	 * Perform prompting for a [class@Prompt].
	 *
	 * Runs a prompt and performs the prompting. Returns a variant result if the
	 * prompt was completed and not dismissed. The type of result depends on the
	 * action the prompt is completing, and is defined in the Secret Service DBus
	 * API specification.
	 *
	 * This function is called by other parts of this library to handle prompts
	 * for the various actions that can require prompting.
	 *
	 * Override the #SecretServiceClass [vfunc@Service.prompt_sync] virtual method
	 * to change the behavior of the prompting. The default behavior is to simply
	 * run [method@Prompt.perform_sync] on the prompt with a %NULL `window_id`.
	 *
	 * Params:
	 *     prompt = the prompt
	 *     cancellable = optional cancellation object
	 *     returnType = the variant type of the prompt result
	 *
	 * Returns: %NULL if the prompt was dismissed or an error occurred,
	 *     a variant result if the prompt was successful
	 *
	 * Throws: GException on failure.
	 */
	public Variant promptSync(Prompt prompt, Cancellable cancellable, VariantType returnType)
	{
		GError* err = null;

		auto __p = secret_service_prompt_sync(secretService, (prompt is null) ? null : prompt.getPromptStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), (returnType is null) ? null : returnType.getVariantTypeStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return new Variant(cast(GVariant*) __p, true);
	}

	/**
	 * Lookup which collection is assigned to this alias.
	 *
	 * Aliases help determine well known collections, such as 'default'. This method
	 * looks up the dbus object path of the well known collection.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     alias_ = the alias to lookup
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void readAliasDbusPath(string alias_, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_read_alias_dbus_path(secretService, Str.toStringz(alias_), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish an asynchronous operation to lookup which collection is assigned
	 * to an alias.
	 *
	 * This method returns the DBus object path of the collection
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: the collection dbus object path,
	 *     or %NULL if none assigned to the alias
	 *
	 * Throws: GException on failure.
	 */
	public string readAliasDbusPathFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto retStr = secret_service_read_alias_dbus_path_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Lookup which collection is assigned to this alias.
	 *
	 * Aliases help determine well known collections, such as 'default'. This method
	 * returns the dbus object path of the collection.
	 *
	 * This method may block and should not be used in user interface threads.
	 *
	 * Params:
	 *     alias_ = the alias to lookup
	 *     cancellable = optional cancellation object
	 *
	 * Returns: the collection dbus object path,
	 *     or %NULL if none assigned to the alias
	 *
	 * Throws: GException on failure.
	 */
	public string readAliasDbusPathSync(string alias_, Cancellable cancellable)
	{
		GError* err = null;

		auto retStr = secret_service_read_alias_dbus_path_sync(secretService, Str.toStringz(alias_), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Search for items matching the @attributes.
	 *
	 * All collections are searched. The @attributes should be a table of string
	 * keys and string values.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get
	 * the default [class@Service] proxy.
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
		secret_service_search(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to search for items.
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

		auto __p = secret_service_search_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err);

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
	 * Search for items matching the @attributes, and return their D-Bus object paths.
	 *
	 * All collections are searched. The @attributes should be a table of string keys
	 * and string values.
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * When your callback is called use [method@Service.search_for_dbus_paths_finish]
	 * to get the results of this function. Only the D-Bus object paths of the
	 * items will be returned. If you would like [class@Item] objects to be returned
	 * instead, then use the [method@Service.search] function.
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
		secret_service_search_for_dbus_paths(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to search for items, and return their
	 * D-Bus object paths.
	 *
	 * Matching items that are locked or unlocked, have their D-Bus paths placed
	 * in the @locked or @unlocked arrays respectively.
	 *
	 * D-Bus object paths of the items will be returned in the @unlocked or
	 * @locked arrays. If you would to have [class@Item] objects to be returned
	 * instead, then us the [method@Service.search] and
	 * [method@Service.search_finish] functions.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *     unlocked = location to place an array of D-Bus object paths for matching
	 *         items which were locked.
	 *     locked = location to place an array of D-Bus object paths for matching
	 *         items which were locked.
	 *
	 * Returns: whether the search was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool searchForDbusPathsFinish(AsyncResultIF result, out string[] unlocked, out string[] locked)
	{
		char** outunlocked = null;
		char** outlocked = null;
		GError* err = null;

		auto __p = secret_service_search_for_dbus_paths_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &outunlocked, &outlocked, &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		unlocked = Str.toStringArray(outunlocked);
		locked = Str.toStringArray(outlocked);

		return __p;
	}

	/**
	 * Search for items matching the @attributes, and return their D-Bus object
	 * paths.
	 *
	 * All collections are searched. The @attributes should be a table of string
	 * keys and string values.
	 *
	 * This function may block indefinitely. Use the asynchronous version
	 * in user interface threads.
	 *
	 * Matching items that are locked or unlocked, have their D-Bus paths placed
	 * in the @locked or @unlocked arrays respectively.
	 *
	 * D-Bus object paths of the items will be returned in the @unlocked or
	 * @locked arrays. If you would to have [class@Item] objects to be returned
	 * instead, then use the [method@Service.search_sync] function.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = search for items matching these attributes
	 *     cancellable = optional cancellation object
	 *     unlocked = location to place an array of D-Bus object paths for matching
	 *         items which were locked.
	 *     locked = location to place an array of D-Bus object paths for matching
	 *         items which were locked.
	 *
	 * Returns: whether the search was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool searchForDbusPathsSync(Schema schema, HashTable attributes, Cancellable cancellable, out string[] unlocked, out string[] locked)
	{
		char** outunlocked = null;
		char** outlocked = null;
		GError* err = null;

		auto __p = secret_service_search_for_dbus_paths_sync(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &outunlocked, &outlocked, &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		unlocked = Str.toStringArray(outunlocked);
		locked = Str.toStringArray(outlocked);

		return __p;
	}

	/**
	 * Search for items matching the @attributes.
	 *
	 * All collections are searched. The @attributes should be a table of string
	 * keys and string values.
	 *
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * If %SECRET_SEARCH_ALL is set in @flags, then all the items matching the
	 * search will be returned. Otherwise only the first item will be returned.
	 * This is almost always the unlocked item that was most recently stored.
	 *
	 * If %SECRET_SEARCH_UNLOCK is set in @flags, then items will be unlocked
	 * if necessary. In either case, locked and unlocked items will match the
	 * search and be returned. If the unlock fails, the search does not fail.
	 *
	 * If %SECRET_SEARCH_LOAD_SECRETS is set in @flags, then the items' secret
	 * values will be loaded for any unlocked items. Loaded item secret values
	 * are available via [method@Item.get_secret]. If the load of a secret values
	 * fail, then the
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

		auto __p = secret_service_search_sync(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

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
	 * Assign a collection to this alias.
	 *
	 * Aliases help determine well known collections, such as 'default'.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     alias_ = the alias to assign the collection to
	 *     collection = the collection to assign to the alias
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void setAlias(string alias_, Collection collection, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_set_alias(secretService, Str.toStringz(alias_), (collection is null) ? null : collection.getCollectionStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish an asynchronous operation to assign a collection to an alias.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: %TRUE if successful
	 *
	 * Throws: GException on failure.
	 */
	public bool setAliasFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_set_alias_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Assign a collection to this alias. Aliases help determine
	 * well known collections, such as 'default'.
	 *
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method may block and should not be used in user interface threads.
	 *
	 * Params:
	 *     alias_ = the alias to assign the collection to
	 *     collection = the collection to assign to the alias
	 *     cancellable = optional cancellation object
	 *
	 * Returns: %TRUE if successful
	 *
	 * Throws: GException on failure.
	 */
	public bool setAliasSync(string alias_, Collection collection, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_set_alias_sync(secretService, Str.toStringz(alias_), (collection is null) ? null : collection.getCollectionStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Assign a collection to this alias. Aliases help determine
	 * well known collections, such as 'default'. This method takes the dbus object
	 * path of the collection to assign to the alias.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     alias_ = the alias to assign the collection to
	 *     collectionPath = the dbus object path of the collection to assign to the alias
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void setAliasToDbusPath(string alias_, string collectionPath, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_set_alias_to_dbus_path(secretService, Str.toStringz(alias_), Str.toStringz(collectionPath), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish an asynchronous operation to assign a collection to an alias.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: %TRUE if successful
	 *
	 * Throws: GException on failure.
	 */
	public bool setAliasToDbusPathFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_set_alias_to_dbus_path_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Assign a collection to this alias.
	 *
	 * Aliases help determine well known collections, such as 'default'. This method
	 * takes the dbus object path of the collection to assign to the alias.
	 *
	 * This method may block and should not be used in user interface threads.
	 *
	 * Params:
	 *     alias_ = the alias to assign the collection to
	 *     collectionPath = the D-Bus object path of the collection to
	 *         assign to the alias
	 *     cancellable = optional cancellation object
	 *
	 * Returns: %TRUE if successful
	 *
	 * Throws: GException on failure.
	 */
	public bool setAliasToDbusPathSync(string alias_, string collectionPath, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_set_alias_to_dbus_path_sync(secretService, Str.toStringz(alias_), Str.toStringz(collectionPath), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Store a secret value in the secret service.
	 *
	 * The @attributes should be a set of key and value string pairs.
	 *
	 * If the attributes match a secret item already stored in the collection, then
	 * the item will be updated with these new values.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * If @collection is not specified, then the default collection will be
	 * used. Use [const@COLLECTION_SESSION] to store the password in the session
	 * collection, which doesn't get stored across login sessions.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     schema = the schema to use to check attributes
	 *     attributes = the attribute keys and values
	 *     collection = a collection alias, or D-Bus object path of the
	 *         collection where to store the secret
	 *     label = label for the secret
	 *     value = the secret value
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void store(Schema schema, HashTable attributes, string collection, string label, Value value, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_store(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), Str.toStringz(collection), Str.toStringz(label), (value is null) ? null : value.getValueStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish asynchronous operation to store a secret value in the secret service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: whether the storage was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool storeFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_service_store_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Store a secret value in the secret service.
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
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = the attribute keys and values
	 *     collection = a collection alias, or D-Bus object path of the
	 *         collection where to store the secret
	 *     label = label for the secret
	 *     value = the secret value
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the storage was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool storeSync(Schema schema, HashTable attributes, string collection, string label, Value value, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_service_store_sync(secretService, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), Str.toStringz(collection), Str.toStringz(label), (value is null) ? null : value.getValueStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Unlock items or collections in the secret service.
	 *
	 * The secret service may not be able to unlock items individually, and may
	 * unlock an entire collection instead.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method may block indefinitely and should not be used in user
	 * interface threads. The secret service may prompt the user.
	 * [method@Service.prompt] will be used to handle any prompts that show up.
	 *
	 * Params:
	 *     objects = the items or collections to unlock
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void unlock(ListG objects, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_unlock(secretService, (objects is null) ? null : objects.getListGStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Unlock items or collections in the secret service.
	 *
	 * The items or collections are represented by their D-Bus object paths. If you
	 * already have [class@Item] and [class@Collection] proxy objects, use use
	 * [method@Service.unlock] instead.
	 *
	 * The secret service may not be able to unlock items individually, and may
	 * unlock an entire collection instead.
	 *
	 * This method returns immediately and completes asynchronously. The secret
	 * service may prompt the user. [method@Service.prompt] will be used to handle
	 * any prompts that show up.
	 *
	 * Params:
	 *     paths = the D-Bus paths for items or
	 *         collections to unlock
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void unlockDbusPaths(string[] paths, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_service_unlock_dbus_paths(secretService, Str.toStringzArray(paths), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to unlock items or collections in the secret
	 * service.
	 *
	 * The secret service may not be able to unlock items individually, and may
	 * unlock an entire collection instead.
	 *
	 * Params:
	 *     result = asynchronous result passed to the callback
	 *     unlocked = location to place array of D-Bus paths of items or collections
	 *         that were unlocked
	 *
	 * Returns: the number of items or collections that were unlocked
	 *
	 * Throws: GException on failure.
	 */
	public int unlockDbusPathsFinish(AsyncResultIF result, out string[] unlocked)
	{
		char** outunlocked = null;
		GError* err = null;

		auto __p = secret_service_unlock_dbus_paths_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &outunlocked, &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		unlocked = Str.toStringArray(outunlocked);

		return __p;
	}

	/**
	 * Unlock items or collections in the secret service.
	 *
	 * The items or collections are represented by their D-Bus object paths. If you
	 * already have [class@Item] and [class@Collection] proxy objects, use use
	 * [method@Service.unlock_sync] instead.
	 *
	 * The secret service may not be able to unlock items individually, and may
	 * unlock an entire collection instead.
	 *
	 * This method may block indefinitely and should not be used in user
	 * interface threads. The secret service may prompt the user.
	 * [method@Service.prompt] will be used to handle any prompts that show up.
	 *
	 * Params:
	 *     paths = the D-Bus object paths of the items or
	 *         collections to unlock
	 *     cancellable = optional cancellation object
	 *     unlocked = location to place array of D-Bus paths of items or collections
	 *         that were unlocked
	 *
	 * Returns: the number of items or collections that were unlocked
	 *
	 * Throws: GException on failure.
	 */
	public int unlockDbusPathsSync(string[] paths, Cancellable cancellable, out string[] unlocked)
	{
		char** outunlocked = null;
		GError* err = null;

		auto __p = secret_service_unlock_dbus_paths_sync(secretService, Str.toStringzArray(paths), (cancellable is null) ? null : cancellable.getCancellableStruct(), &outunlocked, &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		unlocked = Str.toStringArray(outunlocked);

		return __p;
	}

	/**
	 * Complete asynchronous operation to unlock items or collections in the secret
	 * service.
	 *
	 * The secret service may not be able to unlock items individually, and may
	 * unlock an entire collection instead.
	 *
	 * Params:
	 *     result = asynchronous result passed to the callback
	 *     unlocked = location to place list of items or collections that were unlocked
	 *
	 * Returns: the number of items or collections that were unlocked
	 *
	 * Throws: GException on failure.
	 */
	public int unlockFinish(AsyncResultIF result, out ListG unlocked)
	{
		GList* outunlocked = null;
		GError* err = null;

		auto __p = secret_service_unlock_finish(secretService, (result is null) ? null : result.getAsyncResultStruct(), &outunlocked, &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		unlocked = new ListG(outunlocked);

		return __p;
	}

	/**
	 * Unlock items or collections in the secret service.
	 *
	 * The secret service may not be able to unlock items individually, and may
	 * unlock an entire collection instead.
	 *
	 * If @service is %NULL, then [func@Service.get_sync] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method may block indefinitely and should not be used in user
	 * interface threads. The secret service may prompt the user.
	 * [method@Service.prompt] will be used to handle any prompts that show up.
	 *
	 * Params:
	 *     objects = the items or collections to unlock
	 *     cancellable = optional cancellation object
	 *     unlocked = location to place list of items or collections that were unlocked
	 *
	 * Returns: the number of items or collections that were unlocked
	 *
	 * Throws: GException on failure.
	 */
	public int unlockSync(ListG objects, Cancellable cancellable, out ListG unlocked)
	{
		GList* outunlocked = null;
		GError* err = null;

		auto __p = secret_service_unlock_sync(secretService, (objects is null) ? null : objects.getListGStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &outunlocked, &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		unlocked = new ListG(outunlocked);

		return __p;
	}
}
