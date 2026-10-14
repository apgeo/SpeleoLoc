#!/usr/bin/env bash
# Install the previous release, start it, then update it in place to the
# new one and start that: the path every existing user takes, and the one
# where a database migration or a renamed asset breaks first.
#
# Release builds are kept per version by tool/matrix/release_gates.sh in
# build_archive/apk/<version>/app-release.apk. This takes the newest one
# older than the build under test. Both must be signed with the same key,
# or Android refuses the update — which is itself worth knowing.
#
# Usage:
#   tool/android/upgrade_check.sh [--serial S] [--new APK]
#
# Exit code 0 passed, 1 the new version crashed or did not start, 2 NOT RUN
# (no previous release kept yet). The device's copy of the app is
# uninstalled first; use a matrix emulator, never a phone with data on it.
set -euo pipefail

cd "$(dirname "$0")/../.."
. tool/android/lib.sh

SERIAL_ARG="" NEW=build/app/outputs/flutter-apk/app-release.apk
while [ "$#" -gt 0 ]; do
  case "$1" in
    --serial) SERIAL_ARG="$2"; shift ;;
    --new) NEW="$2"; shift ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

current="$(sed -nE 's/^version: *([^ ]+).*/\1/p' pubspec.yaml)"
previous=""
for dir in $(ls -d build_archive/apk/*/ 2>/dev/null | sort -V); do
  v="$(basename "$dir")"
  [ "$v" = "$current" ] && continue
  [ "$(printf '%s\n%s\n' "$v" "$current" | sort -V | head -1)" = "$v" ] && previous="$v"
done
if [ -z "$previous" ] || [ ! -f "build_archive/apk/$previous/app-release.apk" ]; then
  echo "NOT RUN: no release older than $current is kept in build_archive/apk/."
  echo "release_gates.sh keeps each one it checks; the next release can be"
  echo "checked against this one."
  exit 2
fi
OLD="build_archive/apk/$previous/app-release.apk"
[ -f "$NEW" ] || die "no new build at $NEW (tool/matrix/release_gates.sh builds one)"
use_serial "$SERIAL_ARG"

start_app() {
  adb_sh am force-stop "$PKG"
  adb_sh monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
  sleep 20
}
crashes() {
  adb_s logcat -d -v time 2>/dev/null \
    | grep -E "FATAL EXCEPTION|ANR in $PKG|E/flutter|Fatal signal" || true
}

echo "upgrade $previous -> $current on $SERIAL"
adb_s uninstall "$PKG" >/dev/null 2>&1 || true
adb_s install "$OLD" >/dev/null || die "the previous release would not install"
adb_s logcat -c
start_app
[ -z "$(crashes)" ] || { crashes | head -5; die "the previous release crashed on its own; nothing to compare against"; }

if ! out="$(adb_s install -r "$NEW" 2>&1)"; then
  echo "$out" | tail -2
  echo "FAILED: Android refused the update; were both builds signed with the same key?"
  exit 1
fi
adb_s logcat -c
start_app
pid="$(adb_sh pidof "$PKG")"
problems="$(crashes)"
adb_sh am force-stop "$PKG"
if [ -n "$problems" ] || [ -z "$pid" ]; then
  echo "$problems" | head -8
  echo "FAILED: after updating from $previous the app ${pid:+crashed}${pid:-did not stay running}"
  exit 1
fi
echo "passed: $previous updated to $current in place, started, no crash"
