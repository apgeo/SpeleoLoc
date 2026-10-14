#!/usr/bin/env bash
# Run one cell of the test matrix on one device: one shape, one language,
# one settings profile, a chosen set of flows.
#
# This is the unit the matrix runner repeats, and it is also the way to
# reproduce a single failing cell by hand — the report prints the exact
# command.
#
# Usage:
#   tool/android/run_cell.sh --serial emulator-5554 [options]
#
#   --flows a,b        flows to run (default: all). See integration_test/.
#   --shape NAME       a shape from tool/matrix/shapes.json (default: native)
#   --lang ro|en       language (default: ro)
#   --settings NAME    settings profile (default: default)
#   --archive ZIP      data to seed; default is the fixture variant for the
#                      language and settings above
#   --journey NAME     a permission journey (see tool/android/permissions.sh)
#   --state NAME       a platform state (see tool/android/platform_state.sh)
#   --media DIR        photos to put in the device library first
#   --apk FILE         the test build (default: the debug APK in build/)
#   --out DIR          where results go (default: build/matrix/manual/<serial>)
#   --timeout SECONDS  hard limit for the drive (default: 2400)
#   --monkey EVENTS    instead of the flows, send this many random taps,
#                      swipes and keys to the app (needs --apk pointing at
#                      the plain app build, not the test build) and fail on
#                      a crash or an ANR
#
# Exit code: 0 passed, 1 a flow failed, 2 the cell could not be set up,
# 3 this device cannot represent the cell (e.g. dark mode on API 24).
# The last line printed is `CELL=<passed|failed|setup-error|unsupported>`.
set -uo pipefail

cd "$(dirname "$0")/../.."
. tool/android/lib.sh

SERIAL_ARG="" FLOWS="" SHAPE=native LANG_CODE=ro SETTINGS=default ARCHIVE=""
JOURNEY="" STATE="" MEDIA="" OUT="" TIMEOUT=2400 MONKEY=0
APK=build/app/outputs/flutter-apk/app-debug.apk
while [ "$#" -gt 0 ]; do
  case "$1" in
    --serial) SERIAL_ARG="$2"; shift ;;
    --flows) FLOWS="$2"; shift ;;
    --shape) SHAPE="$2"; shift ;;
    --lang) LANG_CODE="$2"; shift ;;
    --settings) SETTINGS="$2"; shift ;;
    --archive) ARCHIVE="$2"; shift ;;
    --journey) JOURNEY="$2"; shift ;;
    --state) STATE="$2"; shift ;;
    --media) MEDIA="$2"; shift ;;
    --apk) APK="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    --timeout) TIMEOUT="$2"; shift ;;
    --monkey) MONKEY="$2"; shift ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
  shift
done

finish() { # status exit-code
  echo "CELL=$1"
  exit "$2"
}
setup_error() {
  echo "SETUP ERROR: $*" >&2
  finish setup-error 2
}

use_serial "$SERIAL_ARG"
[ -n "$OUT" ] || OUT="build/matrix/manual/$SERIAL"
[ -n "$ARCHIVE" ] || ARCHIVE="build/fixtures/$SETTINGS-$LANG_CODE.zip"
[ -f "$ARCHIVE" ] || setup_error "no archive at $ARCHIVE (build the variants with: FIXTURE_VARIANTS_DIR=build/fixtures flutter test tool/android/generate_fixture_archive.dart)"
[ -f "$APK" ] || setup_error "no test build at $APK (tool/test_matrix.sh builds it)"
mkdir -p "$OUT"
export SPELEO_OUT_DIR="$OUT"

# --- shape ------------------------------------------------------------------
tool/android/device_profile.sh "$SHAPE" "$SERIAL" > "$OUT/setup.log" 2>&1 \
  || setup_error "could not apply shape $SHAPE; see $OUT/setup.log"
if grep -q '^unsupported:' "$OUT/setup.log"; then
  grep '^unsupported:' "$OUT/setup.log"
  tool/android/device_profile.sh reset "$SERIAL" >/dev/null 2>&1
  finish unsupported 3
fi

# --- app and data -----------------------------------------------------------
# Reinstalling is the slowest step of a cell and the build is the same for
# every cell of a run, so it is skipped when the device already holds this
# exact file.
apk_sha="$(sha1sum "$APK" | cut -d' ' -f1)"
if [ -z "$(adb_sh pm path "$PKG")" ] \
  || [ "$(adb_sh cat /data/local/tmp/speleo_apk.sha1)" != "$apk_sha" ]; then
  adb_s install -r "$APK" >> "$OUT/setup.log" 2>&1 \
    || setup_error "install failed; see $OUT/setup.log"
  adb_sh "echo $apk_sha > /data/local/tmp/speleo_apk.sha1"
fi

tool/android/seed_app_data.sh "$ARCHIVE" "$SERIAL" >> "$OUT/setup.log" 2>&1 \
  || setup_error "seeding failed; see $OUT/setup.log"
ORIGIN="$(cat "$OUT/.data-origin")"

if [ -n "$MEDIA" ]; then
  tool/android/seed_test_media.sh "$MEDIA" "$SERIAL" >> "$OUT/setup.log" 2>&1 \
    || setup_error "media seeding failed; see $OUT/setup.log"
fi
if [ -n "$JOURNEY" ]; then
  tool/android/permissions.sh journey "$JOURNEY" "$SERIAL" >> "$OUT/setup.log" 2>&1
  if tail -1 "$OUT/setup.log" | grep -q '^unsupported:'; then
    tail -1 "$OUT/setup.log"
    tool/android/device_profile.sh reset "$SERIAL" >/dev/null 2>&1
    finish unsupported 3
  fi
fi
if [ -n "$STATE" ]; then
  tool/android/platform_state.sh "$STATE" "$SERIAL" >> "$OUT/setup.log" 2>&1 \
    || setup_error "could not apply state $STATE; see $OUT/setup.log"
fi

# --- tell the app which cell this is ----------------------------------------
DEVICE="$(adb_s emu avd name 2>/dev/null | head -1 | tr -d '\r')"
[ -n "$DEVICE" ] || DEVICE="$SERIAL"
python3 - "$OUT/cell.json" <<PY
import json, sys
flows = [f for f in "$FLOWS".split(",") if f]
json.dump({
    "flows": flows,
    "shapes": [{"name": "$SHAPE"}],
    "language": "$LANG_CODE",
    "settings": "$SETTINGS",
    "theme": "light",
    "device": "$DEVICE",
    "api": "$(device_api)",
    "data_origin": "$ORIGIN",
    "journey": "$JOURNEY",
    "state": "$STATE",
    "known_issues": json.load(open("tool/matrix/known_issues.json")).get("issues", []),
}, open(sys.argv[1], "w"), indent=1)
PY
adb_s push "$OUT/cell.json" /data/local/tmp/matrix_cell.json >/dev/null
adb_s shell "run-as $PKG cp /data/local/tmp/matrix_cell.json app_flutter/matrix_cell.json" \
  || setup_error "could not hand the cell to the app"

# --- monkey -----------------------------------------------------------------
# Random input finds what no scripted flow thinks of doing: a back press in
# the middle of a save, three dialogs opened on top of each other. The seed
# is fixed per cell so a crash can be replayed with the same events.
if [ "$MONKEY" -gt 0 ]; then
  adb_s logcat -c >/dev/null 2>&1 || true
  # Start the app and let it reach its first screen before any input: a
  # debug build on a software-rendered emulator takes longer than the five
  # seconds Android allows a window to appear, and taps sent before that
  # are reported as the app not responding — a finding about the test,
  # not the app.
  adb_sh am start -W -n "$PKG/.MainActivity" >/dev/null
  sleep 15
  seed="$(printf '%s' "$DEVICE$SHAPE$LANG_CODE" | cksum | cut -d' ' -f1)"
  # Android always lets the home screen start, so some of the input lands
  # on the launcher, and the Google launcher crashes under it. Only the
  # app's own crashes and ANRs count; monkey is told to carry on past
  # anyone's, so one launcher crash does not end the run early, and the
  # others are reported beside the result.
  timeout "$TIMEOUT" "$ADB" -s "$SERIAL" shell monkey -p "$PKG" \
    --pct-syskeys 0 --pct-appswitch 0 --ignore-security-exceptions \
    --ignore-crashes --ignore-timeouts \
    --monitor-native-crashes --throttle 150 -s "$seed" -v "$MONKEY" \
    > "$OUT/monkey.log" 2>&1
  adb_s logcat -d -v time 2>/dev/null \
    | grep -E " E/flutter|FATAL EXCEPTION|ANR in $PKG|Fatal signal|E/AndroidRuntime" \
    > "$OUT/logcat.txt" || true
  adb_sh am force-stop "$PKG"
  tool/android/device_profile.sh reset "$SERIAL" >/dev/null 2>&1
  problem="$(grep -m1 -E "// (CRASH|NOT RESPONDING): $PKG " "$OUT/monkey.log" || true)"
  [ -z "$problem" ] && problem="$(grep -m1 -E "ANR in $PKG|Process: $PKG," "$OUT/logcat.txt" || true)"
  others="$(grep -E '// (CRASH|NOT RESPONDING): ' "$OUT/monkey.log" | grep -vF ": $PKG " \
    | sed -E 's#.*// (CRASH|NOT RESPONDING): ([^ ]+).*#\2#' | sort -u | paste -sd, || true)"
  sent="$(grep -oE 'Events injected: [0-9]+' "$OUT/monkey.log" | grep -oE '[0-9]+' || echo 0)"
  python3 - "$OUT/result.json" "$problem" "$sent" "$seed" "$others" <<'RESULT'
import json, sys
out, problem, sent, seed, others = sys.argv[1:]
detail = problem or f"{sent} events, seed {seed}, no crash and no ANR"
if others:
    detail += f"; under the same input these crashed or hung, not counted: {others}"
json.dump({"flows": [{
    "name": "monkey",
    "status": "failed" if problem else "passed",
    "detail": detail,
}]}, open(out, "w"), indent=1)
RESULT
  [ -z "$problem" ] && finish passed 0
  echo "$problem" >&2
  finish failed 1
fi

# --- drive ------------------------------------------------------------------
adb_s logcat -c >/dev/null 2>&1 || true

# Another app's window over ours — a Google location-accuracy prompt, a
# system camera, a permission dialog — waits for a person, and every screen
# after it is driven behind it. The watcher presses Back on any focused
# window that is not the app's, the launcher's or the system bar's, and
# writes down what it dismissed, so the report can say what interrupted.
foreign_window_watcher() {
  local focus
  while true; do
    focus="$(adb_sh dumpsys window 2>/dev/null | sed -nE 's/.*mCurrentFocus=Window\{[^ ]+ [^ ]+ ([^ }]+).*/\1/p' | head -1)"
    case "$focus" in
      ""|"$PKG"*|*launcher*|*Launcher*|StatusBar|NotificationShade|*systemui*) ;;
      *)
        echo "$(date +%H:%M:%S) $focus" >> "$OUT/foreign_windows.log"
        adb_sh input keyevent 4 ;;
    esac
    sleep 3
  done
}
foreign_window_watcher &
watcher=$!

# Beacons for the app's own detection to find: the fixture's iBeacon and
# Ruuvi tag, advertised into the emulated radio while the drive runs. Every
# emulator on the machine hears them; a cell without this flow never turns
# detection on, so to it they are two more advertisers in the room.
beacons=""
case ",$FLOWS," in
  *,beacon_detect,*|,,)
    dart run tool/android/netsim_beacons.dart > "$OUT/beacons.log" 2>&1 &
    beacons=$! ;;
esac

# --keep-app-running leaves the build installed, so the next cell on this
# device skips the install; the data is replaced by its own seeding step.
timeout --signal=INT --kill-after=30 "$TIMEOUT" flutter drive \
  -d "$SERIAL" --no-pub \
  --use-application-binary "$APK" \
  --driver test_driver/integration_test.dart \
  --target integration_test/suite_test.dart \
  --keep-app-running > "$OUT/drive.log" 2>&1
code=$?
kill "$watcher" $beacons 2>/dev/null
wait "$watcher" $beacons 2>/dev/null

# What the device itself complained about during the run. Under invented
# or anonymized data this is safe to read; otherwise the directory's
# data-origin marker says it is not.
adb_s logcat -d -v time 2>/dev/null \
  | grep -E " E/flutter|FATAL EXCEPTION|ANR in $PKG|Fatal signal|E AndroidRuntime" \
  > "$OUT/logcat.txt" || true

adb_sh am force-stop "$PKG"
[ -n "$STATE" ] && tool/android/platform_state.sh reset "$SERIAL" >/dev/null 2>&1
tool/android/device_profile.sh reset "$SERIAL" >/dev/null 2>&1

if [ "$code" -eq 124 ] || [ "$code" -eq 137 ]; then
  echo "the drive did not finish within ${TIMEOUT}s" >> "$OUT/drive.log"
fi
if [ "$code" -eq 0 ]; then
  finish passed 0
fi
tail -5 "$OUT/drive.log" >&2
finish failed 1
