# ink — C3 Syntax Highlighting Library

A C3 port of [Chroma](https://github.com/alecthomas/chroma), using tree-sitter for lexing.
Outputs styled token streams for terminal apps (escape codes applied externally).

## Source of Truth

[Helix editor](https://github.com/helix-editor/helix) provides everything:

- **`languages.toml`** — Single file: `[[language]]` (name, file-types, scope) + `[[grammar]]` (git repo, pinned rev) per language
- **`runtime/queries/<lang>/highlights.scm`** — Pre-built highlight queries with a rich hierarchical capture convention

Both files are vendored in `data/`. Grammars are cloned + compiled to `.dylib` by a build script.

## Architecture

```
ink/
├── project.json
├── .c3fmt
├── vendor/
│   └── tree_sitter/
│       └── api.h                  (vendored tree-sitter C header)
├── data/
│   ├── languages.toml             (vendored from Helix)
│   └── queries/<lang>/
│       └── highlights.scm         (vendored from Helix runtime/queries)
├── grammars/                      (compiled .dylib output, gitignored)
│   ├── libtree-sitter-c.dylib
│   ├── libtree-sitter-go.dylib
│   └── ...
├── scripts/
│   └── fetch_grammars.c3          (reads languages.toml, clones + compiles)
└── src/
    ├── token.c3                   (TokenType enum, Token struct)
    ├── colour.c3                  (Colour, parse/format/brightness)
    ├── style.c3                   (StyleEntry, Style, StyleRegistry)
    ├── lexer.c3                   (Lexer interface, LexerRegistry, Coalesce)
    ├── ts_bind.c3                 (tree-sitter C API externs)
    ├── ts_lexer.c3                (TsLexer: parse, run query, map captures)
    ├── captures.c3                (capture name → TokenType mapping + fallback)
    ├── lang_registry.c3           (reads languages.toml section to build registry)
    ├── highlight.c3               (top-level: init(), lexer_for(), style_for())
    └── themes/
        ├── monokai.c3
        ├── github.c3
        └── all.c3
```

## API Surface

```c3
// Setup
highlight::init();

// Lookup lexer by language name or filename
Lexer? lexer = highlight::lexer_for("go");
Lexer? lexer2 = highlight::lexer_for_filename("foo.rs");

// Lookup style
Style? style = highlight::style_for("monokai");

// Tokenize source
TokenIterator? it = lexer.tokenise(source)?;

// Resolve style for each token
foreach (token : it) {
    StyleEntry entry = style.get(token.type);
    // entry.fg, entry.bold, etc. → emit ANSI externally
}
```

## Core Types

### TokenType (`src/token.c3`)

C3 `enum TokenType : int` mirroring Chroma's hierarchy exactly:

```
EOFType = 0, None = 0
Background = -1, PreWrapper = -2, ...

Keyword = 1000        → KeywordConstant, KeywordDeclaration, KeywordNamespace,
                         KeywordPseudo, KeywordReserved, KeywordType

Name = 2000           → NameAttribute, NameClass, NameConstant, NameDecorator,
                         NameEntity, NameException, NameKeyword, NameLabel,
                         NameNamespace, NameOperator, NameOther, NamePseudo,
                         NameProperty, NameTag
  NameBuiltin = 2100  → NameBuiltinPseudo
  NameVariable = 2200 → NameVariableAnonymous, NameVariableClass,
                         NameVariableGlobal, NameVariableInstance,
                         NameVariableMagic
  NameFunction = 2300 → NameFunctionMagic

Literal = 3000        → LiteralDate, LiteralOther
  LiteralString = 3100 → LiteralStringAffix, LiteralStringAtom,
                         LiteralStringBacktick, LiteralStringBoolean,
                         LiteralStringChar, LiteralStringDelimiter,
                         LiteralStringDoc, LiteralStringDouble,
                         LiteralStringEscape, LiteralStringHeredoc,
                         LiteralStringInterpol, LiteralStringName,
                         LiteralStringOther, LiteralStringRegex,
                         LiteralStringSingle, LiteralStringSymbol
  LiteralNumber = 3200 → LiteralNumberBin, LiteralNumberFloat,
                         LiteralNumberHex, LiteralNumberInteger,
                         LiteralNumberIntegerLong, LiteralNumberOct,
                         LiteralNumberByte

Operator = 4000       → OperatorWord, OperatorReserved
Punctuation = 5000
Comment = 6000        → CommentHashbang, CommentMultiline, CommentSingle,
                         CommentSpecial
  CommentPreproc = 6100 → CommentPreprocFile

Generic = 7000        → GenericDeleted, GenericEmph, GenericError, GenericHeading,
                         GenericInserted, GenericOutput, GenericPrompt,
                         GenericStrong, GenericSubheading, GenericTraceback,
                         GenericUnderline

Text = 8000           → TextWhitespace, TextSymbol, TextPunctuation
```

Includes `Parent()`, `Category()`, `SubCategory()`, `InCategory()`, `InSubCategory()` methods.

### Token

```c3
struct Token {
    TokenType type;
    String value;
}
```

### Iterator

```c3
def TokenIterator = fn Token?();  // empty optional = EOF
```

### Lexer (`src/lexer.c3`)

```c3
interface Lexer {
    fn LexerConfig* config();
    fn TokenIterator? tokenise(String text);
    fn LexerRegistry* registry();
    fn void setRegistry(LexerRegistry* reg);
}
```

`LexerConfig` stores: name, aliases, file extensions.

`LexerRegistry` stores all lexers, supports lookup by name/alias/extension.

### Coalesce (`src/lexer.c3`)

Merges consecutive tokens of the same type (capped at 8KB per merge):

```c3
fn Lexer coalesce(Lexer* inner);
```

## Style System (`src/style.c3`)

### StyleEntry

```c3
struct StyleEntry {
    Colour fg;         // 0 = unset
    Colour bg;         // 0 = unset
    Colour border;     // 0 = unset
    bool bold;
    bool italic;
    bool underline;
    bool no_inherit;
}
```

Implements `Inherit(ancestors...)` → merges with ancestor entries, respecting `no_inherit`.

### Style

Stores `(TokenType → StyleEntry)` entries with optional parent. `get(tt)` does hierarchical fallback:
exact match → subcategory (tt/100*100) → category (tt/1000*1000) → Text → Background.

Parses from Chroma-compatible XML style definitions.

### StyleRegistry

```c3
fn void styles_register(String name, Style* style);
fn Style? styles_get(String name);
```

## Colour (`src/colour.c3`)

```c3
typedef Colour = uint;  // 0x00RRGGBB-style (unset = 0)

fn Colour colour_new(uint8 r, uint8 g, uint8 b);
fn Colour colour_parse(String s);           // #rgb, #rrggbb, #ansi<name>
fn bool colour_is_set(Colour c);
fn uint8 colour_red(Colour c);
fn uint8 colour_green(Colour c);
fn uint8 colour_blue(Colour c);
fn double colour_brightness(Colour c);
fn Colour colour_brighten(Colour c, double factor);  // <0 = darken
fn Colour colour_brighten_or_darken(Colour c, double factor);
fn Colour colour_clamp_brightness(Colour c, double min, double max);
fn double colour_distance(Colour a, Colour b);
fn String colour_string(Colour c);                     // "#rrggbb"
```

## Tree-sitter Integration

### C API Bindings (`src/ts_bind.c3`)

Extern declarations for the tree-sitter C API:

```c3
extern fn TSParser* ts_parser_new();
extern fn void ts_parser_delete(TSParser* self);
extern fn bool ts_parser_set_language(TSParser* self, const TSLanguage* language);
extern fn TSTree* ts_parser_parse_string(TSParser* self, const TSTree* old_tree, const char* string, uint32_t length);
extern fn TSNode ts_tree_root_node(const TSTree* self);
extern fn TSQuery* ts_query_new(const TSLanguage* language, const char* source, uint32_t source_len, uint32_t* error_offset, TSQueryError* error_type);
extern fn TSQueryCursor* ts_query_cursor_new();
extern fn void ts_query_cursor_exec(TSQueryCursor* self, const TSQuery* query, TSNode node);
extern fn bool ts_query_cursor_next_capture(TSQueryCursor* self, TSQueryMatch* match, uint32_t* capture_index);
// ... plus cleanup functions
```

### TsLexer (`src/ts_lexer.c3`)

Implements `Lexer` interface. Each instance wraps:
- A `TSLanguage*` pointer (from the grammar `.dylib`)
- An embedded highlight query string (from `data/queries/<lang>/highlights.scm`)

Tokenization flow:
1. Create `TSParser`, set language
2. `ts_parser_parse_string()` → `TSTree`
3. `ts_query_new()` to compile the highlight query
4. `ts_query_cursor_exec()` on the root node
5. Iterate `ts_query_cursor_next_capture()` to get captures in source order
6. For each capture: map capture name → `TokenType`, emit token
7. Between captures: emit `Text` token for unmatched source ranges
8. Return a coalesced `TokenIterator`

### Capture → TokenType Mapping (`src/captures.c3`)

Helix's dot-notation captures map to Chroma TokenTypes with **hierarchical fallback**:
if `@constant.numeric.integer` has no exact mapping, try `@constant.numeric`, then `@constant`.

| Helix capture | Chroma TokenType |
|---|---|
| `variable` | NameVariable |
| `variable.other.member` | NameProperty |
| `variable.parameter` | NameVariable |
| `variable.builtin` | NameBuiltin |
| `constant` | NameConstant |
| `constant.builtin` | NameConstant |
| `constant.builtin.boolean` | LiteralStringBoolean |
| `constant.numeric` | LiteralNumber |
| `constant.numeric.integer` | LiteralNumberInteger |
| `constant.numeric.float` | LiteralNumberFloat |
| `constant.character` | LiteralStringChar |
| `constant.character.escape` | LiteralStringEscape |
| `function` | NameFunction |
| `function.builtin` | NameBuiltin |
| `function.method` | NameFunction |
| `function.macro` | NameFunction |
| `function.special` | NameFunction |
| `constructor` | NameFunction |
| `type` | KeywordType |
| `type.builtin` | KeywordType |
| `type.definition` | KeywordType |
| `type.parameter` | KeywordType |
| `type.enum.variant` | NameConstant |
| `keyword` | Keyword |
| `keyword.control` | Keyword |
| `keyword.control.conditional` | Keyword |
| `keyword.control.repeat` | Keyword |
| `keyword.control.return` | Keyword |
| `keyword.control.import` | KeywordNamespace |
| `keyword.function` | Keyword |
| `keyword.storage` | Keyword |
| `keyword.storage.type` | KeywordType |
| `keyword.storage.modifier` | Keyword |
| `keyword.operator` | OperatorWord |
| `keyword.directive` | CommentPreproc |
| `namespace` | NameNamespace |
| `label` | NameLabel |
| `string` | LiteralString |
| `string.regexp` | LiteralStringRegex |
| `string.special` | LiteralStringOther |
| `operator` | Operator |
| `punctuation` | Punctuation |
| `punctuation.delimiter` | Punctuation |
| `punctuation.bracket` | Punctuation |
| `punctuation.special` | Punctuation |
| `comment` | Comment |
| `comment.line` | CommentSingle |
| `comment.block` | CommentMultiline |
| `comment.line.documentation` | CommentSpecial |
| `comment.block.documentation` | CommentSpecial |
| `comment.unused` | Comment |
| `attribute` | NameAttribute |
| `special` | Operator |
| `tag` | NameTag |
| `tag.delimiter` | Punctuation |
| `diff.plus` | GenericInserted |
| `diff.minus` | GenericDeleted |
| `diff.delta` | GenericEmph |
| `markup.heading` | GenericHeading |
| `markup.strong` | GenericStrong |
| `markup.italic` | GenericEmph |
| `markup.underline` | GenericUnderline |
| `markup.link` | Text |
| `markup.raw` | LiteralString |
| `markup.list` | Punctuation |
| `markup.quote` | GenericOutput |
| `markup.math` | LiteralString |
| `markup.strikethrough` | GenericDeleted |
| (unmatched) | Text |

## Language Registry (`src/lang_registry.c3`)

On `init()`, loads language definitions from the embedded `languages.toml` data.
For each `[[language]]` + `[[grammar]]` pair, creates a `TsLexer` with:
- The grammar's `.dylib` path
- The highlight query string from `data/queries/<name>/highlights.scm`

Languages that share grammars (e.g., `jsx` → `javascript`, `jsonc` → `json`) use the
same grammar pointer but potentially different queries.

Lookup by name, alias, or file extension. File extension matching: try exact extension
match, then fall back to the first lexer. No glob matching in v1.

## Themes (`src/themes/`)

Built-in styles ported from Chroma XML style definitions. Minimum set:

- **monokai** — Dark, high-contrast
- **github** — Light
- **dracula** — Dark
- **onedark** — Dark
- **catppuccin-mocha** — Dark

Each is a C3 function that registers a `Style` with the global `StyleRegistry`.
Defined using Chroma's style entry syntax (e.g., `"#a6e22e"`, `"bold #f92672"`,
`"bg:#272822"`, `"italic"`).

## Build System

### Fetching Grammars (`scripts/fetch_grammars.c3`)

Reads `data/languages.toml`, for each `[[grammar]]` entry:
1. Clone the git repo at the pinned revision
2. Compile to `.dylib` using the tree-sitter CLI (`tree-sitter generate && gcc -shared ...`)
3. Place in `grammars/`

### Compilation

Standard `c3c build` with:
- `grammars/` as a library search path
- Tree-sitter runtime library linked
- Grammars linked dynamically (load at runtime via `dlopen`) or statically (extern function per grammar)

### Runtime Grammar Loading

Option A (simpler): Each grammar is compiled to a `.dylib` that exports `tree_sitter_<name>()`.
At runtime, `dlopen` the dylib and `dlsym` the language symbol.

Option B: Statically link grammars. Each language module declares `extern fn TSLanguage* tree_sitter_c();`
etc. More build-time coupling but no runtime loading complexity.

## What's Excluded

- **No formatters** — HTML, ANSI terminal, SVG output are external. We only produce styled tokens.
- **No Chroma XML regex lexer engine** — All lexing is tree-sitter based.
- **No file glob matching** — Extension-based lookup only in v1.
- **No content-based `AnalyseText` detection** — Can be added later via simple keyword heuristics.
- **No `RemappingLexer` / `TypeRemappingLexer`** — Can be added as needed.
- **No Wasm grammars** — Dynamic libraries only initially.

## Phases

| # | Module | Files | Target lines |
|---|--------|-------|-------------|
| 1 | TokenType enum, Token struct, Iterator | `src/token.c3` | ~120 |
| 2 | Colour type (RGB, parse, brightness, format) | `src/colour.c3` | ~100 |
| 3 | StyleEntry, Style (hierarchical lookup), StyleRegistry | `src/style.c3` | ~200 |
| 4 | Lexer interface, LexerConfig, LexerRegistry, Coalesce | `src/lexer.c3` | ~120 |
| 5 | Tree-sitter C API bindings | `src/ts_bind.c3` | ~180 |
| 6 | TsLexer (parse, query, capture mapping, token fill) | `src/ts_lexer.c3` | ~200 |
| 7 | Capture → TokenType mapping table | `src/captures.c3` | ~80 |
| 8 | Language registry (load from toml, grammar/query binding) | `src/lang_registry.c3` | ~150 |
| 9 | Top-level API (init, lexer_for, style_for) | `src/highlight.c3` | ~60 |
| 10 | Built-in themes (Monokai, GitHub, Dracula) | `src/themes/*.c3` | ~250 |
| 11 | Grammar fetch/build script | `scripts/fetch_grammars.c3` | ~100 |
| 12 | Vendored Helix data (languages.toml + queries) | `data/` | — |
| 13 | Tests | `src/test/*.c3` | ~200 |
| | **Total estimated** | | **~1760** |
