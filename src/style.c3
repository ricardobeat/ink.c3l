module ink::style;

import ink::colour;
import ink::token;

const int MAX_ENTRIES = 256;
const int MAX_STYLES = 64;

/**
 * A single style entry for a token type.
 * Fields use 0/false as "unset" sentinel values.
 */
struct StyleEntry
{
	Colour fg;
	Colour bg;
	Colour border;
	bool bold;
	bool italic;
	bool underline;
	bool no_inherit;
}

/**
 * Returns a new zero-initialized (unset) StyleEntry.
 */
fn StyleEntry style_entry_zero()
{
	StyleEntry entry;
	entry.fg = (Colour)0;
	entry.bg = (Colour)0;
	entry.border = (Colour)0;
	entry.bold = false;
	entry.italic = false;
	entry.underline = false;
	entry.no_inherit = false;
	return entry;
}

/**
 * Merges this entry with an ancestor entry.
 */
fn StyleEntry style_entry_inherit(StyleEntry* self, StyleEntry* ancestor)
{
	if (self.no_inherit) return *self;

	StyleEntry result = *self;

	if (result.fg == (Colour)0 && ancestor.fg != (Colour)0) result.fg = ancestor.fg;
	if (result.bg == (Colour)0 && ancestor.bg != (Colour)0) result.bg = ancestor.bg;
	if (result.border == (Colour)0 && ancestor.border != (Colour)0) result.border = ancestor.border;
	if (!result.bold && ancestor.bold) result.bold = true;
	if (!result.italic && ancestor.italic) result.italic = true;
	if (!result.underline && ancestor.underline) result.underline = true;

	return result;
}

/**
 * Parse a single word of a Chroma style spec.
 */
fn void parse_spec_word(StyleEntry* entry, String word)
{
	sz len = word.len;
	if (len == 0) return;

	if (word.ptr[0] == '#')
	{
		entry.fg = colour::colour_parse(word);
	}
	else if (len > 3 && word.ptr[0] == 'b' && word.ptr[1] == 'g' && word.ptr[2] == ':')
	{
		entry.bg = colour::colour_parse(word[3..]);
	}
	else if (len > 7 && word.ptr[0] == 'b' && word.ptr[1] == 'o' && word.ptr[2] == 'r' &&
	         word.ptr[3] == 'd' && word.ptr[4] == 'e' && word.ptr[5] == 'r' && word.ptr[6] == ':')
	{
		entry.border = colour::colour_parse(word[7..]);
	}
	else if (word == "bold")
	{
		entry.bold = true;
	}
	else if (word == "italic")
	{
		entry.italic = true;
	}
	else if (word == "underline")
	{
		entry.underline = true;
	}
	else if (word == "noitalic")
	{
		entry.italic = false;
	}
	else if (word == "nobold")
	{
		entry.bold = false;
	}
	else if (word == "nounderline")
	{
		entry.underline = false;
	}
}

/**
 * Parse a Chroma-compatible style entry spec string.
 */
fn StyleEntry style_entry_parse(String spec) @public
{
	StyleEntry entry = style_entry_zero();

	sz start = 0;
	for (sz i = 0; i <= spec.len; i++)
	{
		if (i == spec.len || spec.ptr[i] == ' ')
		{
			if (i > start)
			{
				String word = spec[start..i-1];
				parse_spec_word(&entry, word);
			}
			start = i + 1;
		}
	}

	return entry;
}

/**
 * A mapping of TokenType -> StyleEntry with hierarchical fallback lookup.
 */
struct Style
{
	StyleEntry[256] entries;
	int[256] keys;
	int count;
	Style* parent;
}

/**
 * Creates a new empty Style.
 */
fn Style style_new() @public
{
	Style s;
	s.count = 0;
	s.parent = null;
	return s;
}

/**
 * Creates a new empty Style with a parent for fallback lookups.
 */
fn Style style_new_with_parent(Style* parent) @public
{
	Style s;
	s.count = 0;
	s.parent = parent;
	return s;
}

/**
 * Add or update an entry for the given TokenType.
 */
fn void style_add(Style* style, int tt, StyleEntry entry) @public
{
	for (int i = 0; i < style.count; i++)
	{
		if (style.keys[i] == tt)
		{
			style.entries[i] = entry;
			return;
		}
	}

	if (style.count < 256)
	{
		style.keys[style.count] = tt;
		style.entries[style.count] = entry;
		style.count++;
	}
}

/**
 * Internal: find entry by exact TokenType. Returns pointer or null.
 */
fn StyleEntry* style_find_exact(Style* style, int tt)
{
	for (int i = 0; i < style.count; i++)
	{
		if (style.keys[i] == tt)
		{
			return &style.entries[i];
		}
	}
	return null;
}

/**
 * Hierarchical fallback lookup for a TokenType.
 *
 * Lookup order:
 * 1. Exact match
 * 2. Subcategory (tt / 100 * 100)
 * 3. Category (tt / 1000 * 1000)
 * 4. Text (8000)
 * 5. Background (-1)
 * 6. Parent style (recursive)
 */
fn StyleEntry style_get(Style* style, int tt) @public
{
	// 1. Exact match
	StyleEntry* exact = style_find_exact(style, tt);
	if (exact != null) return *exact;

	// 2. Subcategory
	int subcat = token::token_type_sub_category(tt);
	if (subcat != tt)
	{
		StyleEntry* sub = style_find_exact(style, subcat);
		if (sub != null) return *sub;
	}

	// 3. Category
	int cat = token::token_type_category(tt);
	if (cat != tt && cat != subcat)
	{
		StyleEntry* cat_entry = style_find_exact(style, cat);
		if (cat_entry != null) return *cat_entry;
	}

	// 4. Text fallback (8000)
	if (tt != 8000)
	{
		StyleEntry* text = style_find_exact(style, 8000);
		if (text != null) return *text;
	}

	// 5. Background fallback (-1)
	if (tt != -1)
	{
		StyleEntry* bg = style_find_exact(style, -1);
		if (bg != null) return *bg;
	}

	// 6. Parent style fallback
	if (style.parent != null)
	{
		return style_get(style.parent, tt);
	}

	return style_entry_zero();
}

/**
 * Global registry of named styles.
 */
struct StyleRegistry
{
	String[64] names;
	Style*[64] styles;
	int count;
}

StyleRegistry global_style_registry;

/**
 * Register a named style in the global registry.
 */
fn void styles_register(String name, Style* style) @public
{
	for (int i = 0; i < global_style_registry.count; i++)
	{
		if (global_style_registry.names[i] == name)
		{
			global_style_registry.styles[i] = style;
			return;
		}
	}

	if (global_style_registry.count < 64)
	{
		global_style_registry.names[global_style_registry.count] = name;
		global_style_registry.styles[global_style_registry.count] = style;
		global_style_registry.count++;
	}
}

/**
 * Look up a style by name from the global registry.
 */
fn Style* styles_get(String name) @public
{
	for (int i = 0; i < global_style_registry.count; i++)
	{
		if (global_style_registry.names[i] == name)
		{
			return global_style_registry.styles[i];
		}
	}
	return null;
}
