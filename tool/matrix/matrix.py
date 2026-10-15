#!/usr/bin/env python3
"""Runs one tier of the test matrix and writes a report.

The matrix is a list of cells. A desktop cell runs the app's Linux build
through every shape it is given; an Android cell runs one shape on one
emulator. tiers.json says which cells a tier has; this file builds what they
need once, runs them — emulators side by side, cells on one emulator in turn
— and turns what they produced into report.md and report.json.

Nothing here knows what the app does. A cell is set up by the scripts in
tool/android/ and judged by the flows in integration_test/.

    tool/test_matrix.sh --tier pulse
    python3 tool/matrix/matrix.py plan --tier full
    python3 tool/matrix/matrix.py report build/matrix/<run>

Exit code: 0 everything ran and passed, 1 something failed, 2 nothing
failed but part of the tier could not be run (which is not a pass).
"""

from __future__ import annotations

import argparse
import datetime as dt
import fcntl
import itertools
import json
import os
import shutil
import struct
import subprocess
import sys
import threading
import time
import zipfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
FIXTURES = ROOT / "build" / "fixtures"
APK = ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk"
MONKEY_APK = ROOT / "build" / "matrix" / "apk" / "app-monkey.apk"
CAMERA_IMAGE = ROOT / "build" / "matrix" / "camera" / "qr_a1.png"
BUNDLED = ROOT / "assets" / "test_archive"
SETTINGS = "build_settings.automation.json"

READABLE = {"invented", "anonymized"}
print_lock = threading.Lock()
boot_lock = threading.Lock()


def say(text: str) -> None:
    with print_lock:
        print(text, flush=True)


def load(name: str) -> dict:
    return json.loads((HERE / name).read_text())


def run(cmd, log: Path | None = None, env=None, timeout=None, cwd=ROOT):
    """Runs a command, optionally teeing everything it prints into a file."""
    full_env = {**os.environ, **(env or {})}
    try:
        proc = subprocess.run(
            cmd, cwd=cwd, env=full_env, timeout=timeout,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        )
        out, code = proc.stdout, proc.returncode
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or "") if isinstance(e.stdout, str) else (e.stdout or b"").decode(errors="replace")
        out += f"\nTIMEOUT after {timeout}s\n"
        code = 124
    if log is not None:
        log.parent.mkdir(parents=True, exist_ok=True)
        with log.open("a") as f:
            f.write(out)
    return code, out


# --- planning ---------------------------------------------------------------


def archive_origin(path: Path) -> str:
    try:
        with zipfile.ZipFile(path) as z:
            marker = str(json.loads(z.read("manifest.json")).get("fixture", ""))
    except Exception:
        return "unmarked"
    for origin in ("invented", "anonymized"):
        if marker.startswith(origin):
            return origin
    return "unmarked"


def pairwise(dimensions: list[list]) -> list[tuple]:
    """The fewest combinations in which every pair of values still meets.

    Greedy: repeatedly take the combination that covers the most pairs not
    yet seen. Deterministic, so the same tier always plans the same cells.
    """
    combos = list(itertools.product(*dimensions))
    indexes = list(itertools.combinations(range(len(dimensions)), 2))

    def pairs(combo):
        return {(i, combo[i], j, combo[j]) for i, j in indexes}

    uncovered = set().union(*(pairs(c) for c in combos)) if combos else set()
    chosen = []
    while uncovered:
        best = max(combos, key=lambda c: len(pairs(c) & uncovered))
        chosen.append(best)
        uncovered -= pairs(best)
    return chosen


def expand(tier: dict, shapes: dict, args) -> list[dict]:
    cells = []
    if args.only in (None, "desktop"):
        for group in tier.get("desktop", []):
            usable = [s for s in group["shapes"] if shapes[s].get("desktop", True)]
            for lang, settings in itertools.product(group["langs"], group["settings"]):
                cells.append({
                    "kind": "desktop", "device": "linux", "lang": lang,
                    "settings": settings, "shapes": usable,
                    "flows": args.flows or group["flows"],
                })
    if args.only in (None, "android"):
        for group in tier.get("android", []):
            avds = [a for a in group["avds"] if not args.avd or a in args.avd]
            if not avds:
                continue
            extras = [("journey", j) for j in group.get("journeys", [])]
            extras += [("state", s) for s in group.get("states", [])]
            dims = [avds, group["shapes"], group["langs"], group["settings"]]
            sample = group.get("sample", "cross")
            if sample == "pairwise":
                combos = pairwise(dims)
            elif sample == "rotate":
                combos = [
                    (avd, shape, lang, group["settings"][n % len(group["settings"])])
                    for n, (avd, shape, lang) in enumerate(itertools.product(*dims[:3]))
                ]
            else:
                combos = list(itertools.product(*dims))
            for avd, shape, lang, settings in combos:
                for kind, name in extras or [(None, None)]:
                    cell = {
                        "kind": "android", "device": avd, "lang": lang,
                        "settings": settings, "shapes": [shape],
                        "flows": args.flows or group["flows"],
                        "media": bool(group.get("media")),
                    }
                    if group.get("monkey"):
                        cell["monkey"] = int(group["monkey"])
                        cell["flows"] = ["monkey"]
                    if kind:
                        cell[kind] = name
                    cells.append(cell)
    seen, unique = set(), []
    for cell in cells:
        key = json.dumps(cell, sort_keys=True)
        if key not in seen:
            seen.add(key)
            unique.append(cell)
    for cell in unique:
        parts = [cell["lang"], cell["settings"]]
        parts.append(cell["shapes"][0] if cell["kind"] == "android" else "shapes")
        parts += [cell[k] for k in ("journey", "state") if k in cell]
        if cell["kind"] == "android" and cell.get("media"):
            parts.append("media")
        if "monkey" in cell:
            parts.append("monkey")
        cell["id"] = f"{cell['device']}/{'-'.join(parts)}"
    # The id names the cell's output directory; two cells under one name
    # would write over each other's results.
    taken: dict[str, int] = {}
    for cell in unique:
        n = taken[cell["id"]] = taken.get(cell["id"], 0) + 1
        if n > 1:
            cell["id"] += f"-{n}"
    return unique


# --- building ---------------------------------------------------------------


def bundled_archives_are_safe() -> str | None:
    """The test build bundles whatever sits in assets/test_archive/.

    An archive there that is not marked invented or anonymized would ride
    along inside the APK onto every emulator and into anything the build is
    later uploaded to, so the build is refused rather than made.
    """
    for path in sorted(BUNDLED.glob("*.zip")):
        if archive_origin(path) not in READABLE:
            return str(path.relative_to(ROOT))
    return None


def build(cells: list[dict], run_dir: Path, args) -> dict:
    notes = {}
    log = run_dir / "build.log"
    say("build: fixtures")
    code, _ = run(
        ["flutter", "test", "--no-pub", "tool/android/generate_fixture_archive.dart"],
        log, env={"FIXTURE_VARIANTS_DIR": str(FIXTURES)}, timeout=900,
    )
    if code != 0:
        raise SystemExit(f"the fixture archives could not be built; see {log}")

    if any(c["kind"] == "android" for c in cells):
        # What every emulator's back camera shows, so the live scanner has
        # a label to read.
        code, _ = run(
            ["dart", "run", "tool/android/generate_test_media.dart", "--camera",
             str(CAMERA_IMAGE), "a1"],
            log, timeout=600,
        )
        if code != 0:
            say("  the camera image could not be made; scanner flows will fail")

    if any(c.get("media") for c in cells):
        say("build: media fixtures")
        media = run_dir / "media"
        code, _ = run(
            ["dart", "run", "tool/android/generate_test_media.dart", str(media), "a1", "a2"],
            log, timeout=600,
        )
        if code != 0:
            raise SystemExit(f"the media fixtures could not be built; see {log}")

    if any(c["kind"] == "android" for c in cells) and not args.no_build:
        unsafe = bundled_archives_are_safe()
        if unsafe:
            notes["android"] = (
                f"{unsafe} is not marked invented or anonymized and would be "
                "bundled into the test build; move it out of assets/test_archive/"
            )
            return notes
        if any("monkey" in c for c in cells):
            # Random input needs the app itself, not the test build, whose
            # entry point is the test suite. Built first and set aside,
            # because both builds write the same output file.
            say("build: Android app for the monkey runs")
            code, _ = run(
                ["flutter", "build", "apk", "--debug",
                 "--target-platform", "android-x64",
                 f"--dart-define-from-file={SETTINGS}"],
                log, timeout=3600,
            )
            if code == 0:
                MONKEY_APK.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(APK, MONKEY_APK)
            else:
                notes["monkey"] = f"the plain app did not build; see {log.relative_to(ROOT)}"
        say("build: Android test app")
        # Never --no-pub for an APK: `pub get` is what rewrites the plugin
        # registrant, and a release build leaves one behind without the
        # test-only integration_test plugin. A test build that reuses it has
        # no screenshots and crashes its renderer on the next launch.
        # x86_64 only: it is what every emulator here runs, and it leaves
        # out two thirds of a build that would otherwise be installed on
        # each of them.
        code, _ = run(
            ["flutter", "build", "apk", "--debug",
             "--target-platform", "android-x64",
             "--target", "integration_test/suite_test.dart",
             f"--dart-define-from-file={SETTINGS}"],
            log, timeout=3600,
        )
        if code != 0:
            notes["android"] = f"the Android test app did not build; see {log.relative_to(ROOT)}"
    return notes


# --- desktop cells ----------------------------------------------------------


def known_issues() -> list:
    return load("known_issues.json").get("issues", [])


def flutter_fonts() -> str:
    flutter = shutil.which("flutter") or ""
    return str(Path(flutter).resolve().parents[1] / "bin/cache/artifacts/material_fonts")


def run_desktop(cell: dict, out: Path, shapes: dict, args) -> dict:
    archive = FIXTURES / f"{cell['settings']}-{cell['lang']}.zip"
    if args.archive:
        archive = Path(args.archive)
    origin = archive_origin(archive)
    sandbox = out / ".sandbox"
    docs = sandbox / "documents"
    for sub in ("config", "data", "cache", "documents"):
        (sandbox / sub).mkdir(parents=True, exist_ok=True)
    # The app keeps its data in the user's Documents folder on Linux. A
    # private one per cell keeps runs apart and keeps them out of the real
    # home directory.
    (sandbox / "config" / "user-dirs.dirs").write_text(
        f'XDG_DOCUMENTS_DIR="{docs}"\nXDG_DOWNLOAD_DIR="{docs}"\n'
    )
    with zipfile.ZipFile(archive) as z:
        for member in z.namelist():
            if member not in ("manifest.json", "ftp_credentials.json"):
                z.extract(member, docs)
    (out / ".data-origin").write_text(origin + "\n")
    spec = {
        "flows": cell["flows"],
        "shapes": [
            {"name": name, **{k: v for k, v in shapes[name].items() if k != "android"}}
            for name in cell["shapes"]
        ],
        "language": cell["lang"], "settings": cell["settings"], "theme": "light",
        "device": "linux", "data_origin": origin,
        "out_dir": str(out), "fonts_dir": flutter_fonts(),
        "known_issues": known_issues(),
    }
    (docs / "matrix_cell.json").write_text(json.dumps(spec, indent=1))
    (out / "cell.json").write_text(json.dumps(spec, indent=1))
    env = {
        "XDG_CONFIG_HOME": str(sandbox / "config"),
        "XDG_DATA_HOME": str(sandbox / "data"),
        "XDG_CACHE_HOME": str(sandbox / "cache"),
        "CI": "true",
    }
    code, _ = run(
        ["xvfb-run", "-a", "-s", "-screen 0 1600x1400x24",
         "flutter", "test", "integration_test/suite_test.dart", "-d", "linux",
         "--no-pub", f"--dart-define-from-file={SETTINGS}"],
        out / "drive.log", env=env, timeout=args.cell_timeout,
    )
    shutil.rmtree(sandbox, ignore_errors=True)
    return {"exit": code, "status": "passed" if code == 0 else "failed"}


# --- android cells ----------------------------------------------------------


def avd_tool(*argv, timeout=600):
    return run([str(ROOT / "tool/android/avd.sh"), *argv], timeout=timeout)


def boot_failure(avd: str) -> str:
    """The emulator's own reason for not starting, when it gave one."""
    log = Path(os.environ.get("TMPDIR", "/tmp")) / f"emulator-{avd}.log"
    try:
        fatal = [l for l in log.read_text(errors="replace").splitlines() if "FATAL" in l]
    except OSError:
        return ""
    return fatal[-1].split("|", 1)[-1].strip() if fatal else ""


def boot(avd: str) -> str | None:
    # One at a time: emulators that start in the same second can each be
    # told there is no hardware acceleration.
    with boot_lock:
        extra = ["--camera", str(CAMERA_IMAGE)] if CAMERA_IMAGE.exists() else []
        code, out = avd_tool("boot", avd, "--headless", "--pristine", *extra, timeout=420)
        time.sleep(3)
    if code != 0:
        say(f"  {avd}: did not boot — {out.strip().splitlines()[-1] if out.strip() else 'no output'}")
        return None
    return out.strip().splitlines()[-1]


def run_android_cell(cell: dict, serial: str, out: Path, run_dir: Path, args) -> dict:
    cmd = [
        str(ROOT / "tool/android/run_cell.sh"), "--serial", serial,
        "--flows", ",".join(cell["flows"]), "--shape", cell["shapes"][0],
        "--lang", cell["lang"], "--settings", cell["settings"],
        "--out", str(out), "--timeout", str(args.cell_timeout),
    ]
    if args.archive:
        cmd += ["--archive", args.archive]
    if cell.get("media"):
        cmd += ["--media", str(run_dir / "media")]
    for key in ("journey", "state"):
        if key in cell:
            cmd += [f"--{key}", cell[key]]
    if "monkey" in cell:
        cmd += ["--monkey", str(cell["monkey"]), "--apk", str(MONKEY_APK)]
    code, text = run(cmd, out / "cell.log", timeout=args.cell_timeout + 600)
    last = text.strip().splitlines()[-1] if text.strip() else ""
    status = last.split("=", 1)[1] if last.startswith("CELL=") else "setup-error"
    return {"exit": code, "status": status}


def android_worker(avd: str, cells: list[dict], run_dir: Path, args, results: dict):
    existing = avd_tool("list", "matrix")[1].split()
    if avd not in existing:
        for cell in cells:
            results[cell["id"]] = {
                "status": "not-run",
                "reason": f"{avd} does not exist; create it with: tool/android/avd.sh prepare {avd}",
            }
        say(f"  {avd}: NOT RUN — the AVD does not exist")
        return
    serial = boot(avd)
    for cell in cells:
        out = run_dir / cell["id"]
        started = time.time()
        if serial is None:
            why = boot_failure(avd)
            results[cell["id"]] = {"status": "not-run",
                                   "reason": f"{avd} did not boot" + (f": {why}" if why else "")}
            continue
        outcome = run_android_cell(cell, serial, out, run_dir, args)
        retried = False
        if outcome["status"] in ("failed", "setup-error") and not args.no_retry:
            # A failure on a fresh device is a finding; a failure that goes
            # away on a fresh device is flakiness, and saying which it was
            # is worth one more boot.
            say(f"  {cell['id']}: {outcome['status']}, retrying on a fresh boot")
            first = out.with_name(out.name + ".first-attempt")
            shutil.rmtree(first, ignore_errors=True)
            out.rename(first)
            avd_tool("stop", serial)
            serial = boot(avd)
            if serial is not None:
                outcome = run_android_cell(cell, serial, out, run_dir, args)
                retried = True
        outcome["seconds"] = round(time.time() - started)
        if retried and outcome["status"] == "passed":
            outcome["flaky"] = True
        results[cell["id"]] = outcome
        say(f"  {cell['id']}: {outcome['status']}{' (flaky)' if outcome.get('flaky') else ''} in {outcome['seconds']}s")
    if serial is not None and not args.keep_emulators:
        avd_tool("stop", serial)


# --- report -----------------------------------------------------------------


def png_size(path: Path) -> tuple[int, int] | None:
    try:
        with path.open("rb") as f:
            head = f.read(24)
        return struct.unpack(">II", head[16:24])
    except Exception:
        return None


def visual_tokens(width: int, height: int, long_edge: int | None = None) -> int:
    """What an image costs a current Claude model to look at.

    One token per 28-pixel square, on an image scaled down to at most 2576
    pixels on its long edge and 4784 tokens. Passing `long_edge` asks what
    it would cost after being resized to that first.
    """
    def cost(w, h):
        return -(-w // 28) * -(-h // 28)

    limit = min(long_edge or 2576, 2576)
    scale = min(1.0, limit / max(width, height))
    w, h = max(1, round(width * scale)), max(1, round(height * scale))
    while cost(w, h) > 4784:
        w, h = round(w * 0.98), round(h * 0.98)
    return cost(w, h)


def collect(run_dir: Path, cells: list[dict], results: dict) -> dict:
    report = {"cells": [], "screens": {}, "failures": [], "not_run": [], "shots": 0,
              "tokens_native": 0, "tokens_reduced": 0, "unreadable_dirs": []}
    for cell in cells:
        out = run_dir / cell["id"]
        outcome = dict(results.get(cell["id"], {"status": "not-run", "reason": "never started"}))
        origin = (out / ".data-origin").read_text().strip() if (out / ".data-origin").exists() else "unknown"
        data = {}
        if (out / "result.json").exists():
            try:
                data = json.loads((out / "result.json").read_text())
            except Exception:
                data = {}
        flows = data.get("flows", [])
        screens = data.get("screens", [])
        row = {
            "id": cell["id"], "kind": cell["kind"], "device": cell["device"],
            "lang": cell["lang"], "settings": cell["settings"],
            "shapes": cell["shapes"], "origin": origin, **outcome,
            "flows": {s: sum(1 for f in flows if f.get("status") == s)
                      for s in ("passed", "failed", "skipped", "known")},
            "screens": {s: sum(1 for x in screens if x.get("status") == s)
                        for s in ("ok", "busy", "error", "timeout", "skipped", "network", "known")},
            "startup_ms": data.get("startup_ms"),
        }
        report["cells"].append(row)
        if outcome["status"] == "not-run":
            report["not_run"].append({"id": cell["id"], "reason": outcome.get("reason", "")})
        foreign = out / "foreign_windows.log"
        if foreign.exists():
            for line in foreign.read_text().splitlines()[:10]:
                report.setdefault("notes", []).append(
                    f"`{cell['id']}` · another app's window took focus and was dismissed: {line}")
        for flow, texts in (data.get("notes") or {}).items():
            for text in texts:
                report.setdefault("notes", []).append(f"`{cell['id']}` · {flow}: {text}")
        for f in flows:
            if f.get("status") == "failed":
                report["failures"].append({"cell": cell["id"], "flow": f.get("name"),
                                           "detail": f.get("detail", "")})
            if f.get("status") == "known":
                report["screens"].setdefault(
                    f"flow {f.get('name')}",
                    {"area": "", "runs": 0, "errors": [], "known": [], "truncated": set()},
                )["known"].append({"cell": cell["id"], "shape": "–",
                                   "error": f.get("detail", "")})
        if outcome["status"] in ("failed", "setup-error") and not any(
            f.get("status") == "failed" for f in flows
        ):
            report["failures"].append({
                "cell": cell["id"], "flow": "(the run itself)",
                "detail": f"{outcome['status']}; see {(out / 'drive.log').relative_to(ROOT)}",
            })
        for s in screens:
            entry = report["screens"].setdefault(
                s["id"], {"area": s.get("area", ""), "runs": 0, "errors": [], "known": [],
                          "truncated": set()})
            if s.get("status") == "known":
                entry["known"].append({"cell": cell["id"], "shape": s.get("shape"),
                                       "error": s.get("error", "")})
            if s.get("status") != "skipped":
                entry["runs"] += 1
            if s.get("status") in ("error", "timeout"):
                entry["errors"].append({
                    "cell": cell["id"], "shape": s.get("shape"),
                    "best_effort": bool(s.get("best_effort")), "error": s.get("error", ""),
                })
            for finding in s.get("findings", []):
                kind = finding.get("kind")
                if kind == "truncated_text":
                    entry["truncated"].add(f"{cell['lang']}/{s.get('shape')}")
                elif "count" in finding:
                    # Worst shape per screen: the same control counted once
                    # per shape would only measure how many shapes ran.
                    a11y = entry.setdefault("a11y", {})
                    a11y[kind] = max(a11y.get(kind, 0), finding["count"])
        if origin not in READABLE and out.exists():
            report["unreadable_dirs"].append(str(out.relative_to(ROOT)))
        for png in out.glob("*.png") if out.exists() else []:
            size = png_size(png)
            if not size:
                continue
            report["shots"] += 1
            report["tokens_native"] += visual_tokens(*size)
            report["tokens_reduced"] += visual_tokens(*size, long_edge=1280)
    for entry in report["screens"].values():
        entry["truncated"] = sorted(entry["truncated"])
    totals = {}
    for entry in report["screens"].values():
        for kind, count in entry.get("a11y", {}).items():
            totals[kind] = totals.get(kind, 0) + count
    report["a11y_totals"] = totals
    return report


def write_report(run_dir: Path, tier: str, about: str, report: dict, notes: dict, seconds: int) -> int:
    cells = report["cells"]
    failed = [c for c in cells if c["status"] in ("failed", "setup-error")]
    passed = [c for c in cells if c["status"] == "passed"]
    unsupported = [c for c in cells if c["status"] == "unsupported"]
    flaky = [c for c in cells if c.get("flaky")]
    hard = [f for f in report["failures"]]
    verdict = "FAILED" if failed or hard else ("INCOMPLETE" if report["not_run"] else "PASSED")
    code = {"PASSED": 0, "FAILED": 1, "INCOMPLETE": 2}[verdict]

    lines = [
        f"# Test matrix — {tier}: {verdict}", "",
        f"{about}", "",
        f"Run `{run_dir.name}`, {seconds // 60} min {seconds % 60} s. "
        f"{len(passed)} cell(s) passed, {len(failed)} failed, "
        f"{len(report['not_run'])} not run, {len(unsupported)} not applicable to their device"
        + (f", {len(flaky)} passed only on a second attempt" if flaky else "") + ".", "",
    ]
    for kind, note in notes.items():
        lines += [f"**{kind} half not run:** {note}", ""]
    if report["unreadable_dirs"]:
        lines += [
            "**Some output shows data that is not marked invented or anonymized.** "
            "An agent must not read the screenshots, semantics dumps or logs in:", "",
            *[f"- `{d}`" for d in report["unreadable_dirs"]], "",
        ]
    if report["not_run"]:
        lines += ["## Not run", "", "A cell that did not run did not pass.", ""]
        lines += [f"- `{n['id']}` — {n['reason']}" for n in report["not_run"]] + [""]
    if hard:
        lines += ["## Failures", ""]
        for f in hard:
            detail = " ".join(str(f["detail"]).split())
            lines.append(f"- `{f['cell']}` · **{f['flow']}** — {detail[:700]}")
        lines.append("")
    broken = {k: v for k, v in report["screens"].items() if v["errors"]}
    if broken:
        lines += ["## Screens that failed to open or lay out", "",
                  "| Screen | Where | What |", "|---|---|---|"]
        for name, entry in sorted(broken.items()):
            for e in entry["errors"]:
                what = " ".join(e["error"].split())[:300].replace("|", "\\|")
                where = f"{e['cell']} @ {e['shape']}" + (" (best effort)" if e["best_effort"] else "")
                lines.append(f"| `{name}` | {where} | {what} |")
        lines.append("")
    known = {k: v for k, v in report["screens"].items() if v.get("known")}
    if known:
        lines += ["## Known issues still present", "",
                  "Listed in tool/matrix/known_issues.json and so not failing this run. "
                  "Remove an entry when its bug is fixed.", "",
                  "| Screen or flow | Where | Why it is known |", "|---|---|---|"]
        for name, entry in sorted(known.items()):
            for k in entry["known"]:
                why = k["error"].split("| known: ", 1)[-1][:240].replace("|", "\\|")
                lines.append(f"| `{name}` | {k['cell']} @ {k['shape']} | {why} |")
        lines.append("")
    truncated = {k: v for k, v in report["screens"].items() if v["truncated"]}
    if truncated:
        lines += ["## Text that was cut off", "",
                  "Not failures. Each is a place where a label did not fit and was "
                  "shortened; worth a look where it is a title or a value.", "",
                  "| Screen | Language / shape |", "|---|---|"]
        for name, entry in sorted(truncated.items()):
            lines.append(f"| `{name}` | {', '.join(entry['truncated'])} |")
        lines.append("")
    a11y = {k: v for k, v in report["screens"].items() if v.get("a11y")}
    if a11y:
        kinds = ["tap_target", "unlabeled_tap_target", "text_contrast"]
        names = {"tap_target": "under 48 dp", "unlabeled_tap_target": "no label",
                 "text_contrast": "low contrast"}
        totals = report["a11y_totals"]
        lines += ["## Accessibility", "",
                  "Flutter's own guidelines, per screen in its worst shape. Findings, not "
                  "failures: the count is the thing to watch, and it should only go down. "
                  "Totals: " + ", ".join(f"{totals.get(k, 0)} {names[k]}" for k in kinds) + ".", "",
                  "| Screen | " + " | ".join(names[k] for k in kinds) + " |",
                  "|---|" + "---|" * len(kinds)]
        for name, entry in sorted(a11y.items(), key=lambda kv: -sum(kv[1]["a11y"].values())):
            lines.append(f"| `{name}` | " + " | ".join(str(entry["a11y"].get(k, 0)) for k in kinds) + " |")
        lines.append("")
    if report.get("notes"):
        lines += ["## Notes from the flows", ""] + [f"- {n}" for n in report["notes"]] + [""]
    lines += ["## Cells", "",
              "| Cell | Result | Time | App start | Flows passed / failed / skipped | Screens ok / busy / failed / skipped |",
              "|---|---|---|---|---|---|"]
    for c in cells:
        f, s = c["flows"], c["screens"]
        result = c["status"] + (" (flaky)" if c.get("flaky") else "")
        lines.append(
            f"| `{c['id']}` | {result} | {c.get('seconds', '–')} s | "
            f"{(str(c['startup_ms']) + ' ms') if c.get('startup_ms') else '–'} | "
            f"{f['passed']} / {f['failed']} / {f['skipped']} | "
            f"{s['ok']} / {s['busy']} / {s['error'] + s['timeout']} / {s['skipped']} |")
    lines += ["", "## Reading the screenshots", "",
              f"{report['shots']} screenshot(s). Having an agent look at every one would cost about "
              f"{report['tokens_native']:,} input tokens at full size, or "
              f"{report['tokens_reduced']:,} resized to 1280 pixels on the long edge — "
              "before whatever it writes back. `tool/matrix/review.py` picks the ones "
              "worth looking at instead of all of them.", "",
              "## Reproducing a cell", "",
              "Each cell's folder holds `cell.json`, the log of its run and its "
              "screenshots. To run one again on a booted emulator:", "",
              "```", "tool/android/run_cell.sh --serial <serial> --flows <a,b> "
              "--shape <shape> --lang <ro|en> --settings <profile>", "```", ""]
    (run_dir / "report.md").write_text("\n".join(lines))
    (run_dir / "report.json").write_text(json.dumps(
        {"tier": tier, "verdict": verdict, "seconds": seconds, "notes": notes, **report}, indent=1))
    say("")
    say("\n".join(lines[:8]).strip())
    say(f"report: {(run_dir / 'report.md').relative_to(ROOT)}")
    return code


# --- commands ---------------------------------------------------------------


def resolve_tier(name: str, config: dict) -> tuple[str, dict]:
    name = config["aliases"].get(name, name)
    if name not in config["tiers"]:
        raise SystemExit(f"no such tier: {name} (have: {', '.join(config['tiers'])})")
    return name, config["tiers"][name]


def cmd_plan(args) -> int:
    tier_name, tier = resolve_tier(args.tier, load("tiers.json"))
    cells = expand(tier, load("shapes.json")["shapes"], args)
    for cell in cells:
        extra = " ".join(f"{k}={cell[k]}" for k in ("journey", "state") if k in cell)
        print(f"{cell['id']:<62} {','.join(cell['shapes']):<40} {','.join(cell['flows'])} {extra}")
    desktop = sum(1 for c in cells if c["kind"] == "desktop")
    print(f"\n{tier_name}: {len(cells)} cell(s) — {desktop} on the desktop build, "
          f"{len(cells) - desktop} on {len({c['device'] for c in cells if c['kind'] == 'android'})} emulator(s)")
    return 0


def take_run_lock():
    """One run at a time: runs share the fixture archives they rebuild, the
    emulators they boot and the `latest` link. A second run waits for none
    of that to be safe — it stops and says who holds the lock."""
    path = ROOT / "build" / "matrix" / ".lock"
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = path.open("a+")
    try:
        fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        handle.seek(0)
        holder = handle.read().strip() or "another process"
        raise SystemExit(f"another matrix run is in progress ({holder}); wait for it to finish")
    handle.seek(0)
    handle.truncate()
    handle.write(f"pid {os.getpid()}, started {dt.datetime.now():%H:%M}")
    handle.flush()
    return handle


def cmd_run(args) -> int:
    lock = take_run_lock()  # noqa: F841 — held until the process exits
    tier_name, tier = resolve_tier(args.tier, load("tiers.json"))
    shapes = load("shapes.json")["shapes"]
    cells = expand(tier, shapes, args)
    if not cells:
        raise SystemExit("nothing to run with those filters")
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    run_dir = ROOT / "build" / "matrix" / f"{stamp}-{tier_name}"
    run_dir.mkdir(parents=True)
    latest = run_dir.parent / "latest"
    if latest.is_symlink() or latest.exists():
        latest.unlink()
    latest.symlink_to(run_dir.name)
    started = time.time()
    say(f"{tier_name}: {len(cells)} cell(s) -> {run_dir.relative_to(ROOT)}")
    free_gb = shutil.disk_usage(ROOT).free // 2**30
    if free_gb < 15 and any(c["kind"] == "android" for c in cells):
        # Each running emulator needs scratch space, and the emulator
        # refuses to start below its own threshold — mid-run, as "did not
        # boot".
        say(f"WARNING: only {free_gb} GB free; emulators may refuse to start")

    notes = build(cells, run_dir, args)
    results: dict = {}

    android = {}
    for cell in cells:
        if cell["kind"] == "android":
            android.setdefault(cell["device"], []).append(cell)
    if "android" in notes:
        for device_cells in android.values():
            for cell in device_cells:
                results[cell["id"]] = {"status": "not-run", "reason": notes["android"]}
        android = {}

    pool = ThreadPoolExecutor(max_workers=max(1, args.parallel))
    futures = [pool.submit(android_worker, avd, group, run_dir, args, results)
               for avd, group in android.items()]

    # The desktop cells run here while the emulators work: they share the
    # machine but not a device, and there is only one Linux build to share
    # between them, so they go one after another.
    for cell in (c for c in cells if c["kind"] == "desktop"):
        out = run_dir / cell["id"]
        out.mkdir(parents=True, exist_ok=True)
        cell_started = time.time()
        outcome = run_desktop(cell, out, shapes, args)
        outcome["seconds"] = round(time.time() - cell_started)
        results[cell["id"]] = outcome
        say(f"  {cell['id']}: {outcome['status']} in {outcome['seconds']}s")

    for future in futures:
        future.result()
    pool.shutdown()

    report = collect(run_dir, cells, results)
    return write_report(run_dir, tier_name, tier.get("about", ""), report, notes,
                        round(time.time() - started))


def cmd_report(args) -> int:
    run_dir = Path(args.run_dir).resolve()
    old = json.loads((run_dir / "report.json").read_text())
    print((run_dir / "report.md").read_text())
    return {"PASSED": 0, "FAILED": 1, "INCOMPLETE": 2}[old["verdict"]]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)

    def common(p):
        p.add_argument("--tier", required=True)
        p.add_argument("--only", choices=["desktop", "android"])
        p.add_argument("--avd", action="append", help="limit to this emulator (repeatable)")
        p.add_argument("--flows", type=lambda v: [f for f in v.split(",") if f],
                       help="run these flows in every cell instead of the tier's own")

    plan = sub.add_parser("plan", help="list the cells a tier would run")
    common(plan)
    plan.set_defaults(func=cmd_plan)

    runp = sub.add_parser("run", help="run a tier")
    common(runp)
    runp.add_argument("--parallel", type=int, default=3,
                      help="emulators running at once (default 3)")
    runp.add_argument("--cell-timeout", type=int, default=2400)
    runp.add_argument("--archive", help="seed every cell from this archive instead of the fixture")
    runp.add_argument("--no-build", action="store_true", help="reuse the Android test app already built")
    runp.add_argument("--no-retry", action="store_true")
    runp.add_argument("--keep-emulators", action="store_true")
    runp.set_defaults(func=cmd_run)

    rep = sub.add_parser("report", help="print a finished run's report")
    rep.add_argument("run_dir")
    rep.set_defaults(func=cmd_report)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
