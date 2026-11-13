module ink::grammars;

import ink::helix;
import ink::lexer;
import ink::lang_registry;
import ink::ts_bind;
import std::io;
import std::os::env;
import std::os::posix;
import std::hash::fnv64a;
import std::compression::gzip;
import libc;

// The grammars ink ships, loaded when first needed. A file's language comes
// from the Helix registry; its grammar is <set>/libtree-sitter-<grammar>.dylib
// and its query <set>/queries/<language>/highlights.scm, where <set> is
// INK_GRAMMARS_DIR under an ink root — the ink.c3l directory, wherever the
// program finds it. Built with -D EMBED_GRAMMARS, the binary carries them
// instead (src/embedded/) and the roots are not used.

// The grammar set to load: grammars/ holds the languages ink ships, and
// grammars-extended/ (made by scripts/build-grammars.sh --extended) every
// language Helix has. Build with -D INK_EXTENDED to use the extended set.
const String INK_GRAMMARS_DIR @public = $feat(INK_EXTENDED) ??? "grammars-extended" : "grammars";

extern fn void* dlopen(ZString filename, int flag);
extern fn void* dlsym(void* handle, ZString symbol);
const int RTLD_NOW = 2;

alias TsLanguageFn = fn ts_bind::TSLanguage*();

faultdef NO_LANGUAGE, NOT_SHIPPED, LOAD_FAILED, CACHE_FAILED;

// lexer_for_file finds the lexer for a file, loading its grammar from the
// first of roots that has it.
fn lexer::Lexer*? lexer_for_file(String path, String[] roots) @public {
	helix::Language*? l = helix::language_for_file(path);
	if (catch l) return NO_LANGUAGE~;
	return lexer_for(l, roots);
}

// shipped says whether one of roots (or the binary) has the grammar and
// query for l.
fn bool shipped(helix::Language* l, String[] roots) @public {
	$if $feat(EMBED_GRAMMARS):
		return find(&EMBEDDED_GRAMMARS, l.grammar) != null && find(&EMBEDDED_QUERIES, l.name) != null;
	$else
		foreach (root : roots) {
			if (file::exists(lib_path(root, l)) && file::exists(query_path(root, l))) return true;
		}
		return false;
	$endif
}

fn String lib_path(String root, helix::Language* l) @local
	=> string::tformat("%s/%s/libtree-sitter-%s.dylib", root, INK_GRAMMARS_DIR, l.grammar);

fn String query_path(String root, helix::Language* l) @local
	=> string::tformat("%s/%s/queries/%s/highlights.scm", root, INK_GRAMMARS_DIR, l.name);

fn lexer::Lexer*? lexer_for(helix::Language* l, String[] roots) @public {
	if (try found = lang_registry::find_lexer_by_name(l.name)) return found;
	$if $feat(EMBED_GRAMMARS):
		EmbeddedFile* packed = find(&EMBEDDED_GRAMMARS, l.grammar);
		EmbeddedFile* query = find(&EMBEDDED_QUERIES, l.name);
		if (packed == null || query == null) return NOT_SHIPPED~;
		return load(l, unpack(packed)!, query.data);
	$else
		foreach (root : roots) {
			String lib = lib_path(root, l);
			String query_file = query_path(root, l);
			if (!file::exists(lib) || !file::exists(query_file)) continue;
			char[]? query = file::load_temp(query_file);
			if (catch query) continue;
			if (try lx = load(l, lib, (String)query)) return lx;
		}
		return NOT_SHIPPED~;
	$endif
}

fn lexer::Lexer*? load(helix::Language* l, String lib, String query) @local {
	void* h = dlopen(lib.zstr_tcopy(), RTLD_NOW);
	if (h == null) return LOAD_FAILED~;
	DString sym = dstring::temp();
	sym.append_string("tree_sitter_");
	foreach (c : l.grammar) sym.append_char(c == '-' || c == '.' ? '_' : c);
	TsLanguageFn make = (TsLanguageFn)dlsym(h, sym.str_view().zstr_tcopy());
	if (make == null) return LOAD_FAILED~;
	ts_bind::TSLanguage* ts = make();
	if (ts == null) return LOAD_FAILED~;
	lang_registry::register_language(l.name, {}, {}, ts, query);
	return lang_registry::find_lexer_by_name(l.name);
}

// The rest is for EMBED_GRAMMARS builds. Grammars are embedded gzipped, and
// dlopen needs a file, so each is unpacked once into the cache directory
// under a name that includes a hash of its contents.

struct EmbeddedFile @if($feat(EMBED_GRAMMARS)) {
	String name;
	String data;
}

fn EmbeddedFile* find(EmbeddedFile[] files, String name) @local @if($feat(EMBED_GRAMMARS)) {
	foreach (&f : files) {
		if (f.name == name) return f;
	}
	return null;
}

// unpack returns the path of f's grammar in the cache, writing it there
// first if it isn't already. It writes to a temporary name and renames, so
// a library another process has loaded is never rewritten in place.
fn String? unpack(EmbeddedFile* f) @local @if($feat(EMBED_GRAMMARS)) {
	String dir = cache_dir()!;
	String path = string::tformat("%s/libtree-sitter-%s-%016x.dylib", dir, f.name, fnv64a::hash(f.data));
	if (file::exists(path)) return path;
	(void)path::mkdir((Path)dir, recursive: true);
	char[]? raw = gzip::uncompress_bytes(tmem, f.data);
	if (catch raw) return LOAD_FAILED~;
	String tmp = string::tformat("%s.%d.tmp", path, posix::getpid());
	if (catch file::save(tmp, raw)) return CACHE_FAILED~;
	if (libc::rename(tmp.zstr_tcopy(), path.zstr_tcopy()) != 0) {
		(void)file::delete(tmp);
		return CACHE_FAILED~;
	}
	return path;
}

// cache_dir is ~/Library/Caches/ink on macOS, and $XDG_CACHE_HOME/ink or
// ~/.cache/ink elsewhere.
fn String? cache_dir() @local @if($feat(EMBED_GRAMMARS)) {
	$if env::DARWIN:
		String? home = env::tget_var("HOME");
		if (catch home) return CACHE_FAILED~;
		return string::tformat("%s/Library/Caches/ink", home);
	$else
		if (try xdg = env::tget_var("XDG_CACHE_HOME")) return string::tformat("%s/ink", xdg);
		String? home = env::tget_var("HOME");
		if (catch home) return CACHE_FAILED~;
		return string::tformat("%s/.cache/ink", home);
	$endif
}
