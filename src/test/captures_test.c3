module ink::test;

import ink::captures;
import ink::token;

fn void test_capture_exact_matches() @test {
	assert(captures::capture_to_token_type("variable") == token::NAME_VARIABLE);
	assert(captures::capture_to_token_type("variable.other.member") == token::NAME_PROPERTY);
	assert(captures::capture_to_token_type("keyword") == token::KEYWORD);
	assert(captures::capture_to_token_type("keyword.control.import") == token::KEYWORD_NAMESPACE);
	assert(captures::capture_to_token_type("comment.block.documentation") == token::COMMENT_SPECIAL);
	assert(captures::capture_to_token_type("markup.heading") == token::GENERIC_HEADING);
}

fn void test_capture_unknown() @test {
	assert(captures::capture_to_token_type("totally_unknown") == token::TEXT);
	assert(captures::capture_to_token_type("") == token::TEXT);
}
