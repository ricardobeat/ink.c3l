module ink::themes;

import ink::style;
import ink::token;

/**
 * Register the Monokai theme.
 * Dark, high-contrast theme inspired by the original Monokai color scheme.
 */
fn void register_monokai() {
	style::Style s = style::style_new();

	// Background & base
	style::style_add(&s, token::BACKGROUND,   style::style_entry_parse("bg:#272822"));
	style::style_add(&s, token::TEXT,          style::style_entry_parse("#f8f8f2"));
	style::style_add(&s, token::TEXT_WHITESPACE, style::style_entry_parse("#f8f8f2"));

	// Comments
	style::style_add(&s, token::COMMENT,           style::style_entry_parse("#75715e"));
	style::style_add(&s, token::COMMENT_SINGLE,    style::style_entry_parse("#75715e"));
	style::style_add(&s, token::COMMENT_MULTILINE, style::style_entry_parse("#75715e"));
	style::style_add(&s, token::COMMENT_SPECIAL,   style::style_entry_parse("#75715e italic"));

	// Keywords
	style::style_add(&s, token::KEYWORD,            style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::KEYWORD_CONSTANT,   style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::KEYWORD_DECLARATION,style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::KEYWORD_NAMESPACE,  style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::KEYWORD_PSEUDO,     style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::KEYWORD_RESERVED,   style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::KEYWORD_TYPE,       style::style_entry_parse("bold #66d9ef"));

	// Names
	style::style_add(&s, token::NAME,               style::style_entry_parse("#f8f8f2"));
	style::style_add(&s, token::NAME_ATTRIBUTE,     style::style_entry_parse("#a6e22e"));
	style::style_add(&s, token::NAME_CLASS,         style::style_entry_parse("bold #a6e22e"));
	style::style_add(&s, token::NAME_CONSTANT,      style::style_entry_parse("#66d9ef"));
	style::style_add(&s, token::NAME_DECORATOR,     style::style_entry_parse("#a6e22e"));
	style::style_add(&s, token::NAME_EXCEPTION,     style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::NAME_FUNCTION,      style::style_entry_parse("#a6e22e"));
	style::style_add(&s, token::NAME_LABEL,         style::style_entry_parse("#f92672"));
	style::style_add(&s, token::NAME_NAMESPACE,     style::style_entry_parse("#f92672"));
	style::style_add(&s, token::NAME_PROPERTY,      style::style_entry_parse("#f92672"));
	style::style_add(&s, token::NAME_TAG,           style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::NAME_VARIABLE,      style::style_entry_parse("#f8f8f2"));
	style::style_add(&s, token::NAME_BUILTIN,       style::style_entry_parse("#66d9ef"));

	// Literals
	style::style_add(&s, token::LITERAL,                style::style_entry_parse("#ae81ff"));
	style::style_add(&s, token::LITERAL_STRING,         style::style_entry_parse("#e6db74"));
	style::style_add(&s, token::LITERAL_STRING_CHAR,    style::style_entry_parse("#e6db74"));
	style::style_add(&s, token::LITERAL_STRING_DOUBLE,  style::style_entry_parse("#e6db74"));
	style::style_add(&s, token::LITERAL_STRING_SINGLE,  style::style_entry_parse("#e6db74"));
	style::style_add(&s, token::LITERAL_STRING_ESCAPE,  style::style_entry_parse("bold #ae81ff"));
	style::style_add(&s, token::LITERAL_STRING_REGEX,   style::style_entry_parse("#e6db74"));
	style::style_add(&s, token::LITERAL_STRING_SYMBOL,  style::style_entry_parse("#e6db74"));
	style::style_add(&s, token::LITERAL_NUMBER,         style::style_entry_parse("#ae81ff"));
	style::style_add(&s, token::LITERAL_NUMBER_INTEGER, style::style_entry_parse("#ae81ff"));
	style::style_add(&s, token::LITERAL_NUMBER_FLOAT,   style::style_entry_parse("#ae81ff"));
	style::style_add(&s, token::LITERAL_NUMBER_HEX,     style::style_entry_parse("#ae81ff"));

	// Operators & punctuation
	style::style_add(&s, token::OPERATOR,    style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::PUNCTUATION, style::style_entry_parse("#f8f8f2"));

	// Generics
	style::style_add(&s, token::GENERIC_DELETED,  style::style_entry_parse("bg:#3e3d32"));
	style::style_add(&s, token::GENERIC_EMPH,     style::style_entry_parse("italic"));
	style::style_add(&s, token::GENERIC_ERROR,    style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::GENERIC_HEADING,  style::style_entry_parse("bold #ae81ff"));
	style::style_add(&s, token::GENERIC_INSERTED, style::style_entry_parse("#a6e22e"));
	style::style_add(&s, token::GENERIC_OUTPUT,   style::style_entry_parse("#75715e"));
	style::style_add(&s, token::GENERIC_PROMPT,   style::style_entry_parse("bold #f92672"));
	style::style_add(&s, token::GENERIC_STRONG,   style::style_entry_parse("bold"));
	style::style_add(&s, token::GENERIC_SUBHEADING, style::style_entry_parse("#75715e"));
	style::style_add(&s, token::GENERIC_TRACEBACK, style::style_entry_parse("#f92672"));
	style::style_add(&s, token::GENERIC_UNDERLINE, style::style_entry_parse("underline"));

	// Register
	Style* sp = mem::new(Style);
	*sp = s;
	style::styles_register("monokai", sp);
}
