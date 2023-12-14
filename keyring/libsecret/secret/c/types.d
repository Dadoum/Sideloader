module secret.c.types;

public import gio.c.types;
public import glib.c.types;
public import gobject.c.types;


/**
 * Flags which determine which parts of the #SecretBackend are initialized.
 *
 * Since: 0.19.0
 */
public enum SecretBackendFlags
{
	/**
	 * no flags for initializing the #SecretBackend
	 */
	NONE = 0,
	/**
	 * establish a session for transfer of secrets
	 * while initializing the #SecretBackend
	 */
	OPEN_SESSION = 2,
	/**
	 * load collections while initializing the
	 * #SecretBackend
	 */
	LOAD_COLLECTIONS = 4,
}
alias SecretBackendFlags BackendFlags;

/**
 * Flags for [func@Collection.create].
 */
public enum SecretCollectionCreateFlags
{
	/**
	 * no flags
	 */
	NONE = 0,
}
alias SecretCollectionCreateFlags CollectionCreateFlags;

/**
 * Flags which determine which parts of the #SecretCollection proxy are initialized.
 */
public enum SecretCollectionFlags
{
	/**
	 * no flags
	 */
	NONE = 0,
	/**
	 * items have or should be loaded
	 */
	LOAD_ITEMS = 2,
}
alias SecretCollectionFlags CollectionFlags;

/**
 * Errors returned by the Secret Service.
 *
 * None of the errors are appropriate for display to the user. It is up to the
 * application to handle them appropriately.
 */
public enum SecretError
{
	/**
	 * received an invalid data or message from the Secret
	 * Service
	 */
	PROTOCOL = 1,
	/**
	 * the item or collection is locked and the operation
	 * cannot be performed
	 */
	IS_LOCKED = 2,
	/**
	 * no such item or collection found in the Secret
	 * Service
	 */
	NO_SUCH_OBJECT = 3,
	/**
	 * a relevant item or collection already exists
	 */
	ALREADY_EXISTS = 4,
	/**
	 * the file format is not valid
	 */
	INVALID_FILE_FORMAT = 5,
}
alias SecretError Error;

/**
 * Flags for [func@Item.create].
 */
public enum SecretItemCreateFlags
{
	/**
	 * no flags
	 */
	NONE = 0,
	/**
	 * replace an item with the same attributes.
	 */
	REPLACE = 2,
}
alias SecretItemCreateFlags ItemCreateFlags;

/**
 * Flags which determine which parts of the #SecretItem proxy are initialized.
 */
public enum SecretItemFlags
{
	/**
	 * no flags
	 */
	NONE = 0,
	/**
	 * a secret has been (or should be) loaded for #SecretItem
	 */
	LOAD_SECRET = 2,
}
alias SecretItemFlags ItemFlags;

/**
 * The type of an attribute in a [struct@SecretSchema].
 *
 * Attributes are stored as strings in the Secret Service, and the attribute
 * types simply define standard ways to store integer and boolean values as
 * strings.
 */
public enum SecretSchemaAttributeType
{
	/**
	 * a utf-8 string attribute
	 */
	STRING = 0,
	/**
	 * an integer attribute, stored as a decimal
	 */
	INTEGER = 1,
	/**
	 * a boolean attribute, stored as 'true' or 'false'
	 */
	BOOLEAN = 2,
}
alias SecretSchemaAttributeType SchemaAttributeType;

/**
 * Flags for a #SecretSchema definition.
 */
public enum SecretSchemaFlags
{
	/**
	 * no flags for the schema
	 */
	NONE = 0,
	/**
	 * don't match the schema name when looking up or
	 * removing passwords
	 */
	DONT_MATCH_NAME = 2,
}
alias SecretSchemaFlags SchemaFlags;

/**
 * Different types of schemas for storing secrets, intended for use with
 * [func@get_schema].
 *
 * ## @SECRET_SCHEMA_NOTE
 *
 * A predefined schema for personal passwords stored by the user in the
 * password manager. This schema has no attributes, and the items are not
 * meant to be used automatically by applications.
 *
 * When used to search for items using this schema, it will only match
 * items that have the same schema. Items stored via libgnome-keyring with the
 * `GNOME_KEYRING_ITEM_NOTE` item type will match.
 *
 * ## @SECRET_SCHEMA_COMPAT_NETWORK
 *
 * A predefined schema that is compatible with items stored via the
 * libgnome-keyring 'network password' functions. This is meant to be used by
 * applications migrating from libgnome-keyring which stored their secrets as
 * 'network passwords'. It is not recommended that new code use this schema.
 *
 * When used to search for items using this schema, it will only match
 * items that have the same schema. Items stored via libgnome-keyring with the
 * `GNOME_KEYRING_ITEM_NETWORK_PASSWORD` item type will match.
 *
 * The following attributes exist in the schema:
 *
 * ### Attributes:
 *
 * <table>
 * <tr>
 * <td><tt>user</tt>:</td>
 * <td>The user name (string).</td>
 * </tr>
 * <tr>
 * <td><tt>domain</tt>:</td>
 * <td>The login domain or realm (string).</td></tr>
 * <tr>
 * <td><tt>object</tt>:</td>
 * <td>The object or path (string).</td>
 * </tr>
 * <tr>
 * <td><tt>protocol</tt>:</td>
 * <td>The protocol (a string like 'http').</td>
 * </tr>
 * <tr>
 * <td><tt>port</tt>:</td>
 * <td>The network port (integer).</td>
 * </tr>
 * <tr>
 * <td><tt>server</tt>:</td>
 * <td>The hostname or server (string).</td>
 * </tr>
 * <tr>
 * <td><tt>authtype</tt>:</td>
 * <td>The authentication type (string).</td>
 * </tr>
 * </table>
 *
 * Since: 0.18.6
 */
public enum SecretSchemaType
{
	/**
	 * Personal passwords
	 */
	NOTE = 0,
	/**
	 * Network passwords from older
	 * libgnome-keyring storage
	 */
	COMPAT_NETWORK = 1,
}
alias SecretSchemaType SchemaType;

/**
 * Various flags to be used with [method@Service.search] and [method@Service.search_sync].
 */
public enum SecretSearchFlags
{
	/**
	 * no flags
	 */
	NONE = 0,
	/**
	 * all the items matching the search will be returned, instead of just the first one
	 */
	ALL = 2,
	/**
	 * unlock locked items while searching
	 */
	UNLOCK = 4,
	/**
	 * while searching load secrets for items that are not locked
	 */
	LOAD_SECRETS = 8,
}
alias SecretSearchFlags SearchFlags;

/**
 * Flags which determine which parts of the #SecretService proxy are initialized
 * during a [func@Service.get] or [func@Service.open] operation.
 */
public enum SecretServiceFlags
{
	/**
	 * no flags for initializing the #SecretService
	 */
	NONE = 0,
	/**
	 * establish a session for transfer of secrets
	 * while initializing the #SecretService
	 */
	OPEN_SESSION = 2,
	/**
	 * load collections while initializing the
	 * #SecretService
	 */
	LOAD_COLLECTIONS = 4,
}
alias SecretServiceFlags ServiceFlags;

struct SecretBackend;

/**
 * The interface for #SecretBackend.
 *
 * Since: 0.19.0
 */
struct SecretBackendInterface
{
	/**
	 * the parent interface
	 */
	GTypeInterface parentIface;
	/** */
	extern(C) void function(SecretBackend* self, SecretBackendFlags flags, GCancellable* cancellable, GAsyncReadyCallback callback, void* userData) ensureForFlags;
	/** */
	extern(C) int function(SecretBackend* self, GAsyncResult* result, GError** err) ensureForFlagsFinish;
	/** */
	extern(C) void function(SecretBackend* self, SecretSchema* schema, GHashTable* attributes, const(char)* collection, const(char)* label, SecretValue* value, GCancellable* cancellable, GAsyncReadyCallback callback, void* userData) store;
	/** */
	extern(C) int function(SecretBackend* self, GAsyncResult* result, GError** err) storeFinish;
	/** */
	extern(C) void function(SecretBackend* self, SecretSchema* schema, GHashTable* attributes, GCancellable* cancellable, GAsyncReadyCallback callback, void* userData) lookup;
	/** */
	extern(C) SecretValue* function(SecretBackend* self, GAsyncResult* result, GError** err) lookupFinish;
	/** */
	extern(C) void function(SecretBackend* self, SecretSchema* schema, GHashTable* attributes, GCancellable* cancellable, GAsyncReadyCallback callback, void* userData) clear;
	/** */
	extern(C) int function(SecretBackend* self, GAsyncResult* result, GError** err) clearFinish;
	/** */
	extern(C) void function(SecretBackend* self, SecretSchema* schema, GHashTable* attributes, SecretSearchFlags flags, GCancellable* cancellable, GAsyncReadyCallback callback, void* userData) search;
	/** */
	extern(C) GList* function(SecretBackend* self, GAsyncResult* result, GError** err) searchFinish;
}

struct SecretCollection
{
	GDBusProxy parent;
	SecretCollectionPrivate* pv;
}

/**
 * The class for #SecretCollection.
 */
struct SecretCollectionClass
{
	/**
	 * the parent class
	 */
	GDBusProxyClass parentClass;
	void*[8] padding;
}

struct SecretCollectionPrivate;

struct SecretItem
{
	GDBusProxy parentInstance;
	SecretItemPrivate* pv;
}

/**
 * The class for #SecretItem.
 */
struct SecretItemClass
{
	/**
	 * the parent class
	 */
	GDBusProxyClass parentClass;
	void*[4] padding;
}

struct SecretItemPrivate;

struct SecretPrompt
{
	GDBusProxy parentInstance;
	SecretPromptPrivate* pv;
}

/**
 * The class for #SecretPrompt.
 */
struct SecretPromptClass
{
	/**
	 * the parent class
	 */
	GDBusProxyClass parentClass;
	void*[8] padding;
}

struct SecretPromptPrivate;

struct SecretRetrievable;

/**
 * The interface for #SecretRetrievable.
 *
 * Since: 0.19.0
 */
struct SecretRetrievableInterface
{
	/**
	 * the parent interface
	 */
	GTypeInterface parentIface;
	/** */
	extern(C) void function(SecretRetrievable* self, GCancellable* cancellable, GAsyncReadyCallback callback, void* userData) retrieveSecret;
	/**
	 *
	 * Params:
	 *     self = a retrievable object
	 *     result = asynchronous result passed to callback
	 * Returns: the secret value which should be
	 *     released with [method@Value.unref], or %NULL
	 *
	 * Throws: GException on failure.
	 */
	extern(C) SecretValue* function(SecretRetrievable* self, GAsyncResult* result, GError** err) retrieveSecretFinish;
}

struct SecretSchema
{
	/**
	 * the dotted name of the schema
	 */
	const(char)* name;
	/**
	 * flags for the schema
	 */
	SecretSchemaFlags flags;
	/**
	 * the attribute names and types of those attributes
	 */
	SecretSchemaAttribute[32] attributes;
	int reserved;
	void* reserved1;
	void* reserved2;
	void* reserved3;
	void* reserved4;
	void* reserved5;
	void* reserved6;
	void* reserved7;
}

/**
 * An attribute in a #SecretSchema.
 */
struct SecretSchemaAttribute
{
	/**
	 * name of the attribute
	 */
	const(char)* name;
	/**
	 * the type of the attribute
	 */
	SecretSchemaAttributeType type;
}

struct SecretService
{
	GDBusProxy parent;
	SecretServicePrivate* pv;
}

/**
 * The class for #SecretService.
 */
struct SecretServiceClass
{
	/**
	 * the parent class
	 */
	GDBusProxyClass parentClass;
	/**
	 * the [alias@GLib.Type] of the [class@Collection] objects instantiated
	 * by the #SecretService proxy
	 */
	GType collectionGtype;
	/**
	 * the [alias@GLib.Type] of the [class@Item] objects instantiated by the
	 * #SecretService proxy
	 */
	GType itemGtype;
	/**
	 *
	 * Params:
	 *     self = the secret service
	 *     prompt = the prompt
	 *     cancellable = optional cancellation object
	 *     returnType = the variant type of the prompt result
	 * Returns: %NULL if the prompt was dismissed or an error occurred,
	 *     a variant result if the prompt was successful
	 *
	 * Throws: GException on failure.
	 */
	extern(C) GVariant* function(SecretService* self, SecretPrompt* prompt, GCancellable* cancellable, GVariantType* returnType, GError** err) promptSync;
	/** */
	extern(C) void function(SecretService* self, SecretPrompt* prompt, GVariantType* returnType, GCancellable* cancellable, GAsyncReadyCallback callback, void* userData) promptAsync;
	/**
	 *
	 * Params:
	 *     self = the secret service
	 *     result = the asynchronous result passed to the callback
	 * Returns: %NULL if the prompt was dismissed or an error occurred,
	 *     a variant result if the prompt was successful
	 *
	 * Throws: GException on failure.
	 */
	extern(C) GVariant* function(SecretService* self, GAsyncResult* result, GError** err) promptFinish;
	/**
	 *
	 * Params:
	 *     self = the secret service
	 * Returns: the gobject type for collections
	 */
	extern(C) GType function(SecretService* self) getCollectionGtype;
	/**
	 *
	 * Params:
	 *     self = the service
	 * Returns: the gobject type for items
	 */
	extern(C) GType function(SecretService* self) getItemGtype;
	void*[14] padding;
}

struct SecretServicePrivate;

struct SecretValue;

/**
 * Extension point for the secret backend.
 */
enum BACKEND_EXTENSION_POINT_NAME = "secret-backend";
alias SECRET_BACKEND_EXTENSION_POINT_NAME = BACKEND_EXTENSION_POINT_NAME;

/**
 * An alias to the default collection.
 *
 * This can be passed to [func@password_store] [func@Collection.for_alias].
 */
enum COLLECTION_DEFAULT = "default";
alias SECRET_COLLECTION_DEFAULT = COLLECTION_DEFAULT;

/**
 * An alias to the session collection, which will be cleared when the user ends
 * the session.
 *
 * This can be passed to [func@password_store], [func@Collection.for_alias] or
 * similar functions.
 */
enum COLLECTION_SESSION = "session";
alias SECRET_COLLECTION_SESSION = COLLECTION_SESSION;

/**
 * The major version of libsecret.
 */
enum MAJOR_VERSION = 0;
alias SECRET_MAJOR_VERSION = MAJOR_VERSION;

/**
 * The micro version of libsecret.
 */
enum MICRO_VERSION = 1;
alias SECRET_MICRO_VERSION = MICRO_VERSION;

/**
 * The minor version of libsecret.
 */
enum MINOR_VERSION = 21;
alias SECRET_MINOR_VERSION = MINOR_VERSION;
