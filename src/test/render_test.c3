module ink::test;

import ink::token;
import ink::style;
import ink::colour;
import ink::themes;
import ink::ts_lexer;
import ink::ts_bind;
import std::io;

extern fn void* dlopen(char* filename, int flag);
extern fn void* dlsym(void* handle, char* symbol);
extern fn int dlclose(void* handle);
const int RTLD_NOW = 2;

extern fn void* fopen(char* path, char* mode);
extern fn int fclose(void* stream);
extern fn sz fread(void* ptr, sz size, sz count, void* stream);
extern fn int fseek(void* stream, long offset, int whence);
extern fn long ftell(void* stream);
const int SEEK_END = 2;
const int SEEK_SET = 0;

alias TsLanguageFunc = fn ts_bind::TSLanguage*();

fn String read_file_to_string(String path) {
	void* f = fopen(path.ptr, "rb");
	if (f == null) return "";
	fseek(f, 0, SEEK_END);
	long size = ftell(f);
	fseek(f, 0, SEEK_SET);
	char* buf = mem::temp_array(char, (sz)size + 1);
	sz bytes_read = fread(buf, 1, (sz)size, f);
	buf[bytes_read] = 0;
	fclose(f);
	if (bytes_read == 0) return "";
	return (String)buf[0..bytes_read-1];
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

fn ts_bind::TSLanguage* load_language(String dylib_path, String symbol_name) {
	void* handle = dlopen(dylib_path.ptr, RTLD_NOW);
	if (handle == null) return null;
	void* sym = dlsym(handle, symbol_name.ptr);
	if (sym == null) { dlclose(handle); return null; }
	TsLanguageFunc lang_fn = (TsLanguageFunc)sym;
	return lang_fn();
}

fn void run_lang_test(
	String dylib_path,
	String symbol_name,
	String query_path,
	String source_path,
	String lang_name,
	String header,
	style::Style* theme
) {
	@pool() {
	io::printf("%s\n", header.ptr);

	ts_bind::TSLanguage* lang = load_language(dylib_path, symbol_name);
	if (lang == null) {
		io::printf("  [ERROR] Could not load language dylib\n\n");
		return;
	}

	String query = read_file_to_string(query_path);
	String source = read_file_to_string(source_path);
	if (query.len == 0 || source.len == 0) {
		io::printf("  [ERROR] Could not read files\n\n");
		return;
	}

	ts_lexer::TsLexer* lexer = ts_lexer::ts_lexer_new(lang_name, (String[]){}, (String[]){}, lang, query);
	token::TokenIterator*? it_opt = lexer.tokenise(source);
	if (try it = it_opt) {
		while (try tok = token::token_iterator_next(it)) {
			render_token(theme, tok);
		}
	}
	io::printf("\n\n");
	};
}

fn void test_render_go() @test {
	themes::register_all_themes();
	style::Style* theme = style::styles_get("monokai");
	assert(theme != null);
	run_lang_test(
		"grammars/libtree-sitter-go.dylib", "tree_sitter_go",
		"data/queries/go/highlights.scm", "data/samples/example.go",
		"go", "── Go (Monokai) ──────────────────────────", theme
	);
}

fn void test_render_c() @test {
	themes::register_all_themes();
	style::Style* theme = style::styles_get("monokai");
	assert(theme != null);
	run_lang_test(
		"grammars/libtree-sitter-c.dylib", "tree_sitter_c",
		"data/queries/c/highlights.scm", "data/samples/example.c",
		"c", "── C (Monokai) ───────────────────────────", theme
	);
}

fn void test_render_python() @test {
	themes::register_all_themes();
	style::Style* theme = style::styles_get("monokai");
	assert(theme != null);
	run_lang_test(
		"grammars/libtree-sitter-python.dylib", "tree_sitter_python",
		"data/queries/python/highlights.scm", "data/samples/example.py",
		"python", "── Python (Monokai) ──────────────────────", theme
	);
}
