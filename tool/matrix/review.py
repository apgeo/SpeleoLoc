#!/usr/bin/env python3
"""Prepares a finished matrix run for an agent (or a person) to review.

The run's own checks are mechanical: a screen threw, text was cut off, a
tap target was too small. What they cannot judge is whether a screen looks
right — a dialog that fits but is cut oddly, a label in the wrong language,
an empty area where a list should be, two shapes that disagree. That needs
eyes, and eyes cost: every screenshot an agent reads is paid for in tokens.
So this picks what is worth looking at, lays each screen's shapes side by
side on one contact sheet, and writes a brief with the checklist, the
known findings for each sheet and what it will cost to read.

    python3 tool/matrix/review.py                    # the latest run
    python3 tool/matrix/review.py build/matrix/<run> --budget 120000
    python3 tool/matrix/review.py --accept           # this run is the new baseline

What is picked, in order, until the token budget is spent:
  1. screens that failed to open or lay out;
  2. screens with findings (cut-off text, accessibility);
  3. screens whose pixels changed since the accepted baseline.
An unchanged, finding-free screen is never sent: it was looked at before.

Only output whose data origin is `invented` or `anonymized` is ever put in
front of an agent; anything else is listed as skipped, by folder only.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from matrix import READABLE, png_size, visual_tokens  # noqa: E402

BASELINE = ROOT / "build" / "matrix" / "baseline" / "hashes.json"

RUBRIC = """\
For each sheet, look for these and nothing else; the run already checked
overflow, cut-off text and tap-target sizes mechanically, and those
findings are listed under each sheet so you do not report them twice.

- **Layout**: a control clipped, overlapping another, hidden under the
  status or navigation bar, or pushed off screen in one shape but not the
  others; a dialog or sheet cut off; a large empty area where content
  should be (a list that failed to load looks like this).
- **Text**: a label in the other language than the rest of the screen, a
  raw key (`select_all`, `trip_media_from_qr`) instead of words, an empty
  box where a letter should be (a missing glyph, often ș or ț), a number,
  date or coordinate shown unformatted, `null`, `NaN`, a UUID or a file
  path shown to a person.
- **Controls**: an icon whose meaning is not guessable and has no label,
  controls packed so close they will be mis-tapped, something that looks
  disabled but is not or the reverse.
- **Consistency**: the same element placed, sized or coloured differently
  between shapes or between screens without a reason.
- **Field use**: this app is used underground, with gloves, by headlamp.
  Note anything small, low-contrast or fiddly that would be hard there.

Report each issue on one line: sheet, shape, severity (`bug` breaks or
misleads; `polish` looks wrong; `idea` could be better), what you see, and
the change you would make. Say "no issues" for a sheet that has none —
silence is not a verdict. Write the result to `verdicts.md` next to this
file.
"""


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_cells(run_dir: Path):
    report = json.loads((run_dir / "report.json").read_text())
    for cell in report["cells"]:
        out = run_dir / cell["id"]
        result = out / "result.json"
        if not result.exists():
            continue
        yield cell, out, json.loads(result.read_text())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("run_dir", nargs="?", default=str(ROOT / "build/matrix/latest"))
    parser.add_argument("--budget", type=int, default=150_000,
                        help="input tokens the review may cost (default 150000)")
    parser.add_argument("--sheet-height", type=int, default=900,
                        help="height of each screenshot on a sheet, in pixels")
    parser.add_argument("--accept", action="store_true",
                        help="record this run's screenshots as the baseline and stop")
    args = parser.parse_args()
    run_dir = Path(args.run_dir).resolve()

    baseline = json.loads(BASELINE.read_text()) if BASELINE.exists() else {}
    current, skipped_dirs, groups = {}, [], {}
    for cell, out, result in load_cells(run_dir):
        origin = cell.get("origin", "unknown")
        if origin not in READABLE:
            skipped_dirs.append(cell["id"])
            continue
        for screen in result.get("screens", []):
            shot = screen.get("shot")
            if not shot or not (out / f"{shot}.png").exists():
                continue
            png = out / f"{shot}.png"
            key = f"{cell['device']}/{cell['lang']}-{cell['settings']}/{shot}"
            current[key] = sha(png)
            findings = screen.get("findings", [])
            failed = screen.get("status") in ("error", "timeout")
            changed = baseline.get(key) != current[key]
            if not (failed or findings or changed):
                continue
            rank = 0 if failed else (1 if findings else 2)
            group_key = (cell["kind"], cell["lang"], cell["settings"], screen["id"])
            group = groups.setdefault(group_key, {"rank": rank, "images": [], "notes": []})
            group["rank"] = min(group["rank"], rank)
            label = screen["shape"] if cell["kind"] == "desktop" else f"{cell['device']} {screen['shape']}"
            group["images"].append({"path": str(png), "label": label})
            if failed:
                group["notes"].append(f"{label}: FAILED — {screen.get('error', '')[:240]}")
            for f in findings:
                if f.get("kind") == "truncated_text":
                    group["notes"].append(f"{label}: cut off — \"{f.get('text', '')}\"")
                elif "count" in f:
                    group["notes"].append(f"{label}: {f['count']} × {f['kind'].replace('_', ' ')}")

    if args.accept:
        BASELINE.parent.mkdir(parents=True, exist_ok=True)
        BASELINE.write_text(json.dumps({**baseline, **current}, indent=1, sort_keys=True))
        print(f"baseline: {len(current)} screenshot(s) recorded in {BASELINE.relative_to(ROOT)}")
        return 0

    review_dir = run_dir / "review"
    shutil.rmtree(review_dir, ignore_errors=True)
    review_dir.mkdir()
    ordered = sorted(groups.items(), key=lambda kv: (kv[1]["rank"], kv[0]))
    plan, spent, left_out = [], 0, 0
    for (kind, lang, settings, screen_id), group in ordered:
        # What one sheet will cost once its tiles are scaled to a common
        # height and laid side by side.
        width = 16
        for image in group["images"]:
            w, h = png_size(Path(image["path"])) or (720, 1280)
            width += round(w * args.sheet_height / h) + 16
        cost = visual_tokens(width, args.sheet_height + 84)
        if spent + cost > args.budget:
            left_out += 1
            continue
        spent += cost
        name = f"{len(plan) + 1:03d}_{kind}_{lang}_{settings}_{screen_id}.png"
        plan.append({
            "out": str(review_dir / name),
            "title": f"{screen_id} — {lang}, {settings} settings, {kind}",
            "height": args.sheet_height,
            "images": group["images"],
            "_notes": group["notes"],
            "_rank": group["rank"],
            "_cost": cost,
        })

    if plan:
        spec = review_dir / "sheets.json"
        spec.write_text(json.dumps([{k: v for k, v in p.items() if not k.startswith("_")} for p in plan]))
        subprocess.run(["dart", "run", "tool/matrix/contact_sheet.dart", str(spec)],
                       cwd=ROOT, check=True, stdout=subprocess.DEVNULL)

    why = {0: "failed", 1: "has findings", 2: "changed since the baseline"}
    lines = [
        f"# UI review — {run_dir.name}", "",
        f"{len(plan)} sheet(s), about {spent:,} input tokens to read"
        + (f"; {left_out} more left out by the {args.budget:,}-token budget" if left_out else "")
        + ".", "",
    ]
    if skipped_dirs:
        lines += ["Not offered for review, because their data is not marked invented or "
                  "anonymized: " + ", ".join(f"`{d}`" for d in skipped_dirs) + ".", ""]
    if not plan:
        lines += ["Nothing to review: no failures, no findings and no change since the "
                  "accepted baseline.", ""]
    lines += ["## What to look for", "", RUBRIC, "## Sheets", ""]
    for p in plan:
        lines.append(f"### `{Path(p['out']).name}` — {why[p['_rank']]}, ~{p['_cost']:,} tokens")
        lines += [f"- {n}" for n in p["_notes"][:12]] or ["- no mechanical findings"]
        lines.append("")
    lines += ["When the run has been judged, record it as the baseline so the next "
              "review only shows what changed:", "", "```",
              f"python3 tool/matrix/review.py {run_dir.relative_to(ROOT)} --accept", "```", ""]
    (review_dir / "REVIEW.md").write_text("\n".join(lines))
    print(f"{len(plan)} sheet(s), ~{spent:,} tokens -> {(review_dir / 'REVIEW.md').relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
