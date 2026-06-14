module ink::themes;

import ink::style;
import ink::token;

/**
 * Register the GitHub theme.
 * Light theme based on GitHub's syntax highlighting.
 */
fn void register_github() {
	style::Style s = style::style_new();

	// Background & base
	style::style_add(&s, token::BACKGROUND,   style::style_entry_parse("bg:#ffffff"));
	style::style_add(&s, token::TEXT,          style::style_entry_parse("#24292e"));
	style::style_add(&s, token::TEXT_WHITESPACE, style::style_entry_parse("#24292e"));

	// Comments
	style::style_add(&s, token::COMMENT,           style::style_entry_parse("#6a737d"));
	style::style_add(&s, token::COMMENT_SINGLE,    style::style_entry_parse("#6a737d"));
	style::style_add(&s, token::COMMENT_MULTILINE, style::style_entry_parse("#6a737d"));
	style::style_add(&s, token::COMMENT_SPECIAL,   style::style_entry_parse("#6a737d italic"));

	// Keywords
	style::style_add(&s, token::KEYWORD,            style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::KEYWORD_CONSTANT,   style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::KEYWORD_DECLARATION,style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::KEYWORD_NAMESPACE,  style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::KEYWORD_PSEUDO,     style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::KEYWORD_RESERVED,   style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::KEYWORD_TYPE,       style::style_entry_parse("bold #d73a49"));

	// Names
	style::style_add(&s, token::NAME,               style::style_entry_parse("#24292e"));
	style::style_add(&s, token::NAME_ATTRIBUTE,     style::style_entry_parse("#6f42c1"));
	style::style_add(&s, token::NAME_CLASS,         style::style_entry_parse("bold #6f42c1"));
	style::style_add(&s, token::NAME_CONSTANT,      style::style_entry_parse("#005cc5"));
	style::style_add(&s, token::NAME_DECORATOR,     style::style_entry_parse("#6f42c1"));
	style::style_add(&s, token::NAME_EXCEPTION,     style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::NAME_FUNCTION,      style::style_entry_parse("#6f42c1"));
	style::style_add(&s, token::NAME_LABEL,         style::style_entry_parse("#d73a49"));
	style::style_add(&s, token::NAME_NAMESPACE,     style::style_entry_parse("#d73a49"));
	style::style_add(&s, token::NAME_PROPERTY,      style::style_entry_parse("#e36209"));
	style::style_add(&s, token::NAME_TAG,           style::style_entry_parse("bold #22863a"));
	style::style_add(&s, token::NAME_VARIABLE,      style::style_entry_parse("#e36209"));
	style::style_add(&s, token::NAME_BUILTIN,       style::style_entry_parse("#005cc5"));

	// Literals
	style::style_add(&s, token::LITERAL,                style::style_entry_parse("#005cc5"));
	style::style_add(&s, token::LITERAL_STRING,         style::style_entry_parse("#032f62"));
	style::style_add(&s, token::LITERAL_STRING_CHAR,    style::style_entry_parse("#032f62"));
	style::style_add(&s, token::LITERAL_STRING_DOUBLE,  style::style_entry_parse("#032f62"));
	style::style_add(&s, token::LITERAL_STRING_SINGLE,  style::style_entry_parse("#032f62"));
	style::style_add(&s, token::LITERAL_STRING_ESCAPE,  style::style_entry_parse("bold #005cc5"));
	style::style_add(&s, token::LITERAL_STRING_REGEX,   style::style_entry_parse("#032f62"));
	style::style_add(&s, token::LITERAL_STRING_SYMBOL,  style::style_entry_parse("#032f62"));
	style::style_add(&s, token::LITERAL_NUMBER,         style::style_entry_parse("#005cc5"));
	style::style_add(&s, token::LITERAL_NUMBER_INTEGER, style::style_entry_parse("#005cc5"));
	style::style_add(&s, token::LITERAL_NUMBER_FLOAT,   style::style_entry_parse("#005cc5"));
	style::style_add(&s, token::LITERAL_NUMBER_HEX,     style::style_entry_parse("#005cc5"));

	// Operators & punctuation
	style::style_add(&s, token::OPERATOR,    style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::PUNCTUATION, style::style_entry_parse("#24292e"));

	// Generics
	style::style_add(&s, token::GENERIC_DELETED,  style::style_entry_parse("bg:#ffeef0"));
	style::style_add(&s, token::GENERIC_EMPH,     style::style_entry_parse("italic"));
	style::style_add(&s, token::GENERIC_ERROR,    style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::GENERIC_HEADING,  style::style_entry_parse("bold #005cc5"));
	style::style_add(&s, token::GENERIC_INSERTED, style::style_entry_parse("#22863a bg:#f0fff4"));
	style::style_add(&s, token::GENERIC_OUTPUT,   style::style_entry_parse("#6a737d"));
	style::style_add(&s, token::GENERIC_PROMPT,   style::style_entry_parse("bold #d73a49"));
	style::style_add(&s, token::GENERIC_STRONG,   style::style_entry_parse("bold"));
	style::style_add(&s, token::GENERIC_SUBHEADING, style::style_entry_parse("#6a737d"));
	style::style_add(&s, token::GENERIC_TRACEBACK, style::style_entry_parse("#d73a49"));
	style::style_add(&s, token::GENERIC_UNDERLINE, style::style_entry_parse("underline"));

	// Register
	Style* sp = mem::new(Style);
	*sp = s;
	style::styles_register("github", sp);
}
