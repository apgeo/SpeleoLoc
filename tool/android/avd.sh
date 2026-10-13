#!/usr/bin/env bash
# Create and run the project's Android emulators.
#
# The matrix brackets what the app actually supports: minSdk 24 at the
# bottom, the API 33 boundary where photo access changed from
# READ_EXTERNAL_STORAGE to READ_MEDIA_*, compileSdk 36 at the top, and one
# tablet so a large screen is covered as well as a range of versions.
#
# Usage:
#   tool/android/avd.sh doctor          # can this machine run an emulator?
#   tool/android/avd.sh create          # create every AVD (idempotent)
#   tool/android/avd.sh configure       # re-apply shared settings to them
#   tool/android/avd.sh list            # what exists now
#   tool/android/avd.sh start <name>    # boot one, in the background
#   tool/android/avd.sh boot <name>     # boot one and wait until it is ready
#                                       # (add --headless for no window)
#   tool/android/avd.sh stop            # stop every running emulator
set -euo pipefail

ANDROID_HOME="${ANDROID_HOME:-$HOME/.local/opt/android-sdk}"
export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
AVDMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
EMULATOR="$ANDROID_HOME/emulator/emulator"
ADB="$ANDROID_HOME/platform-tools/adb"

# name|api|device profile
AVDS=(
  "speleo_api24_pixel2|24|pixel_2"
  "speleo_api30_pixel4|30|pixel_4"
  "speleo_api34_pixel7|34|pixel_7"
  "speleo_api34_tablet|34|medium_tablet"
  "speleo_api36_pixel7pro|36|pixel_7_pro"
)

die() { echo "ERROR: $*" >&2; exit 1; }

kvm_report() {
  if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    echo "OK: /dev/kvm is present and writable — the emulator can run."
    return 0
  fi
  cat >&2 <<'MSG'
BLOCKED: this machine has no usable /dev/kvm, so the Android emulator
cannot run. On a Hyper-V guest that means nested virtualization is not
exposed to it (check: no vmx/svm in /proc/cpuinfo).

The kernel ships kvm-intel, so the only missing piece is host-side. On
the Windows host, with this VM SHUT DOWN:

    Set-VMProcessor -VMName <vm-name> -ExposeVirtualizationExtensions $true

Dynamic Memory can stay on. Microsoft's restriction applies while
Hyper-V itself runs inside the guest, and this guest runs KVM; measured
here with the balloon still growing under a live emulator.

Then boot the VM and re-run `tool/android/avd.sh doctor`.
MSG
  return 1
}

cmd_doctor() {
  echo "SDK:        $ANDROID_HOME"
  [ -x "$EMULATOR" ] || die "emulator package missing; run: sdkmanager --install emulator"
  echo "emulator:   $("$EMULATOR" -version 2>/dev/null | head -1)"
  echo "images:     $(ls "$ANDROID_HOME/system-images" 2>/dev/null | tr '\n' ' ')"
  echo "avds:       $("$EMULATOR" -list-avds 2>/dev/null | tr '\n' ' ')"
  echo
  "$EMULATOR" -accel-check 2>&1 | sed 's/^/accel-check: /' || true
  echo
  kvm_report || return 1
  kvm_access_report
}

# /dev/kvm can be reachable two ways, and they do not fail alike. Group
# membership holds everywhere. The session ACL is granted by logind to
# whoever holds the desktop seat, so it covers anything started while that
# session is up and silently disappears for a systemd service, a CI runner
# or a container — where the emulator then reports no acceleration at all.
kvm_access_report() {
  if id -nG | tr ' ' '\n' | grep -qx kvm; then
    echo "access:     kvm group membership"
  else
    cat <<'MSG'
access:     desktop-session ACL only — fine from a terminal or an agent
            while the desktop session is up; before launching emulators
            from a service, CI or a container, add the user to the group:
                sudo usermod -aG kvm "$USER"    (then log in again)
MSG
  fi
}

cmd_create() {
  for entry in "${AVDS[@]}"; do
    IFS='|' read -r name api device <<<"$entry"
    local_pkg="system-images;android-$api;google_apis;x86_64"
    if "$EMULATOR" -list-avds 2>/dev/null | grep -qx "$name"; then
      echo "exists:  $name"
      continue
    fi
    if [ ! -d "$ANDROID_HOME/system-images/android-$api/google_apis/x86_64" ]; then
      echo "skip:    $name (missing $local_pkg)" >&2
      continue
    fi
    echo "create:  $name (API $api, $device)"
    echo "no" | "$AVDMANAGER" create avd \
      --name "$name" \
      --package "$local_pkg" \
      --device "$device" \
      --force >/dev/null
    configure_one "$name"
  done
}

# Sets one key in an AVD config.ini, replacing any existing definitions
# rather than appending a second one — the file is read as last-wins, so a
# duplicate key works by accident and is a trap for the next edit.
set_ini() {
  local file="$1" key="$2" value="$3"
  sed -i "/^$(printf '%s' "$key" | sed 's/\./\\./g')=/d" "$file"
  printf '%s=%s\n' "$key" "$value" >> "$file"
}

# Settings every AVD needs regardless of its device profile. A plain AVD
# has no SD card and the media import needs somewhere for photos to live;
# there is no GPU on this host, so rendering is software either way and
# saying so avoids a probe that fails; the host keyboard lets a test type.
configure_one() {
  local name="$1"
  local cfg="$HOME/.android/avd/$name.avd/config.ini"
  [ -f "$cfg" ] || { echo "no config for $name" >&2; return 1; }
  set_ini "$cfg" hw.keyboard yes
  set_ini "$cfg" sdcard.size "2048M"
  set_ini "$cfg" hw.gpu.enabled yes
  set_ini "$cfg" hw.gpu.mode swiftshader_indirect
  echo "configured: $name"
}

cmd_configure() {
  for entry in "${AVDS[@]}"; do
    IFS='|' read -r name _ _ <<<"$entry"
    "$EMULATOR" -list-avds 2>/dev/null | grep -qx "$name" && configure_one "$name"
  done
}

cmd_list() { "$EMULATOR" -list-avds; }

start_one() {
  local name="$1"; shift
  "$EMULATOR" -list-avds | grep -qx "$name" || die "no such AVD: $name (run: $0 create)"
  kvm_report >/dev/null 2>&1 || { kvm_report || true; die "refusing to start without KVM — it would fall back to software CPU emulation, which never finishes booting in practice."; }

  local extra=()
  for arg in "$@"; do
    [ "$arg" = "--headless" ] && extra+=(-no-window)
  done
  # With no display the windowed emulator dies at startup, so a run from a
  # service or a bare SSH session goes headless without being asked. A
  # person at the desktop still gets the window unless they say otherwise.
  if [ -z "${DISPLAY:-}" ] && [ "${#extra[@]}" -eq 0 ]; then
    extra+=(-no-window)
    echo "no DISPLAY — starting headless"
  fi

  # No GPU on this host, so render in software. -no-audio because there is
  # no sound device, -no-boot-anim to shave boot time.
  nohup "$EMULATOR" -avd "$name" \
    -gpu swiftshader_indirect \
    -no-audio -no-boot-anim \
    "${extra[@]}" >"/tmp/emulator-$name.log" 2>&1 &
  echo "started $name (log: /tmp/emulator-$name.log)"
}

cmd_start() {
  local name="${1:?usage: $0 start <avd> [--headless]}"; shift
  start_one "$name" "$@"
}

cmd_boot() {
  local name="${1:?usage: $0 boot <avd> [--headless]}"; shift
  start_one "$name" "$@"
  echo -n "waiting for boot"
  "$ADB" wait-for-device
  for _ in $(seq 1 180); do
    if [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
      echo " — ready"
      "$ADB" devices
      return 0
    fi
    echo -n "."
    sleep 2
  done
  die "timed out waiting for $name to finish booting"
}

cmd_stop() {
  for serial in $("$ADB" devices | awk '/emulator-/ {print $1}'); do
    echo "stopping $serial"
    "$ADB" -s "$serial" emu kill || true
  done
}

case "${1:-doctor}" in
  doctor) cmd_doctor ;;
  create) cmd_create ;;
  configure) cmd_configure ;;
  list)   cmd_list ;;
  start)  shift; cmd_start "$@" ;;
  boot)   shift; cmd_boot "$@" ;;
  stop)   cmd_stop ;;
  *) die "unknown command: $1" ;;
esac
