#!/usr/bin/env python3
"""Two UI checks the analyzer does not make, held against a recorded count.

  hardcoded_text   user-visible strings written into the code rather than
                   looked up through LocServ: a `Text('…')`, a `tooltip:`,
                   `labelText:`, `hintText:`, `title:` or `content:` given a
                   literal with letters in it. Each one is a string that
                   stays English — or Romanian — whatever language is set.
  untitled_icon    an `IconButton(` with no `tooltip:` — no label for a
                   screen reader, and nothing to explain an icon on a long
                   press.

Both counts are compared with tool/ui_lint_baseline.json: a change may not
add to either, and lowering one is a matter of running with
--update-baseline. --list prints every occurrence (file:line), which is
where to start when fixing them.

    python3 tool/ui_lint.py
    python3 tool/ui_lint.py --list hardcoded_text
    python3 tool/ui_lint.py --update-baseline
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASELINE = ROOT / "tool" / "ui_lint_baseline.json"

# Where a user-visible string literal starts: right after one of these.
STARTS = [
    re.compile(r"\bText\(\s*(?=['\"])"),
    re.compile(r"\b(?:tooltip|labelText|hintText|helperText|semanticLabel)\s*:\s*(?=['\"])"),
    re.compile(r"\b(?:title|content|label)\s*:\s*(?:const\s+)?Text\(\s*(?=['\"])"),
]
# A word a person would read: three letters or more, Romanian included.
WORD = re.compile(r"[A-Za-zĂÂÎȘȚăâîșț]{3,}")


def literal_text(source: str, i: int) -> str:
    """The fixed text of the string literal starting at source[i], with
    every `${…}` and `$name` interpolation taken out — those are data, not
    words someone forgot to translate."""
    quote = source[i]
    triple = source[i:i + 3] == quote * 3
    end_mark = quote * 3 if triple else quote
    i += 3 if triple else 1
    out = []
    while i < len(source) and not source.startswith(end_mark, i):
        ch = source[i]
        if ch == "\\":
            i += 2
            continue
        if ch == "$" and i + 1 < len(source) and source[i + 1] == "{":
            depth, i = 1, i + 2
            while depth and i < len(source):
                if source[i] == "{":
                    depth += 1
                elif source[i] == "}":
                    depth -= 1
                i += 1
            out.append(" ")
            continue
        if ch == "$":
            m = re.match(r"\$[A-Za-z_]\w*", source[i:])
            if m:
                i += len(m.group(0))
                out.append(" ")
                continue
        if ch == "\n" and not triple:
            break
        out.append(ch)
        i += 1
    return "".join(out)


def strip_comments(source: str) -> str:
    source = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), source, flags=re.S)
    return re.sub(r"//[^\n]*", "", source)


def hardcoded_text(path: Path, source: str):
    seen = set()
    for pattern in STARTS:
        for match in pattern.finditer(source):
            text = literal_text(source, match.end()).strip()
            if not WORD.search(text):
                continue
            line = source.count("\n", 0, match.start()) + 1
            if line not in seen:
                seen.add(line)
                yield line, text


def untitled_icon(path: Path, source: str):
    for match in re.finditer(r"\bIconButton(?:\.\w+)?\(", source):
        depth, i = 1, match.end()
        while depth and i < len(source):
            if source[i] == "(":
                depth += 1
            elif source[i] == ")":
                depth -= 1
            i += 1
        # Only the button's own arguments, not those of widgets nested in it.
        own, nested, level = [], 0, 0
        for ch in source[match.end():i - 1]:
            if ch in "([{":
                level += 1
            elif ch in ")]}":
                level -= 1
            own.append(ch if level == 0 else " ")
        if not re.search(r"\btooltip\s*:", "".join(own)):
            yield source.count("\n", 0, match.start()) + 1, "IconButton"


CHECKS = {"hardcoded_text": hardcoded_text, "untitled_icon": untitled_icon}


def scan():
    found = {name: [] for name in CHECKS}
    for path in sorted((ROOT / "lib").rglob("*.dart")):
        if path.name.endswith(".g.dart"):
            continue
        source = strip_comments(path.read_text())
        rel = path.relative_to(ROOT)
        for name, check in CHECKS.items():
            for line, what in check(path, source):
                found[name].append(f"{rel}:{line}  {what[:60]}")
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--list", choices=list(CHECKS), help="print every occurrence of one check")
    parser.add_argument("--update-baseline", action="store_true")
    args = parser.parse_args()

    found = scan()
    if args.list:
        print("\n".join(found[args.list]))
        return 0
    counts = {name: len(items) for name, items in found.items()}
    if args.update_baseline or not BASELINE.exists():
        BASELINE.write_text(json.dumps(counts, indent=1, sort_keys=True) + "\n")
        print(f"ui lint baseline set: {counts}")
        return 0
    baseline = json.loads(BASELINE.read_text())
    status = 0
    for name, count in counts.items():
        allowed = baseline.get(name, 0)
        if count > allowed:
            print(f"ui lint: {name} {count}, up from {allowed} — see: python3 tool/ui_lint.py --list {name}",
                  file=sys.stderr)
            status = 1
        else:
            note = "; lower the baseline with --update-baseline" if count < allowed else ""
            print(f"ui lint: {name} {count} (baseline {allowed}){note}")
    return status


if __name__ == "__main__":
    sys.exit(main())
