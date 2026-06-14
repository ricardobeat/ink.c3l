module ink::test;

import ink::token;

fn void test_token_type_category() @test {
	assert(token::token_type_category(token::KEYWORD) == token::KEYWORD);
	assert(token::token_type_category(token::KEYWORD_TYPE) == token::KEYWORD);
	assert(token::token_type_category(token::NAME) == token::NAME);
	assert(token::token_type_category(token::NAME_BUILTIN) == token::NAME);
	assert(token::token_type_category(token::NAME_VARIABLE) == token::NAME);
	assert(token::token_type_category(token::NAME_FUNCTION) == token::NAME);
	assert(token::token_type_category(token::LITERAL_STRING) == token::LITERAL);
	assert(token::token_type_category(token::LITERAL_NUMBER_FLOAT) == token::LITERAL);
	assert(token::token_type_category(token::COMMENT_SINGLE) == token::COMMENT);
	assert(token::token_type_category(token::GENERIC_HEADING) == token::GENERIC);
	assert(token::token_type_category(token::TEXT_WHITESPACE) == token::TEXT);
}

fn void test_token_type_sub_category() @test {
	assert(token::token_type_sub_category(token::KEYWORD) == token::KEYWORD);
	assert(token::token_type_sub_category(token::KEYWORD_TYPE) == token::KEYWORD);
	assert(token::token_type_sub_category(token::NAME_BUILTIN) == token::NAME_BUILTIN);
	assert(token::token_type_sub_category(token::NAME_BUILTIN_PSEUDO) == token::NAME_BUILTIN);
	assert(token::token_type_sub_category(token::NAME_VARIABLE) == token::NAME_VARIABLE);
	assert(token::token_type_sub_category(token::NAME_VARIABLE_GLOBAL) == token::NAME_VARIABLE);
	assert(token::token_type_sub_category(token::NAME_FUNCTION) == token::NAME_FUNCTION);
	assert(token::token_type_sub_category(token::LITERAL_STRING) == token::LITERAL_STRING);
	assert(token::token_type_sub_category(token::LITERAL_STRING_ESCAPE) == token::LITERAL_STRING);
	assert(token::token_type_sub_category(token::LITERAL_NUMBER_INTEGER) == token::LITERAL_NUMBER);
	assert(token::token_type_sub_category(token::COMMENT_PREPROC) == token::COMMENT_PREPROC);
}

fn void test_token_type_parent() @test {
	// Special types
	assert(token::token_type_parent(0) == 0);
	assert(token::token_type_parent(-1) == 0);

	// Top-level categories return themselves
	assert(token::token_type_parent(token::KEYWORD) == token::KEYWORD);
	assert(token::token_type_parent(token::NAME) == token::NAME);
	assert(token::token_type_parent(token::TEXT) == token::TEXT);

	// Subcategories
	assert(token::token_type_parent(token::KEYWORD_TYPE) == token::KEYWORD);
	assert(token::token_type_parent(token::NAME_BUILTIN) == token::NAME);
	assert(token::token_type_parent(token::NAME_VARIABLE) == token::NAME);
	assert(token::token_type_parent(token::NAME_FUNCTION) == token::NAME);

	// Sub-subcategories
	assert(token::token_type_parent(token::NAME_BUILTIN_PSEUDO) == token::NAME_BUILTIN);
	assert(token::token_type_parent(token::NAME_VARIABLE_GLOBAL) == token::NAME_VARIABLE);
	assert(token::token_type_parent(token::NAME_FUNCTION_MAGIC) == token::NAME_FUNCTION);
	assert(token::token_type_parent(token::LITERAL_STRING_ESCAPE) == token::LITERAL_STRING);
	assert(token::token_type_parent(token::LITERAL_NUMBER_INTEGER) == token::LITERAL_NUMBER);
	assert(token::token_type_parent(token::COMMENT_PREPROC_FILE) == token::COMMENT_PREPROC);
}

fn void test_token_type_in_category() @test {
	assert(token::token_type_in_category(token::KEYWORD_TYPE, token::KEYWORD));
	assert(token::token_type_in_category(token::NAME_FUNCTION, token::NAME));
	assert(token::token_type_in_category(token::LITERAL_STRING, token::LITERAL));
	assert(!token::token_type_in_category(token::KEYWORD, token::NAME));
	assert(!token::token_type_in_category(token::TEXT, token::COMMENT));
}
