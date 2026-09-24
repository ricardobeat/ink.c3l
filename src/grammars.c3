module ink::grammars;

import ink::helix;
import ink::lexer;
import ink::lang_registry;
import ink::ts_bind;
import std::io;

// The grammars ink ships, loaded when first needed. A file's language comes
// from the Helix registry; its grammar is grammars/libtree-sitter-<grammar>.dylib
// and its query data/queries/<language>/highlights.scm, both under an ink
// root — the ink.c3l directory, wherever the program finds it.

extern fn void* dlopen(ZString filename, int flag);
extern fn void* dlsym(void* handle, ZString symbol);
const int RTLD_NOW = 2;

alias TsLanguageFn = fn ts_bind::TSLanguage*();

faultdef NO_LANGUAGE, NOT_SHIPPED;

// lexer_for_file finds the lexer for a file, loading its grammar from the
// first of roots that has it.
fn lexer::Lexer*? lexer_for_file(String path, String[] roots) @public {
	helix::Language*? l = helix::language_for_file(path);
	if (catch l) return NO_LANGUAGE~;
	return lexer_for(l, roots);
}

fn lexer::Lexer*? lexer_for(helix::Language* l, String[] roots) @public {
	if (try found = lang_registry::find_lexer_by_name(l.name)) return found;
	foreach (root : roots) {
		String lib = string::tformat("%s/grammars/libtree-sitter-%s.dylib", root, l.grammar);
		String query_file = string::tformat("%s/data/queries/%s/highlights.scm", root, l.name);
		if (!file::exists(lib) || !file::exists(query_file)) continue;

		void* h = dlopen(lib.zstr_tcopy(), RTLD_NOW);
		if (h == null) continue;
		DString sym = dstring::temp();
		sym.append_string("tree_sitter_");
		foreach (c : l.grammar) sym.append_char(c == '-' || c == '.' ? '_' : c);
		TsLanguageFn make = (TsLanguageFn)dlsym(h, sym.str_view().zstr_tcopy());
		if (make == null) continue;
		ts_bind::TSLanguage* ts = make();
		if (ts == null) continue;

		char[]? query = file::load_temp(query_file);
		if (catch query) continue;
		lang_registry::register_language(l.name, {}, {}, ts, (String)query);
		return lang_registry::find_lexer_by_name(l.name);
	}
	return NOT_SHIPPED~;
}
