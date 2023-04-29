module secret.Value;

private import glib.ConstructionException;
private import glib.Str;
private import glib.c.functions;
private import gobject.ObjectG;
private import linker.Loader;
private import secret.c.functions;
public  import secret.c.types;


/**
 * A value containing a secret
 * 
 * A #SecretValue contains a password or other secret value.
 * 
 * Use [method@Value.get] to get the actual secret data, such as a password.
 * The secret data is not necessarily null-terminated, unless the content type
 * is "text/plain".
 * 
 * Each #SecretValue has a content type. For passwords, this is `text/plain`.
 * Use [method@Value.get_content_type] to look at the content type.
 * 
 * #SecretValue is reference counted and immutable. The secret data is only
 * freed when all references have been released via [method@Value.unref].
 */
public class Value
{
    /** the main Gtk struct */
    protected SecretValue* secretValue;
    protected bool ownedRef;

    /** Get the main Gtk struct */
    public SecretValue* getValueStruct(bool transferOwnership = false)
    {
        if (transferOwnership)
            ownedRef = false;
        return secretValue;
    }

    /** the main Gtk struct as a void* */
    protected void* getStruct()
    {
        return cast(void*)secretValue;
    }

    /**
     * Sets our main struct and passes it to the parent class.
     */
    public this (SecretValue* secretValue, bool ownedRef = false)
    {
        this.secretValue = secretValue;
        this.ownedRef = ownedRef;
    }

    ~this ()
    {
        if ( Linker.isLoaded(LIBRARY_SECRET[0]) && ownedRef )
            secret_value_unref(secretValue);
    }


    /** */
    public static GType getType()
    {
        return secret_value_get_type();
    }

    /**
     * Create a #SecretValue for the secret data passed in.
     *
     * The secret data is copied into non-pageable 'secure' memory.
     *
     * If the length is less than zero, then @secret is assumed to be
     * null-terminated.
     *
     * Params:
     *     secret = the secret data
     *     length = the length of the data
     *     contentType = the content type of the data
     *
     * Returns: the new #SecretValue
     *
     * Throws: ConstructionException GTK+ fails to create the object.
     */
    public this(string secret, ptrdiff_t length, string contentType)
    {
        auto __p = secret_value_new(Str.toStringz(secret), length, Str.toStringz(contentType));

        if(__p is null)
        {
            throw new ConstructionException("null returned by new");
        }

        this(cast(SecretValue*) __p);
    }

    /**
     * Create a #SecretValue for the secret data passed in.
     *
     * The secret data is not copied, and will later be freed with the @destroy
     * function.
     *
     * If the length is less than zero, then @secret is assumed to be
     * null-terminated.
     *
     * Params:
     *     secret = the secret data
     *     length = the length of the data
     *     contentType = the content type of the data
     *     destroy = function to call to free the secret data
     *
     * Returns: the new #SecretValue
     *
     * Throws: ConstructionException GTK+ fails to create the object.
     */
    public this(string secret, ptrdiff_t length, string contentType, GDestroyNotify destroy)
    {
        auto __p = secret_value_new_full(Str.toStringz(secret), length, Str.toStringz(contentType), destroy);

        if(__p is null)
        {
            throw new ConstructionException("null returned by new_full");
        }

        this(cast(SecretValue*) __p);
    }

    /**
     * Get the secret data in the #SecretValue.
     *
     * The value is not necessarily null-terminated unless it was created with
     * [ctor@Value.new] or a null-terminated string was passed to
     * [ctor@Value.new_full].
     *
	 * Returns: the secret data
	 */
	public string get()
	{
		size_t length;

		return Str.toString(secret_value_get(secretValue, &length));
	}

	/**
	 * Get the content type of the secret value, such as
	 * `text/plain`.
	 *
	 * Returns: the content type
	 */
	public string getContentType()
	{
		return Str.toString(secret_value_get_content_type(secretValue));
	}

	/**
	 * Get the secret data in the #SecretValue if it contains a textual
	 * value.
	 *
	 * The content type must be `text/plain`.
	 *
	 * Returns: the content type
	 */
	public string getText()
	{
		return Str.toString(secret_value_get_text(secretValue));
	}

	alias doref = ref_;
	/**
	 * Add another reference to the #SecretValue.
	 *
	 * For each reference [method@Value.unref] should be called to unreference the
	 * value.
	 *
	 * Returns: the value
	 */
	public Value ref_()
	{
		auto __p = secret_value_ref(secretValue);

		if(__p is null)
		{
			return null;
		}

		return ObjectG.getDObject!(Value)(cast(SecretValue*) __p, true);
	}

	/**
	 * Unreference a #SecretValue.
	 *
	 * When the last reference is gone, then the value will be freed.
	 */
	public void unref()
	{
		secret_value_unref(secretValue);
	}

	/**
	 * Unreference a #SecretValue and steal the secret data in
	 * #SecretValue as nonpageable memory.
	 *
	 * Params:
	 *     length = the length of the secret
	 *
	 * Returns: a new password string stored in nonpageable memory
	 *     which must be freed with [func@password_free] when done
	 *
	 * Since: 0.19.0
	 */
	public string unrefToPassword(ref size_t length)
	{
		auto retStr = secret_value_unref_to_password(secretValue, &length);

		scope(exit) Str.freeString(retStr);
		return Str.toString(retStr);
	}
}
