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
