module ink::lexer;

import ink::token;

faultdef LEXER_DONE;

/**
 * Configuration for a language lexer.
 */
struct LexerConfig
{
	String name;
	String[] aliases;
	String[] extensions;
}

/**
 * Registry that stores all available lexers.
 */
const int MAX_LEXERS = 128;

struct LexerRegistry
{
	Lexer*[128] lexers;
	int count;
}

/**
 * Interface that all language lexers must implement.
 */
interface Lexer
{
	fn LexerConfig* config();
	fn token::TokenIterator*? tokenise(String text);
	fn LexerRegistry* registry();
	fn void setRegistry(LexerRegistry* reg);
}

/**
 * Register a lexer in the registry.
 */
fn void lexer_registry_register(LexerRegistry* reg, Lexer* lexer) @public
{
	if (reg.count >= MAX_LEXERS) return;
	reg.lexers[reg.count] = lexer;
	lexer.setRegistry(reg);
	reg.count++;
}

/**
 * Lookup a lexer by name or alias (case-insensitive).
 */
fn Lexer*? lexer_registry_by_name(LexerRegistry* reg, String name) @public
{
	for (int i = 0; i < reg.count; i++)
	{
		Lexer* lexer = reg.lexers[i];
		LexerConfig* cfg = lexer.config();

		if (str_eqi(cfg.name, name))
		{
			return lexer;
		}

		foreach (alias_name : cfg.aliases)
		{
			if (str_eqi(alias_name, name))
			{
				return lexer;
			}
		}
	}
	return LEXER_DONE~;
}

/**
 * Lookup a lexer by file extension (e.g., ".go").
 */
fn Lexer*? lexer_registry_by_extension(LexerRegistry* reg, String ext) @public
{
	for (int i = 0; i < reg.count; i++)
	{
		Lexer* lexer = reg.lexers[i];
		LexerConfig* cfg = lexer.config();

		foreach (extension : cfg.extensions)
		{
			if (str_eqi(extension, ext))
			{
				return lexer;
			}
		}
	}
	return LEXER_DONE~;
}

/**
 * Lookup a lexer by filename. Extracts the extension and delegates.
 */
fn Lexer*? lexer_registry_by_filename(LexerRegistry* reg, String filename) @public
{
	int dot_pos = -1;
	for (int i = filename.len - 1; i >= 0; i--)
	{
		if (filename.ptr[i] == '.')
		{
			dot_pos = i;
			break;
		}
	}

	if (dot_pos < 0 || dot_pos == filename.len - 1)
	{
		return LEXER_DONE~;
	}

	String ext = filename[dot_pos..];
	return lexer_registry_by_extension(reg, ext);
}

// ---- Internal helpers ----

fn bool str_eqi(String a, String b)
{
	if (a.len != b.len) return false;
	for (int i = 0; i < a.len; i++)
	{
		char ca = char_lower(a.ptr[i]);
		char cb = char_lower(b.ptr[i]);
		if (ca != cb) return false;
	}
	return true;
}

fn char char_lower(char c)
{
	if (c >= 'A' && c <= 'Z') return (char)(c + 32);
	return c;
}

// ---- Coalesce ----

const int COALESCE_MAX_LEN = 8192;

struct CoalesceState
{
	token::TokenIterator inner;
	token::Token buffered;
	bool has_buffered;
}

fn token::Token? coalesce_next(void* ctx)
{
	CoalesceState* state = (CoalesceState*)ctx;

	if (state.has_buffered)
	{
		token::Token tok = state.buffered;
		state.has_buffered = false;
		return tok;
	}

	token::Token? first_opt = token::token_iterator_next(&state.inner);
	if (try first = first_opt)
	{
		token::Token current = first;

		while (true)
		{
			token::Token? next_opt = token::token_iterator_next(&state.inner);

			if (try n = next_opt)
			{
				if (n.type != current.type)
				{
					state.buffered = n;
					state.has_buffered = true;
					return current;
				}

				int new_len = current.value.len + n.value.len;
				if (new_len > COALESCE_MAX_LEN)
				{
					state.buffered = n;
					state.has_buffered = true;
					return current;
				}

				int total = current.value.len + n.value.len;
				char* buf = mem::new_array(char, total);
				for (int i = 0; i < current.value.len; i++)
				{
					buf[i] = current.value.ptr[i];
				}
				for (int i = 0; i < n.value.len; i++)
				{
					buf[current.value.len + i] = n.value.ptr[i];
				}
				current.value = (String)buf[0..total];
			}
			else
			{
				return current;
			}
		}
	}

	return LEXER_DONE~;
}

/**
 * Create a coalescing iterator wrapping an inner iterator.
 */
fn token::TokenIterator coalesce_iter(token::TokenIterator* inner)
{
	CoalesceState* state = mem::new(CoalesceState);
	state.inner = *inner;
	state.has_buffered = false;

	token::TokenIterator it;
	it.next = &coalesce_next;
	it.ctx = (void*)state;
	return it;
}
