module ink::ts_lexer;

import ink::token;
import ink::lexer;
import ink::ts_bind;
import ink::captures;

faultdef TS_LEXER_DONE;

struct TsLexer (lexer::Lexer) {
	lexer::LexerConfig lexer_config;
	ts_bind::TSLanguage* language;
	String query_source;
	lexer::LexerRegistry* reg;
}

fn TsLexer* ts_lexer_new(
	String name,
	String[] aliases,
	String[] extensions,
	ts_bind::TSLanguage* language,
	String query_source
) @public {
	TsLexer* l = mem::new(TsLexer);
	l.lexer_config.name = name;
	l.lexer_config.aliases = aliases;
	l.lexer_config.extensions = extensions;
	l.language = language;
	l.query_source = query_source;
	l.reg = null;
	return l;
}

// ---- Iterator over a pre-collected token array ----

struct TsIterState {
	token::Token* tokens;
	int count;
	int index;
}

fn token::Token? ts_iter_next(void* ctx) {
	TsIterState* state = (TsIterState*)ctx;

	if (state.index >= state.count) {
		mem::free(state.tokens);
		return TS_LEXER_DONE~;
	}

	token::Token tok = state.tokens[state.index];
	state.index++;
	return tok;
}

// ---- Token collection ----

/**
 * Semantic priority of a capture name, used as the primary specificity
 * key so that e.g. `@function` beats the generic `@variable` when both
 * capture the same span (common on function definitions).
 */
fn sz capture_priority(String name) {
	if (name.starts_with("function")) return 200;
	if (name.starts_with("type")) return 160;
	if (name.starts_with("class")) return 150;
	if (name.starts_with("constant")) return 120;
	if (name.starts_with("keyword")) return 100;
	if (name.starts_with("variable")) return 50;
	return 60;
}

/**
 * Specificity of a capture name: category priority, then dot-segments,
 * then length. Used to pick the best capture when several cover the same
 * byte range.
 */
fn sz capture_specificity(String name) {
	sz dots = 0;
	for (sz i = 0; i < name.len; i++) {
		if (name.ptr[i] == '.') dots++;
	}
	return capture_priority(name) * 10000 + dots * 1000 + name.len;
}

fn void append_token(token::Token** buf, int* cap, int* count, token::Token tok) {
	if (*count == *cap) {
		int ncap = (*cap == 0) ? 256 : *cap * 2;
		*buf = mem::realloc(*buf, (sz)ncap * token::Token::size);
		*cap = ncap;
	}
	(*buf)[*count] = tok;
	(*count)++;
}

fn token::TokenIterator*? ts_lexer_tokenise(TsLexer* self, String source) {
	ts_bind::TSParser* parser = ts_bind::ts_parser_new();
	if (!ts_bind::ts_parser_set_language(parser, self.language)) {
		ts_bind::ts_parser_delete(parser);
		return TS_LEXER_DONE~;
	}

	ts_bind::TSTree* tree = ts_bind::ts_parser_parse_string(parser, null, source.ptr, (uint)source.len);
	if (tree == null) {
		ts_bind::ts_parser_delete(parser);
		return TS_LEXER_DONE~;
	}

	uint error_offset = 0;
	ts_bind::TSQueryError error_type = ts_bind::TS_QUERY_ERROR_NONE;
	ts_bind::TSQuery* query = ts_bind::ts_query_new(
		self.language,
		self.query_source.ptr,
		(uint)self.query_source.len,
		&error_offset,
		&error_type
	);
	if (query == null || error_type != ts_bind::TS_QUERY_ERROR_NONE) {
		ts_bind::ts_tree_delete(tree);
		ts_bind::ts_parser_delete(parser);
		return TS_LEXER_DONE~;
	}

	ts_bind::TSQueryCursor* cursor = ts_bind::ts_query_cursor_new();
	ts_bind::TSNode root = ts_bind::ts_tree_root_node(tree);
	ts_bind::ts_query_cursor_exec(cursor, query, root);

	// Collect tokens eagerly: this lets us resolve same-span capture
	// conflicts (e.g. @variable + @function on a function name) by
	// preferring the most specific capture name.
	ts_bind::TSQueryMatch match;
	uint capture_index = 0;
	uint pos = 0;
	token::Token* buf = null;
	int cap = 0;
	int count = 0;

	bool has_cur = false;
	uint cur_start = 0;
	uint cur_end = 0;
	String cur_name = "text";

	// Prime the first capture.
	has_cur = ts_bind::ts_query_cursor_next_capture(cursor, &match, &capture_index);
	if (has_cur) {
		ts_bind::TSQueryCapture first = match.captures[capture_index];
		cur_start = ts_bind::ts_node_start_byte(first.node);
		cur_end = ts_bind::ts_node_end_byte(first.node);
		uint name_len = 0;
		char* name_ptr = ts_bind::ts_query_capture_name_for_id(query, first.index, &name_len);
		if (name_ptr != null && name_len > 0) {
			cur_name = (String)name_ptr[0..name_len-1];
		} else {
			cur_name = "text";
		}
		if (cur_start == cur_end) has_cur = false; // drop zero-width captures
	}

	while (has_cur) {
		// Look ahead for captures covering the same byte range.
		bool has_next = ts_bind::ts_query_cursor_next_capture(cursor, &match, &capture_index);
		if (has_next) {
			ts_bind::TSQueryCapture nxt = match.captures[capture_index];
			uint n_start = ts_bind::ts_node_start_byte(nxt.node);
			uint n_end = ts_bind::ts_node_end_byte(nxt.node);
			uint name_len = 0;
			char* name_ptr = ts_bind::ts_query_capture_name_for_id(query, nxt.index, &name_len);
			String n_name = "text";
			if (name_ptr != null && name_len > 0) {
				n_name = (String)name_ptr[0..name_len-1];
			}

			if (n_start == cur_start && n_end == cur_end) {
				if (capture_specificity(n_name) > capture_specificity(cur_name)) {
					cur_name = n_name;
				}
				continue; // same span: prefer the more specific name
			}

			// Different span: emit the current capture, then step forward
			// with the lookahead as the new current.
			if (cur_start > pos) {
				token::Token text_tok;
				text_tok.type = token::TEXT;
				text_tok.value = source[pos..cur_start-1];
				append_token(&buf, &cap, &count, text_tok);
				pos = cur_start;
			}
			if (cur_end > pos) {
				token::Token tok;
				tok.type = captures::capture_to_token_type(cur_name);
				tok.value = source[cur_start..cur_end-1];
				append_token(&buf, &cap, &count, tok);
				pos = cur_end;
			}

			cur_start = n_start;
			cur_end = n_end;
			cur_name = n_name;
			if (cur_start == cur_end) {
				has_cur = false; // drop zero-width captures
				if (has_next) has_next = ts_bind::ts_query_cursor_next_capture(cursor, &match, &capture_index);
			}
			continue;
		}

		// No more captures: emit the current one and finish.
		if (cur_start > pos) {
			token::Token text_tok;
			text_tok.type = token::TEXT;
			text_tok.value = source[pos..cur_start-1];
			append_token(&buf, &cap, &count, text_tok);
			pos = cur_start;
		}
		if (cur_end > pos) {
			token::Token tok;
			tok.type = captures::capture_to_token_type(cur_name);
			tok.value = source[cur_start..cur_end-1];
			append_token(&buf, &cap, &count, tok);
			pos = cur_end;
		}
		has_cur = false;
	}

	if (pos < (uint)source.len) {
		token::Token text_tok;
		text_tok.type = token::TEXT;
		text_tok.value = source[pos..source.len-1];
		append_token(&buf, &cap, &count, text_tok);
	}

	ts_bind::ts_query_cursor_delete(cursor);
	ts_bind::ts_query_delete(query);
	ts_bind::ts_tree_delete(tree);
	ts_bind::ts_parser_delete(parser);

	TsIterState* state = mem::tnew(TsIterState);
	state.tokens = buf;
	state.count = count;
	state.index = 0;

	token::TokenIterator* it = mem::tnew(token::TokenIterator);
	it.next = &ts_iter_next;
	it.ctx = (void*)state;
	return it;
}

fn lexer::LexerConfig* TsLexer.config(&self) @dynamic {
	return &self.lexer_config;
}

fn token::TokenIterator*? TsLexer.tokenise(&self, String text) @dynamic {
	return ts_lexer_tokenise((TsLexer*)self, text);
}

fn lexer::LexerRegistry* TsLexer.registry(&self) @dynamic {
	return self.reg;
}

fn void TsLexer.setRegistry(&self, lexer::LexerRegistry* reg) @dynamic {
	((TsLexer*)self).reg = reg;
}