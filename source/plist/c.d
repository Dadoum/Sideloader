module plist.c;

version = LibPlistDynamic;

/**
 * @file plist/plist.h
 * @brief Main include of libplist
 * \internal
 *
 * Copyright (c) 2012-2019 Nikias Bassen, All Rights Reserved.
 * Copyright (c) 2008-2009 Jonathan Beck, All Rights Reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

import core.stdc.stdarg;

private enum PlistImport;

version (LibPlistDynamic) {
    import core.sys.posix.dlfcn;
    import core.stdc.stdlib;
    import std.traits: getSymbolsByUDA, ReturnType, Parameters;

    template delegateStorage(string name) {
        __gshared void* delegateStorage;
    }

    private __gshared void* libplistHandle;

    shared static this() {
        import slf4d;
        static foreach (libplistName; ["libplist.so.3", "libplist-2.0.so.3"]) {
            libplistHandle = dlopen(libplistName, RTLD_LAZY);
            if (libplistHandle) {
                return;
            }
        }
        getLogger().error("libplist is not available on this machine. ");
        abort();
    }

    mixin template implementSymbol(alias symbol) {
        static if (is(typeof(symbol) == function)) {
            alias DelT = typeof(&symbol);
            enum funcName = __traits(identifier, symbol);
            alias del = delegateStorage!funcName;

            shared static this() {
                del = dlsym(libplistHandle, funcName);
            }

            pragma(mangle, symbol.mangleof)
            extern (C) ReturnType!symbol impl(Parameters!symbol params) @(__traits(getAttributes, symbol)) {
                return (cast(DelT) del)(params);
            }
        }
    }

    static foreach (symbol; getSymbolsByUDA!(__traits(parent, {}), PlistImport)) {
        mixin implementSymbol!symbol;
    }
}

@PlistImport extern (C):

/**
 * \mainpage libplist : A library to handle Apple Property Lists
 * \defgroup PublicAPI Public libplist API
 */
/*@{*/

/**
 * The basic plist abstract data type.
 */
alias plist_t = void*;

/**
 * The plist dictionary iterator.
 */
alias plist_dict_iter = void*;

/**
 * The plist array iterator.
 */
alias plist_array_iter = void*;

/**
 * The enumeration of plist node types.
 */
enum plist_type
{
    PLIST_BOOLEAN = 0, /**< Boolean, scalar type */
    PLIST_UINT = 1, /**< Unsigned integer, scalar type */
    PLIST_REAL = 2, /**< Real, scalar type */
    PLIST_STRING = 3, /**< ASCII string, scalar type */
    PLIST_ARRAY = 4, /**< Ordered array, structured type */
    PLIST_DICT = 5, /**< Unordered dictionary (key/value pair), structured type */
    PLIST_DATE = 6, /**< Date, scalar type */
    PLIST_DATA = 7, /**< Binary data, scalar type */
    PLIST_KEY = 8, /**< Key in dictionaries (ASCII String), scalar type */
    PLIST_UID = 9, /**< Special type used for 'keyed encoding' */
    PLIST_NONE = 10 /**< No type */
}

/********************************************
 *                                          *
 *          Creation & Destruction          *
 *                                          *
 ********************************************/

/**
 * Create a new root plist_t type #PLIST_DICT
 *
 * @return the created plist
 * @sa #plist_type
 */
plist_t plist_new_dict ();

/**
 * Create a new root plist_t type #PLIST_ARRAY
 *
 * @return the created plist
 * @sa #plist_type
 */
plist_t plist_new_array ();

/**
 * Create a new plist_t type #PLIST_STRING
 *
 * @param val the sting value, encoded in UTF8.
 * @return the created item
 * @sa #plist_type
 */
plist_t plist_new_string (const(char)* val);

/**
 * Create a new plist_t type #PLIST_BOOLEAN
 *
 * @param val the boolean value, 0 is false, other values are true.
 * @return the created item
 * @sa #plist_type
 */
plist_t plist_new_bool (ubyte val);

/**
 * Create a new plist_t type #PLIST_UINT
 *
 * @param val the unsigned integer value
 * @return the created item
 * @sa #plist_type
 */
plist_t plist_new_uint (ulong val);

/**
 * Create a new plist_t type #PLIST_REAL
 *
 * @param val the real value
 * @return the created item
 * @sa #plist_type
 */
plist_t plist_new_real (double val);

/**
 * Create a new plist_t type #PLIST_DATA
 *
 * @param val the binary buffer
 * @param length the length of the buffer
 * @return the created item
 * @sa #plist_type
 */
plist_t plist_new_data (const(char)* val, ulong length);

/**
 * Create a new plist_t type #PLIST_DATE
 *
 * @param sec the number of seconds since 01/01/2001
 * @param usec the number of microseconds
 * @return the created item
 * @sa #plist_type
 */
plist_t plist_new_date (int sec, int usec);

/**
 * Create a new plist_t type #PLIST_UID
 *
 * @param val the unsigned integer value
 * @return the created item
 * @sa #plist_type
 */
plist_t plist_new_uid (ulong val);

/**
 * Destruct a plist_t node and all its children recursively
 *
 * @param plist the plist to free
 */
void plist_free (plist_t plist);

/**
 * Return a copy of passed node and it's children
 *
 * @param node the plist to copy
 * @return copied plist
 */
plist_t plist_copy (plist_t node);

/********************************************
 *                                          *
 *            Array functions               *
 *                                          *
 ********************************************/

/**
 * Get size of a #PLIST_ARRAY node.
 *
 * @param node the node of type #PLIST_ARRAY
 * @return size of the #PLIST_ARRAY node
 */
uint plist_array_get_size (plist_t node);

/**
 * Get the nth item in a #PLIST_ARRAY node.
 *
 * @param node the node of type #PLIST_ARRAY
 * @param n the index of the item to get. Range is [0, array_size[
 * @return the nth item or NULL if node is not of type #PLIST_ARRAY
 */
plist_t plist_array_get_item (plist_t node, uint n);

/**
 * Get the index of an item. item must be a member of a #PLIST_ARRAY node.
 *
 * @param node the node
 * @return the node index or UINT_MAX if node index can't be determined
 */
uint plist_array_get_item_index (plist_t node);

/**
 * Set the nth item in a #PLIST_ARRAY node.
 * The previous item at index n will be freed using #plist_free
 *
 * @param node the node of type #PLIST_ARRAY
 * @param item the new item at index n. The array is responsible for freeing item when it is no longer needed.
 * @param n the index of the item to get. Range is [0, array_size[. Assert if n is not in range.
 */
void plist_array_set_item (plist_t node, plist_t item, uint n);

/**
 * Append a new item at the end of a #PLIST_ARRAY node.
 *
 * @param node the node of type #PLIST_ARRAY
 * @param item the new item. The array is responsible for freeing item when it is no longer needed.
 */
void plist_array_append_item (plist_t node, plist_t item);

/**
 * Insert a new item at position n in a #PLIST_ARRAY node.
 *
 * @param node the node of type #PLIST_ARRAY
 * @param item the new item to insert. The array is responsible for freeing item when it is no longer needed.
 * @param n The position at which the node will be stored. Range is [0, array_size[. Assert if n is not in range.
 */
void plist_array_insert_item (plist_t node, plist_t item, uint n);

/**
 * Remove an existing position in a #PLIST_ARRAY node.
 * Removed position will be freed using #plist_free.
 *
 * @param node the node of type #PLIST_ARRAY
 * @param n The position to remove. Range is [0, array_size[. Assert if n is not in range.
 */
void plist_array_remove_item (plist_t node, uint n);

/**
 * Remove a node that is a child node of a #PLIST_ARRAY node.
 * node will be freed using #plist_free.
 *
 * @param node The node to be removed from its #PLIST_ARRAY parent.
 */
void plist_array_item_remove (plist_t node);

/**
 * Create an iterator of a #PLIST_ARRAY node.
 * The allocated iterator should be freed with the standard free function.
 *
 * @param node The node of type #PLIST_ARRAY
 * @param iter Location to store the iterator for the array.
 */
void plist_array_new_iter (plist_t node, plist_array_iter* iter);

/**
 * Increment iterator of a #PLIST_ARRAY node.
 *
 * @param node The node of type #PLIST_ARRAY.
 * @param iter Iterator of the array
 * @param item Location to store the item. The caller must *not* free the
 *          returned item. Will be set to NULL when no more items are left
 *          to iterate.
 */
void plist_array_next_item (plist_t node, plist_array_iter iter, plist_t* item);

/********************************************
 *                                          *
 *         Dictionary functions             *
 *                                          *
 ********************************************/

/**
 * Get size of a #PLIST_DICT node.
 *
 * @param node the node of type #PLIST_DICT
 * @return size of the #PLIST_DICT node
 */
uint plist_dict_get_size (plist_t node);

/**
 * Create an iterator of a #PLIST_DICT node.
 * The allocated iterator should be freed with the standard free function.
 *
 * @param node The node of type #PLIST_DICT.
 * @param iter Location to store the iterator for the dictionary.
 */
void plist_dict_new_iter (plist_t node, plist_dict_iter* iter);

/**
 * Increment iterator of a #PLIST_DICT node.
 *
 * @param node The node of type #PLIST_DICT
 * @param iter Iterator of the dictionary
 * @param key Location to store the key, or NULL. The caller is responsible
 *		for freeing the the returned string.
 * @param val Location to store the value, or NULL. The caller must *not*
 *		free the returned value. Will be set to NULL when no more
 *		key/value pairs are left to iterate.
 */
void plist_dict_next_item (plist_t node, plist_dict_iter iter, char** key, plist_t* val);

/**
 * Get key associated key to an item. Item must be member of a dictionary.
 *
 * @param node the item
 * @param key a location to store the key. The caller is responsible for freeing the returned string.
 */
void plist_dict_get_item_key (plist_t node, char** key);

/**
 * Get the nth item in a #PLIST_DICT node.
 *
 * @param node the node of type #PLIST_DICT
 * @param key the identifier of the item to get.
 * @return the item or NULL if node is not of type #PLIST_DICT. The caller should not free
 *		the returned node.
 */
plist_t plist_dict_get_item (plist_t node, const(char)* key);

/**
 * Get key node associated to an item. Item must be member of a dictionary.
 *
 * @param node the item
 * @return the key node of the given item, or NULL.
 */
plist_t plist_dict_item_get_key (plist_t node);

/**
 * Set item identified by key in a #PLIST_DICT node.
 * The previous item identified by key will be freed using #plist_free.
 * If there is no item for the given key a new item will be inserted.
 *
 * @param node the node of type #PLIST_DICT
 * @param item the new item associated to key
 * @param key the identifier of the item to set.
 */
void plist_dict_set_item (plist_t node, const(char)* key, plist_t item);

/**
 * Insert a new item into a #PLIST_DICT node.
 *
 * @deprecated Deprecated. Use plist_dict_set_item instead.
 *
 * @param node the node of type #PLIST_DICT
 * @param item the new item to insert
 * @param key The identifier of the item to insert.
 */
void plist_dict_insert_item (plist_t node, const(char)* key, plist_t item);

/**
 * Remove an existing position in a #PLIST_DICT node.
 * Removed position will be freed using #plist_free
 *
 * @param node the node of type #PLIST_DICT
 * @param key The identifier of the item to remove. Assert if identifier is not present.
 */
void plist_dict_remove_item (plist_t node, const(char)* key);

/**
 * Merge a dictionary into another. This will add all key/value pairs
 * from the source dictionary to the target dictionary, overwriting
 * any existing key/value pairs that are already present in target.
 *
 * @param target pointer to an existing node of type #PLIST_DICT
 * @param source node of type #PLIST_DICT that should be merged into target
 */
void plist_dict_merge (plist_t* target, plist_t source);

/********************************************
 *                                          *
 *                Getters                   *
 *                                          *
 ********************************************/

/**
 * Get the parent of a node
 *
 * @param node the parent (NULL if node is root)
 */
plist_t plist_get_parent (plist_t node);

/**
 * Get the #plist_type of a node.
 *
 * @param node the node
 * @return the type of the node
 */
plist_type plist_get_node_type (plist_t node);

/**
 * Get the value of a #PLIST_KEY node.
 * This function does nothing if node is not of type #PLIST_KEY
 *
 * @param node the node
 * @param val a pointer to a C-string. This function allocates the memory,
 *            caller is responsible for freeing it.
 */
void plist_get_key_val (plist_t node, char** val);

/**
 * Get the value of a #PLIST_STRING node.
 * This function does nothing if node is not of type #PLIST_STRING
 *
 * @param node the node
 * @param val a pointer to a C-string. This function allocates the memory,
 *            caller is responsible for freeing it. Data is UTF-8 encoded.
 */
void plist_get_string_val (plist_t node, char** val);

/**
 * Get a pointer to the buffer of a #PLIST_STRING node.
 *
 * @note DO NOT MODIFY the buffer. Mind that the buffer is only available
 *   until the plist node gets freed. Make a copy if needed.
 *
 * @param node The node
 * @param length If non-NULL, will be set to the length of the string
 *
 * @return Pointer to the NULL-terminated buffer.
 */
const(char)* plist_get_string_ptr (plist_t node, ulong* length);

/**
 * Get the value of a #PLIST_BOOLEAN node.
 * This function does nothing if node is not of type #PLIST_BOOLEAN
 *
 * @param node the node
 * @param val a pointer to a uint8_t variable.
 */
void plist_get_bool_val (plist_t node, ubyte* val);

/**
 * Get the value of a #PLIST_UINT node.
 * This function does nothing if node is not of type #PLIST_UINT
 *
 * @param node the node
 * @param val a pointer to a uint64_t variable.
 */
void plist_get_uint_val (plist_t node, ulong* val);

/**
 * Get the value of a #PLIST_REAL node.
 * This function does nothing if node is not of type #PLIST_REAL
 *
 * @param node the node
 * @param val a pointer to a double variable.
 */
void plist_get_real_val (plist_t node, double* val);

/**
 * Get the value of a #PLIST_DATA node.
 * This function does nothing if node is not of type #PLIST_DATA
 *
 * @param node the node
 * @param val a pointer to an unallocated char buffer. This function allocates the memory,
 *            caller is responsible for freeing it.
 * @param length the length of the buffer
 */
void plist_get_data_val (plist_t node, char** val, ulong* length);

/**
 * Get a pointer to the data buffer of a #PLIST_DATA node.
 *
 * @note DO NOT MODIFY the buffer. Mind that the buffer is only available
 *   until the plist node gets freed. Make a copy if needed.
 *
 * @param node The node
 * @param length Pointer to a uint64_t that will be set to the length of the buffer
 *
 * @return Pointer to the buffer
 */
const(char)* plist_get_data_ptr (plist_t node, ulong* length);

/**
 * Get the value of a #PLIST_DATE node.
 * This function does nothing if node is not of type #PLIST_DATE
 *
 * @param node the node
 * @param sec a pointer to an int32_t variable. Represents the number of seconds since 01/01/2001.
 * @param usec a pointer to an int32_t variable. Represents the number of microseconds
 */
void plist_get_date_val (plist_t node, int* sec, int* usec);

/**
 * Get the value of a #PLIST_UID node.
 * This function does nothing if node is not of type #PLIST_UID
 *
 * @param node the node
 * @param val a pointer to a uint64_t variable.
 */
void plist_get_uid_val (plist_t node, ulong* val);

/********************************************
 *                                          *
 *                Setters                   *
 *                                          *
 ********************************************/

/**
 * Set the value of a node.
 * Forces type of node to #PLIST_KEY
 *
 * @param node the node
 * @param val the key value
 */
void plist_set_key_val (plist_t node, const(char)* val);

/**
 * Set the value of a node.
 * Forces type of node to #PLIST_STRING
 *
 * @param node the node
 * @param val the string value. The string is copied when set and will be
 *		freed by the node.
 */
void plist_set_string_val (plist_t node, const(char)* val);

/**
 * Set the value of a node.
 * Forces type of node to #PLIST_BOOLEAN
 *
 * @param node the node
 * @param val the boolean value
 */
void plist_set_bool_val (plist_t node, ubyte val);

/**
 * Set the value of a node.
 * Forces type of node to #PLIST_UINT
 *
 * @param node the node
 * @param val the unsigned integer value
 */
void plist_set_uint_val (plist_t node, ulong val);

/**
 * Set the value of a node.
 * Forces type of node to #PLIST_REAL
 *
 * @param node the node
 * @param val the real value
 */
void plist_set_real_val (plist_t node, double val);

/**
 * Set the value of a node.
 * Forces type of node to #PLIST_DATA
 *
 * @param node the node
 * @param val the binary buffer. The buffer is copied when set and will
 *		be freed by the node.
 * @param length the length of the buffer
 */
void plist_set_data_val (plist_t node, const(char)* val, ulong length);

/**
 * Set the value of a node.
 * Forces type of node to #PLIST_DATE
 *
 * @param node the node
 * @param sec the number of seconds since 01/01/2001
 * @param usec the number of microseconds
 */
void plist_set_date_val (plist_t node, int sec, int usec);

/**
 * Set the value of a node.
 * Forces type of node to #PLIST_UID
 *
 * @param node the node
 * @param val the unsigned integer value
 */
void plist_set_uid_val (plist_t node, ulong val);

/********************************************
 *                                          *
 *            Import & Export               *
 *                                          *
 ********************************************/

/**
 * Export the #plist_t structure to XML format.
 *
 * @param plist the root node to export
 * @param plist_xml a pointer to a C-string. This function allocates the memory,
 *            caller is responsible for freeing it. Data is UTF-8 encoded.
 * @param length a pointer to an uint32_t variable. Represents the length of the allocated buffer.
 */
void plist_to_xml (plist_t plist, char** plist_xml, uint* length);

/**
 * Export the #plist_t structure to binary format.
 *
 * @param plist the root node to export
 * @param plist_bin a pointer to a char* buffer. This function allocates the memory,
 *            caller is responsible for freeing it.
 * @param length a pointer to an uint32_t variable. Represents the length of the allocated buffer.
 */
void plist_to_bin (plist_t plist, char** plist_bin, uint* length);

version (NewPlist) {
    /**
     * Free memory allocated by relevant libplist API calls:
     * - plist_to_xml()
     * - plist_to_bin()
     * - plist_get_key_val()
     * - plist_get_string_val()
     * - plist_get_data_val()
     *
     * @param ptr pointer to the memory to free
     *
     * @note Do not use this function to free plist_t nodes, use plist_free()
     *     instead.
     */
    void plist_mem_free(void* ptr);

    alias plist_to_xml_free = plist_mem_free;
    alias plist_to_bin_free = plist_mem_free;
} else {
    import core.stdc.stdlib: free;
    alias plist_mem_free = free;

    /**
     * Frees the memory allocated by plist_to_xml().
     *
     * @param plist_xml The buffer allocated by plist_to_xml().
     */
    void plist_to_xml_free (char* plist_xml);

    /**
     * Frees the memory allocated by plist_to_bin().
     *
     * @param plist_bin The buffer allocated by plist_to_bin().
     */
    void plist_to_bin_free (char* plist_bin);
}

/**
 * Import the #plist_t structure from XML format.
 *
 * @param plist_xml a pointer to the xml buffer.
 * @param length length of the buffer to read.
 * @param plist a pointer to the imported plist.
 */
void plist_from_xml (const(char)* plist_xml, uint length, plist_t* plist);

/**
 * Import the #plist_t structure from binary format.
 *
 * @param plist_bin a pointer to the xml buffer.
 * @param length length of the buffer to read.
 * @param plist a pointer to the imported plist.
 */
void plist_from_bin (const(char)* plist_bin, uint length, plist_t* plist);

/**
 * Import the #plist_t structure from memory data.
 * This method will look at the first bytes of plist_data
 * to determine if plist_data contains a binary or XML plist.
 *
 * @param plist_data a pointer to the memory buffer containing plist data.
 * @param length length of the buffer to read.
 * @param plist a pointer to the imported plist.
 */
void plist_from_memory (const(char)* plist_data, uint length, plist_t* plist);

/**
 * Test if in-memory plist data is binary or XML
 * This method will look at the first bytes of plist_data
 * to determine if plist_data contains a binary or XML plist.
 * This method is not validating the whole memory buffer to check if the
 * content is truly a plist, it's only using some heuristic on the first few
 * bytes of plist_data.
 *
 * @param plist_data a pointer to the memory buffer containing plist data.
 * @param length length of the buffer to read.
 * @return 1 if the buffer is a binary plist, 0 otherwise.
 */
int plist_is_binary (const(char)* plist_data, uint length);

/********************************************
 *                                          *
 *                 Utils                    *
 *                                          *
 ********************************************/

/**
 * Get a node from its path. Each path element depends on the associated father node type.
 * For Dictionaries, var args are casted to const char*, for arrays, var args are caster to uint32_t
 * Search is breath first order.
 *
 * @param plist the node to access result from.
 * @param length length of the path to access
 * @return the value to access.
 */
// plist_t plist_access_path (plist_t plist, uint length, ...);

/**
 * Variadic version of #plist_access_path.
 *
 * @param plist the node to access result from.
 * @param length length of the path to access
 * @param v list of array's index and dic'st key
 * @return the value to access.
 */
plist_t plist_access_pathv (plist_t plist, uint length, va_list v);

/**
 * Compare two node values
 *
 * @param node_l left node to compare
 * @param node_r rigth node to compare
 * @return TRUE is type and value match, FALSE otherwise.
 */
char plist_compare_node_value (plist_t node_l, plist_t node_r);

/* Helper macros for the different plist types */
extern (D) auto PLIST_IS_BOOLEAN(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, BOOLEAN);
}

extern (D) auto PLIST_IS_UINT(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, UINT);
}

extern (D) auto PLIST_IS_REAL(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, REAL);
}

extern (D) auto PLIST_IS_STRING(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, STRING);
}

extern (D) auto PLIST_IS_ARRAY(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, ARRAY);
}

extern (D) auto PLIST_IS_DICT(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, DICT);
}

extern (D) auto PLIST_IS_DATE(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, DATE);
}

extern (D) auto PLIST_IS_DATA(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, DATA);
}

extern (D) auto PLIST_IS_KEY(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, KEY);
}

extern (D) auto PLIST_IS_UID(T)(auto ref T __plist)
{
    return _PLIST_IS_TYPE(__plist, UID);
}

/**
 * Helper function to check the value of a PLIST_BOOL node.
 *
 * @param boolnode node of type PLIST_BOOL
 * @return 1 if the boolean node has a value of TRUE, 0 if FALSE,
 *   or -1 if the node is not of type PLIST_BOOL
 */
int plist_bool_val_is_true (plist_t boolnode);

/**
 * Helper function to compare the value of a PLIST_UINT node against
 * a given value.
 *
 * @param uintnode node of type PLIST_UINT
 * @param cmpval value to compare against
 * @return 0 if the node's value and cmpval are equal,
 *         1 if the node's value is greater than cmpval,
 *         or -1 if the node's value is less than cmpval.
 */
int plist_uint_val_compare (plist_t uintnode, ulong cmpval);

/**
 * Helper function to compare the value of a PLIST_UID node against
 * a given value.
 *
 * @param uidnode node of type PLIST_UID
 * @param cmpval value to compare against
 * @return 0 if the node's value and cmpval are equal,
 *         1 if the node's value is greater than cmpval,
 *         or -1 if the node's value is less than cmpval.
 */
int plist_uid_val_compare (plist_t uidnode, ulong cmpval);

/**
 * Helper function to compare the value of a PLIST_REAL node against
 * a given value.
 *
 * @note WARNING: Comparing floating point values can give inaccurate
 *     results because of the nature of floating point values on computer
 *     systems. While this function is designed to be as accurate as
 *     possible, please don't rely on it too much.
 *
 * @param realnode node of type PLIST_REAL
 * @param cmpval value to compare against
 * @return 0 if the node's value and cmpval are (almost) equal,
 *         1 if the node's value is greater than cmpval,
 *         or -1 if the node's value is less than cmpval.
 */
int plist_real_val_compare (plist_t realnode, double cmpval);

/**
 * Helper function to compare the value of a PLIST_DATE node against
 * a given set of seconds and fraction of a second since epoch.
 *
 * @param datenode node of type PLIST_DATE
 * @param cmpsec number of seconds since epoch to compare against
 * @param cmpusec fraction of a second in microseconds to compare against
 * @return 0 if the node's date is equal to the supplied values,
 *         1 if the node's date is greater than the supplied values,
 *         or -1 if the node's date is less than the supplied values.
 */
int plist_date_val_compare (plist_t datenode, int cmpsec, int cmpusec);

/**
 * Helper function to compare the value of a PLIST_STRING node against
 * a given value.
 * This function basically behaves like strcmp.
 *
 * @param strnode node of type PLIST_STRING
 * @param cmpval value to compare against
 * @return 0 if the node's value and cmpval are equal,
 *     > 0 if the node's value is lexicographically greater than cmpval,
 *     or < 0 if the node's value is lexicographically less than cmpval.
 */
int plist_string_val_compare (plist_t strnode, const(char)* cmpval);

/**
 * Helper function to compare the value of a PLIST_STRING node against
 * a given value, while not comparing more than n characters.
 * This function basically behaves like strncmp.
 *
 * @param strnode node of type PLIST_STRING
 * @param cmpval value to compare against
 * @param n maximum number of characters to compare
 * @return 0 if the node's value and cmpval are equal,
 *     > 0 if the node's value is lexicographically greater than cmpval,
 *     or < 0 if the node's value is lexicographically less than cmpval.
 */
int plist_string_val_compare_with_size (plist_t strnode, const(char)* cmpval, size_t n);

/**
 * Helper function to match a given substring in the value of a
 * PLIST_STRING node.
 *
 * @param strnode node of type PLIST_STRING
 * @param substr value to match
 * @return 1 if the node's value contains the given substring,
 *     or 0 if not.
 */
int plist_string_val_contains (plist_t strnode, const(char)* substr);

/**
 * Helper function to compare the value of a PLIST_KEY node against
 * a given value.
 * This function basically behaves like strcmp.
 *
 * @param keynode node of type PLIST_KEY
 * @param cmpval value to compare against
 * @return 0 if the node's value and cmpval are equal,
 *     > 0 if the node's value is lexicographically greater than cmpval,
 *     or < 0 if the node's value is lexicographically less than cmpval.
 */
int plist_key_val_compare (plist_t keynode, const(char)* cmpval);

/**
 * Helper function to compare the value of a PLIST_KEY node against
 * a given value, while not comparing more than n characters.
 * This function basically behaves like strncmp.
 *
 * @param keynode node of type PLIST_KEY
 * @param cmpval value to compare against
 * @param n maximum number of characters to compare
 * @return 0 if the node's value and cmpval are equal,
 *     > 0 if the node's value is lexicographically greater than cmpval,
 *     or < 0 if the node's value is lexicographically less than cmpval.
 */
int plist_key_val_compare_with_size (plist_t keynode, const(char)* cmpval, size_t n);

/**
 * Helper function to match a given substring in the value of a
 * PLIST_KEY node.
 *
 * @param keynode node of type PLIST_KEY
 * @param substr value to match
 * @return 1 if the node's value contains the given substring,
 *     or 0 if not.
 */
int plist_key_val_contains (plist_t keynode, const(char)* substr);

/**
 * Helper function to compare the data of a PLIST_DATA node against
 * a given blob and size.
 * This function basically behaves like memcmp after making sure the
 * size of the node's data value is equal to the size of cmpval (n),
 * making this a "full match" comparison.
 *
 * @param datanode node of type PLIST_DATA
 * @param cmpval data blob to compare against
 * @param n size of data blob passed in cmpval
 * @return 0 if the node's data blob and cmpval are equal,
 *     > 0 if the node's value is lexicographically greater than cmpval,
 *     or < 0 if the node's value is lexicographically less than cmpval.
 */
int plist_data_val_compare (plist_t datanode, const(ubyte)* cmpval, size_t n);

/**
 * Helper function to compare the data of a PLIST_DATA node against
 * a given blob and size, while no more than n bytes are compared.
 * This function basically behaves like memcmp after making sure the
 * size of the node's data value is at least n, making this a
 * "starts with" comparison.
 *
 * @param datanode node of type PLIST_DATA
 * @param cmpval data blob to compare against
 * @param n size of data blob passed in cmpval
 * @return 0 if the node's value and cmpval are equal,
 *     > 0 if the node's value is lexicographically greater than cmpval,
 *     or < 0 if the node's value is lexicographically less than cmpval.
 */
int plist_data_val_compare_with_size (plist_t datanode, const(ubyte)* cmpval, size_t n);

/**
 * Helper function to match a given data blob within the value of a
 * PLIST_DATA node.
 *
 * @param datanode node of type PLIST_KEY
 * @param cmpval data blob to match
 * @param n size of data blob passed in cmpval
 * @return 1 if the node's value contains the given data blob
 *     or 0 if not.
 */
int plist_data_val_contains (plist_t datanode, const(ubyte)* cmpval, size_t n);

/*@}*/
