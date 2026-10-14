#!/usr/bin/env bash
# Put the app's runtime permissions into a known state on a device.
#
# Automated flows cannot tap a system permission dialog — it belongs to
# another process — so permissions are set from outside, before the app
# starts. The default is everything granted, so a flow never stalls behind
# a dialog. The journeys are the opposite case: they take one permission
# away in the specific way a user can, and the flow then checks that the
# app copes.
#
# What exists differs by Android version, which is the reason the test
# matrix spans several: Bluetooth scanning needed location until API 31 and
# has its own permission since; photos moved from storage to media
# permissions at 33 and gained "only the ones I pick" at 34; notifications
# became a runtime permission at 33.
#
# Usage:
#   tool/android/permissions.sh grant-all [serial]
#   tool/android/permissions.sh revoke-all [serial]
#   tool/android/permissions.sh journey <name> [serial]
#   tool/android/permissions.sh journeys            # list them
#   tool/android/permissions.sh state [serial]      # what is granted now
#
# A journey prints `applied:` when it set the device up, or `unsupported:`
# when this Android version has no such state — never silence.
set -euo pipefail

. "$(dirname "$0")/lib.sh"

P=android.permission
ALL=(
  CAMERA RECORD_AUDIO
  ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION
  BLUETOOTH_SCAN BLUETOOTH_CONNECT
  POST_NOTIFICATIONS
  READ_MEDIA_IMAGES READ_MEDIA_VIDEO READ_MEDIA_VISUAL_USER_SELECTED
  READ_EXTERNAL_STORAGE WRITE_EXTERNAL_STORAGE
)

grant() { adb_sh pm grant "$PKG" "$P.$1" >/dev/null 2>&1 || true; }
revoke() { adb_sh pm revoke "$PKG" "$P.$1" >/dev/null 2>&1 || true; }

# Granting a permission this Android version does not have, or that the
# manifest caps below it, fails; that is expected and ignored — the set
# that sticks is the right one for the device.
grant_all() {
  local p
  for p in "${ALL[@]}"; do grant "$p"; done
  # Not a runtime permission but a special access the beacon settings ask
  # for; without it that screen opens a system settings page on top of the
  # app.
  adb_sh dumpsys deviceidle whitelist "+$PKG" >/dev/null 2>&1 || true
}

revoke_all() {
  local p
  for p in "${ALL[@]}"; do revoke "$p"; done
  adb_sh dumpsys deviceidle whitelist "-$PKG" >/dev/null 2>&1 || true
}

JOURNEYS=(
  "no_camera|the scanner and the camera capture screen with the camera refused"
  "no_location|the surface map and GPS recorder with location refused"
  "approximate_location|API 31+: only approximate location granted; beacon scanning needs precise"
  "no_bluetooth|API 31+: Bluetooth scanning refused"
  "no_notifications|API 33+: notifications refused; detection alerts cannot be shown"
  "no_media|photos and videos refused; points-from-pictures falls back to the picker"
  "partial_media|API 34+: only selected photos allowed"
  "no_microphone|the sound recorder with the microphone refused"
)

journey() {
  local name="$1" api
  api="$(device_api)"
  grant_all
  case "$name" in
    no_camera) revoke CAMERA ;;
    no_microphone) revoke RECORD_AUDIO ;;
    no_location) revoke ACCESS_FINE_LOCATION; revoke ACCESS_COARSE_LOCATION ;;
    approximate_location)
      [ "$api" -ge 31 ] || { echo "unsupported: approximate-only location needs API 31 (this is $api)"; return 0; }
      revoke ACCESS_FINE_LOCATION ;;
    no_bluetooth)
      [ "$api" -ge 31 ] || { echo "unsupported: the Bluetooth permissions need API 31 (this is $api)"; return 0; }
      revoke BLUETOOTH_SCAN; revoke BLUETOOTH_CONNECT ;;
    no_notifications)
      [ "$api" -ge 33 ] || { echo "unsupported: notifications are not a runtime permission before API 33 (this is $api)"; return 0; }
      revoke POST_NOTIFICATIONS ;;
    no_media)
      revoke READ_MEDIA_IMAGES; revoke READ_MEDIA_VIDEO
      revoke READ_MEDIA_VISUAL_USER_SELECTED; revoke READ_EXTERNAL_STORAGE ;;
    partial_media)
      [ "$api" -ge 34 ] || { echo "unsupported: selected-photos access needs API 34 (this is $api)"; return 0; }
      revoke READ_MEDIA_IMAGES; revoke READ_MEDIA_VIDEO
      grant READ_MEDIA_VISUAL_USER_SELECTED ;;
    *) die "no such journey: $name (see: $0 journeys)" ;;
  esac
  echo "applied: $name"
}

state() {
  adb_sh dumpsys package "$PKG" \
    | grep -E "android\.permission\.[A-Z_]+: granted=" \
    | sed -E 's/^ *android\.permission\.([A-Z_]+): granted=(true|false).*/\2 \1/' \
    | sort -u
}

case "${1:-}" in
  grant-all) use_serial "${2:-}"; grant_all; echo "applied: everything granted" ;;
  revoke-all) use_serial "${2:-}"; revoke_all; echo "applied: everything revoked" ;;
  journey) use_serial "${3:-}"; journey "${2:?usage: $0 journey <name> [serial]}" ;;
  journeys) printf '%s\n' "${JOURNEYS[@]}" | sed 's/|/\t/' ;;
  state) use_serial "${2:-}"; state ;;
  *) die "usage: $0 grant-all|revoke-all|journey <name>|journeys|state [serial]" ;;
esac
