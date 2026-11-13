#!/bin/sh
# Builds ink's grammars. Each grammar is fetched from the git repository Helix
# names, at Helix's pinned revision, and compiled into the set's folder, with
# a gzipped copy for -D EMBED_GRAMMARS builds; its highlight query goes to
# <folder>/queries/. Each run regenerates the set's embed list in
# src/embedded/. Grammars and queries already
# there are kept, so this only builds what is missing; delete one to rebuild
# it. Needs c3c, git, cc and curl.
#
#   grammars/           the languages in grammars.txt (only queries/ is checked in)
#   grammars-extended/  every language Helix has (gitignored); starts as a
#                       copy of grammars/ so those aren't rebuilt
#
# Programs use grammars/ unless built with -D INK_EXTENDED.
#
#   scripts/build-grammars.sh             # grammars/
#   scripts/build-grammars.sh json yaml   # just these, into grammars/
#   scripts/build-grammars.sh --extended  # grammars-extended/
#
# Some Helix grammars fail to fetch or build; the rest are still installed
# and the script exits non-zero.
set -e
cd "$(dirname "$0")/.."
mkdir -p src/embedded
c3c build grammars

if [ "$1" = "--extended" ]; then
	mkdir -p grammars-extended
	cp -Rn grammars/ grammars-extended/
	exec ./out/grammars --extended --all
fi
if [ $# -eq 0 ]; then
	set -- $(sed 's/#.*//' grammars.txt)
fi
exec ./out/grammars "$@"
