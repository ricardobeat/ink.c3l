module ink::build;

import ink::helix;
import std::io;

// Building a grammar from source: fetch it from the git repository Helix
// names, at Helix's pinned revision; compile it into a shared library; and
// fetch Helix's highlight query for the language, with the queries it
// inherits from. cli/grammars.c3 drives it to fill ink's grammars/ and
// data/queries/ ahead of time.
//
// It shells out to git, cc and curl, which must be on the PATH, and it
// blocks for as long as the fetch and the compile take.

extern fn int system(ZString command);

faultdef NO_GRAMMAR, FETCH_FAILED, BUILD_FAILED, QUERY_FAILED;

// Queries may say they inherit others ("; inherits: ecma,jsx"); this deep is
// plenty for Helix's, and stops a cycle.
const int MAX_INHERIT_DEPTH = 4;

// Dirs says where a build reads and writes.
struct Dirs {
	// Compiled grammars: libtree-sitter-<grammar>.dylib.
	String grammars;
	// Highlight queries: <language>/highlights.scm.
	String queries;
	// Grammar checkouts, kept so a rebuild need not fetch again.
	String work;
	// What git, cc and curl said, appended to.
	String log;
}

fn String library_path(Dirs* d, helix::Language* l) @public {
	return string::tformat("%s/libtree-sitter-%s.dylib", d.grammars, l.grammar);
}

fn String query_path(Dirs* d, helix::Language* l) @public {
	return string::tformat("%s/%s/highlights.scm", d.queries, l.name);
}

// build makes l's grammar and query, skipping whichever already exists —
// several languages share a grammar, and a hand-tuned query is kept.
fn void? build(Dirs* d, helix::Language* l) @public {
	if (!file::exists(library_path(d, l))) build_grammar(d, l)!;
	if (!file::exists(query_path(d, l))) {
		run(d, string::tformat("mkdir -p %s", quote(string::tformat("%s/%s", d.queries, l.name))), QUERY_FAILED)!;
		DString query;
		defer query.free();
		fetch_query(d, &query, l.name, 0)!;
		if (catch file::save(query_path(d, l), query.str_view())) return QUERY_FAILED~;
	}
}

fn void? build_grammar(Dirs* d, helix::Language* l) @local {
	helix::Grammar*? found = helix::grammar_for(l);
	if (catch found) return NO_GRAMMAR~;
	helix::Grammar* g = found;
	if (g.git.len == 0 || g.rev.len == 0) return NO_GRAMMAR~;

	String checkout = string::tformat("%s/%s", d.work, g.name);
	String src_dir = g.subpath.len > 0
		? string::tformat("%s/%s/src", checkout, g.subpath)
		: string::tformat("%s/src", checkout);

	run(d, string::tformat("mkdir -p %s %s", quote(checkout), quote(d.grammars)), FETCH_FAILED)!;

	// A shallow fetch of the one pinned commit, not the whole history.
	run(d, string::tformat(
		"cd %s && git init -q && git fetch -q --depth 1 %s %s && git checkout -q -f FETCH_HEAD",
		quote(checkout), quote(g.git), quote(g.rev)), FETCH_FAILED)!;

	// parser.c always; a hand-written scanner when there is one, in C or C++.
	run(d, string::tformat(
		"cd %s && files=parser.c && link=cc"
		" && if [ -f scanner.c ]; then files=\"$files scanner.c\"; fi"
		" && if [ -f scanner.cc ]; then c++ -c -fPIC -O2 -I. scanner.cc -o scanner.o && files=\"$files scanner.o\" && link=c++; fi"
		" && $link -shared -fPIC -O2 -I. $files -o %s",
		quote(src_dir), quote(library_path(d, l))), BUILD_FAILED)!;
}

// fetch_query appends Helix's highlights for lang to out, with the queries
// it inherits from first, the way Helix assembles them.
fn void? fetch_query(Dirs* d, DString* out, String lang, int depth) @local {
	if (depth > MAX_INHERIT_DEPTH) return;
	String url = string::tformat(
		"https://raw.githubusercontent.com/helix-editor/helix/%s/runtime/queries/%s/highlights.scm",
		helix::HELIX_REV, lang);
	String tmp = string::tformat("%s/.query-%s.scm", d.work, lang);
	run(d, string::tformat("mkdir -p %s && curl -fsSL %s -o %s", quote(d.work), quote(url), quote(tmp)), QUERY_FAILED)!;
	char[]? data = file::load_temp(tmp);
	if (catch data) return QUERY_FAILED~;
	(void)file::delete(tmp);
	String text = (String)data;

	// "; inherits: a,b" in the comments at the top names the parents.
	sz i = 0;
	while (i < text.len) {
		sz end = i;
		while (end < text.len && text[end] != '\n') end++;
		String line = text[i:end - i].trim();
		i = end + 1;
		if (!line.starts_with(";")) {
			if (line.len > 0) break;
			continue;
		}
		String rest = line[1..].trim();
		if (!rest.starts_with("inherits:")) continue;
		String names = rest["inherits:".len..].trim();
		sz start = 0;
		for (sz j = 0; j <= names.len; j++) {
			if (j < names.len && names[j] != ',') continue;
			String parent = names[start:j - start].trim();
			if (parent.len > 0) fetch_query(d, out, parent, depth + 1)!;
			start = j + 1;
		}
	}
	out.append_string(text);
	out.append_char('\n');
}

// run runs a shell command, logging its output, and fails with f when the
// command does.
fn void? run(Dirs* d, String command, fault f) @local {
	String line = string::tformat("{ %s; } >>%s 2>&1", command, quote(d.log));
	if (system(line.zstr_tcopy()) != 0) return f~;
}

// quote makes s one shell word.
fn String quote(String s) @local {
	DString q = dstring::temp();
	q.append_char('\'');
	foreach (c : s) {
		if (c == '\'') {
			q.append_string("'\\''");
		} else {
			q.append_char(c);
		}
	}
	q.append_char('\'');
	return q.str_view();
}
