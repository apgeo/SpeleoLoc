#!/usr/bin/env bash
# One command to check the UI, for a person or an agent iterating on a change.
#
# Runs the layers that need no device first and always; they are seconds
# each and catch most of what breaks. The on-device layer runs only when a
# device is actually connected, and its absence is reported rather than
# treated as a pass — a check that silently does nothing is worse than no
# check.
#
# Usage:
#   tool/ui_check.sh              # analyze + layout + goldens, device if present
#   tool/ui_check.sh --no-device  # skip the device layer even if one is up
#   tool/ui_check.sh --update-goldens
set -euo pipefail

cd "$(dirname "$0")/.."
ANDROID_HOME="${ANDROID_HOME:-$HOME/.local/opt/android-sdk}"
ADB="$ANDROID_HOME/platform-tools/adb"

WANT_DEVICE=1
GOLDEN_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --no-device) WANT_DEVICE=0 ;;
    --update-goldens) GOLDEN_ARGS+=(--update-goldens) ;;
    *) echo "unknown flag: $arg" >&2; exit 64 ;;
  esac
done

status=0
step() { echo; echo "=== $* ==="; }

step "analyze"
flutter analyze || status=1

step "layout across device profiles"
flutter test test/widgets/trip_media_layout_test.dart || status=1

step "golden images"
flutter test "${GOLDEN_ARGS[@]}" test/widgets/trip_media_golden_test.dart || status=1

if [ "$WANT_DEVICE" = "0" ]; then
  echo; echo "device layer: skipped (--no-device)"
  exit "$status"
fi

step "on-device"
if [ ! -x "$ADB" ] || ! "$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device"' | grep -q .; then
  cat <<'MSG'
NOT RUN: no Android device or emulator is connected, so nothing on a real
platform was checked. Start one with:

    tool/android/avd.sh boot speleo_api34_pixel7

If that reports no /dev/kvm, this VM still needs nested virtualization
enabled on the Hyper-V host — `tool/android/avd.sh doctor` prints the
commands.
MSG
  # Deliberately not a failure: the no-device layers above did run and
  # their verdict stands on its own.
  exit "$status"
fi

flutter drive \
  --driver test_driver/integration_test.dart \
  --target integration_test/app_smoke_test.dart \
  --dart-define-from-file=build_settings.json || status=1

echo
if [ -d build/screenshots ]; then
  echo "screenshots:"
  ls -1 build/screenshots/*.png 2>/dev/null | sed 's/^/  /' || echo "  (none)"
fi

exit "$status"
