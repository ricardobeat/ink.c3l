module ink::lang_registry;

import ink::lexer;
import ink::ts_lexer;

/**
 * Global lexer registry. Populated via register_language() or at init.
 */
lexer::LexerRegistry global_lexer_registry;

/**
 * Register a TsLexer for a language.
 *
 * Call this for each language with a compiled grammar and highlight query.
 */
fn void register_language(
	String name,
	String[] aliases,
	String[] extensions,
	void* language,       // TSLanguage*
	String query_source   // highlights.scm content
) @public {
	// Deep-copy the config so it outlives the caller's scope/temp allocator.
	// Literal String contents are static; only the arrays need copying.
	String name_copy = name.copy(mem);
	String query_copy = query_source.copy(mem);
	String[] aliases_copy = mem::new_array(String, aliases.len);
	for (sz i = 0; i < aliases.len; i++) aliases_copy[i] = aliases[i].copy(mem);
	String[] extensions_copy = mem::new_array(String, extensions.len);
	for (sz i = 0; i < extensions.len; i++) extensions_copy[i] = extensions[i].copy(mem);

	ink::ts_lexer::TsLexer* l = ink::ts_lexer::ts_lexer_new(
		name_copy, aliases_copy, extensions_copy, language, query_copy
	);
	lexer::lexer_registry_register(&global_lexer_registry, (lexer::Lexer)l);
}

/**
 * Get the global lexer registry.
 */
fn lexer::LexerRegistry* get_lexer_registry() @public {
	return &global_lexer_registry;
}

/**
 * Lookup a lexer by language name.
 */
fn lexer::Lexer*? find_lexer_by_name(String name) @public {
	return lexer::lexer_registry_by_name(&global_lexer_registry, name);
}

/**
 * Lookup a lexer by filename.
 */
fn lexer::Lexer*? find_lexer_by_filename(String filename) @public {
	return lexer::lexer_registry_by_filename(&global_lexer_registry, filename);
}
