module inkfmt;

import ink::token;
import ink::style;
import ink::colour;
import ink::themes;
import ink::lexer;
import ink::lang_registry;
import ink::ts_lexer;
import ink::ts_bind;
import std::io;
import std::os;
import std::os::env;
import std::core::string;

extern fn void* dlopen(char* filename, int flag);
extern fn void* dlsym(void* handle, char* symbol);
const int RTLD_NOW = 2;

alias TsLanguageFunc = fn ts_bind::TSLanguage*();

const char[] QUERY_GO = $embed("../data/queries/go/highlights.scm");
const char[] QUERY_C = $embed("../data/queries/c/highlights.scm");
const char[] QUERY_PYTHON = $embed("../data/queries/python/highlights.scm");
const char[] QUERY_RUST = $embed("../data/queries/rust/highlights.scm");
const char[] QUERY_C3 = $embed("../data/queries/c3/highlights.scm");

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

fn bool load_grammar(String lname, String symbol, String[] aliases, String[] extensions, String query) {
	@pool() {
		String dir = exe_dir();
		String c0 = string::tformat("grammars/libtree-sitter-%s.dylib", lname);
		String c1 = string::tformat("%s/grammars/libtree-sitter-%s.dylib", dir, lname);
		String c2 = string::tformat("%s/../grammars/libtree-sitter-%s.dylib", dir, lname);
		String[] candidates = { c0, c1, c2 };
		ZString sym = symbol.zstr_tcopy();
		foreach (cand : candidates) {
			void* h = dlopen(cand.zstr_tcopy(), RTLD_NOW);
			if (h == null) continue;
			TsLanguageFunc fn_ptr = (TsLanguageFunc)dlsym(h, sym);
			if (fn_ptr == null) continue;
			ts_bind::TSLanguage* lang = fn_ptr();
			if (lang == null) continue;
			lang_registry::register_language(lname, aliases, extensions, lang, query);
			return true;
		}
		return false;
	};
}

fn void load_all_grammars() {
	load_grammar("go", "tree_sitter_go", (String[]){"go", "golang"}, (String[]){".go"}, (String)QUERY_GO);
	load_grammar("c", "tree_sitter_c", (String[]){"c"}, (String[]){".c", ".h"}, (String)QUERY_C);
	load_grammar("python", "tree_sitter_python", (String[]){"python", "py"}, (String[]){".py"}, (String)QUERY_PYTHON);
	load_grammar("rust", "tree_sitter_rust", (String[]){"rust", "rs"}, (String[]){".rs"}, (String)QUERY_RUST);
	load_grammar("c3", "tree_sitter_c3", (String[]){"c3"}, (String[]){".c3"}, (String)QUERY_C3);
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
	lexer::LexerRegistry* reg = lang_registry::get_lexer_registry();
	for (int i = 0; i < reg.count; i++) {
		lexer::LexerConfig* cfg = reg.lexers[i].config();
		io::printf("%s\n", cfg.name);
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
			themes::register_all_themes();
			load_all_grammars();
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
	load_all_grammars();

	String lang_name = lang_opt;
	if (lang_name.len == 0 && file_opt.len != 0) {
		lexer::Lexer*? by_file = lang_registry::find_lexer_by_filename(file_opt);
		if (try lf = by_file) {
			lang_name = lf.config().name;
		} else {
			io::eprintf("no lexer for file: %s (try --lang)\n", file_opt);
			os::exit(1);
		}
	}
	if (lang_name.len == 0) {
		lang_name = shebang_lang(src);
	}
	if (lang_name.len == 0) {
		lang_name = heuristic_lang(src);
	}
	if (lang_name.len == 0) {
		io::eprintf("could not detect language, pass --lang (see --list-langs)\n");
		os::exit(1);
	}

	lexer::Lexer*? lexer_opt = lang_registry::find_lexer_by_name(lang_name);
	if (catch err = lexer_opt) {
		io::eprintf("unsupported language: %s (see --list-langs)\n", lang_name);
		os::exit(1);
	}

	style::Style* theme = style::styles_get(theme_opt);
	if (theme == null) {
		io::eprintf("unknown theme: %s\n", theme_opt);
		os::exit(1);
	}

	@pool() {
		token::TokenIterator*? it_opt = lexer_opt.tokenise(src);
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
