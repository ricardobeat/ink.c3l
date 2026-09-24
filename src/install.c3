module ink::install;

import ink::helix;

// Installing a grammar on demand, for a language whose grammar ink does not
// ship: download it prebuilt, with its query, into the user's cache, so an
// editor can offer it when a file needs it. Nothing is compiled on the
// user's machine; building is for the grammars ink ships (cli/grammars.c3).
//
// Not implemented yet. Callers can already offer an install and treat
// NOT_IMPLEMENTED as "not available".

faultdef NOT_IMPLEMENTED;

fn void? install(helix::Language* l) @public {
	return NOT_IMPLEMENTED~;
}
