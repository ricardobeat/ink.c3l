module inkfmt;

import ink::token;
import ink::style;
import ink::colour;
import ink::themes;
import ink::lexer;
import ink::helix;
import ink::grammars;
import std::io;
import std::os;
import std::os::env;
import std::core::string;
import std::collections::list;

// roots are where inkfmt looks for its grammar set (grammars::INK_GRAMMARS_DIR): the current
// directory, then next to and above the executable.
String[3] root_list;

fn String[] roots() {
	if (root_list[0].len == 0) {
		String dir = exe_dir().copy(mem);
		root_list = { ".", dir, string::format(mem, "%s/..", dir) };
	}
	return &root_list;
}

fn String exe_dir() {
	String? p = os::env::executable_path();
	if (catch err = p) return "";
	sz slash = 0;
	bool found = false;
	for (sz i = 0; i < p.len; i++) {
		if (p.ptr[i] == '/') { slash = i; found = true; }
	}
	if (!found) return "";
	if (slash == 0) return "/";
	return p[0..slash - 1];
}

// language_for_name finds a language by its Helix name, or failing that by
// treating name as an extension, so --lang py and --lang yml work too.
fn helix::Language*? language_for_name(String name) {
	if (try l = helix::language_named(name)) return l;
	return helix::language_for_file(string::tformat("x.%s", name));
}

fn int count_sub(String hay, String needle) {
	if (needle.len == 0 || hay.len < needle.len) return 0;
	int n = 0;
	for (sz i = 0; i + needle.len <= hay.len; i++) {
		bool match = true;
		for (sz j = 0; j < needle.len; j++) {
			if (hay.ptr[i + j] != needle.ptr[j]) { match = false; break; }
		}
		if (match) n++;
	}
	return n;
}

fn String shebang_lang(String src) {
	if (!src.starts_with("#!")) return "";
	sz end = 0;
	while (end < src.len && src.ptr[end] != '\n') end++;
	String first;
	if (end >= src.len) {
		first = src;
	} else {
		first = src[0..end];
	}
	if (first.contains("python")) return "python";
	if (first.contains("ruby")) return "ruby";
	if (first.contains("node") || first.contains("deno") || first.contains("bun")) return "javascript";
	if (first.contains("bash") || first.contains("sh")) return "bash";
	return "";
}

fn String heuristic_lang(String src) {
	int go = count_sub(src, "package ") + count_sub(src, "func ") + count_sub(src, ":=") + count_sub(src, "import (");
	int c = count_sub(src, "#include") + count_sub(src, "#define") + count_sub(src, "int main") + count_sub(src, "printf(");
	int py = count_sub(src, "def ") + count_sub(src, "elif ") + count_sub(src, "print(") + count_sub(src, "self") + count_sub(src, "None");
	int rs = count_sub(src, "fn ") + count_sub(src, "let mut") + count_sub(src, "impl ") + count_sub(src, "unwrap()");
	int c3 = count_sub(src, "module ") + count_sub(src, "import ") + count_sub(src, "!!") + count_sub(src, "@test") + count_sub(src, "defer ") + count_sub(src, "faultdef") + count_sub(src, "@pool") + count_sub(src, "$embed");
	int best = go;
	String name = "go";
	if (c > best) { best = c; name = "c"; }
	if (py > best) { best = py; name = "python"; }
	if (rs > best) { best = rs; name = "rust"; }
	if (c3 > best) { best = c3; name = "c3"; }
	if (best == 0) return "";
	int ties = 0;
	if (go == best) ties++;
	if (c == best) ties++;
	if (py == best) ties++;
	if (rs == best) ties++;
	if (c3 == best) ties++;
	if (ties > 1) return "";
	return name;
}

fn void render_token(style::Style* theme, token::Token tok) {
	style::StyleEntry entry = style::style_get(theme, tok.type);
	if (colour::colour_is_set(entry.bg)) io::printf("\x1b[48;2;%d;%d;%dm", (int)colour::colour_red(entry.bg), (int)colour::colour_green(entry.bg), (int)colour::colour_blue(entry.bg));
	if (colour::colour_is_set(entry.fg)) io::printf("\x1b[38;2;%d;%d;%dm", (int)colour::colour_red(entry.fg), (int)colour::colour_green(entry.fg), (int)colour::colour_blue(entry.fg));
	if (entry.bold) io::printf("\x1b[1m");
	if (entry.italic) io::printf("\x1b[3m");
	io::printf("%s", tok.value);
	io::printf("\x1b[0m");
}

// HtmlWriter emits a stylesheet followed by a <pre> with classed spans.
// Runs of tokens that share a style are written as one span, and the span
// is left out where the style is just the <pre>'s own colours.
struct HtmlWriter {
	style::Style* theme;
	style::StyleEntry base;
	style::StyleEntry open;
	List{style::StyleEntry} classes;
	bool is_open;
}

fn void html_colour(String prop, colour::Colour c) {
	io::printf("%s:#%02x%02x%02x;", prop, (int)colour::colour_red(c), (int)colour::colour_green(c), (int)colour::colour_blue(c));
}

fn void html_escape(String s) {
	sz start = 0;
	foreach (i, c : s) {
		String rep;
		switch (c) {
			case '&': rep = "&amp;";
			case '<': rep = "&lt;";
			case '>': rep = "&gt;";
			case '"': rep = "&quot;";
			default: continue;
		}
		io::print(s[start:i - start]);
		io::print(rep);
		start = i + 1;
	}
	io::print(s[start..]);
}

fn bool same_entry(style::StyleEntry a, style::StyleEntry b) {
	return a.fg == b.fg && a.bg == b.bg && a.bold == b.bold && a.italic == b.italic && a.underline == b.underline;
}

fn style::StyleEntry HtmlWriter.relative_entry(&self, style::StyleEntry entry) {
	// Colours equal to the <pre>'s are inherited, so they need no span.
	if (entry.fg == self.base.fg) entry.fg = (colour::Colour)0;
	if (entry.bg == self.base.bg) entry.bg = (colour::Colour)0;
	return entry;
}

fn sz HtmlWriter.class_for(&self, style::StyleEntry entry) {
	foreach (i, existing : self.classes) {
		if (same_entry(entry, existing)) return i;
	}
	self.classes.push(entry);
	return self.classes.len() - 1;
}

fn void html_style(style::StyleEntry entry) {
	if (colour::colour_is_set(entry.fg)) html_colour("color", entry.fg);
	if (colour::colour_is_set(entry.bg)) html_colour("background", entry.bg);
	if (entry.bold) io::print("font-weight:bold;");
	if (entry.italic) io::print("font-style:italic;");
	if (entry.underline) io::print("text-decoration:underline;");
}

fn void HtmlWriter.begin(&self) {
	self.base = style::style_get(self.theme, token::BACKGROUND);
	self.base.fg = style::style_get(self.theme, token::TEXT).fg;
	self.classes.init(mem);
	// Include parent entries so every result of style_get has a CSS class.
	for (style::Style* theme = self.theme; theme != null; theme = theme.parent) {
		for (int i = 0; i < theme.count; i++) {
			style::StyleEntry entry = self.relative_entry(theme.entries[i]);
			if (!same_entry(entry, style::style_entry_zero())) self.class_for(entry);
		}
	}
	io::print("<style>\n.ink{");
	if (colour::colour_is_set(self.base.bg)) html_colour("background", self.base.bg);
	if (colour::colour_is_set(self.base.fg)) html_colour("color", self.base.fg);
	io::print("}\n");
	foreach (i, entry : self.classes) {
		io::printf(".ink .ink-s%d{", i);
		html_style(entry);
		io::print("}\n");
	}
	io::print("</style>\n<pre class=\"ink\">");
}

fn void HtmlWriter.write(&self, token::Token tok) {
	style::StyleEntry entry = self.relative_entry(style::style_get(self.theme, tok.type));
	if (!self.is_open || !same_entry(entry, self.open)) {
		self.close();
		if (colour::colour_is_set(entry.fg) || colour::colour_is_set(entry.bg) || entry.bold || entry.italic || entry.underline) {
			io::printf("<span class=\"ink-s%d\">", self.class_for(entry));
			self.open = entry;
			self.is_open = true;
		}
	}
	html_escape(tok.value);
}

fn void HtmlWriter.close(&self) {
	if (self.is_open) io::print("</span>");
	self.is_open = false;
}

fn void HtmlWriter.end(&self) {
	self.close();
	io::print("</pre>\n");
	self.classes.free();
}

fn void usage() {
	io::eprintf("usage: inkfmt [--lang NAME] [--file NAME] [--theme NAME] [--theme-dir DIR] [--html] [--list-langs] [--help] < stdin\n");
}

fn void list_langs() {
	String[] rs = roots();
	foreach (&l : helix::all()) {
		if (grammars::shipped(l, rs)) io::printn(l.name);
	}
}

fn void main(String[] args) {
	String lang_opt = "";
	String file_opt = "";
	String theme_opt = "monokai";
	String theme_dir = "";
	bool html = false;

	for (sz i = 1; i < args.len; i++) {
		String a = args[i];
		if (a == "--help" || a == "-h") {
			usage();
			return;
		} else if (a == "--html") {
			html = true;
		} else if (a == "--list-langs") {
			list_langs();
			return;
		} else if (a == "--lang" || a == "-l") {
			if (i + 1 >= args.len) { io::eprintf("--lang needs a value\n"); os::exit(2); }
			i++;
			lang_opt = args[i];
		} else if (a.starts_with("--lang=")) {
			lang_opt = a["--lang=".len..];
		} else if (a == "--file" || a == "-f") {
			if (i + 1 >= args.len) { io::eprintf("--file needs a value\n"); os::exit(2); }
			i++;
			file_opt = args[i];
		} else if (a.starts_with("--file=")) {
			file_opt = a["--file=".len..];
		} else if (a == "--theme" || a == "-t") {
			if (i + 1 >= args.len) { io::eprintf("--theme needs a value\n"); os::exit(2); }
			i++;
			theme_opt = args[i];
		} else if (a.starts_with("--theme=")) {
			theme_opt = a["--theme=".len..];
		} else if (a == "--theme-dir") {
			if (i + 1 >= args.len) { io::eprintf("--theme-dir needs a value\n"); os::exit(2); }
			i++;
			theme_dir = args[i];
		} else if (a.starts_with("--theme-dir=")) {
			theme_dir = a["--theme-dir=".len..];
		} else {
			io::eprintf("unknown argument: %s\n", a);
			usage();
			os::exit(2);
		}
	}

	char[]? data_opt = io::read_fully(mem, io::stdin());
	if (catch err = data_opt) {
		io::eprintf("failed to read stdin\n");
		os::exit(1);
	}
	if (data_opt.len == 0) {
		io::eprintf("no input on stdin\n");
		os::exit(1);
	}
	String src = (String)data_opt;

	themes::register_all_themes();
	if (theme_dir.len != 0) {
		if (catch themes::load_theme_dir(theme_dir)) {
			io::eprintf("can't read theme dir: %s\n", theme_dir);
			os::exit(1);
		}
	}
	String[] rs = roots();

	lexer::Lexer* lex;
	if (lang_opt.len == 0 && file_opt.len != 0) {
		lexer::Lexer*? by_file = grammars::lexer_for_file(file_opt, rs);
		if (catch err = by_file) {
			if (err == grammars::NOT_SHIPPED) {
				io::eprintf("no grammar installed for file: %s\n", file_opt);
			} else {
				io::eprintf("no language for file: %s (try --lang)\n", file_opt);
			}
			os::exit(1);
		}
		lex = by_file;
	} else {
		String lang_name = lang_opt;
		if (lang_name.len == 0) lang_name = shebang_lang(src);
		if (lang_name.len == 0) lang_name = heuristic_lang(src);
		if (lang_name.len == 0) {
			io::eprintf("could not detect language, pass --lang (see --list-langs)\n");
			os::exit(1);
		}
		helix::Language*? l = language_for_name(lang_name);
		if (catch l) {
			io::eprintf("unknown language: %s (see --list-langs)\n", lang_name);
			os::exit(1);
		}
		lexer::Lexer*? by_name = grammars::lexer_for(l, rs);
		if (catch by_name) {
			io::eprintf("no grammar installed for language: %s (see --list-langs)\n", l.name);
			os::exit(1);
		}
		lex = by_name;
	}

	style::Style* theme = style::styles_get(theme_opt);
	if (theme == null) {
		io::eprintf("unknown theme: %s\n", theme_opt);
		os::exit(1);
	}

	@pool() {
		token::TokenIterator*? it_opt = lex.tokenise(src);
		if (try it = it_opt) {
			if (html) {
				HtmlWriter w = { .theme = theme };
				w.begin();
				while (try tok = token::token_iterator_next(it)) w.write(tok);
				w.end();
			} else {
				while (try tok = token::token_iterator_next(it)) {
					render_token(theme, tok);
				}
			}
		} else {
			io::eprintf("failed to tokenise input\n");
			os::exit(1);
		}
	};
	(void)io::stdout().flush();
}
