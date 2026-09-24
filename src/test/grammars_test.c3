module ink::test;

import ink::helix;
import ink::grammars;
import ink::lexer;
import ink::token;

fn void test_grammars_load_a_shipped_grammar() @test {
	defer helix::unload();
	lexer::Lexer*? lx = grammars::lexer_for_file("x.json", { "." });
	if (catch err = lx) {
		assert(false, "no lexer: %s", err);
		return;
	}
	token::TokenIterator* it = lx.tokenise("{\"a\": [1, true]}")!!;
	int n = 0;
	while (try t = token::token_iterator_next(it)) n++;
	assert(n > 4, "only %d tokens", n);
}
