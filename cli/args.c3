module inkfmt::args;

import std::io;

struct Options {
	String lang;
	String filename;
	String path;
	String theme;
	String theme_dir;
	bool html;
	bool list_langs;
	bool help;
}

faultdef BAD_ARGUMENTS;

fn void usage() {
	io::eprintf("usage: inkfmt [--lang NAME] [--filename NAME] [--theme NAME] [--theme-dir DIR] [--html] [--list-langs] [--help] [FILE | < stdin]\n");
}

// parse reads inkfmt's command line. On a bad argument it prints why and
// returns BAD_ARGUMENTS.
fn Options? parse(String[] args) {
	Options o = { .theme = "monokai" };
	for (sz i = 1; i < args.len; i++) {
		String a = args[i];
		if (a == "--help" || a == "-h") {
			o.help = true;
		} else if (a == "--html") {
			o.html = true;
		} else if (a == "--list-langs") {
			o.list_langs = true;
		} else if (value(args, &i, "--lang", "-l", &o.lang)!) {
		} else if (value(args, &i, "--filename", "-f", &o.filename)!) {
		} else if (value(args, &i, "--theme", "-t", &o.theme)!) {
		} else if (value(args, &i, "--theme-dir", "", &o.theme_dir)!) {
		} else if (!a.starts_with("-") && o.path.len == 0) {
			o.path = a;
		} else {
			io::eprintf("unknown argument: %s\n", a);
			usage();
			return BAD_ARGUMENTS~;
		}
	}
	return o;
}

// value matches an option that takes a value, given as `--name value`,
// `--name=value` or `-abbr value`, and stores it in out.
fn bool? value(String[] args, sz* i, String name, String abbr, String* out) @local {
	String a = args[*i];
	if (a.starts_with(name) && a.len > name.len && a[name.len] == '=') {
		*out = a[name.len + 1..];
		return true;
	}
	if (a != name && (abbr.len == 0 || a != abbr)) return false;
	if (*i + 1 >= args.len) {
		io::eprintf("%s needs a value\n", name);
		return BAD_ARGUMENTS~;
	}
	*out = args[++*i];
	return true;
}
