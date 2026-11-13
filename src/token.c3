module ink::token;

/**
 * Token type classification matching Chroma's hierarchy.
 * Stored as int since C3 enums don't support explicit values.
 */
alias TokenType = int;

// Special types
const TokenType EOF_TYPE = 0;
const TokenType BACKGROUND = -1;
const TokenType PRE_WRAPPER = -2;

// Keyword category (1000)
const TokenType KEYWORD = 1000;
const TokenType KEYWORD_CONSTANT = 1001;
const TokenType KEYWORD_DECLARATION = 1002;
const TokenType KEYWORD_NAMESPACE = 1003;
const TokenType KEYWORD_PSEUDO = 1004;
const TokenType KEYWORD_RESERVED = 1005;
const TokenType KEYWORD_TYPE = 1006;

// Name category (2000)
const TokenType NAME = 2000;
const TokenType NAME_ATTRIBUTE = 2001;
const TokenType NAME_CLASS = 2002;
const TokenType NAME_CONSTANT = 2003;
const TokenType NAME_DECORATOR = 2004;
const TokenType NAME_ENTITY = 2005;
const TokenType NAME_EXCEPTION = 2006;
const TokenType NAME_KEYWORD = 2007;
const TokenType NAME_LABEL = 2008;
const TokenType NAME_NAMESPACE = 2009;
const TokenType NAME_OPERATOR = 2010;
const TokenType NAME_OTHER = 2011;
const TokenType NAME_PSEUDO = 2012;
const TokenType NAME_PROPERTY = 2013;
const TokenType NAME_TAG = 2014;

// Name builtin subcategory (2100)
const TokenType NAME_BUILTIN = 2100;
const TokenType NAME_BUILTIN_PSEUDO = 2101;

// Name variable subcategory (2200)
const TokenType NAME_VARIABLE = 2200;
const TokenType NAME_VARIABLE_ANONYMOUS = 2201;
const TokenType NAME_VARIABLE_CLASS = 2202;
const TokenType NAME_VARIABLE_GLOBAL = 2203;
const TokenType NAME_VARIABLE_INSTANCE = 2204;
const TokenType NAME_VARIABLE_MAGIC = 2205;

// Name function subcategory (2300)
const TokenType NAME_FUNCTION = 2300;
const TokenType NAME_FUNCTION_MAGIC = 2301;

// Literal category (3000)
const TokenType LITERAL = 3000;
const TokenType LITERAL_DATE = 3001;
const TokenType LITERAL_OTHER = 3002;

// Literal string subcategory (3100)
const TokenType LITERAL_STRING = 3100;
const TokenType LITERAL_STRING_AFFIX = 3101;
const TokenType LITERAL_STRING_ATOM = 3102;
const TokenType LITERAL_STRING_BACKTICK = 3103;
const TokenType LITERAL_STRING_BOOLEAN = 3104;
const TokenType LITERAL_STRING_CHAR = 3105;
const TokenType LITERAL_STRING_DELIMITER = 3106;
const TokenType LITERAL_STRING_DOC = 3107;
const TokenType LITERAL_STRING_DOUBLE = 3108;
const TokenType LITERAL_STRING_ESCAPE = 3109;
const TokenType LITERAL_STRING_HEREDOC = 3110;
const TokenType LITERAL_STRING_INTERPOL = 3111;
const TokenType LITERAL_STRING_NAME = 3112;
const TokenType LITERAL_STRING_OTHER = 3113;
const TokenType LITERAL_STRING_REGEX = 3114;
const TokenType LITERAL_STRING_SINGLE = 3115;
const TokenType LITERAL_STRING_SYMBOL = 3116;

// Literal number subcategory (3200)
const TokenType LITERAL_NUMBER = 3200;
const TokenType LITERAL_NUMBER_BIN = 3201;
const TokenType LITERAL_NUMBER_FLOAT = 3202;
const TokenType LITERAL_NUMBER_HEX = 3203;
const TokenType LITERAL_NUMBER_INTEGER = 3204;
const TokenType LITERAL_NUMBER_INTEGER_LONG = 3205;
const TokenType LITERAL_NUMBER_OCT = 3206;
const TokenType LITERAL_NUMBER_BYTE = 3207;

// Operator category (4000)
const TokenType OPERATOR = 4000;
const TokenType OPERATOR_WORD = 4001;
const TokenType OPERATOR_RESERVED = 4002;

// Punctuation category (5000)
const TokenType PUNCTUATION = 5000;

// Comment category (6000)
const TokenType COMMENT = 6000;
const TokenType COMMENT_HASHBANG = 6001;
const TokenType COMMENT_MULTILINE = 6002;
const TokenType COMMENT_SINGLE = 6003;
const TokenType COMMENT_SPECIAL = 6004;

// Comment preproc subcategory (6100)
const TokenType COMMENT_PREPROC = 6100;
const TokenType COMMENT_PREPROC_FILE = 6101;

// Generic category (7000)
const TokenType GENERIC = 7000;
const TokenType GENERIC_DELETED = 7001;
const TokenType GENERIC_EMPH = 7002;
const TokenType GENERIC_ERROR = 7003;
const TokenType GENERIC_HEADING = 7004;
const TokenType GENERIC_INSERTED = 7005;
const TokenType GENERIC_OUTPUT = 7006;
const TokenType GENERIC_PROMPT = 7007;
const TokenType GENERIC_STRONG = 7008;
const TokenType GENERIC_SUBHEADING = 7009;
const TokenType GENERIC_TRACEBACK = 7010;
const TokenType GENERIC_UNDERLINE = 7011;

// Text category (8000)
const TokenType TEXT = 8000;
const TokenType TEXT_WHITESPACE = 8001;
const TokenType TEXT_SYMBOL = 8002;
const TokenType TEXT_PUNCTUATION = 8003;

// ---- TokenType functions ----

/**
 * Returns the parent category for a token type.
 */
fn int token_type_parent(int tt)
{
	if (tt <= 0) return 0;

	// Top-level categories return themselves
	if (tt % 1000 == 0) return tt;

	// Subcategories at x00 boundaries (e.g., NAME_BUILTIN=2100) return parent
	int subcat = (tt / 100) * 100;
	if (subcat == tt) return (tt / 1000) * 1000;

	// All other values return their subcategory
	return subcat;
}

/**
 * Returns the top-level category (tt / 1000 * 1000).
 */
fn int token_type_category(int tt) => (tt / 1000) * 1000;

/**
 * Returns the subcategory (tt / 100 * 100).
 */
fn int token_type_sub_category(int tt) => (tt / 100) * 100;

/**
 * Checks if this token type is in the given top-level category.
 */
fn bool token_type_in_category(int tt, int cat) => token_type_category(tt) == cat;

/**
 * Checks if this token type is in the given subcategory.
 */
fn bool token_type_in_sub_category(int tt, int subcat) => token_type_sub_category(tt) == subcat;

// ---- Names ----

struct TokenName
{
	String name;
	TokenType type;
}

// Dotted lower-case names as theme files spell them: KEYWORD_CONSTANT is
// "keyword.constant".
const TokenName[*] TOKEN_NAMES @local = {
	{ "background", BACKGROUND },
	{ "keyword", KEYWORD },
	{ "keyword.constant", KEYWORD_CONSTANT },
	{ "keyword.declaration", KEYWORD_DECLARATION },
	{ "keyword.namespace", KEYWORD_NAMESPACE },
	{ "keyword.pseudo", KEYWORD_PSEUDO },
	{ "keyword.reserved", KEYWORD_RESERVED },
	{ "keyword.type", KEYWORD_TYPE },
	{ "name", NAME },
	{ "name.attribute", NAME_ATTRIBUTE },
	{ "name.class", NAME_CLASS },
	{ "name.constant", NAME_CONSTANT },
	{ "name.decorator", NAME_DECORATOR },
	{ "name.entity", NAME_ENTITY },
	{ "name.exception", NAME_EXCEPTION },
	{ "name.keyword", NAME_KEYWORD },
	{ "name.label", NAME_LABEL },
	{ "name.namespace", NAME_NAMESPACE },
	{ "name.operator", NAME_OPERATOR },
	{ "name.other", NAME_OTHER },
	{ "name.pseudo", NAME_PSEUDO },
	{ "name.property", NAME_PROPERTY },
	{ "name.tag", NAME_TAG },
	{ "name.builtin", NAME_BUILTIN },
	{ "name.builtin.pseudo", NAME_BUILTIN_PSEUDO },
	{ "name.variable", NAME_VARIABLE },
	{ "name.variable.anonymous", NAME_VARIABLE_ANONYMOUS },
	{ "name.variable.class", NAME_VARIABLE_CLASS },
	{ "name.variable.global", NAME_VARIABLE_GLOBAL },
	{ "name.variable.instance", NAME_VARIABLE_INSTANCE },
	{ "name.variable.magic", NAME_VARIABLE_MAGIC },
	{ "name.function", NAME_FUNCTION },
	{ "name.function.magic", NAME_FUNCTION_MAGIC },
	{ "literal", LITERAL },
	{ "literal.date", LITERAL_DATE },
	{ "literal.other", LITERAL_OTHER },
	{ "literal.string", LITERAL_STRING },
	{ "literal.string.affix", LITERAL_STRING_AFFIX },
	{ "literal.string.atom", LITERAL_STRING_ATOM },
	{ "literal.string.backtick", LITERAL_STRING_BACKTICK },
	{ "literal.string.boolean", LITERAL_STRING_BOOLEAN },
	{ "literal.string.char", LITERAL_STRING_CHAR },
	{ "literal.string.delimiter", LITERAL_STRING_DELIMITER },
	{ "literal.string.doc", LITERAL_STRING_DOC },
	{ "literal.string.double", LITERAL_STRING_DOUBLE },
	{ "literal.string.escape", LITERAL_STRING_ESCAPE },
	{ "literal.string.heredoc", LITERAL_STRING_HEREDOC },
	{ "literal.string.interpol", LITERAL_STRING_INTERPOL },
	{ "literal.string.name", LITERAL_STRING_NAME },
	{ "literal.string.other", LITERAL_STRING_OTHER },
	{ "literal.string.regex", LITERAL_STRING_REGEX },
	{ "literal.string.single", LITERAL_STRING_SINGLE },
	{ "literal.string.symbol", LITERAL_STRING_SYMBOL },
	{ "literal.number", LITERAL_NUMBER },
	{ "literal.number.bin", LITERAL_NUMBER_BIN },
	{ "literal.number.float", LITERAL_NUMBER_FLOAT },
	{ "literal.number.hex", LITERAL_NUMBER_HEX },
	{ "literal.number.integer", LITERAL_NUMBER_INTEGER },
	{ "literal.number.integer.long", LITERAL_NUMBER_INTEGER_LONG },
	{ "literal.number.oct", LITERAL_NUMBER_OCT },
	{ "literal.number.byte", LITERAL_NUMBER_BYTE },
	{ "operator", OPERATOR },
	{ "operator.word", OPERATOR_WORD },
	{ "operator.reserved", OPERATOR_RESERVED },
	{ "punctuation", PUNCTUATION },
	{ "comment", COMMENT },
	{ "comment.hashbang", COMMENT_HASHBANG },
	{ "comment.multiline", COMMENT_MULTILINE },
	{ "comment.single", COMMENT_SINGLE },
	{ "comment.special", COMMENT_SPECIAL },
	{ "comment.preproc", COMMENT_PREPROC },
	{ "comment.preproc.file", COMMENT_PREPROC_FILE },
	{ "generic", GENERIC },
	{ "generic.deleted", GENERIC_DELETED },
	{ "generic.emph", GENERIC_EMPH },
	{ "generic.error", GENERIC_ERROR },
	{ "generic.heading", GENERIC_HEADING },
	{ "generic.inserted", GENERIC_INSERTED },
	{ "generic.output", GENERIC_OUTPUT },
	{ "generic.prompt", GENERIC_PROMPT },
	{ "generic.strong", GENERIC_STRONG },
	{ "generic.subheading", GENERIC_SUBHEADING },
	{ "generic.traceback", GENERIC_TRACEBACK },
	{ "generic.underline", GENERIC_UNDERLINE },
	{ "text", TEXT },
	{ "text.whitespace", TEXT_WHITESPACE },
	{ "text.symbol", TEXT_SYMBOL },
	{ "text.punctuation", TEXT_PUNCTUATION },
};

/**
 * Look up a token type by its dotted name, e.g. "literal.string.double".
 */
fn TokenType? token_type_from_name(String name) @public
{
	foreach (n : TOKEN_NAMES)
	{
		if (n.name == name) return n.type;
	}
	return UNKNOWN_TOKEN_NAME~;
}

faultdef UNKNOWN_TOKEN_NAME;

// ---- Token ----

/**
 * Represents a single token with its type and the source text value.
 */
struct Token
{
	TokenType type;
	String value;
}

// ---- Iterator ----

/**
 * Function type for token iteration callbacks.
 */
alias TokenNextFn = fn Token?(void* ctx);

/**
 * Opaque state for a token iterator.
 * Call token_iterator_next() to advance.
 */
struct TokenIterator
{
	TokenNextFn next;
	void* ctx;
}

/**
 * Advance the iterator, returning the next token or empty at EOF.
 */
fn Token? token_iterator_next(TokenIterator* it) => it.next(it.ctx);
