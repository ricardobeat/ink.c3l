module ink::highlight;

import ink::lexer;
import ink::style;
import ink::lang_registry;
import ink::themes;

/**
 * Initialises the ink highlighting system.
 * Call once at startup before using any lookup functions.
 */
fn void init() @public {
	themes::register_all_themes();
}

/**
 * Look up a lexer by language name or alias.
 */
fn lexer::Lexer*? lexer_for(String name) @public {
	return lang_registry::find_lexer_by_name(name);
}

/**
 * Look up a lexer by filename.
 */
fn lexer::Lexer*? lexer_for_filename(String filename) @public {
	return lang_registry::find_lexer_by_filename(filename);
}

/**
 * Look up a style/theme by name.
 */
fn style::Style*? style_for(String name) @public {
	return style::styles_get(name);
}

/**
 * Get the global lexer registry.
 */
fn lexer::LexerRegistry* lexer_registry() @public {
	return lang_registry::get_lexer_registry();
}
