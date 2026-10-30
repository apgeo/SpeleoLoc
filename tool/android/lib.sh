# Shared by the scripts in tool/android/ and tool/matrix/. Sourced, not run.
#
# Everything that talks to a device goes through `adb_s`, which addresses
# exactly one of them. With several emulators up at once a bare `adb` either
# fails ("more than one device") or, worse, quietly picks whichever one a
# stray ANDROID_SERIAL names.

ANDROID_HOME="${ANDROID_HOME:-$HOME/.local/opt/android-sdk}"
export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
# Recent command-line tools create AVDs under $XDG_CONFIG_HOME/.android while
# the emulator only looks in ~/.android, so a freshly created AVD is
# "unknown" to the thing meant to run it. Naming the directory once keeps
# both tools on the same one.
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$HOME/.android/avd}"

ADB="$ANDROID_HOME/platform-tools/adb"
EMULATOR="$ANDROID_HOME/emulator/emulator"
AVDMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
PKG="${SPELEO_PACKAGE:-ro.speotopo.speleoloc}"

die() { echo "ERROR: $*" >&2; exit 1; }

# The device every call in this process addresses. Set by `use_serial`.
SERIAL="${SPELEO_SERIAL:-}"

# Picks the device: an explicit serial, or the only one connected. Refuses
# to guess between several.
use_serial() {
  local want="${1:-${SPELEO_SERIAL:-}}"
  if [ -n "$want" ]; then
    SERIAL="$want"
  else
    local found
    found="$("$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1}')"
    case "$(printf '%s\n' "$found" | grep -c .)" in
      0) die "no device; start one with tool/android/avd.sh boot <avd>" ;;
      1) SERIAL="$found" ;;
      *) die "several devices are connected ($(echo $found)); name one with --serial or SPELEO_SERIAL" ;;
    esac
  fi
  [ "$("$ADB" -s "$SERIAL" get-state 2>/dev/null)" = "device" ] \
    || die "device $SERIAL is not ready"
  export SPELEO_SERIAL="$SERIAL"
}

adb_s() { "$ADB" -s "$SERIAL" "$@"; }

# Shell output with the carriage returns older Android versions add removed.
adb_sh() { "$ADB" -s "$SERIAL" shell "$@" 2>/dev/null | tr -d '\r'; }

device_api() { adb_sh getprop ro.build.version.sdk; }

wait_for_boot() {
  local tries="${1:-150}"
  "$ADB" -s "$SERIAL" wait-for-device
  for _ in $(seq 1 "$tries"); do
    [ "$(adb_sh getprop sys.boot_completed)" = "1" ] && return 0
    sleep 2
  done
  return 1
}

# Which data origins an agent may read screenshots and dumps of. `invented`
# is the generated fixture; `anonymized` is a real export that the
# anonymizer's own verifier passed. Anything else is treated as real.
origin_is_readable() {
  case "$1" in invented|anonymized) return 0 ;; *) return 1 ;; esac
}

# Reads the origin an archive declares in its manifest. The marker is taken
# from the file itself, never from its name.
archive_origin() {
  local manifest
  manifest="$(unzip -p "$1" manifest.json 2>/dev/null || true)"
  if printf '%s' "$manifest" | grep -q '"fixture"[[:space:]]*:[[:space:]]*"invented'; then
    echo invented
  elif printf '%s' "$manifest" | grep -q '"fixture"[[:space:]]*:[[:space:]]*"anonymized'; then
    echo anonymized
  else
    echo unmarked
  fi
}
