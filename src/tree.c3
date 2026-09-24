module ink::tree;

import ink::lexer;
import ink::ts_bind;

// The syntax tree of a source text, for callers that need more than colored
// tokens: what construct a position is inside, whether an element is closed.
// It wraps just enough of tree-sitter's node API to walk the tree.

faultdef NO_GRAMMAR, PARSE_FAILED;

struct Tree {
	ts_bind::TSParser* parser;
	ts_bind::TSTree* tree;
	String source;
}

struct Node {
	ts_bind::TSNode n;
	String source;
}

// parse parses source with a lexer's grammar. The tree refers to source, so
// source must outlive it; free() releases it.
fn Tree? parse(lexer::Lexer* lx, String source) @public {
	if (!&lx.ts_language) return NO_GRAMMAR~;
	ts_bind::TSLanguage* lang = lx.ts_language();
	if (lang == null) return NO_GRAMMAR~;
	ts_bind::TSParser* p = ts_bind::ts_parser_new();
	if (!ts_bind::ts_parser_set_language(p, lang)) {
		ts_bind::ts_parser_delete(p);
		return NO_GRAMMAR~;
	}
	ts_bind::TSTree* t = ts_bind::ts_parser_parse_string(p, null, source.ptr, (uint)source.len);
	if (t == null) {
		ts_bind::ts_parser_delete(p);
		return PARSE_FAILED~;
	}
	return { .parser = p, .tree = t, .source = source };
}

fn void Tree.free(&self) {
	if (self.tree) ts_bind::ts_tree_delete(self.tree);
	if (self.parser) ts_bind::ts_parser_delete(self.parser);
	*self = {};
}

fn Node Tree.root(&self) => { ts_bind::ts_tree_root_node(self.tree), self.source };

// node_at is the smallest node spanning [start, end).
fn Node Tree.node_at(&self, sz start, sz end) {
	return { ts_bind::ts_node_descendant_for_byte_range(ts_bind::ts_tree_root_node(self.tree), (uint)start, (uint)end), self.source };
}

fn bool Node.is_null(self) => ts_bind::ts_node_is_null(self.n);
fn bool Node.is_named(self) => ts_bind::ts_node_is_named(self.n);
fn bool Node.is_missing(self) => ts_bind::ts_node_is_missing(self.n);
fn String Node.kind(self) => ((ZString)ts_bind::ts_node_type(self.n)).str_view();
fn sz Node.start(self) => ts_bind::ts_node_start_byte(self.n);
fn sz Node.end(self) => ts_bind::ts_node_end_byte(self.n);
fn String Node.text(self) => self.source[self.start():self.end() - self.start()];
fn Node Node.parent(self) => { ts_bind::ts_node_parent(self.n), self.source };
fn uint Node.child_count(self) => ts_bind::ts_node_child_count(self.n);
fn Node Node.child(self, uint i) => { ts_bind::ts_node_child(self.n, i), self.source };

// child_of_kind is the first child of one of the given kinds, or a null node.
fn Node Node.child_of_kind(self, String[] kinds) {
	for (uint i = 0; i < self.child_count(); i++) {
		Node c = self.child(i);
		foreach (k : kinds) if (c.kind() == k) return c;
	}
	return { .source = self.source };
}

// inside reports whether the node or one of its ancestors has a kind
// containing any of the given words — "string", "comment" — which is how
// grammars name those constructs across languages.
fn bool Node.inside(self, String[] words) {
	for (Node n = self; !n.is_null(); n = n.parent()) {
		String k = n.kind();
		foreach (w : words) if (k.contains(w)) return true;
	}
	return false;
}

// Elements HTML never closes.
const String[] VOID_ELEMENTS = {
	"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
	"param", "source", "track", "wbr",
};

// tag_to_close is the name of the tag to close when a start tag has just
// been finished at pos (the > typed): the start tag ending there, when its
// element has no end tag of its own. HTML and the grammars built on it
// (Vue, Svelte, Astro) name the parts start_tag / end_tag; JSX names them
// jsx_opening_element / jsx_closing_element.
fn String? Tree.tag_to_close(&self, sz pos) {
	if (pos == 0) return NOT_A_TAG~;
	Node n = self.node_at(pos - 1, pos);
	while (!n.is_null() && n.kind() != "start_tag" && n.kind() != "jsx_opening_element") n = n.parent();
	if (n.is_null() || n.end() != pos) return NOT_A_TAG~;

	Node name = n.child_of_kind({ "tag_name", "identifier", "member_expression", "nested_identifier", "jsx_namespace_name" });
	if (name.is_null()) return NOT_A_TAG~;
	String tag = name.text();
	if (n.kind() == "start_tag") {
		foreach (v : VOID_ELEMENTS) if (v == tag) return NOT_A_TAG~;
	}

	Node end = n.parent().child_of_kind({ "end_tag", "jsx_closing_element" });
	if (!end.is_null() && !end.is_missing() && end.end() > end.start()) return NOT_A_TAG~;
	return tag;
}

faultdef NOT_A_TAG;
