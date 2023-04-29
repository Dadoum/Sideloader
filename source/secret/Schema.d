module secret.Schema;

private import glib.ConstructionException;
private import glib.HashTable;
private import glib.Str;
private import gobject.ObjectG;
private import linker.Loader;
private import secret.c.functions;
public  import secret.c.types;


/**
 * Represents a set of attributes that are stored with an item.
 * 
 * These schemas are used for interoperability between various services storing
 * the same types of items.
 * 
 * Each schema has a name like `org.gnome.keyring.NetworkPassword`, and defines a
 * set of attributes, and types (string, integer, boolean) for those attributes.
 * 
 * Attributes are stored as strings in the Secret Service, and the attribute types
 * simply define standard ways to store integer and boolean values as strings.
 * Attributes are represented in libsecret via a [struct@GLib.HashTable] with
 * string keys and values. Even for values that defined as an integer or boolean in
 * the schema, the attribute values in the [struct@GLib.HashTable] are strings.
 * Boolean values are stored as the strings 'true' and 'false'. Integer values are
 * stored in decimal, with a preceding negative sign for negative integers.
 * 
 * Schemas are handled entirely on the client side by this library. The name of the
 * schema is automatically stored as an attribute on the item.
 * 
 * Normally when looking up passwords only those with matching schema names are
 * returned. If the schema @flags contain the `SECRET_SCHEMA_DONT_MATCH_NAME` flag,
 * then lookups will not check that the schema name matches that on the item, only
 * the schema's attributes are matched. This is useful when you are looking up
 * items that are not stored by the libsecret library. Other libraries such as
 * libgnome-keyring don't store the schema name.
 * 
 * Additional schemas can be defined via the %SecretSchema structure like this:
 * 
 * ```c
 * // in a header:
 * 
 * const SecretSchema * example_get_schema (void) G_GNUC_CONST;
 * 
 * #define EXAMPLE_SCHEMA  example_get_schema ()
 * 
 * 
 * // in a .c file
 * 
 * const SecretSchema *
 * example_get_schema (void)
 * {
 * static const SecretSchema the_schema = {
 * "org.example.Password", SECRET_SCHEMA_NONE,
 * {
 * {  "number", SECRET_SCHEMA_ATTRIBUTE_INTEGER },
 * {  "string", SECRET_SCHEMA_ATTRIBUTE_STRING },
 * {  "even", SECRET_SCHEMA_ATTRIBUTE_BOOLEAN },
 * {  NULL, 0 },
 * }
 * };
 * return &the_schema;
 * }
 * ```
 */
public class Schema
{
    /** the main Gtk struct */
    protected SecretSchema* secretSchema;
    protected bool ownedRef;

    /** Get the main Gtk struct */
    public SecretSchema* getSchemaStruct(bool transferOwnership = false)
    {
        if (transferOwnership)
            ownedRef = false;
        return secretSchema;
    }

    /** the main Gtk struct as a void* */
    protected void* getStruct()
    {
        return cast(void*)secretSchema;
    }

    /**
     * Sets our main struct and passes it to the parent class.
     */
    public this (SecretSchema* secretSchema, bool ownedRef = false)
    {
        this.secretSchema = secretSchema;
        this.ownedRef = ownedRef;
    }

    ~this ()
    {
        if ( Linker.isLoaded(LIBRARY_SECRET[0]) && ownedRef )
            secret_schema_unref(secretSchema);
    }


    /** */
    public static GType getType()
    {
        return secret_schema_get_type();
    }

    /**
     * Using this function is not normally necessary from C code. This is useful
     * for constructing #SecretSchema structures in bindings.
     *
     * A schema represents a set of attributes that are stored with an item. These
     * schemas are used for interoperability between various services storing the
     * same types of items.
     *
     * Each schema has an @name like `org.gnome.keyring.NetworkPassword`, and
     * defines a set of attributes names, and types (string, integer, boolean) for
     * those attributes.
     *
     * Each key in the @attributes table should be a attribute name strings, and
     * the values in the table should be integers from the [enum@SchemaAttributeType]
     * enumeration, representing the attribute type for each attribute name.
     *
     * Normally when looking up passwords only those with matching schema names are
     * returned. If the schema @flags contain the %SECRET_SCHEMA_DONT_MATCH_NAME flag,
     * then lookups will not check that the schema name matches that on the item, only
     * the schema's attributes are matched. This is useful when you are looking up items
     * that are not stored by the libsecret library. Other libraries such as libgnome-keyring
     * don't store the schema name.
     *
     * Params:
     *     name = the dotted name of the schema
     *     flags = the flags for the schema
     *     attributeNamesAndTypes = the attribute names and types of those attributes
     *
     * Returns: the new schema, which should be unreferenced with
     *     [method@Schema.unref] when done
     *
     * Throws: ConstructionException GTK+ fails to create the object.
     */
    public this(string name, SecretSchemaFlags flags, HashTable attributeNamesAndTypes)
    {
        auto __p = secret_schema_newv(Str.toStringz(name), flags, (attributeNamesAndTypes is null) ? null : attributeNamesAndTypes.getHashTableStruct());

        if(__p is null)
        {
            throw new ConstructionException("null returned by newv");
        }

        this(cast(SecretSchema*) __p);
    }

    alias doref = ref_;
    /**
     * Adds a reference to the #SecretSchema.
     *
     * It is not normally necessary to call this function from C code, and is
     * mainly present for the sake of bindings. If the @schema was statically
     * allocated, then this function will copy the schema.
     *
     * Returns: the referenced schema, which should be later
     *     unreferenced with [method@Schema.unref]
	 */
	public Schema ref_()
	{
		auto __p = secret_schema_ref(secretSchema);

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Schema)(cast(SecretSchema*) __p, true);
	}

	/**
	 * Releases a reference to the #SecretSchema.
	 *
	 * If the last reference is released then the schema will be freed.
	 *
	 * It is not normally necessary to call this function from C code, and is
	 * mainly present for the sake of bindings. It is an error to call this for
	 * a @schema that was statically allocated.
	 */
	public void unref()
	{
		secret_schema_unref(secretSchema);
	}
}
