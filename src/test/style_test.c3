module ink::test;

import ink::style;
import ink::token;
import ink::colour;

fn void test_style_entry_parse_fg() @test {
	style::StyleEntry e = style::style_entry_parse("#aabbcc");
	assert(e.fg == colour::colour_parse("#aabbcc"));
	assert(!e.bold);
	assert(!e.italic);
}

fn void test_style_entry_parse_bold() @test {
	style::StyleEntry e = style::style_entry_parse("bold");
	assert(e.bold);
	assert(!e.italic);
	assert(e.fg == (Colour)0);
}

fn void test_style_entry_parse_bold_fg() @test {
	style::StyleEntry e = style::style_entry_parse("bold #ff0000");
	assert(e.bold);
	assert(e.fg == colour::colour_parse("#ff0000"));
}

fn void test_style_entry_parse_bg() @test {
	style::StyleEntry e = style::style_entry_parse("bg:#112233");
	assert(e.bg == colour::colour_parse("#112233"));
	assert(e.fg == (Colour)0);
}

fn void test_style_entry_parse_italic() @test {
	style::StyleEntry e = style::style_entry_parse("italic");
	assert(e.italic);
}

fn void test_style_entry_parse_noitalic() @test {
	style::StyleEntry e = style::style_entry_parse("noitalic");
	assert(!e.italic);
}

fn void test_style_get_exact() @test {
	style::Style s = style::style_new();
	style::StyleEntry e = style::style_entry_parse("#ff0000");
	style::style_add(&s, token::KEYWORD, e);

	style::StyleEntry result = style::style_get(&s, token::KEYWORD);
	assert(result.fg == colour::colour_parse("#ff0000"));
}

fn void test_style_get_fallback_subcategory() @test {
	style::Style s = style::style_new();
	style::StyleEntry e = style::style_entry_parse("#00ff00");
	style::style_add(&s, token::LITERAL_STRING, e);

	// LITERAL_STRING_ESCAPE should fall back to LITERAL_STRING
	style::StyleEntry result = style::style_get(&s, token::LITERAL_STRING_ESCAPE);
	assert(result.fg == colour::colour_parse("#00ff00"));
}

fn void test_style_get_fallback_category() @test {
	style::Style s = style::style_new();
	style::StyleEntry e = style::style_entry_parse("#0000ff");
	style::style_add(&s, token::NAME, e);

	// NAME_FUNCTION should fall back to NAME
	style::StyleEntry result = style::style_get(&s, token::NAME_FUNCTION);
	assert(result.fg == colour::colour_parse("#0000ff"));
}

fn void test_style_get_fallback_text() @test {
	style::Style s = style::style_new();
	style::StyleEntry e = style::style_entry_parse("#aaaaaa");
	style::style_add(&s, token::TEXT, e);

	// Unknown token type should fall back to TEXT
	style::StyleEntry result = style::style_get(&s, 9999);
	assert(result.fg == colour::colour_parse("#aaaaaa"));
}

fn void test_style_registry() @test {
	style::Style s = style::style_new();
	style::styles_register("test_style", &s);

	style::Style* found = style::styles_get("test_style");
	assert(found != null);
	assert(found == &s);

	style::Style* missing = style::styles_get("nonexistent");
	assert(missing == null);
}
