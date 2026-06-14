module ink::themes;

import ink::style;

/**
 * Register all built-in themes.
 */
fn void register_all_themes() @public {
	register_monokai();
	register_github();
}
