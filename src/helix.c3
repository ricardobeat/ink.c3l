module ink::helix;

import std::collections::list;

// The language registry, read from Helix's languages.toml (vendored in
// data/helix, pinned to HELIX_REV). It says which languages exist, which
// files belong to each, and where each grammar's source lives — enough to
// offer a grammar for a file and to build it (see ink::install).
//
// Only the parts ink needs are read: a [[language]]'s name, file-types and
// grammar, and a [[grammar]]'s name and source. Everything else, including
// the nested tables Helix hangs off a language, is skipped. Every string is
// a slice of the embedded file, so the registry copies no text; only its
// lists allocate, and unload() frees them.

const String HELIX_REV = "079a789e8cb08ead67f19e1971a1b7438b37354b";
const char[] LANGUAGES_TOML = $embed("../data/helix/languages.toml");

struct Language {
	String name;
	// The grammar it parses with; the language's own name unless it says.
	String grammar;
	// Plain entries in file-types: an extension, or a whole file name.
	List{String} file_types;
	// { glob = "..." } entries, matched against the file name.
	List{String} globs;
}

struct Grammar {
	String name;
	String git;
	String rev;
	// Where in the repository the grammar is, for repositories holding
	// several (tree-sitter-typescript has typescript/ and tsx/).
	String subpath;
}

List{Language} languages;
List{Grammar} grammars;
bool loaded;

// unload frees the registry; the next lookup reads it again.
fn void unload() @public {
	foreach (&l : languages) {
		l.file_types.free();
		l.globs.free();
	}
	languages.free();
	grammars.free();
	loaded = false;
}

// ── lookup ────────────────────────────────────────────────────────────────

// language_for_file finds the language a file belongs to by its name.
fn Language*? language_for_file(String path) @public {
	load();
	String base = basename(path);
	String ext = extension(base);
	// Globs and whole names are more specific than an extension, so a
	// tsconfig.json is jsonc rather than json.
	foreach (&l : languages) {
		foreach (g : l.globs) if (glob_match(g, base)) return l;
	}
	foreach (&l : languages) {
		foreach (ft : l.file_types) if (ft == base) return l;
	}
	if (ext.len == 0) return NOT_FOUND~;
	foreach (&l : languages) {
		foreach (ft : l.file_types) if (ft == ext) return l;
	}
	return NOT_FOUND~;
}

fn Language*? language_named(String name) @public {
	load();
	foreach (&l : languages) if (l.name == name) return l;
	return NOT_FOUND~;
}

fn Grammar*? grammar_for(Language* l) @public {
	load();
	foreach (&g : grammars) if (g.name == l.grammar) return g;
	return NOT_FOUND~;
}

faultdef NOT_FOUND;

fn String basename(String path) @local {
	for (sz i = path.len; i > 0; i--) {
		if (path[i - 1] == '/') return path[i..];
	}
	return path;
}

fn String extension(String base) @local {
	for (sz i = base.len; i > 1; i--) {
		if (base[i - 1] == '.') return base[i..];
	}
	return "";
}

// glob_match matches name against a pattern with * and ?; a {a,b}
// alternation matches either branch.
fn bool glob_match(String pat, String name) @local {
	for (sz i = 0; i < pat.len; i++) {
		if (pat[i] != '{') continue;
		sz close = i;
		while (close < pat.len && pat[close] != '}') close++;
		if (close == pat.len) break;
		String head = pat[:i];
		String tail = pat[close + 1..];
		sz start = i + 1;
		for (sz j = i + 1; j <= close; j++) {
			if (j < close && pat[j] != ',') continue;
			String alt = string::tformat("%s%s%s", head, pat[start:j - start], tail);
			if (glob_match(alt, name)) return true;
			start = j + 1;
		}
		return false;
	}
	return wild_match(pat, name);
}

fn bool wild_match(String p, String s) @local {
	if (p.len == 0) return s.len == 0;
	if (p[0] == '*') {
		for (sz i = 0; i <= s.len; i++) {
			if (wild_match(p[1..], s[i..])) return true;
		}
		return false;
	}
	if (s.len == 0) return false;
	if (p[0] == '?' || p[0] == s[0]) return wild_match(p[1..], s[1..]);
	return false;
}

// ── reading languages.toml ────────────────────────────────────────────────

enum Section {
	OTHER,
	LANGUAGE,
	GRAMMAR,
}

fn void load() @local {
	if (loaded) return;
	loaded = true;
	String src = (String)LANGUAGES_TOML;
	Section section = OTHER;
	sz i = 0;
	while (i < src.len) {
		sz end = line_end(src, i);
		String line = strip_comment(src[i:end - i]).trim();
		sz line_start = i;
		i = end + 1;
		if (line.len == 0) continue;

		if (line[0] == '[') {
			if (line == "[[language]]") {
				section = LANGUAGE;
				languages.push({});
			} else if (line == "[[grammar]]") {
				section = GRAMMAR;
				grammars.push({});
			} else {
				section = OTHER;
			}
			continue;
		}
		if (section == OTHER) continue;

		sz eq = 0;
		while (eq < line.len && line[eq] != '=') eq++;
		if (eq == line.len) continue;
		String key = line[:eq].trim();

		// The value runs from after the = to the end of the line, or on
		// through the lines below while an array or table is still open.
		sz vstart = line_start;
		while (src[vstart] != '=') vstart++;
		vstart++;
		sz vend = end;
		while (!balanced(src[vstart:vend - vstart]) && vend < src.len) {
			vend = line_end(src, vend + 1);
		}
		String value = src[vstart:vend - vstart].trim();
		if (vend > end) i = vend + 1;

		if (section == LANGUAGE) {
			Language* l = &languages[languages.len() - 1];
			switch (key) {
				case "name":
					l.name = unquote(value);
					if (l.grammar.len == 0) l.grammar = l.name;
				case "grammar":
					l.grammar = unquote(value);
				case "file-types":
					read_file_types(l, value);
				default:
			}
		} else {
			Grammar* g = &grammars[grammars.len() - 1];
			switch (key) {
				case "name": g.name = unquote(value);
				case "source":
					g.git = table_field(value, "git");
					g.rev = table_field(value, "rev");
					g.subpath = table_field(value, "subpath");
				default:
			}
		}
	}
}

fn sz line_end(String s, sz i) @local {
	while (i < s.len && s[i] != '\n') i++;
	return i;
}

// read_file_types splits a file-types array into plain entries and globs.
fn void read_file_types(Language* l, String value) @local {
	sz i = 0;
	while (i < value.len) {
		char c = value[i];
		if (c == '#') {
			i = line_end(value, i);
			continue;
		}
		if (c == '"') {
			l.file_types.push(next_string(value, &i));
			continue;
		}
		if (c == '{') {
			sz close = i;
			while (close < value.len && value[close] != '}') {
				if (value[close] == '"') { next_string(value, &close); continue; }
				close++;
			}
			if (close >= value.len) break;
			String g = table_field(value[i:close - i + 1], "glob");
			if (g.len > 0) l.globs.push(g);
			i = close + 1;
			continue;
		}
		i++;
	}
}

// table_field reads key = "value" out of an inline table.
fn String table_field(String table, String key) @local {
	sz i = 0;
	while (i < table.len) {
		if (table[i] == '"') {
			next_string(table, &i);
			continue;
		}
		if (i + key.len <= table.len && table[i:key.len] == key
			&& (i == 0 || table[i - 1] == ' ' || table[i - 1] == '{' || table[i - 1] == ',')) {
			sz j = i + key.len;
			while (j < table.len && table[j] == ' ') j++;
			if (j < table.len && table[j] == '=') {
				j++;
				while (j < table.len && table[j] == ' ') j++;
				if (j < table.len && table[j] == '"') return next_string(table, &j);
			}
		}
		i++;
	}
	return "";
}

// next_string reads the quoted string at *i and moves past it. Escapes are
// kept as written; none of the fields ink reads use them.
fn String next_string(String s, sz* i) @local {
	sz start = *i + 1;
	sz j = start;
	while (j < s.len && s[j] != '"') {
		if (s[j] == '\\') j++;
		j++;
	}
	*i = j + 1;
	return s[start:(j < s.len ? j : s.len) - start];
}

fn String unquote(String v) @local {
	if (v.len >= 2 && v[0] == '"') {
		sz i = 0;
		return next_string(v, &i);
	}
	return v;
}

// strip_comment drops a # comment, minding # inside strings.
fn String strip_comment(String line) @local {
	bool in_str = false;
	for (sz i = 0; i < line.len; i++) {
		if (line[i] == '\\' && in_str) { i++; continue; }
		if (line[i] == '"') in_str = !in_str;
		if (line[i] == '#' && !in_str) return line[:i];
	}
	return line;
}

// balanced reports whether every [ and { in v outside strings and comments
// is closed.
fn bool balanced(String v) @local {
	int depth = 0;
	bool in_str = false;
	for (sz i = 0; i < v.len; i++) {
		if (v[i] == '\\' && in_str) { i++; continue; }
		if (v[i] == '"') in_str = !in_str;
		if (in_str) continue;
		if (v[i] == '#') { i = line_end(v, i); continue; }
		if (v[i] == '[' || v[i] == '{') depth++;
		if (v[i] == ']' || v[i] == '}') depth--;
	}
	return depth <= 0;
}
