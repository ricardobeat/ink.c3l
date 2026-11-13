# ink

ink is a syntax highlighter written in [C3](https://c3-lang.org). It parses
source with tree-sitter grammars and highlights it with
[Helix](https://helix-editor.com)'s highlight queries. Colours come from TOML
themes in Chroma's style format. It builds as a static library (`out/ink.a`)
and a command line tool (`out/inkfmt`).

## Supported languages

ink supports 90 languages, listed in [`grammars.txt`](grammars.txt).

```
ada              astro            awk              bash             blade
c                c3               caddyfile        capnp            clojure
cpp              crystal          csv              css              c-sharp
d                dart             dockerfile       env              elixir
elm              erlang           fsharp           flatbuffers      gdscript
gherkin          gleam            git-commit       git-config       git-rebase
git-attributes   git-ignore       git-notes        glsl             go
godot-resource   gomod            gowork           gotmpl           graphql
groovy           haskell          haxe             html             ini
javascript       jsx              java             jq               json
json5            julia            kcl              kotlin           lua
markdown         markdown.inline  matlab           meson            nginx
nim              nix              odin             perl             php
sql              protobuf         python           qml              r
racket           regex            ruby             rust             scala
scheme           scss             svelte           swift            tcl
hcl              toml             typescript       tsx              vue
wgsl             nasm             gas              yaml             zig
```

`inkfmt --list-langs` prints the languages whose grammars are built.



## How to use

Needs c3c 0.8.3 or newer and the tree-sitter runtime. On macOS, install the
runtime with `brew install tree-sitter`.

### The `inkfmt` binary

```sh
c3c build inkfmt
cat main.rs | out/inkfmt --lang rust
cat main.rs | out/inkfmt --lang rust --theme nord --html
out/inkfmt --file src/style.c3 < src/style.c3
out/inkfmt --list-langs
```

```sh
inkfmt --html  # outputs html
inkfmt --lang  # sets the language name (or file extension)
inkfmt --file  # takes the language from the file name
inkfmt --theme # picks a theme (monokai is the default)
```

### Embedding in C

Build the library with `c3c build ink` (`out/ink.a`). It is an ordinary native
archive, but the API is C3: C3 programs import the modules directly, while a C
program reaches it through a small shim compiled from C3 with `@export`:

```c3
// shim.c3
module shim;

import ink::grammars;
import ink::helix;
import ink::lexer;
import ink::token;
import std::io;

fn int ink_print_source(char* source, char* lang_name, char* roots) @export @cname("ink_print_source")
{
	String[] root_list = { ((ZString)roots).str_view() };
	helix::Language*? language = helix::language_named(((ZString)lang_name).str_view());
	if (catch language) return 1;

	lexer::Lexer*? lx = grammars::lexer_for(language, root_list);
	if (catch lx) return 2;

	token::TokenIterator*? tokens = lx.tokenise(((ZString)source).str_view());
	if (catch tokens) return 3;

	while (try tok = token::token_iterator_next(tokens))
	{
		io::print(tok.value);
	}
	return 0;
}
```

Compile the shim into a static library and link it from C together with the
tree-sitter runtime:

```sh
c3c --libdir /path/to/libs --lib ink static-lib shim.c3 -o libinkshim
cc -o myprog main.c libinkshim.a -L/opt/homebrew/lib -ltree-sitter
```

```c
#include <stdio.h>

int ink_print_source(const char* source, const char* lang, const char* roots);

int main(void)
{
    ink_print_source("fn main() {}\n", "rust", "/path/to/ink.c3l");
    return 0;
}
```

`libtree-sitter` and the grammar set under `roots` have to be present at run
time, unless the library is built with `-D EMBED_GRAMMARS`.

## How it works

### Tree-sitter

Every language is parsed by a tree-sitter grammar, a shared library exporting
a `tree_sitter_<name>` function. ink `dlopen`s the library at run time.

Grammars are compiled for your machine, so they aren't checked in: run
`scripts/build-grammars.sh` after cloning.

`grammars/` holds the 90 languages above. `grammars-extended/` holds every
language Helix has. Programs use `grammars/` unless built with
`-D INK_EXTENDED`.

`-D EMBED_GRAMMARS` puts the grammars in the binary instead, gzipped. The first
time a language is used, ink unpacks it into `~/Library/Caches/ink`
(`~/.cache/ink` on Linux) and loads it from there.


```sh
scripts/build-grammars.sh               # build what is missing from grammars/
scripts/build-grammars.sh json yaml     # just these
scripts/build-grammars.sh --extended    # build grammars-extended/
c3c build inkfmt -D INK_EXTENDED        # inkfmt with every Helix language
c3c build inkfmt -D EMBED_GRAMMARS      # a single binary with its grammars
```

### The theme format

A theme is a TOML file with one entry per token type. The key is a dotted token
name; the value is a Chroma style string:

```toml
background = "bg:#272822"
text = "#f8f8f2"
comment = "#75715e"
comment.special = "#75715e italic"
keyword = "bold #f92672"
keyword.type = "bold #66d9ef"
name.function = "#a6e22e"
literal.string = "#e6db74"
```

`inkfmt --theme-dir [dir]` can be used to load themes from a custom location.

