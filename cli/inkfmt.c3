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

// roots are where inkfmt looks for grammars/ and data/queries/: the current
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

fn void usage() {
	io::eprintf("usage: inkfmt [--lang NAME] [--file NAME] [--theme NAME] [--list-langs] [--help] < stdin\n");
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

	for (sz i = 1; i < args.len; i++) {
		String a = args[i];
		if (a == "--help" || a == "-h") {
			usage();
			return;
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
			while (try tok = token::token_iterator_next(it)) {
				render_token(theme, tok);
			}
		} else {
			io::eprintf("failed to tokenise input\n");
			os::exit(1);
		}
	};
	(void)io::stdout().flush();
}
