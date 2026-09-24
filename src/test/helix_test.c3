module ink::test;

import ink::helix;

fn void test_helix_finds_json_by_extension() @test {
	defer helix::unload();
	helix::Language* l = helix::language_for_file("data/package.json")!!;
	assert(l.name == "json", "got %s", l.name);
	helix::Grammar* g = helix::grammar_for(l)!!;
	assert(g.git == "https://github.com/tree-sitter/tree-sitter-json");
	assert(g.rev.len == 40);
}

fn void test_helix_prefers_a_glob_to_an_extension() @test {
	defer helix::unload();
	helix::Language* l = helix::language_for_file("tsconfig.json")!!;
	assert(l.name == "jsonc", "got %s", l.name);
}

fn void test_helix_matches_whole_file_names() @test {
	defer helix::unload();
	helix::Language* l = helix::language_for_file("/x/Cargo.lock")!!;
	assert(l.name == "toml", "got %s", l.name);
}

fn void test_helix_reads_subpaths_and_grammar_overrides() @test {
	defer helix::unload();
	helix::Language* l = helix::language_for_file("a.tsx")!!;
	helix::Grammar* g = helix::grammar_for(l)!!;
	assert(g.subpath == "tsx", "got %s", g.subpath);
	helix::Language* p = helix::language_named("protobuf")!!;
	assert(p.grammar == "proto", "got %s", p.grammar);
}

fn void test_helix_has_no_language_for_unknown_files() @test {
	defer helix::unload();
	assert(!@ok(helix::language_for_file("notes.qqqqzz")));
}
