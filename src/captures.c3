module ink::captures;

import ink::token;

const int MAX_CAPTURE_MAPPINGS = 80;

struct CaptureMapping {
	String capture;
	int token_type;
}

/**
 * Static table of capture name -> TokenType mappings.
 * Sorted roughly by frequency for linear scan efficiency.
 */
CaptureMapping[MAX_CAPTURE_MAPPINGS] capture_table;
int capture_table_count;

fn void init_capture_table() {
	if (capture_table_count > 0) return;

	capture_table[0]  = (CaptureMapping){ "variable",                   token::NAME_VARIABLE };
	capture_table[1]  = (CaptureMapping){ "variable.other.member",      token::NAME_PROPERTY };
	capture_table[2]  = (CaptureMapping){ "variable.parameter",         token::NAME_VARIABLE };
	capture_table[3]  = (CaptureMapping){ "variable.builtin",           token::NAME_BUILTIN };
	capture_table[4]  = (CaptureMapping){ "constant",                   token::NAME_CONSTANT };
	capture_table[5]  = (CaptureMapping){ "constant.builtin",           token::NAME_CONSTANT };
	capture_table[6]  = (CaptureMapping){ "constant.builtin.boolean",   token::LITERAL_STRING_BOOLEAN };
	capture_table[7]  = (CaptureMapping){ "constant.numeric",           token::LITERAL_NUMBER };
	capture_table[8]  = (CaptureMapping){ "constant.numeric.integer",   token::LITERAL_NUMBER_INTEGER };
	capture_table[9]  = (CaptureMapping){ "constant.numeric.float",     token::LITERAL_NUMBER_FLOAT };
	capture_table[10] = (CaptureMapping){ "constant.character",         token::LITERAL_STRING_CHAR };
	capture_table[11] = (CaptureMapping){ "constant.character.escape",  token::LITERAL_STRING_ESCAPE };
	capture_table[12] = (CaptureMapping){ "function",                   token::NAME_FUNCTION };
	capture_table[13] = (CaptureMapping){ "function.builtin",           token::NAME_BUILTIN };
	capture_table[14] = (CaptureMapping){ "function.method",            token::NAME_FUNCTION };
	capture_table[15] = (CaptureMapping){ "function.macro",             token::NAME_FUNCTION };
	capture_table[16] = (CaptureMapping){ "function.special",           token::NAME_FUNCTION };
	capture_table[17] = (CaptureMapping){ "constructor",                token::NAME_FUNCTION };
	capture_table[18] = (CaptureMapping){ "type",                       token::KEYWORD_TYPE };
	capture_table[19] = (CaptureMapping){ "type.builtin",               token::KEYWORD_TYPE };
	capture_table[20] = (CaptureMapping){ "type.definition",            token::KEYWORD_TYPE };
	capture_table[21] = (CaptureMapping){ "type.parameter",             token::KEYWORD_TYPE };
	capture_table[22] = (CaptureMapping){ "type.enum.variant",          token::NAME_CONSTANT };
	capture_table[23] = (CaptureMapping){ "keyword",                    token::KEYWORD };
	capture_table[24] = (CaptureMapping){ "keyword.control",            token::KEYWORD };
	capture_table[25] = (CaptureMapping){ "keyword.control.conditional",token::KEYWORD };
	capture_table[26] = (CaptureMapping){ "keyword.control.repeat",     token::KEYWORD };
	capture_table[27] = (CaptureMapping){ "keyword.control.return",     token::KEYWORD };
	capture_table[28] = (CaptureMapping){ "keyword.control.import",     token::KEYWORD_NAMESPACE };
	capture_table[29] = (CaptureMapping){ "keyword.function",           token::KEYWORD };
	capture_table[30] = (CaptureMapping){ "keyword.storage",            token::KEYWORD };
	capture_table[31] = (CaptureMapping){ "keyword.storage.type",       token::KEYWORD_TYPE };
	capture_table[32] = (CaptureMapping){ "keyword.storage.modifier",   token::KEYWORD };
	capture_table[33] = (CaptureMapping){ "keyword.operator",           token::OPERATOR_WORD };
	capture_table[34] = (CaptureMapping){ "keyword.directive",          token::COMMENT_PREPROC };
	capture_table[35] = (CaptureMapping){ "namespace",                  token::NAME_NAMESPACE };
	capture_table[36] = (CaptureMapping){ "label",                      token::NAME_LABEL };
	capture_table[37] = (CaptureMapping){ "string",                     token::LITERAL_STRING };
	capture_table[38] = (CaptureMapping){ "string.regexp",              token::LITERAL_STRING_REGEX };
	capture_table[39] = (CaptureMapping){ "string.special",             token::LITERAL_STRING_OTHER };
	capture_table[40] = (CaptureMapping){ "operator",                   token::OPERATOR };
	capture_table[41] = (CaptureMapping){ "punctuation",                token::PUNCTUATION };
	capture_table[42] = (CaptureMapping){ "punctuation.delimiter",      token::PUNCTUATION };
	capture_table[43] = (CaptureMapping){ "punctuation.bracket",        token::PUNCTUATION };
	capture_table[44] = (CaptureMapping){ "punctuation.special",        token::PUNCTUATION };
	capture_table[45] = (CaptureMapping){ "comment",                    token::COMMENT };
	capture_table[46] = (CaptureMapping){ "comment.line",               token::COMMENT_SINGLE };
	capture_table[47] = (CaptureMapping){ "comment.block",              token::COMMENT_MULTILINE };
	capture_table[48] = (CaptureMapping){ "comment.line.documentation",  token::COMMENT_SPECIAL };
	capture_table[49] = (CaptureMapping){ "comment.block.documentation", token::COMMENT_SPECIAL };
	capture_table[50] = (CaptureMapping){ "comment.unused",             token::COMMENT };
	capture_table[51] = (CaptureMapping){ "attribute",                  token::NAME_ATTRIBUTE };
	capture_table[52] = (CaptureMapping){ "special",                    token::OPERATOR };
	capture_table[53] = (CaptureMapping){ "tag",                        token::NAME_TAG };
	capture_table[54] = (CaptureMapping){ "tag.delimiter",              token::PUNCTUATION };
	capture_table[55] = (CaptureMapping){ "diff.plus",                  token::GENERIC_INSERTED };
	capture_table[56] = (CaptureMapping){ "diff.minus",                 token::GENERIC_DELETED };
	capture_table[57] = (CaptureMapping){ "diff.delta",                 token::GENERIC_EMPH };
	capture_table[58] = (CaptureMapping){ "markup.heading",             token::GENERIC_HEADING };
	capture_table[59] = (CaptureMapping){ "markup.strong",              token::GENERIC_STRONG };
	capture_table[60] = (CaptureMapping){ "markup.italic",              token::GENERIC_EMPH };
	capture_table[61] = (CaptureMapping){ "markup.underline",           token::GENERIC_UNDERLINE };
	capture_table[62] = (CaptureMapping){ "markup.link",                token::TEXT };
	capture_table[63] = (CaptureMapping){ "markup.raw",                 token::LITERAL_STRING };
	capture_table[64] = (CaptureMapping){ "markup.list",                token::PUNCTUATION };
	capture_table[65] = (CaptureMapping){ "markup.quote",               token::GENERIC_OUTPUT };
	capture_table[66] = (CaptureMapping){ "markup.math",                token::LITERAL_STRING };
	capture_table[67] = (CaptureMapping){ "markup.strikethrough",       token::GENERIC_DELETED };

	capture_table_count = 68;
}

/**
 * Map a Helix dot-notation capture name to a Chroma TokenType.
 * Uses hierarchical fallback: if "constant.numeric.integer" has no
 * exact mapping, try "constant.numeric", then "constant".
 */
fn int capture_to_token_type(String capture) @public {
	init_capture_table();

	// Try progressively shorter prefixes (most specific first)
	String candidate = capture;
	while (candidate.len > 0) {
		// Linear scan for exact match
		for (int i = 0; i < capture_table_count; i++) {
			if (candidate == capture_table[i].capture) {
				return capture_table[i].token_type;
			}
		}

		// Strip last dot-segment
		int last_dot = -1;
		for (int i = candidate.len - 1; i >= 0; i--) {
			if (candidate.ptr[i] == '.') {
				last_dot = i;
				break;
			}
		}

		if (last_dot <= 0) break;
		candidate = candidate[0..last_dot];
	}

	return token::TEXT;
}
