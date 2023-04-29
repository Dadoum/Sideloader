module secret.Item;

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
private import secret.Collection;
private import secret.RetrievableIF;
private import secret.RetrievableT;
private import secret.Schema;
private import secret.Service;
private import secret.Value;
private import secret.c.functions;
public  import secret.c.types;


/**
 * A secret item
 * 
 * #SecretItem represents a secret item stored in the Secret Service.
 * 
 * Each item has a value, represented by a [struct@Value], which can be
 * retrieved by [method@Item.get_secret] or set by [method@Item.set_secret].
 * The item is only available when the item is not locked.
 * 
 * Items can be locked or unlocked using the [method@Service.lock] or
 * [method@Service.unlock] functions. The Secret Service may not be able to
 * unlock individual items, and may unlock an entire collection when a single
 * item is unlocked.
 * 
 * Each item has a set of attributes, which are used to locate the item later.
 * These are not stored or transferred in a secure manner. Each attribute has
 * a string name and a string value. Use [method@Service.search] to search for
 * items based on their attributes, and [method@Item.set_attributes] to change
 * the attributes associated with an item.
 * 
 * Items can be created with [func@Item.create] or [method@Service.store].
 */
public class Item : DBusProxy, RetrievableIF
{
    /** the main Gtk struct */
    protected SecretItem* secretItem;

    /** Get the main Gtk struct */
    public SecretItem* getItemStruct(bool transferOwnership = false)
    {
        if (transferOwnership)
            ownedRef = false;
        return secretItem;
    }

    /** the main Gtk struct as a void* */
    protected override void* getStruct()
    {
        return cast(void*)secretItem;
    }

    /**
     * Sets our main struct and passes it to the parent class.
     */
    public this (SecretItem* secretItem, bool ownedRef = false)
    {
        this.secretItem = secretItem;
        super(cast(GDBusProxy*)secretItem, ownedRef);
    }

    // add the Retrievable capabilities
    mixin RetrievableT!(SecretItem);


    /** */
    public static GType getType()
    {
        return secret_item_get_type();
    }

    /**
     * Finish asynchronous operation to get a new item proxy for a secret
     * item in the secret service.
     *
     * Params:
     *     result = the asynchronous result passed to the callback
     *
     * Returns: the new item, which should be unreferenced
     *     with [method@GObject.Object.unref]
     *
     * Throws: GException on failure.
     * Throws: ConstructionException GTK+ fails to create the object.
     */
    public this(AsyncResultIF result)
    {
        GError* err = null;

        auto __p = secret_item_new_for_dbus_path_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

        if (err !is null)
        {
            throw new GException( new ErrorG(err) );
        }

        if(__p is null)
        {
            throw new ConstructionException("null returned by new_for_dbus_path_finish");
        }

        this(cast(SecretItem*) __p, true);
    }

    /**
     * Get a new item proxy for a secret item in the secret service.
     *
     * If @service is %NULL, then [func@Service.get_sync] will be called to get
     * the default [class@Service] proxy.
     *
     * This method may block indefinitely and should not be used in user interface
     * threads.
     *
     * Params:
     *     service = a secret service object
     *     itemPath = the D-Bus path of the item
     *     flags = initialization flags for the new item
     *     cancellable = optional cancellation object
     *
     * Returns: the new item, which should be unreferenced
     *     with [method@GObject.Object.unref]
     *
     * Throws: GException on failure.
     * Throws: ConstructionException GTK+ fails to create the object.
     */
    public this(Service service, string itemPath, SecretItemFlags flags, Cancellable cancellable)
    {
        GError* err = null;

        auto __p = secret_item_new_for_dbus_path_sync((service is null) ? null : service.getServiceStruct(), Str.toStringz(itemPath), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

        if (err !is null)
        {
            throw new GException( new ErrorG(err) );
        }

		if(__p is null)
		{
			throw new ConstructionException("null returned by new_for_dbus_path_sync");
		}

		this(cast(SecretItem*) __p, true);
	}

	/**
	 * Create a new item in the secret service.
	 *
	 * If the @flags contains %SECRET_ITEM_CREATE_REPLACE, then the secret
	 * service will search for an item matching the @attributes, and update that item
	 * instead of creating a new one.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads. The secret service may prompt the user. [method@Service.prompt]
	 * will be used to handle any prompts that are required.
	 *
	 * Params:
	 *     collection = a secret collection to create this item in
	 *     schema = the schema for the attributes
	 *     attributes = attributes for the new item
	 *     label = label for the new item
	 *     value = secret value for the new item
	 *     flags = flags for the creation of the new item
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public static void create(Collection collection, Schema schema, HashTable attributes, string label, Value value, SecretItemCreateFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_item_create((collection is null) ? null : collection.getCollectionStruct(), (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), Str.toStringz(label), (value is null) ? null : value.getValueStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Finish operation to create a new item in the secret service.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: the new item, which should be unreferenced
	 *     with [method@GObject.Object.unref]
	 *
	 * Throws: GException on failure.
	 */
	public static Item createFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_item_create_finish((result is null) ? null : result.getAsyncResultStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Item)(cast(SecretItem*) __p, true);
	}

	/**
	 * Create a new item in the secret service.
	 *
	 * If the @flags contains %SECRET_ITEM_CREATE_REPLACE, then the secret
	 * service will search for an item matching the @attributes, and update that item
	 * instead of creating a new one.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads. The secret service may prompt the user. [method@Service.prompt]
	 * will be used to handle any prompts that are required.
	 *
	 * Params:
	 *     collection = a secret collection to create this item in
	 *     schema = the schema for the attributes
	 *     attributes = attributes for the new item
	 *     label = label for the new item
	 *     value = secret value for the new item
	 *     flags = flags for the creation of the new item
	 *     cancellable = optional cancellation object
	 *
	 * Returns: the new item, which should be unreferenced
	 *     with [method@GObject.Object.unref]
	 *
	 * Throws: GException on failure.
	 */
	public static Item createSync(Collection collection, Schema schema, HashTable attributes, string label, Value value, SecretItemCreateFlags flags, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_item_create_sync((collection is null) ? null : collection.getCollectionStruct(), (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), Str.toStringz(label), (value is null) ? null : value.getValueStruct(), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err);

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Item)(cast(SecretItem*) __p, true);
	}

	/**
	 * Load the secret values for a secret item stored in the service.
	 *
	 * The @items must all have the same [property@Item:service] property.
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * Params:
	 *     items = the items to retrieve secrets for
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public static void loadSecrets(ListG items, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_item_load_secrets((items is null) ? null : items.getListGStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to load the secret values for
	 * secret items stored in the service.
	 *
	 * Items that are locked will not have their secrets loaded.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: whether the operation succeeded or not
	 *
	 * Throws: GException on failure.
	 */
	public static bool loadSecretsFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_item_load_secrets_finish((result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Load the secret values for a secret item stored in the service.
	 *
	 * The @items must all have the same [property@Item:service] property.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Items that are locked will not have their secrets loaded.
	 *
	 * Params:
	 *     items = the items to retrieve secrets for
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the operation succeeded or not
	 *
	 * Throws: GException on failure.
	 */
	public static bool loadSecretsSync(ListG items, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_item_load_secrets_sync((items is null) ? null : items.getListGStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Get a new item proxy for a secret item in the secret service.
	 *
	 * If @service is %NULL, then [func@Service.get] will be called to get
	 * the default [class@Service] proxy.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     service = a secret service object
	 *     itemPath = the D-Bus path of the collection
	 *     flags = initialization flags for the new item
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public static void newForDbusPath(Service service, string itemPath, SecretItemFlags flags, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_item_new_for_dbus_path((service is null) ? null : service.getServiceStruct(), Str.toStringz(itemPath), flags, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	alias delet = delete_;
	/**
	 * Delete this item.
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
		secret_item_delete(secretItem, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to delete the secret item.
	 *
	 * Params:
	 *     result = asynchronous result passed to the callback
	 *
	 * Returns: whether the item was successfully deleted or not
	 *
	 * Throws: GException on failure.
	 */
	public bool deleteFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_item_delete_finish(secretItem, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Delete this secret item.
	 *
	 * This method may block indefinitely and should not be used in user
	 * interface threads. The secret service may prompt the user.
	 * [method@Service.prompt] will be used to handle any prompts that show up.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the item was successfully deleted or not
	 *
	 * Throws: GException on failure.
	 */
	public bool deleteSync(Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_item_delete_sync(secretItem, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Set the attributes of this item.
	 *
	 * The @attributes are a mapping of string keys to string values.
	 * Attributes are used to search for items. Attributes are not stored
	 * or transferred securely by the secret service.
	 *
	 * Do not modify the attributes returned by this method. Use
	 * [method@Item.set_attributes] instead.
	 *
	 * Returns: a new reference
	 *     to the attributes, which should not be modified, and
	 *     released with [func@GLib.HashTable.unref]
	 */
	public HashTable getAttributes()
	{
		auto __p = secret_item_get_attributes(secretItem);

		if(__p is null)
		{
			return null;
		}

		return new HashTable(cast(GHashTable*) __p, true);
	}

	/**
	 * Get the created date and time of the item.
	 *
	 * The return value is the number of seconds since the unix epoch, January 1st
	 * 1970.
	 *
	 * Returns: the created date and time
	 */
	public ulong getCreated()
	{
		return secret_item_get_created(secretItem);
	}

	alias getFlags = DBusProxy.getFlags;

	/**
	 * Get the flags representing what features of the #SecretItem proxy
	 * have been initialized.
	 *
	 * Use [method@Item.load_secret] to initialize further features
	 * and change the flags.
	 *
	 * Returns: the flags for features initialized
	 */
	public SecretItemFlags getFlags()
	{
		return secret_item_get_flags(secretItem);
	}

	/**
	 * Get the label of this item.
	 *
	 * Returns: the label, which should be freed with [func@GLib.free]
	 */
	public string getLabel()
	{
		auto retStr = secret_item_get_label(secretItem);

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Get whether the item is locked or not.
	 *
	 * Depending on the secret service an item may not be able to be locked
	 * independently from the collection that it is in.
	 *
	 * Returns: whether the item is locked or not
	 */
	public bool getLocked()
	{
		return secret_item_get_locked(secretItem) != 0;
	}

	/**
	 * Get the modified date and time of the item.
	 *
	 * The return value is the number of seconds since the unix epoch, January 1st
	 * 1970.
	 *
	 * Returns: the modified date and time
	 */
	public ulong getModified()
	{
		return secret_item_get_modified(secretItem);
	}

	/**
	 * Gets the name of the schema that this item was stored with. This is also
	 * available at the `xdg:schema` attribute.
	 *
	 * Returns: the schema name
	 */
	public string getSchemaName()
	{
		auto retStr = secret_item_get_schema_name(secretItem);

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}

	/**
	 * Get the secret value of this item.
	 *
	 * If this item is locked or the secret has not yet been loaded then this will
	 * return %NULL.
	 *
	 * To load the secret call the [method@Item.load_secret] method.
	 *
	 * Returns: the secret value which should be
	 *     released with [method@Value.unref], or %NULL
	 */
	public Value getSecret()
	{
		auto __p = secret_item_get_secret(secretItem);

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Value)(cast(SecretValue*) __p, true);
	}

	/**
	 * Get the Secret Service object that this item was created with.
	 *
	 * Returns: the Secret Service object
	 */
	public Service getService()
	{
		auto __p = secret_item_get_service(secretItem);

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Service)(cast(SecretService*) __p);
	}

	/**
	 * Load the secret value of this item.
	 *
	 * Each item has a single secret which might be a password or some
	 * other secret binary value.
	 *
	 * This function will fail if the secret item is locked.
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void loadSecret(Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_item_load_secret(secretItem, (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to load the secret value of this item.
	 *
	 * The newly loaded secret value can be accessed by calling
	 * [method@Item.get_secret].
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: whether the secret item successfully loaded or not
	 *
	 * Throws: GException on failure.
	 */
	public bool loadSecretFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_item_load_secret_finish(secretItem, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Load the secret value of this item.
	 *
	 * Each item has a single secret which might be a password or some
	 * other secret binary value.
	 *
	 * This function may block indefinitely. Use the asynchronous version
	 * in user interface threads.
	 *
	 * Params:
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the secret item successfully loaded or not
	 *
	 * Throws: GException on failure.
	 */
	public bool loadSecretSync(Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_item_load_secret_sync(secretItem, (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Refresh the properties on this item.
	 *
	 * This fires off a request to refresh, and the properties will be updated
	 * later.
	 *
	 * Calling this method is not normally necessary, as the secret service
	 * will notify the client when properties change.
	 */
	public void refresh()
	{
		secret_item_refresh(secretItem);
	}

	/**
	 * Set the attributes of this item.
	 *
	 * The @attributes are a mapping of string keys to string values.
	 * Attributes are used to search for items. Attributes are not stored
	 * or transferred securely by the secret service.
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = a new set of attributes
	 *     cancellable = optional cancellation object
	 *     callback = called when the asynchronous operation completes
	 *     userData = data to pass to the callback
	 */
	public void setAttributes(Schema schema, HashTable attributes, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_item_set_attributes(secretItem, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete operation to set the attributes of this item.
	 *
	 * Params:
	 *     result = asynchronous result passed to the callback
	 *
	 * Returns: whether the change was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool setAttributesFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_item_set_attributes_finish(secretItem, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Set the attributes of this item.
	 *
	 * The @attributes are a mapping of string keys to string values.
	 * Attributes are used to search for items. Attributes are not stored
	 * or transferred securely by the secret service.
	 *
	 * This function may block indefinitely. Use the asynchronous version
	 * in user interface threads.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     attributes = a new set of attributes
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the change was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool setAttributesSync(Schema schema, HashTable attributes, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_item_set_attributes_sync(secretItem, (schema is null) ? null : schema.getSchemaStruct(), (attributes is null) ? null : attributes.getHashTableStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Set the label of this item.
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
		secret_item_set_label(secretItem, Str.toStringz(label), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
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

		auto __p = secret_item_set_label_finish(secretItem, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Set the label of this item.
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

		auto __p = secret_item_set_label_sync(secretItem, Str.toStringz(label), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Set the secret value of this item.
	 *
	 * Each item has a single secret which might be a password or some
	 * other secret binary value.
	 *
	 * This function returns immediately and completes asynchronously.
	 *
	 * Params:
	 *     value = a new secret value
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to pass to the callback
	 */
	public void setSecret(Value value, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_item_set_secret(secretItem, (value is null) ? null : value.getValueStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to set the secret value of this item.
	 *
	 * Params:
	 *     result = asynchronous result passed to callback
	 *
	 * Returns: whether the change was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool setSecretFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_item_set_secret_finish(secretItem, (result is null) ? null : result.getAsyncResultStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}

	/**
	 * Set the secret value of this item.
	 *
	 * Each item has a single secret which might be a password or some
	 * other secret binary value.
	 *
	 * This function may block indefinitely. Use the asynchronous version
	 * in user interface threads.
	 *
	 * Params:
	 *     value = a new secret value
	 *     cancellable = optional cancellation object
	 *
	 * Returns: whether the change was successful or not
	 *
	 * Throws: GException on failure.
	 */
	public bool setSecretSync(Value value, Cancellable cancellable)
	{
		GError* err = null;

		auto __p = secret_item_set_secret_sync(secretItem, (value is null) ? null : value.getValueStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), &err) != 0;

		if (err !is null)
		{
			throw new GException( new ErrorG(err) );
		}

		return __p;
	}
}
