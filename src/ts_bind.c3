module ink::ts_bind;

// ---- Opaque types (C forward-declared structs, used as pointers) ----
typedef TSParser = void;
typedef TSLanguage = void;
typedef TSTree = void;
typedef TSQuery = void;
typedef TSQueryCursor = void;

// ---- Structs ----
struct TSPoint {
	uint row;
	uint column;
}

struct TSNode {
	uint[4] context;
	void* id;
	TSTree* tree;
}

struct TSQueryCapture {
	TSNode node;
	uint index;
}

struct TSQueryMatch {
	uint id;
	ushort pattern_index;
	ushort capture_count;
	TSQueryCapture* captures;
}

alias TSQueryError = int;
const TSQueryError TS_QUERY_ERROR_NONE      = 0;
const TSQueryError TS_QUERY_ERROR_SYNTAX    = 1;
const TSQueryError TS_QUERY_ERROR_NODE_TYPE = 2;
const TSQueryError TS_QUERY_ERROR_FIELD     = 3;
const TSQueryError TS_QUERY_ERROR_CAPTURE   = 4;
const TSQueryError TS_QUERY_ERROR_STRUCTURE = 5;
const TSQueryError TS_QUERY_ERROR_LANGUAGE  = 6;

// ---- Parser functions ----
extern fn TSParser* ts_parser_new();
extern fn void ts_parser_delete(TSParser* self);
extern fn bool ts_parser_set_language(TSParser* self, TSLanguage* language);
extern fn TSTree* ts_parser_parse_string(TSParser* self, TSTree* old_tree, char* string, uint length);

// ---- Tree functions ----
extern fn void ts_tree_delete(TSTree* self);
extern fn TSNode ts_tree_root_node(TSTree* self);

// ---- Node functions ----
extern fn uint ts_node_start_byte(TSNode self);
extern fn uint ts_node_end_byte(TSNode self);
extern fn char* ts_node_type(TSNode self);
extern fn bool ts_node_is_null(TSNode self);

// ---- Query functions ----
extern fn TSQuery* ts_query_new(
	TSLanguage* language,
	char* source,
	uint source_len,
	uint* error_offset,
	TSQueryError* error_type
);
extern fn void ts_query_delete(TSQuery* self);
extern fn uint ts_query_capture_count(TSQuery* self);
extern fn char* ts_query_capture_name_for_id(TSQuery* self, uint index, uint* length);

// ---- Query cursor functions ----
extern fn TSQueryCursor* ts_query_cursor_new();
extern fn void ts_query_cursor_delete(TSQueryCursor* self);
extern fn void ts_query_cursor_exec(TSQueryCursor* self, TSQuery* query, TSNode node);
extern fn bool ts_query_cursor_next_capture(TSQueryCursor* self, TSQueryMatch* match, uint* capture_index);

// ---- Language functions ----
extern fn uint ts_language_symbol_count(TSLanguage* self);
