module ink_grammars;

import ink::helix;
import ink::build;
import std::io;
import std::os::env;
import std::collections::list;

// grammars builds grammar sets: for each language named on the command
// line (by its Helix name), fetch and compile its grammar into the set's
// folder and fetch its highlight query into <folder>/queries/. Existing ones
// are kept, so re-running it only builds what is missing. Run it from ink's
// root:
//
//   c3c run grammars -- json yaml toml
//
// --dir DIR builds into DIR instead of grammars/, and --all builds every
// language Helix has instead of the ones named.
fn int main(String[] args) {
	// Absolute, since the build runs its tools from inside each checkout.
	String root = env::tget_var("PWD") ?? ".";
	String dir = "grammars";
	bool all = false;
	List{String} names;
	names.tinit();
	for (usz i = 1; i < args.len; i++) {
		if (args[i] == "--all") {
			all = true;
		} else if (args[i] == "--dir" && i + 1 < args.len) {
			dir = args[++i];
		} else {
			names.push(args[i]);
		}
	}
	if (all) {
		foreach (&l : helix::all()) names.push(l.name);
	}
	build::Dirs dirs = {
		.grammars = string::tformat("%s/%s", root, dir),
		.queries = string::tformat("%s/%s/queries", root, dir),
		.work = string::tformat("%s/out/grammar-src", root),
		.log = string::tformat("%s/out/grammars.log", root),
	};
	int failed = 0;
	foreach (name : names) {
		io::printf("%-18s ", name);
		(void)io::stdout().flush();
		helix::Language*? l = helix::language_named(name);
		if (catch l) {
			io::printn("no such language in Helix");
			failed++;
			continue;
		}
		if (catch err = build::build(&dirs, l)) {
			io::printfn("failed: %s (see %s)", err, dirs.log);
			failed++;
			continue;
		}
		io::printn("ok");
	}
	return failed > 0 ? 1 : 0;
}
