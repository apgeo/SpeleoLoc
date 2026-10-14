#!/usr/bin/env bash
# Give a running emulator a different screen shape, or put it back.
#
# One emulator per Android version is enough to cover a range of shapes,
# because size, density, font scale, bold text, rotation and dark mode are
# all settings of the running system rather than properties of the virtual
# hardware. Each raises a real configuration change, so the app sees
# exactly what it would on a device built that way.
#
# The shapes themselves live in tool/matrix/shapes.json.
#
# Usage:
#   tool/android/device_profile.sh <shape> [serial]
#   tool/android/device_profile.sh reset   [serial]
#   tool/android/device_profile.sh list
#
# Prints one `applied:` or `unsupported:` line per setting. A setting this
# Android version does not have is reported, never silently skipped: a run
# labelled "dark" that was not dark is worse than one that says it could
# not be.
set -euo pipefail

. "$(dirname "$0")/lib.sh"
SHAPES="$(dirname "$0")/../matrix/shapes.json"

shape_field() { # shape key -> value or empty
  python3 - "$SHAPES" "$1" "$2" <<'PY'
import json, sys
shapes = json.load(open(sys.argv[1]))["shapes"]
if sys.argv[2] not in shapes:
    sys.exit(3)
value = shapes[sys.argv[2]].get("android", {}).get(sys.argv[3], "")
print(str(value).lower() if isinstance(value, bool) else value)
PY
}

# A status bar that shows the real clock, battery and whatever notification
# arrived makes two screenshots of the same screen differ for reasons that
# have nothing to do with the app. Demo mode pins all of it.
demo_mode() {
  adb_sh settings put global sysui_demo_allowed 1
  local b="am broadcast -a com.android.systemui.demo -e command"
  adb_sh "$b enter" >/dev/null
  adb_sh "$b clock -e hhmm 1200" >/dev/null
  adb_sh "$b battery -e level 100 -e plugged false" >/dev/null
  adb_sh "$b network -e wifi show -e level 4 -e mobile hide" >/dev/null
  adb_sh "$b notifications -e visible false" >/dev/null
}

reset_shape() {
  adb_sh wm size reset
  adb_sh wm density reset
  adb_sh settings put system font_scale 1.0
  adb_sh settings put system accelerometer_rotation 0
  adb_sh settings put system user_rotation 0
  adb_sh settings put secure font_weight_adjustment 0 >/dev/null 2>&1 || true
  adb_sh cmd uimode night no >/dev/null 2>&1 || true
}

apply_shape() {
  local shape="$1" api size density font rotation bold night
  size="$(shape_field "$shape" size)" || die "no such shape: $shape (see: $0 list)"
  density="$(shape_field "$shape" density)"
  font="$(shape_field "$shape" font_scale)"
  rotation="$(shape_field "$shape" rotation)"
  bold="$(shape_field "$shape" bold)"
  night="$(shape_field "$shape" night)"
  api="$(device_api)"

  reset_shape
  if [ -n "$size" ]; then
    adb_sh wm size "$size"
    adb_sh wm density "$density"
    echo "applied: size $size at $density dpi"
  fi
  if [ -n "$font" ]; then
    adb_sh settings put system font_scale "$font"
    echo "applied: font scale $font"
  fi
  if [ -n "$rotation" ] && [ "$rotation" != 0 ]; then
    adb_sh settings put system user_rotation "$rotation"
    echo "applied: rotation $rotation"
  fi
  if [ "$bold" = true ]; then
    if [ "$api" -ge 31 ]; then
      adb_sh settings put secure font_weight_adjustment 300
      echo "applied: bold text"
    else
      echo "unsupported: bold text needs API 31 (this is $api)"
    fi
  fi
  if [ "$night" = true ]; then
    if [ "$api" -ge 29 ]; then
      adb_sh cmd uimode night yes >/dev/null
      echo "applied: dark mode"
    else
      echo "unsupported: dark mode needs API 29 (this is $api)"
    fi
  fi
  demo_mode
  # A configuration change is delivered asynchronously; give it a moment
  # to land before anything starts the app.
  sleep 2
}

case "${1:-}" in
  list)
    python3 -c 'import json,sys; [print(k) for k in json.load(open(sys.argv[1]))["shapes"]]' "$SHAPES"
    ;;
  reset)
    use_serial "${2:-}"
    reset_shape
    adb_sh "am broadcast -a com.android.systemui.demo -e command exit" >/dev/null
    echo "applied: native shape"
    ;;
  "") die "usage: $0 <shape>|reset|list [serial]" ;;
  *)
    use_serial "${2:-}"
    apply_shape "$1"
    ;;
esac
