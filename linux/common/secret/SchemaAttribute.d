module secret.SchemaAttribute;

private import glib.MemorySlice;
private import glib.Str;
private import glib.c.functions;
private import linker.Loader;
private import secret.c.functions;
public  import secret.c.types;


/**
 * An attribute in a #SecretSchema.
 */
public final class SchemaAttribute
{
    /** the main Gtk struct */
    protected SecretSchemaAttribute* secretSchemaAttribute;
    protected bool ownedRef;

    /** Get the main Gtk struct */
    public SecretSchemaAttribute* getSchemaAttributeStruct(bool transferOwnership = false)
    {
        if (transferOwnership)
            ownedRef = false;
        return secretSchemaAttribute;
    }

    /** the main Gtk struct as a void* */
    protected void* getStruct()
    {
        return cast(void*)secretSchemaAttribute;
    }

    /**
     * Sets our main struct and passes it to the parent class.
     */
    public this (SecretSchemaAttribute* secretSchemaAttribute, bool ownedRef = false)
    {
        this.secretSchemaAttribute = secretSchemaAttribute;
        this.ownedRef = ownedRef;
    }

    ~this ()
    {
        if ( Linker.isLoaded(LIBRARY_SECRET[0]) && ownedRef )
            sliceFree(secretSchemaAttribute);
    }


    /**
     * name of the attribute
     */
    public @property string name()
    {
        return Str.toString(secretSchemaAttribute.name);
    }

    /** Ditto */
    public @property void name(string value)
    {
        secretSchemaAttribute.name = Str.toStringz(value);
    }

    /**
     * the type of the attribute
     */
    public @property SecretSchemaAttributeType type()
    {
        return secretSchemaAttribute.type;
    }

    /** Ditto */
    public @property void type(SecretSchemaAttributeType value)
    {
        secretSchemaAttribute.type = value;
    }

    /** */
    public static GType getType()
    {
        return secret_schema_attribute_get_type();
    }
}
