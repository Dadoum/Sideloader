module secret.Prompt;

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
private import glib.Str;
private import glib.Variant;
private import glib.VariantType;
private import secret.c.functions;
public  import secret.c.types;


/**
 * A prompt in the Service
 * 
 * A proxy object representing a prompt that the Secret Service will display
 * to the user.
 * 
 * Certain actions on the Secret Service require user prompting to complete,
 * such as creating a collection, or unlocking a collection. When such a prompt
 * is necessary, then a #SecretPrompt object is created by this library, and
 * passed to the [method@Service.prompt] method. In this way it is handled
 * automatically.
 * 
 * In order to customize prompt handling, override the
 * [vfunc@Service.prompt_async] and [vfunc@Service.prompt_finish] virtual
 * methods of the [class@Service] class.
 */
public class Prompt : DBusProxy
{
	/** the main Gtk struct */
	protected SecretPrompt* secretPrompt;

	/** Get the main Gtk struct */
	public SecretPrompt* getPromptStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return secretPrompt;
	}

	/** the main Gtk struct as a void* */
	protected override void* getStruct()
	{
		return cast(void*)secretPrompt;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (SecretPrompt* secretPrompt, bool ownedRef = false)
	{
		this.secretPrompt = secretPrompt;
		super(cast(GDBusProxy*)secretPrompt, ownedRef);
	}


	/** */
	public static GType getType()
	{
		return secret_prompt_get_type();
	}

	/**
	 * Runs a prompt and performs the prompting.
	 *
	 * Returns %TRUE if the prompt was completed and not dismissed.
	 *
	 * If @window_id is non-null then it is used as an XWindow id on Linux. The API
	 * expects this id to be converted to a string using the `%d` printf format. The
	 * Secret Service can make its prompt transient for the window with this id. In
	 * some Secret Service implementations this is not possible, so the behavior
	 * depending on this should degrade gracefully.
	 *
	 * This method will return immediately and complete asynchronously.
	 *
	 * Params:
	 *     windowId = string form of XWindow id for parent window to be transient for
	 *     returnType = the variant type of the prompt result
	 *     cancellable = optional cancellation object
	 *     callback = called when the operation completes
	 *     userData = data to be passed to the callback
	 */
	public void perform(string windowId, VariantType returnType, Cancellable cancellable, GAsyncReadyCallback callback, void* userData)
	{
		secret_prompt_perform(secretPrompt, Str.toStringz(windowId), (returnType is null) ? null : returnType.getVariantTypeStruct(), (cancellable is null) ? null : cancellable.getCancellableStruct(), callback, userData);
	}

	/**
	 * Complete asynchronous operation to run a prompt and perform the prompting.
	 *
	 * Returns a variant result if the prompt was completed and not dismissed. The
	 * type of result depends on the action the prompt is completing, and is
	 * defined in the Secret Service DBus API specification.
	 *
	 * Params:
	 *     result = the asynchronous result passed to the callback
	 *
	 * Returns: %NULL if the prompt was dismissed or an error occurred,
	 *     a variant result if the prompt was successful
	 *
	 * Throws: GException on failure.
	 */
	public Variant performFinish(AsyncResultIF result)
	{
		GError* err = null;

		auto __p = secret_prompt_perform_finish(secretPrompt, (result is null) ? null : result.getAsyncResultStruct(), &err);

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
	 * Runs a prompt and performs the prompting.
	 *
	 * Returns a variant result if the prompt was completed and not dismissed. The
	 * type of result depends on the action the prompt is completing, and is defined
	 * in the Secret Service DBus API specification.
	 *
	 * If @window_id is non-null then it is used as an XWindow id on Linux. The API
	 * expects this id to be converted to a string using the `%d` printf format. The
	 * Secret Service can make its prompt transient for the window with this id. In
	 * some Secret Service implementations this is not possible, so the behavior
	 * depending on this should degrade gracefully.
	 *
	 * This method may block indefinitely and should not be used in user interface
	 * threads.
	 *
	 * Params:
	 *     windowId = string form of XWindow id for parent window to be transient for
	 *     cancellable = optional cancellation object
	 *     returnType = the variant type of the prompt result
	 *
	 * Returns: %NULL if the prompt was dismissed or an error occurred
	 *
	 * Throws: GException on failure.
	 */
	public Variant performSync(string windowId, Cancellable cancellable, VariantType returnType)
	{
		GError* err = null;

		auto __p = secret_prompt_perform_sync(secretPrompt, Str.toStringz(windowId), (cancellable is null) ? null : cancellable.getCancellableStruct(), (returnType is null) ? null : returnType.getVariantTypeStruct(), &err);

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
	 * Runs a prompt and performs the prompting.
	 *
	 * Returns a variant result if the prompt was completed and not dismissed. The
	 * type of result depends on the action the prompt is completing, and is defined
	 * in the Secret Service DBus API specification.
	 *
	 * If @window_id is non-null then it is used as an XWindow id on Linux. The API
	 * expects this id to be converted to a string using the `%d` printf format. The
	 * Secret Service can make its prompt transient for the window with this id. In
	 * some Secret Service implementations this is not possible, so the behavior
	 * depending on this should degrade gracefully.
	 *
	 * This runs the dialog in a recursive mainloop. When run from a user interface
	 * thread, this means the user interface will remain responsive. Care should be
	 * taken that appropriate user interface actions are disabled while running the
	 * prompt.
	 *
	 * Params:
	 *     windowId = string form of XWindow id for parent window to be transient for
	 *     cancellable = optional cancellation object
	 *     returnType = the variant type of the prompt result
	 *
	 * Returns: %NULL if the prompt was dismissed or an error occurred
	 *
	 * Throws: GException on failure.
	 */
	public Variant run(string windowId, Cancellable cancellable, VariantType returnType)
	{
		GError* err = null;

		auto __p = secret_prompt_run(secretPrompt, Str.toStringz(windowId), (cancellable is null) ? null : cancellable.getCancellableStruct(), (returnType is null) ? null : returnType.getVariantTypeStruct(), &err);

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
}
