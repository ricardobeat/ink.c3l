#!/bin/sh
# Builds the grammars listed in grammars.txt: fetches each from the git
# repository Helix names, at Helix's pinned revision, compiles it into
# grammars/, and fetches its highlight query into data/queries/. Grammars and
# queries already there are kept, so this only builds what is missing; delete
# one to rebuild it. Needs c3c, git, cc and curl.
#
#   scripts/build-grammars.sh            # everything in grammars.txt
#   scripts/build-grammars.sh json yaml  # just these
set -e
cd "$(dirname "$0")/.."
c3c build grammars
if [ $# -eq 0 ]; then
	set -- $(sed 's/#.*//' grammars.txt)
fi
exec ./out/grammars "$@"
