#!/usr/bin/env bash
# Replace the app's whole data set on a device with a DataArchive, without
# going through the app.
#
# The in-app import ends by restarting the process, which kills an
# integration test mid-run, so automated runs seed from outside instead. An
# archive's layout maps one-to-one onto the app's documents directory — the
# database plus any document and map files — so this unpacks it and copies
# the tree in with run-as (debug builds only).
#
# It always wipes first. That is deliberate: a device that has been used by
# hand may hold the real cave register, and a run that starts from whatever
# was there cannot promise what ends up in its screenshots.
#
# Usage:
#   tool/android/seed_app_data.sh                 # the invented fixture
#   tool/android/seed_app_data.sh <archive.zip>   # a curated archive
#   ... [serial] as a second argument to pick a device
#
# Prints DATA_ORIGIN=invented only when the archive's manifest carries the
# fixture marker. Anything else is reported as unmarked and must be treated
# as real data: its screenshots are for people to look at, not for an agent
# to read.
set -euo pipefail

cd "$(dirname "$0")/../.."
ANDROID_HOME="${ANDROID_HOME:-$HOME/.local/opt/android-sdk}"
ADB="$ANDROID_HOME/platform-tools/adb"
PKG="${SPELEO_PACKAGE:-ro.speosilex.speleoloc}"
DEFAULT_ARCHIVE="assets/test_archive/automation_fixture.zip"
ORIGIN_FILE="build/screenshots/.data-origin"

die() { echo "ERROR: $*" >&2; exit 1; }

ARCHIVE="${1:-$DEFAULT_ARCHIVE}"
SERIAL_ARG=()
[ "${2:-}" != "" ] && SERIAL_ARG=(-s "$2")

if [ ! -f "$ARCHIVE" ] && [ "$ARCHIVE" = "$DEFAULT_ARCHIVE" ]; then
  die "no fixture at $ARCHIVE — build it with: flutter test tool/android/generate_fixture_archive.dart"
fi
[ -f "$ARCHIVE" ] || die "no such archive: $ARCHIVE"
"$ADB" "${SERIAL_ARG[@]}" get-state >/dev/null 2>&1 || die "no device; start one with tool/android/avd.sh boot <avd>"
# `pm path` rather than `pm list | grep -q`: under pipefail the early exit of
# grep -q can kill adb with SIGPIPE and report an installed app as missing.
# The app has to be there already because run-as needs the package; note
# that `flutter drive` uninstalls it when a run ends.
[ -n "$("$ADB" "${SERIAL_ARG[@]}" shell pm path "$PKG" 2>/dev/null)" ] \
  || die "$PKG is not installed on the device"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
unzip -q "$ARCHIVE" -d "$work/tree"
[ -f "$work/tree/speleo_loc.sqlite" ] || die "not a DataArchive: no speleo_loc.sqlite inside $ARCHIVE"

# The marker is read here, from the manifest, rather than trusted from a
# file name: only an archive that says it is invented is treated as such.
origin="unmarked"
if grep -q '"fixture"[[:space:]]*:[[:space:]]*"invented' "$work/tree/manifest.json" 2>/dev/null; then
  origin="invented"
fi
# Neither file belongs in the documents directory; the importer skips them too.
rm -f "$work/tree/manifest.json" "$work/tree/ftp_credentials.json"

remote_tmp=/data/local/tmp/speleo_seed
"$ADB" "${SERIAL_ARG[@]}" shell am force-stop "$PKG"
"$ADB" "${SERIAL_ARG[@]}" shell pm clear "$PKG" >/dev/null
"$ADB" "${SERIAL_ARG[@]}" shell "rm -rf $remote_tmp"
"$ADB" "${SERIAL_ARG[@]}" push "$work/tree" "$remote_tmp" >/dev/null
"$ADB" "${SERIAL_ARG[@]}" shell "chmod -R a+rX $remote_tmp"
"$ADB" "${SERIAL_ARG[@]}" shell \
  "run-as $PKG sh -c 'mkdir -p app_flutter && cp -r $remote_tmp/. app_flutter/'" \
  || die "run-as failed — is this a debug build?"
"$ADB" "${SERIAL_ARG[@]}" shell "rm -rf $remote_tmp"

"$ADB" "${SERIAL_ARG[@]}" shell "run-as $PKG ls app_flutter/speleo_loc.sqlite" >/dev/null \
  || die "the database did not arrive in the app's documents directory"

# pm clear also drops runtime permissions, so the media library access the
# points-from-pictures screen needs is granted again here. Whichever of the
# two families this API level has is the one that sticks; the other fails
# quietly.
for perm in READ_MEDIA_IMAGES READ_MEDIA_VIDEO READ_EXTERNAL_STORAGE; do
  "$ADB" "${SERIAL_ARG[@]}" shell pm grant "$PKG" "android.permission.$perm" >/dev/null 2>&1 || true
done

# Screenshots taken before this seed came from different data, and must not
# be mistaken for captures of what is on the device now.
mkdir -p "$(dirname "$ORIGIN_FILE")"
rm -f build/screenshots/*.png
echo "$origin" > "$ORIGIN_FILE"

echo "seeded $PKG from $ARCHIVE"
echo "DATA_ORIGIN=$origin"
if [ "$origin" != "invented" ]; then
  cat >&2 <<'MSG'
NOTE: this archive does not carry the invented-fixture marker, so it is
treated as real data. Screenshots from this device are for a person to
review; an agent must not read them into its context.
MSG
fi
