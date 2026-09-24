module ink_grammars;

import ink::helix;
import ink::build;
import std::io;
import std::os::env;

// grammars builds the grammars ink ships: for each language named on the
// command line (by its Helix name), fetch and compile its grammar into
// grammars/ and fetch its highlight query into data/queries/. Existing ones
// are kept, so re-running it only builds what is missing. Run it from ink's
// root:
//
//   c3c run grammars -- json yaml toml
fn int main(String[] args) {
	// Absolute, since the build runs its tools from inside each checkout.
	String root = env::tget_var("PWD") ?? ".";
	build::Dirs dirs = {
		.grammars = string::tformat("%s/grammars", root),
		.queries = string::tformat("%s/data/queries", root),
		.work = string::tformat("%s/out/grammar-src", root),
		.log = string::tformat("%s/out/grammars.log", root),
	};
	int failed = 0;
	foreach (name : args[1..]) {
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
