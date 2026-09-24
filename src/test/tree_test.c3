module ink::test;

import ink::helix;
import ink::grammars;
import ink::lexer;
import ink::tree;

fn void test_tree_finds_the_node_at_a_position() @test {
	defer helix::unload();
	lexer::Lexer* lx = grammars::lexer_for_file("x.json", { "." })!!;
	String src = "{\"a\": [1, \"b\"]}";
	tree::Tree t = tree::parse(lx, src)!!;
	defer t.free();
	tree::Node n = t.node_at(12, 12);
	assert(n.inside({ "string" }), "position 12 is in \"b\", got %s", n.kind());
	assert(!t.node_at(8, 8).inside({ "string" }), "position 8 is in a number");
}

fn void test_tree_finds_a_tag_to_close() @test {
	defer helix::unload();
	lexer::Lexer* lx = grammars::lexer_for_file("x.html", { "." })!!;
	String src = "<ul><li class=\"a\">";
	tree::Tree t = tree::parse(lx, src)!!;
	defer t.free();
	assert(t.tag_to_close(src.len)!! == "li");
	assert(!@ok(t.tag_to_close(4)) || t.tag_to_close(4)!! == "ul");

	String closed = "<p></p>";
	tree::Tree t2 = tree::parse(lx, closed)!!;
	defer t2.free();
	assert(!@ok(t2.tag_to_close(3)), "already closed");

	String br = "<br>";
	tree::Tree t3 = tree::parse(lx, br)!!;
	defer t3.free();
	assert(!@ok(t3.tag_to_close(4)), "void element");
}

fn void test_tree_closes_jsx() @test {
	defer helix::unload();
	lexer::Lexer* lx = grammars::lexer_for_file("x.jsx", { "." })!!;
	String src = "const a = <Foo.Bar x={1}>";
	tree::Tree t = tree::parse(lx, src)!!;
	defer t.free();
	assert(t.tag_to_close(src.len)!! == "Foo.Bar");
}

fn void test_helix_reads_auto_pairs() @test {
	defer helix::unload();
	helix::Language* rs = helix::language_named("rust")!!;
	assert(rs.auto_pairs.len() > 0 && rs.auto_pairs.len() % 2 == 0);
	assert(!rs.auto_pairs.contains("'"), "rust does not pair ' (lifetimes)");
}
