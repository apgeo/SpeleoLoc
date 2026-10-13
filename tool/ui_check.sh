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
#
# The device layer runs on the invented fixture by default. To run it on a
# curated dataset instead, point it at that archive:
#   SPELEO_TEST_ARCHIVE=/path/to/curated.zip tool/ui_check.sh
# Only the content-blind smoke test runs then, and the screenshots it leaves
# are marked as not safe for an agent to read.
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

`tool/android/avd.sh doctor` says whether this machine can run one.
MSG
  # Deliberately not a failure: the no-device layers above did run and
  # their verdict stands on its own.
  exit "$status"
fi

# --- on a device ------------------------------------------------------------
#
# Build once, install, replace the app's data, then drive. The order is
# forced by two things: seeding uses run-as, which needs the package to be
# installed already, and `flutter drive` uninstalls the app when it ends, so
# nothing can be assumed to survive from a previous run.
ARCHIVE="${SPELEO_TEST_ARCHIVE:-assets/test_archive/automation_fixture.zip}"
SETTINGS=build_settings.automation.json
APK=build/app/outputs/flutter-apk/app-debug.apk

if [ "$ARCHIVE" = "assets/test_archive/automation_fixture.zip" ]; then
  # Rebuilt every time: it is the app's own schema that produces it, so a
  # stale archive from before a migration would be a confusing failure.
  step "invented fixture archive"
  flutter test tool/android/generate_fixture_archive.dart || { echo "fixture build failed" >&2; exit 1; }
fi

# Decided from the archive's own manifest before anything is built, because
# it selects which flows are compiled in.
if unzip -p "$ARCHIVE" manifest.json 2>/dev/null | grep -q '"fixture"[[:space:]]*:[[:space:]]*"invented'; then
  INVENTED=true
else
  INVENTED=false
fi

step "build the test app (data: $([ "$INVENTED" = true ] && echo invented fixture || echo "UNMARKED — treated as real"))"
flutter build apk --debug \
  --target integration_test/suite_test.dart \
  --dart-define-from-file="$SETTINGS" \
  --dart-define=SPELEO_FIXTURE_INVENTED="$INVENTED" || exit 1

step "install and seed"
"$ADB" install -r "$APK" >/dev/null || exit 1
tool/android/seed_app_data.sh "$ARCHIVE" || exit 1

if [ "$INVENTED" = true ]; then
  # The points-from-pictures flow needs pictures in the device's library.
  media_dir="$(mktemp -d)"
  dart run tool/android/generate_test_media.dart "$media_dir" a1 a2 >/dev/null
  tool/android/seed_test_media.sh "$media_dir" | grep -E "indexed|rebooting" || true
  rm -rf "$media_dir"
fi

step "drive"
flutter drive \
  --use-application-binary "$APK" \
  --driver test_driver/integration_test.dart \
  --target integration_test/suite_test.dart || status=1

echo
if ls build/screenshots/*.png >/dev/null 2>&1; then
  echo "screenshots (data origin: $(cat build/screenshots/.data-origin 2>/dev/null || echo unknown)):"
  ls -1 build/screenshots/*.png | sed 's/^/  /'
  if [ "$INVENTED" != true ]; then
    echo "  These show data that is not marked invented. They are for a person"
    echo "  to review; an agent must not read them into its context."
  fi
fi

exit "$status"
