#!/usr/bin/env python3
"""Convert Chroma styles to ink's TOML theme files.

Usage: scripts/chroma-themes.py <chroma checkout> <theme name>...

Writes data/themes/<name>.toml for each theme. Add the new files to the
list in src/themes/themes.c3 so they get embedded.
"""
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

root = pathlib.Path(__file__).resolve().parent.parent
chroma = pathlib.Path(sys.argv[1])


def key(chroma_type):
    # KeywordConstant -> keyword.constant
    return ".".join(w.lower() for w in re.findall(r"[A-Z][a-z]*", chroma_type))


for name in sys.argv[2:]:
    src = chroma / "styles" / f"{name}.xml"
    lines = [f"# Converted from Chroma's styles/{name}.xml", ""]
    for e in ET.parse(src).getroot().iter("entry"):
        lines.append(f'{key(e.get("type"))} = "{e.get("style")}"')
    (root / "data/themes" / f"{name}.toml").write_text("\n".join(lines) + "\n")
    print(name)
