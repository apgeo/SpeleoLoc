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
#   tool/android/seed_app_data.sh <archive.zip>   # another archive
#   ... [serial] as a second argument to pick a device
#
# Output goes to $SPELEO_OUT_DIR (default build/screenshots): the data
# origin is recorded there and stale screenshots are removed from it.
#
# Prints DATA_ORIGIN=invented or DATA_ORIGIN=anonymized only when the
# archive's manifest carries that marker. Anything else is reported as
# unmarked and must be treated as real data: its screenshots are for people
# to look at, not for an agent to read.
set -euo pipefail

cd "$(dirname "$0")/../.."
. tool/android/lib.sh

DEFAULT_ARCHIVE="assets/test_archive/automation_fixture.zip"
OUT_DIR="${SPELEO_OUT_DIR:-build/screenshots}"

ARCHIVE="${1:-$DEFAULT_ARCHIVE}"
if [ ! -f "$ARCHIVE" ] && [ "$ARCHIVE" = "$DEFAULT_ARCHIVE" ]; then
  die "no fixture at $ARCHIVE — build it with: flutter test tool/android/generate_fixture_archive.dart"
fi
[ -f "$ARCHIVE" ] || die "no such archive: $ARCHIVE"
use_serial "${2:-}"
# `pm path` rather than `pm list | grep -q`: under pipefail the early exit of
# grep -q can kill adb with SIGPIPE and report an installed app as missing.
# The app has to be there already because run-as needs the package; note
# that `flutter drive` uninstalls it when a run ends.
[ -n "$(adb_sh pm path "$PKG")" ] || die "$PKG is not installed on $SERIAL"

work="$(mktemp -d)"
trap 'rm -rf "${work:?}"' EXIT
unzip -q "$ARCHIVE" -d "$work/tree"
[ -f "$work/tree/speleo_loc.sqlite" ] || die "not a DataArchive: no speleo_loc.sqlite inside $ARCHIVE"

origin="$(archive_origin "$ARCHIVE")"
# Neither file belongs in the documents directory; the importer skips them too.
rm -f "$work/tree/manifest.json" "$work/tree/ftp_credentials.json"

remote_tmp=/data/local/tmp/speleo_seed
adb_sh am force-stop "$PKG"
adb_sh pm clear "$PKG" >/dev/null
adb_sh rm -rf "$remote_tmp"
adb_s push "$work/tree" "$remote_tmp" >/dev/null
adb_sh chmod -R a+rX "$remote_tmp"
adb_s shell "run-as $PKG sh -c 'mkdir -p app_flutter && cp -r $remote_tmp/. app_flutter/'" \
  || die "run-as failed — is this a debug build?"
adb_sh rm -rf "$remote_tmp"

[ -n "$(adb_sh "run-as $PKG ls app_flutter/speleo_loc.sqlite")" ] \
  || die "the database did not arrive in the app's documents directory"

# pm clear also drops every runtime permission. Grant them all again, so a
# flow never stalls behind a system dialog it cannot see; the runs that are
# about a permission being refused take it away again themselves.
tool/android/permissions.sh grant-all "$SERIAL" >/dev/null

# Screenshots taken before this seed came from different data, and must not
# be mistaken for captures of what is on the device now.
mkdir -p "$OUT_DIR"
find "${OUT_DIR:?}" -maxdepth 1 -type f \
  \( -name '*.png' -o -name '*.semantics.txt' -o -name result.json \) -delete
echo "$origin" > "$OUT_DIR/.data-origin"

echo "seeded $PKG on $SERIAL from $ARCHIVE"
echo "DATA_ORIGIN=$origin"
if ! origin_is_readable "$origin"; then
  cat >&2 <<'MSG'
NOTE: this archive carries neither the invented nor the anonymized marker,
so it is treated as real data. Screenshots from this device are for a
person to review; an agent must not read them into its context.
MSG
fi
