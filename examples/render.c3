module render;

import ink::token;
import ink::style;
import ink::colour;
import ink::themes;
import ink::ts_lexer;
import ink::ts_bind;
import ink::captures;
import std::io;

extern fn void* dlopen(char* filename, int flag);
extern fn void* dlsym(void* handle, char* symbol);
extern fn void* fopen(char* path, char* mode);
extern fn int fclose(void* stream);
extern fn sz fread(void* ptr, sz size, sz count, void* stream);
extern fn int fseek(void* stream, long offset, int whence);
extern fn long ftell(void* stream);
const int RTLD_NOW = 2;
const int SEEK_END = 2;
const int SEEK_SET = 0;

alias TsLanguageFunc = fn ts_bind::TSLanguage*();

fn String read_file(char* path) {
	void* f = fopen(path, "rb");
	if (f == null) { io::printf("Cannot open: %s\n", path); return ""; }
	fseek(f, 0, SEEK_END);
	long size = ftell(f);
	fseek(f, 0, SEEK_SET);
	char* buf = mem::new_array(char, (sz)size + 1);
	sz n = fread(buf, 1, (sz)size, f);
	buf[n] = 0;
	fclose(f);
	if (n == 0) return "";
	return (String)buf[0..n-1];
}

fn void ansi_fg(Colour c) {
	if (!colour::colour_is_set(c)) return;
	io::printf("\x1b[38;2;%d;%d;%dm", (int)colour::colour_red(c), (int)colour::colour_green(c), (int)colour::colour_blue(c));
}

fn void ansi_bg(Colour c) {
	if (!colour::colour_is_set(c)) return;
	io::printf("\x1b[48;2;%d;%d;%dm", (int)colour::colour_red(c), (int)colour::colour_green(c), (int)colour::colour_blue(c));
}

fn void ansi_reset() { io::printf("\x1b[0m"); }

fn void render_token(style::Style* theme, token::Token tok) {
	style::StyleEntry entry = style::style_get(theme, tok.type);
	if (colour::colour_is_set(entry.bg)) ansi_bg(entry.bg);
	if (colour::colour_is_set(entry.fg)) ansi_fg(entry.fg);
	if (entry.bold) io::printf("\x1b[1m");
	if (entry.italic) io::printf("\x1b[3m");
	io::printf("%s", tok.value);
	ansi_reset();
}

fn void render_lang(char* dylib, char* symbol, char* query_path, char* source_path, String name) {
	void* handle = dlopen(dylib, RTLD_NOW);
	if (handle == null) { io::printf("Cannot load: %s\n", dylib); return; }
	TsLanguageFunc fn_ptr = (TsLanguageFunc)dlsym(handle, symbol);
	if (fn_ptr == null) { io::printf("Cannot find: %s\n", symbol); return; }
	ts_bind::TSLanguage* lang = fn_ptr();

	String query = read_file(query_path);
	String source = read_file(source_path);
	if (query.len == 0 || source.len == 0) return;

	io::printf("\n\x1b[1m── %s ──\x1b[0m\n", name);

	style::Style* theme = style::styles_get("monokai");

	@pool() {
		ts_lexer::TsLexer* lexer = ts_lexer::ts_lexer_new(
			name,
			(String[]){},
			(String[]){},
			lang,
			query
		);

		token::TokenIterator*? it_opt = lexer.tokenise(source);
		if (try it = it_opt) {
			while (try tok = token::token_iterator_next(it)) {
				render_token(theme, tok);
			}
		}
	};
	io::printf("\n");
}

fn void main() @export {
	themes::register_all_themes();

	render_lang(
		"grammars/libtree-sitter-go.dylib",
		"tree_sitter_go",
		"data/queries/go/highlights.scm",
		"data/samples/example.go",
		"Go"
	);
	render_lang(
		"grammars/libtree-sitter-c.dylib",
		"tree_sitter_c",
		"data/queries/c/highlights.scm",
		"data/samples/example.c",
		"C"
	);
	render_lang(
		"grammars/libtree-sitter-python.dylib",
		"tree_sitter_python",
		"data/queries/python/highlights.scm",
		"data/samples/example.py",
		"Python"
	);
}
