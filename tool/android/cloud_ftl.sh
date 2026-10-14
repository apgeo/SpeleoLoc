#!/usr/bin/env bash
# Run the UI tests on real phones in Firebase Test Lab.
#
# The emulators here are all Google images. What differs on the phones
# cavers actually carry — a Samsung or Xiaomi build of Android, its
# permission dialogs, its battery management — only shows on those phones,
# and a device lab is the way to borrow them for an hour.
#
# What leaves this machine: the debug test build and the invented fixture
# bundled in it, nothing else. The script refuses to build when
# assets/test_archive/ holds anything not marked invented.
#
# Usage:
#   tool/android/cloud_ftl.sh                      # default devices and flows
#   tool/android/cloud_ftl.sh --devices 'model=oriole,version=33;model=a14,version=34'
#   tool/android/cloud_ftl.sh --flows smoke,sweep_all
#   tool/android/cloud_ftl.sh --build-only         # build, check, do not upload
#   tool/android/cloud_ftl.sh --list-devices       # physical phones on offer
#
# Needs, once: the Google Cloud CLI (`gcloud`), `gcloud auth login`, and a
# Firebase project with Test Lab enabled, selected with
# `gcloud config set project <id>`. The free Spark plan allows a handful of
# physical-device runs a day.
#
# Without those it builds nothing and says NOT RUN (exit code 2), so it is
# safe to call from a tier that is not sure it has a cloud to go to.
set -euo pipefail

cd "$(dirname "$0")/../.."
. tool/android/lib.sh

# A virtual Pixel always exists; physical models come and go, so name them
# from `--list-devices` when picking manufacturers.
DEVICES="${FTL_DEVICES:-model=MediumPhone.arm,version=34}"
FLOWS="smoke,sweep_all"
BUILD_ONLY=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --devices) DEVICES="$2"; shift ;;
    --flows) FLOWS="$2"; shift ;;
    --build-only) BUILD_ONLY=1 ;;
    --list-devices)
      command -v gcloud >/dev/null || die "gcloud is not installed"
      exec gcloud firebase test android models list --filter='form=PHYSICAL' \
        --format='table(id,brand,name,supportedVersionIds.list())' ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

not_run() {
  cat >&2 <<MSG
NOT RUN: $1

To enable cloud device runs:
  1. install the Google Cloud CLI: https://cloud.google.com/sdk/docs/install
  2. gcloud auth login
  3. create a Firebase project with Test Lab, then:
     gcloud config set project <project-id>
MSG
  exit 2
}

if [ "$BUILD_ONLY" = 0 ]; then
  command -v gcloud >/dev/null || not_run "the Google Cloud CLI (gcloud) is not installed"
  [ -n "$(gcloud config get-value project 2>/dev/null)" ] \
    || not_run "no Google Cloud project is selected"
fi

# --- build ------------------------------------------------------------------
flutter test --no-pub tool/android/generate_fixture_archive.dart >/dev/null
for archive in assets/test_archive/*.zip; do
  [ -e "$archive" ] || continue
  [ "$(archive_origin "$archive")" = invented ] \
    || die "$archive is not marked invented; it would be uploaded inside the test build. Move it out of assets/test_archive/ first."
done

# The Flutter Gradle plugin takes compile-time constants as a comma-separated
# list of base64-encoded KEY=VALUE pairs.
defines="$(
  for kv in \
    "test_archive_url=assets/test_archive/automation_fixture.zip" \
    "SPELEO_SEED_FROM_BUNDLE=true" \
    "SPELEO_FIXTURE_INVENTED=true" \
    "SPELEO_FLOWS=$FLOWS"; do
    printf '%s' "$kv" | base64 -w0
    printf ','
  done | sed 's/,$//'
)"
# Generates the Gradle-side configuration the next two steps read.
flutter build apk --debug --no-pub --config-only >/dev/null
(
  cd android
  ./gradlew -q app:assembleAndroidTest
  ./gradlew -q app:assembleDebug \
    -Ptarget="$PWD/../integration_test/suite_test.dart" \
    -Pdart-defines="$defines"
)
APP=build/app/outputs/apk/debug/app-debug.apk
TEST=build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
[ -f "$APP" ] && [ -f "$TEST" ] || die "the build did not produce $APP and $TEST"
echo "built: $APP ($(du -h "$APP" | cut -f1)), $TEST"

if [ "$BUILD_ONLY" = 1 ]; then
  echo "--build-only: not uploaded. To try the same thing on a local emulator:"
  echo "  adb install -r $APP && adb install -r $TEST"
  echo "  adb shell am instrument -w $PKG.test/androidx.test.runner.AndroidJUnitRunner"
  exit 0
fi

# --- run --------------------------------------------------------------------
device_args=()
IFS=';' read -ra list <<<"$DEVICES"
for d in "${list[@]}"; do device_args+=(--device "$d"); done
gcloud firebase test android run \
  --type instrumentation \
  --app "$APP" \
  --test "$TEST" \
  "${device_args[@]}" \
  --timeout 45m
