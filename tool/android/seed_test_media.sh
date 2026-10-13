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

ANDROID_HOME="${ANDROID_HOME:-$HOME/.local/opt/android-sdk}"
ADB="$ANDROID_HOME/platform-tools/adb"
REMOTE_DIR=/sdcard/DCIM/Camera

die() { echo "ERROR: $*" >&2; exit 1; }

[ -x "$ADB" ] || die "adb not found at $ADB"
SERIAL_ARG=()
[ "${2:-}" != "" ] && SERIAL_ARG=(-s "$2")

"$ADB" "${SERIAL_ARG[@]}" get-state >/dev/null 2>&1 || die "no device; start one with tool/android/avd.sh boot <avd>"

if [ "${1:-}" = "--clear" ]; then
  echo "removing seeded media from $REMOTE_DIR"
  "$ADB" "${SERIAL_ARG[@]}" shell "rm -f $REMOTE_DIR/speleo_*.jpg" || true
  "$ADB" "${SERIAL_ARG[@]}" shell am broadcast \
    -a android.intent.action.MEDIA_MOUNTED -d file://$REMOTE_DIR >/dev/null || true
  echo "done"
  exit 0
fi

SRC="${1:?usage: $0 <dir-of-jpegs> [serial]}"
[ -d "$SRC" ] || die "not a directory: $SRC"

"$ADB" "${SERIAL_ARG[@]}" shell mkdir -p "$REMOTE_DIR"

count=0
for f in "$SRC"/*.jpg "$SRC"/*.jpeg; do
  [ -e "$f" ] || continue
  "$ADB" "${SERIAL_ARG[@]}" push "$f" "$REMOTE_DIR/" >/dev/null
  count=$((count + 1))
done
[ "$count" -gt 0 ] || die "no .jpg files in $SRC"
echo "pushed $count file(s) to $REMOTE_DIR"

# MediaStore only learns about a pushed file when something tells it to
# look. scan_file per path is exact; the MEDIA_MOUNTED broadcast is the
# fallback for API levels where the scan service is not reachable.
for f in "$SRC"/*.jpg "$SRC"/*.jpeg; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  "$ADB" "${SERIAL_ARG[@]}" shell \
    "content call --uri content://media/external/file --method scan_file --arg $REMOTE_DIR/$base" \
    >/dev/null 2>&1 || true
done
"$ADB" "${SERIAL_ARG[@]}" shell am broadcast \
  -a android.intent.action.MEDIA_MOUNTED -d file://$REMOTE_DIR >/dev/null 2>&1 || true

echo "media store refreshed"
echo
echo "Grant the app library access without tapping through the dialog:"
echo "  $ADB ${SERIAL_ARG[*]} shell pm grant <applicationId> android.permission.READ_MEDIA_IMAGES"
echo "  $ADB ${SERIAL_ARG[*]} shell pm grant <applicationId> android.permission.READ_MEDIA_VIDEO"
echo "(API 32 and below use READ_EXTERNAL_STORAGE instead.)"
