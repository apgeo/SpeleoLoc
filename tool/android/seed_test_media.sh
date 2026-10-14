#!/usr/bin/env bash
# Put invented photos into a running emulator's media library, so the
# "points from pictures" screen has something to find.
#
# The screen reads the device's own media store — capture dates and all —
# so an empty emulator shows an empty list and nothing can be exercised.
# This pushes generated JPEGs with chosen EXIF capture times, some of them
# carrying a cave place's QR code, and makes the media scanner notice them.
#
# Generate the files first with:
#   dart run tool/android/generate_test_media.dart <out-dir>
#
# Usage:
#   tool/android/seed_test_media.sh <dir-of-jpegs> [serial]
#   tool/android/seed_test_media.sh --clear [serial]
set -euo pipefail

. "$(dirname "$0")/lib.sh"
REMOTE_DIR=/sdcard/DCIM/Camera

[ -x "$ADB" ] || die "adb not found at $ADB"
use_serial "${2:-}"

if [ "${1:-}" = "--clear" ]; then
  echo "removing seeded media from $REMOTE_DIR"
  adb_sh "rm -f $REMOTE_DIR/speleo_*.jpg" || true
  adb_sh am broadcast \
    -a android.intent.action.MEDIA_MOUNTED -d "file://$REMOTE_DIR" >/dev/null || true
  echo "done"
  exit 0
fi

SRC="${1:?usage: $0 <dir-of-jpegs> [serial]}"
[ -d "$SRC" ] || die "not a directory: $SRC"

adb_sh mkdir -p "$REMOTE_DIR"

count=0
for f in "$SRC"/*.jpg "$SRC"/*.jpeg; do
  [ -e "$f" ] || continue
  adb_s push "$f" "$REMOTE_DIR/" >/dev/null
  count=$((count + 1))
done
[ "$count" -gt 0 ] || die "no .jpg files in $SRC"
echo "pushed $count file(s) to $REMOTE_DIR"

# MediaStore only learns about a pushed file when something tells it to
# look, and the cheap triggers do not always finish the job: on an API 34
# emulator every `scan_file` variant returned a null URI and left the row
# `is_pending=1` with no size, width or date. A reboot makes MediaProvider
# scan the volume properly, so the cheap path is tried first and verified,
# and the reboot is the fallback rather than the default.
scan_cheap() {
  local f base
  for f in "$SRC"/*.jpg "$SRC"/*.jpeg; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    adb_sh "content call --uri content://media/external/file --method scan_file --arg $REMOTE_DIR/$base" \
      >/dev/null 2>&1 || true
  done
  adb_sh am broadcast \
    -a android.intent.action.MEDIA_MOUNTED -d "file://$REMOTE_DIR" >/dev/null 2>&1 || true
}

# Counts seeded rows that the scanner actually completed.
indexed_count() {
  adb_sh "content query --uri content://media/external/images/media \
       --projection _display_name \
       --where \"_display_name LIKE 'speleo_%' AND is_pending=0 AND datetaken IS NOT NULL\"" \
    | grep -c '^Row:' || true
}

scan_cheap
sleep 3
if [ "$(indexed_count)" -lt "$count" ]; then
  echo "scan did not complete ($(indexed_count)/$count indexed); rebooting to force a full volume scan"
  adb_s reboot
  sleep 5
  wait_for_boot 90 || die "device did not come back after the reboot"
  sleep 20
fi

final="$(indexed_count)"
echo "media store refreshed — $final/$count indexed with a capture date"
[ "$final" -ge "$count" ] || echo "WARNING: some files are still not indexed" >&2
