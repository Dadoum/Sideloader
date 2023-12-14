module secret.Attributes;

private import glib.HashTable;
private import secret.Schema;
private import secret.c.functions;
public  import secret.c.types;


/** */
public struct Attributes
{

	/**
	 * Build up a hash table of attribute values.
	 *
	 * The variable argument list should contain pairs of a) The attribute name as
	 * a null-terminated string, followed by b) attribute value, either a character
	 * string, an int number, or a gboolean value, as defined in the password
	 * @schema. The list of attributes should be terminated with a %NULL.
	 *
	 * Params:
	 *     schema = the schema for the attributes
	 *     va = the attribute keys and values, terminated with %NULL
	 *
	 * Returns: a new table of
	 *     attributes, to be released with [func@GLib.HashTable.unref]
	 */
	public static HashTable buildv(Schema schema, void* va)
	{
		auto __p = secret_attributes_buildv((schema is null) ? null : schema.getSchemaStruct(), va);

		if(__p is null)
		{
			return null;
		}

		return new HashTable(cast(GHashTable*) __p, true);
	}
}
