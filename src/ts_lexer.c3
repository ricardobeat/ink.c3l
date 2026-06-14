module ink::ts_lexer;

import ink::token;
import ink::lexer;
import ink::ts_bind;
import ink::captures;

faultdef TS_LEXER_DONE;

struct TsLexer {
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
	TsLexer* l = mem::tnew(TsLexer);
	l.lexer_config.name = name;
	l.lexer_config.aliases = aliases;
	l.lexer_config.extensions = extensions;
	l.language = language;
	l.query_source = query_source;
	l.reg = null;
	return l;
}

struct TsIterState {
	ts_bind::TSParser* parser;
	ts_bind::TSTree* tree;
	ts_bind::TSQuery* query;
	ts_bind::TSQueryCursor* cursor;
	String source;
	uint pos;
	bool done;
}

fn void ts_iter_cleanup(TsIterState* state) {
	ts_bind::ts_query_cursor_delete(state.cursor);
	ts_bind::ts_query_delete(state.query);
	ts_bind::ts_tree_delete(state.tree);
	ts_bind::ts_parser_delete(state.parser);
}

fn token::Token? ts_iter_next(void* ctx) {
	TsIterState* state = (TsIterState*)ctx;

	if (state.done) {
		ts_iter_cleanup(state);
		return TS_LEXER_DONE~;
	}

	uint source_len = (uint)state.source.len;

	ts_bind::TSQueryMatch match;
	uint capture_index = 0;

	while (ts_bind::ts_query_cursor_next_capture(state.cursor, &match, &capture_index)) {
		ts_bind::TSQueryCapture cap = match.captures[capture_index];
		uint cap_start = ts_bind::ts_node_start_byte(cap.node);
		uint cap_end = ts_bind::ts_node_end_byte(cap.node);

		if (cap_start == cap_end) continue;
		if (cap_start < state.pos) continue;

		uint name_len = 0;
		char* name_ptr = ts_bind::ts_query_capture_name_for_id(state.query, cap.index, &name_len);
		String cap_name;
		if (name_ptr != null && name_len > 0) {
			cap_name = (String)name_ptr[0..name_len-1];
		} else {
			cap_name = "text";
		}

		if (cap_start > state.pos) {
			token::Token text_tok;
			text_tok.type = token::TEXT;
			text_tok.value = state.source[state.pos..cap_start-1];
			state.pos = cap_start;
			return text_tok;
		}

		state.pos = cap_end;
		token::Token tok;
		tok.type = captures::capture_to_token_type(cap_name);
		tok.value = state.source[cap_start..cap_end-1];
		return tok;
	}

	if (state.pos < source_len) {
		token::Token text_tok;
		text_tok.type = token::TEXT;
		text_tok.value = state.source[state.pos..source_len-1];
		state.pos = source_len;
		state.done = true;
		return text_tok;
	}

	state.done = true;
	ts_iter_cleanup(state);
	return TS_LEXER_DONE~;
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

	TsIterState* state = mem::tnew(TsIterState);
	state.parser = parser;
	state.tree = tree;
	state.query = query;
	state.cursor = cursor;
	state.source = source;
	state.pos = 0;
	state.done = false;

	token::TokenIterator* it = mem::tnew(token::TokenIterator);
	it.next = &ts_iter_next;
	it.ctx = (void*)state;
	return it;
}

fn lexer::LexerConfig* TsLexer.config(&self) {
	return &self.lexer_config;
}

fn token::TokenIterator*? TsLexer.tokenise(&self, String text) {
	return ts_lexer_tokenise((TsLexer*)self, text);
}

fn lexer::LexerRegistry* TsLexer.registry(&self) {
	return self.reg;
}

fn void TsLexer.setRegistry(&self, lexer::LexerRegistry* reg) {
	((TsLexer*)self).reg = reg;
}
