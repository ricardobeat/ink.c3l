module ink::themes;

import ink::style;
import ink::token;
import std::io::path, std::io::file;

struct ThemeFile @local
{
	String name;
	String toml;
}

// Each theme is a TOML file in data/themes, embedded at compile time. To add
// one, drop the file in (scripts/chroma-themes.py converts Chroma styles)
// and list it here.
const ThemeFile[*] THEME_FILES @local = {
	{ "bw",                (String)$embed("../../data/themes/bw.toml") },
	{ "catppuccin-latte",  (String)$embed("../../data/themes/catppuccin-latte.toml") },
	{ "catppuccin-mocha",  (String)$embed("../../data/themes/catppuccin-mocha.toml") },
	{ "dracula",           (String)$embed("../../data/themes/dracula.toml") },
	{ "emacs",             (String)$embed("../../data/themes/emacs.toml") },
	{ "friendly",          (String)$embed("../../data/themes/friendly.toml") },
	{ "github",            (String)$embed("../../data/themes/github.toml") },
	{ "gruvbox",           (String)$embed("../../data/themes/gruvbox.toml") },
	{ "gruvbox-light",     (String)$embed("../../data/themes/gruvbox-light.toml") },
	{ "monokai",           (String)$embed("../../data/themes/monokai.toml") },
	{ "native",            (String)$embed("../../data/themes/native.toml") },
	{ "nord",              (String)$embed("../../data/themes/nord.toml") },
	{ "onedark",           (String)$embed("../../data/themes/onedark.toml") },
	{ "rose-pine",         (String)$embed("../../data/themes/rose-pine.toml") },
	{ "rose-pine-dawn",    (String)$embed("../../data/themes/rose-pine-dawn.toml") },
	{ "solarized-dark",    (String)$embed("../../data/themes/solarized-dark.toml") },
	{ "solarized-light",   (String)$embed("../../data/themes/solarized-light.toml") },
	{ "tango",             (String)$embed("../../data/themes/tango.toml") },
	{ "tokyonight-day",    (String)$embed("../../data/themes/tokyonight-day.toml") },
	{ "tokyonight-night",  (String)$embed("../../data/themes/tokyonight-night.toml") },
	{ "vim",               (String)$embed("../../data/themes/vim.toml") },
	{ "vs",                (String)$embed("../../data/themes/vs.toml") },
	{ "xcode",             (String)$embed("../../data/themes/xcode.toml") },
};

/**
 * Register all built-in themes.
 */
fn void register_all_themes() @public
{
	foreach (f : THEME_FILES) style::styles_register(f.name, parse_theme(f.toml));
}

/**
 * Register every *.toml file in dir as a theme named after the file, so
 * dir/dracula.toml becomes "dracula". A file with the same name as a
 * built-in theme replaces it. Returns how many themes were loaded; files
 * that can't be read are skipped.
 */
fn usz? load_theme_dir(String dir) @public
{
	@pool()
	{
		PathList files = path::ls(tmem, (Path)dir, no_dirs: true, mask: "*.toml")!;
		usz loaded;
		foreach (f : files)
		{
			String file = (String)f;
			char[]? src = file::load_temp(string::tformat("%s/%s", dir, file));
			if (catch src) continue;
			String name = file[:file.len - ".toml".len].copy(mem);
			style::styles_register(name, parse_theme((String)src));
			loaded++;
		}
		return loaded;
	};
}

/**
 * Parse a theme file into a heap-allocated Style. Each line is
 * `token.name = "spec"`, where spec is a Chroma style string. Blank lines,
 * `#` comments and token names ink doesn't know are skipped.
 */
fn Style* parse_theme(String toml) @public
{
	Style* s = mem::new(Style);
	*s = style::style_new();
	foreach (raw : toml.tsplit("\n"))
	{
		String line = raw.trim();
		if (line.len == 0 || line[0] == '#') continue;
		sz? eq = line.index_of_char('=');
		if (catch eq) continue;
		String key = line[:eq].trim();
		String value = line[eq + 1..].trim();
		if (value.len < 2 || value[0] != '"' || value[^1] != '"') continue;
		token::TokenType? tt = token::token_type_from_name(key);
		if (catch tt) continue;
		style::style_add(s, tt, style::style_entry_parse(value[1:value.len - 2]));
	}
	return s;
}
