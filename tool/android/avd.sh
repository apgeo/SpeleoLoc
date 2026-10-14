#!/usr/bin/env bash
# Create and run the project's Android emulators.
#
# There are two sets, and they are kept apart on purpose.
#
#   hand    speleo_api*    For working by hand, from a terminal or the VSCode
#                          launch configurations. Whatever you leave on them
#                          stays there; nothing here ever wipes them.
#   matrix  speleo_mx_*    Owned by the automated test matrix. `prepare`
#                          wipes one, boots it once, settles it and freezes
#                          that state as a snapshot named `pristine`; every
#                          automated run starts from that snapshot and
#                          discards what it did. Do not use them by hand.
#
# The matrix set brackets what the app supports and where Android changed
# under it: minSdk 24 and legacy storage; 30 scoped storage and one-time
# permissions; 31 the Bluetooth permission split and approximate location;
# 33 notification and media permissions; 34 partial photo access; 35 forced
# edge-to-edge on a 16 KB page-size image; 36 the adaptive-layout rules on a
# foldable. One AOSP image without Google services stands in for the phones
# that ship without them, and one tablet covers a large screen.
#
# Usage:
#   tool/android/avd.sh doctor              # can this machine run an emulator?
#   tool/android/avd.sh images [--install]  # system images the sets need
#   tool/android/avd.sh sparsify            # give back the empty space in them
#   tool/android/avd.sh create [hand|matrix|all|<avd>...]   (idempotent)
#   tool/android/avd.sh configure           # re-apply shared settings
#   tool/android/avd.sh prepare <avd>|matrix [--force] [--no-snapshot]
#   tool/android/avd.sh list [hand|matrix]
#   tool/android/avd.sh start <avd> [flags] # boot one, in the background
#   tool/android/avd.sh boot <avd> [flags]  # boot one and wait until ready
#        flags: --headless  --port <even number>  --pristine
#               --camera <image>  what the back camera shows
#   tool/android/avd.sh stop [<serial>|<avd>...]   # default: every emulator
#   tool/android/avd.sh serial <avd>        # serial of a running AVD
#   tool/android/avd.sh disk                # what the sets cost on disk
set -euo pipefail

. "$(dirname "$0")/lib.sh"

# name|api|device profile|system image tag|set
AVDS=(
  "speleo_api24_pixel2|24|pixel_2|google_apis|hand"
  "speleo_api30_pixel4|30|pixel_4|google_apis|hand"
  "speleo_api34_pixel7|34|pixel_7|google_apis|hand"
  "speleo_api34_tablet|34|medium_tablet|google_apis|hand"
  "speleo_api36_pixel7pro|36|pixel_7_pro|google_apis|hand"
  "speleo_mx_api24|24|pixel_2|google_apis|matrix"
  "speleo_mx_api30|30|pixel_4|google_apis|matrix"
  "speleo_mx_api31|31|pixel_5|google_apis|matrix"
  "speleo_mx_api33|33|pixel_6a|google_apis|matrix"
  "speleo_mx_api34|34|pixel_7|google_apis|matrix"
  "speleo_mx_api34_tablet|34|medium_tablet|google_apis|matrix"
  "speleo_mx_api34_aosp|34|pixel_7|default|matrix"
  "speleo_mx_api35_16k|35|pixel_8|google_apis_ps16k|matrix"
  "speleo_mx_api36_fold|36|pixel_9_pro_fold|google_apis|matrix"
)

SNAPSHOT=pristine
# Below this much free space on the SDK's disk nothing here downloads an
# image or creates a snapshot: a build needs room too, and a full disk
# fails in far more confusing ways than a refusal does.
MIN_FREE_GB="${SPELEO_MIN_FREE_GB:-12}"
# Rendering is on the CPU either way; this only picks which software
# renderer. Kept overridable so the alternatives can be measured.
GPU_MODE="${SPELEO_EMU_GPU:-swiftshader_indirect}"

entry_of() {
  local e
  for e in "${AVDS[@]}"; do
    [ "${e%%|*}" = "$1" ] && { echo "$e"; return 0; }
  done
  return 1
}

names_in() { # hand|matrix|all
  local e name set
  for e in "${AVDS[@]}"; do
    IFS='|' read -r name _ _ _ set <<<"$e"
    { [ "$1" = all ] || [ "$1" = "$set" ]; } && echo "$name"
  done
}

image_pkg() { echo "system-images;android-$1;$2;x86_64"; }
image_dir() { echo "$ANDROID_HOME/system-images/android-$1/$2/x86_64"; }
avd_dir() { echo "$ANDROID_AVD_HOME/$1.avd"; }
avd_exists() { [ -f "$(avd_dir "$1")/config.ini" ]; }
has_snapshot() { [ -d "$(avd_dir "$1")/snapshots/$SNAPSHOT" ]; }

free_gb() { df -BG --output=avail "$ANDROID_HOME" | tail -1 | tr -dc '0-9'; }
require_space() {
  local free
  free="$(free_gb)"
  [ "$free" -ge "$MIN_FREE_GB" ] \
    || die "only ${free} GB free where the SDK lives; refusing to $1 below ${MIN_FREE_GB} GB (override with SPELEO_MIN_FREE_GB)"
}

# --- KVM --------------------------------------------------------------------

kvm_usable() { [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; }
in_kvm_group_db() { getent group kvm | cut -d: -f4 | tr ',' '\n' | grep -qx "$(id -un)"; }

# /dev/kvm can be reachable two ways, and they do not fail alike. Group
# membership holds everywhere. The session ACL is granted by logind to
# whoever holds the desktop seat, and moves to the greeter the moment the
# screen locks or a remote session detaches — so an unattended run that
# relied on it loses acceleration part-way through, which shows up as
# emulators that never finish booting.
#
# A shell that was started before the user joined the group does not carry
# the membership yet; `sg` picks it up from the group database, so such a
# shell works without logging in again.
with_kvm() {
  if kvm_usable; then
    "$@"
  elif [ -e /dev/kvm ] && in_kvm_group_db; then
    sg kvm -c "$(printf '%q ' "$@")"
  else
    kvm_report || true
    die "no access to /dev/kvm"
  fi
}

kvm_report() {
  if [ ! -e /dev/kvm ]; then
    cat >&2 <<'MSG'
BLOCKED: this machine has no /dev/kvm, so the Android emulator cannot run.
On a Hyper-V guest that means nested virtualization is not exposed to it
(check: no vmx/svm in /proc/cpuinfo).

The kernel ships kvm-intel, so the only missing piece is host-side. On
the Windows host, with this VM SHUT DOWN:

    Set-VMProcessor -VMName <vm-name> -ExposeVirtualizationExtensions $true

Dynamic Memory can stay on. Microsoft's restriction applies while
Hyper-V itself runs inside the guest, and this guest runs KVM; measured
here with the balloon still growing under a live emulator.

Then boot the VM and re-run `tool/android/avd.sh doctor`.
MSG
    return 1
  fi
  if in_kvm_group_db; then
    if id -nG | tr ' ' '\n' | grep -qx kvm; then
      echo "access:     kvm group membership"
    else
      echo "access:     kvm group membership (this shell predates it; emulators are started through \`sg kvm\`)"
    fi
    return 0
  fi
  if kvm_usable; then
    cat <<'MSG'
access:     desktop-session ACL only. It works now and stops working when
            the screen locks or the remote desktop detaches, which is when
            unattended runs happen. Make it permanent:
                sudo usermod -aG kvm "$USER"
MSG
    return 0
  fi
  cat >&2 <<'MSG'
BLOCKED: /dev/kvm exists but this user cannot open it. Access so far came
from the desktop session's ACL, and that session is not the active one
(locked screen, detached remote desktop). Make it permanent:

    sudo usermod -aG kvm "$USER"

No new login is needed for these scripts afterwards.
MSG
  return 1
}

# --- reporting --------------------------------------------------------------

cmd_doctor() {
  echo "SDK:        $ANDROID_HOME"
  echo "AVD home:   $ANDROID_AVD_HOME"
  [ -x "$EMULATOR" ] || die "emulator package missing; run: sdkmanager --install emulator"
  echo "emulator:   $("$EMULATOR" -version 2>/dev/null | head -1)"
  echo "images:     $(cd "$ANDROID_HOME/system-images" 2>/dev/null && ls -d */* 2>/dev/null | tr '\n' ' ')"
  echo "avds:       $("$EMULATOR" -list-avds 2>/dev/null | tr '\n' ' ')"
  echo "free disk:  $(free_gb) GB"
  echo
  kvm_report || return 1
  with_kvm "$EMULATOR" -accel-check 2>&1 | grep -iE "kvm|accel" | sed 's/^/accel-check: /' || true
}

cmd_images() {
  local install=0 e api tag seen="" pkg dir
  [ "${1:-}" = "--install" ] && install=1
  for e in "${AVDS[@]}"; do
    IFS='|' read -r _ api tag_dev tag _ <<<"$e"
    case " $seen " in *" $api/$tag "*) continue ;; esac
    seen="$seen $api/$tag"
    pkg="$(image_pkg "$api" "$tag")"
    dir="$(image_dir "$api" "$tag")"
    if [ -d "$dir" ]; then
      printf 'present  %-52s %s\n' "$pkg" "$(du -sh "$dir" | cut -f1)"
    elif [ "$install" = 1 ]; then
      require_space "download a system image"
      echo "install  $pkg"
      yes | "$SDKMANAGER" --install "$pkg" >/dev/null \
        || die "sdkmanager could not install $pkg"
      sparsify "$dir"
      printf 'present  %-52s %s\n' "$pkg" "$(du -sh "$dir" | cut -f1)"
    else
      printf 'MISSING  %s\n' "$pkg"
    fi
  done
  [ "$install" = 1 ] || echo "(install the missing ones with: $0 images --install)"
}

# System images unpack as fully allocated files, though much of each is
# empty filesystem: the API 33 image takes 8.2 GB and holds 3 GB. Turning
# the zero-filled ranges into holes changes no byte the emulator reads and
# gave back 10 GB across the images used here. Safe to repeat.
sparsify() {
  local f
  for f in "$1"/*.img; do
    [ -f "$f" ] && fallocate --dig-holes "$f" 2>/dev/null || true
  done
}

cmd_disk() {
  echo "system images:"
  du -sh "$ANDROID_HOME"/system-images/*/* 2>/dev/null | sed 's/^/  /'
  echo "avds:"
  local n
  for n in $(names_in all); do
    avd_exists "$n" || continue
    printf '  %-6s %-26s %s\n' "$(du -sh "$(avd_dir "$n")" | cut -f1)" "$n" \
      "$(has_snapshot "$n" && echo "snapshot $(du -sh "$(avd_dir "$n")/snapshots/$SNAPSHOT" | cut -f1)" || true)"
  done
  echo "total:  $(du -shc "$ANDROID_HOME/system-images" "$ANDROID_AVD_HOME" 2>/dev/null | tail -1 | cut -f1)"
  echo "free:   $(free_gb) GB"
}

cmd_list() {
  local set="${1:-all}" n
  for n in $(names_in "$set"); do
    avd_exists "$n" && echo "$n"
  done
}

# --- creation ---------------------------------------------------------------

# Sets one key in an AVD config.ini, replacing any existing definitions
# rather than appending a second one — the file is read as last-wins, so a
# duplicate key works by accident and is a trap for the next edit.
set_ini() {
  local file="$1" key="$2" value="$3"
  sed -i "/^$(printf '%s' "$key" | sed 's/\./\\./g')=/d" "$file"
  printf '%s=%s\n' "$key" "$value" >> "$file"
}

# Settings every AVD needs regardless of its device profile. There is no GPU
# on this host, so rendering is software either way and saying so avoids a
# probe that fails; the host keyboard lets a test type. A hand AVD gets a
# roomy SD card for whatever someone copies onto it; a matrix AVD only ever
# holds a handful of fixture photos, and its card is part of every snapshot.
configure_one() {
  local name="$1" set
  IFS='|' read -r _ _ _ _ set <<<"$(entry_of "$name")"
  local cfg
  cfg="$(avd_dir "$name")/config.ini"
  [ -f "$cfg" ] || { echo "no config for $name" >&2; return 1; }
  set_ini "$cfg" hw.keyboard yes
  set_ini "$cfg" sdcard.size "$([ "$set" = matrix ] && echo 512M || echo 2048M)"
  set_ini "$cfg" hw.gpu.enabled yes
  set_ini "$cfg" hw.gpu.mode "$GPU_MODE"
  echo "configured: $name"
}

create_one() {
  local name="$1" api device tag
  IFS='|' read -r _ api device tag _ <<<"$(entry_of "$name")" \
    || die "not an AVD this script knows: $name"
  if avd_exists "$name"; then
    echo "exists:  $name"
    return 0
  fi
  if [ ! -d "$(image_dir "$api" "$tag")" ]; then
    echo "skip:    $name (missing $(image_pkg "$api" "$tag"); see: $0 images)" >&2
    return 0
  fi
  echo "create:  $name (API $api, $device, $tag)"
  echo "no" | "$AVDMANAGER" create avd \
    --name "$name" \
    --package "$(image_pkg "$api" "$tag")" \
    --device "$device" \
    --force >/dev/null 2>&1
  avd_exists "$name" || die "avdmanager did not create $name under $ANDROID_AVD_HOME"
  configure_one "$name"
}

cmd_create() {
  local what=("$@") n
  [ "${#what[@]}" -gt 0 ] || what=(hand)
  for w in "${what[@]}"; do
    case "$w" in
      hand|matrix|all) for n in $(names_in "$w"); do create_one "$n"; done ;;
      *) create_one "$w" ;;
    esac
  done
}

cmd_configure() {
  local n
  for n in $(names_in all); do
    avd_exists "$n" && configure_one "$n"
  done
}

# --- running ----------------------------------------------------------------

running_serials() { "$ADB" devices 2>/dev/null | awk '/^emulator-[0-9]+/{print $1}'; }

serial_of() { # avd name -> serial, if it is running
  local s
  for s in $(running_serials); do
    [ "$("$ADB" -s "$s" emu avd name 2>/dev/null | head -1 | tr -d '\r')" = "$1" ] \
      && { echo "$s"; return 0; }
  done
  return 1
}

# The console port; adb takes the next one up, so only even numbers.
free_port() {
  local p
  for p in $(seq 5554 2 5598); do
    "$ADB" devices 2>/dev/null | grep -q "^emulator-$p[[:space:]]" && continue
    ss -ltn 2>/dev/null | grep -qE "[:.]($p|$((p + 1)))[[:space:]]" && continue
    echo "$p"
    return 0
  done
  die "no free emulator port between 5554 and 5598"
}

# Parses the flags boot/start share into BOOT_* variables.
parse_boot_flags() {
  BOOT_HEADLESS=0 BOOT_PORT="" BOOT_PRISTINE=0 BOOT_EXTRA=() BOOT_CAMERA=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --headless) BOOT_HEADLESS=1 ;;
      --pristine) BOOT_PRISTINE=1 ;;
      --port) BOOT_PORT="${2:?--port needs a number}"; shift ;;
      --camera) BOOT_CAMERA="${2:?--camera needs an image}"; shift ;;
      --wipe) BOOT_EXTRA+=(-wipe-data -no-snapshot-load) ;;
      *) die "unknown flag: $1" ;;
    esac
    shift
  done
}

# Starts the emulator process for <name> and prints its serial on stdout.
# Everything else it says goes to stderr, so a caller can capture the serial.
start_one() {
  local name="$1"; shift
  local set
  IFS='|' read -r _ _ _ _ set <<<"$(entry_of "$name" || echo '||||hand')"
  avd_exists "$name" || die "no such AVD: $name (run: $0 create)"
  parse_boot_flags "$@"
  if s="$(serial_of "$name")"; then
    echo "$name is already running as $s" >&2
    echo "$s"
    return 0
  fi

  local args=(-avd "$name" -gpu "$GPU_MODE" -no-audio -no-boot-anim)
  local port="${BOOT_PORT:-$(free_port)}"
  args+=(-port "$port")
  # With no display the windowed emulator dies at startup, so a run from a
  # service or a bare SSH session goes headless without being asked. A
  # person at the desktop still gets the window unless they say otherwise.
  if [ "$BOOT_HEADLESS" = 1 ] || [ -z "${DISPLAY:-}" ]; then
    args+=(-no-window)
  fi
  if [ "$set" = matrix ]; then
    # Never let a run write itself into the AVD: the quick-boot snapshot
    # the emulator saves on exit would both cost a second snapshot's worth
    # of disk and become what the next run starts from.
    args+=(-no-snapshot-save)
    if [ "$BOOT_PRISTINE" = 1 ] && has_snapshot "$name"; then
      args+=(-snapshot "$SNAPSHOT")
    else
      args+=(-no-snapshot-load)
      if [ "$BOOT_PRISTINE" = 1 ]; then
        # Without a snapshot to return to, the only way to leave the AVD
        # as it was is to keep this run's writes off it altogether.
        echo "$name has no '$SNAPSHOT' snapshot; cold boot, read-only" >&2
        args+=(-read-only)
      fi
    fi
  fi
  # The back camera shows a still image: a QR label, so the live scanner
  # has something to read. Without it the camera shows a generated scene.
  if [ -n "$BOOT_CAMERA" ]; then
    [ -f "$BOOT_CAMERA" ] || die "no camera image at $BOOT_CAMERA"
    args+=(-camera-back "imagefile:$(realpath "$BOOT_CAMERA")")
  fi
  args+=("${BOOT_EXTRA[@]}")

  local log="${TMPDIR:-/tmp}/emulator-$name.log"
  local attempt
  for attempt in 1 2 3; do
    with_kvm nohup "$EMULATOR" "${args[@]}" >"$log" 2>&1 &
    # Several emulators probing KVM in the same second can each be told
    # there is no acceleration. The process exits at once when that
    # happens, so a short look is enough to tell and try again.
    sleep 6
    if grep -q "requires hardware acceleration" "$log" 2>/dev/null; then
      echo "$name: KVM probe failed (attempt $attempt), retrying" >&2
      sleep $((attempt * 4))
      continue
    fi
    echo "started $name on emulator-$port (log: $log)" >&2
    echo "emulator-$port"
    return 0
  done
  die "$name could not get hardware acceleration; see $log"
}

cmd_start() {
  local name="${1:?usage: $0 start <avd> [--headless] [--port N] [--pristine]}"; shift
  start_one "$name" "$@" >/dev/null
}

boot_one() {
  local name="$1"; shift
  SERIAL="$(start_one "$name" "$@")"
  echo -n "waiting for $name ($SERIAL)" >&2
  if wait_for_boot 150; then
    echo " — ready" >&2
    echo "$SERIAL"
    return 0
  fi
  echo >&2
  die "timed out waiting for $name to finish booting; see ${TMPDIR:-/tmp}/emulator-$name.log"
}

cmd_boot() {
  local name="${1:?usage: $0 boot <avd> [--headless] [--port N] [--pristine]}"; shift
  boot_one "$name" "$@"
}

stop_serial() {
  local s="$1"
  "$ADB" -s "$s" emu kill >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do
    "$ADB" devices 2>/dev/null | grep -q "^$s[[:space:]]" || return 0
    sleep 1
  done
  echo "WARNING: $s did not go away" >&2
}

cmd_stop() {
  local targets=("$@") t s
  if [ "${#targets[@]}" -eq 0 ]; then
    for s in $(running_serials); do
      echo "stopping $s"
      stop_serial "$s"
    done
    return 0
  fi
  for t in "${targets[@]}"; do
    case "$t" in
      emulator-*) s="$t" ;;
      *) s="$(serial_of "$t")" || { echo "$t is not running"; continue; } ;;
    esac
    echo "stopping $s"
    stop_serial "$s"
  done
}

cmd_serial() { serial_of "${1:?usage: $0 serial <avd>}" || die "$1 is not running"; }

# --- preparing a matrix AVD -------------------------------------------------

# What every automated run assumes about the device before the app starts.
# Animations off because a test that waits for the UI to settle should not
# be waiting on a transition; the rest keeps things that are not the app —
# a dimmed screen, a lock screen, a heads-up notification, the "swipe to
# exit full screen" hint — out of the screenshots.
#
# Each is allowed to fail: not every Android version has every command
# (API 24 has no `locksettings`), and a setting that does not exist cannot
# get in the way either.
apply_base_settings() {
  local k
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do
    adb_sh settings put global "$k" 0 || true
  done
  adb_sh svc power stayon true || true
  adb_sh settings put system screen_off_timeout 2147483647 || true
  adb_sh locksettings set-disabled true >/dev/null || true
  adb_sh wm dismiss-keyguard || true
  adb_sh settings put global heads_up_notifications_enabled 0 || true
  adb_sh settings put secure immersive_mode_confirmations confirmed || true
  adb_sh settings put system accelerometer_rotation 0 || true
}

prepare_one() {
  local name="$1" force="$2" snapshot="$3" set
  IFS='|' read -r _ _ _ _ set <<<"$(entry_of "$name")" || die "not an AVD this script knows: $name"
  [ "$set" = matrix ] || die "$name is a hand AVD; prepare wipes, and only matrix AVDs are disposable"
  create_one "$name"
  avd_exists "$name" || return 0
  local stamp
  stamp="$(avd_dir "$name")/.prepared"
  if [ -f "$stamp" ] && [ "$force" = 0 ]; then
    if [ "$snapshot" = 0 ] || has_snapshot "$name"; then
      echo "prepared: $name ($(cat "$stamp"))"
      return 0
    fi
  fi
  [ "$snapshot" = 1 ] && require_space "save a snapshot"
  serial_of "$name" >/dev/null 2>&1 && die "$name is running; stop it first"

  echo "prepare:  $name — wiping and booting for the first time"
  rm -rf "$(avd_dir "$name")/snapshots"
  SERIAL="$(start_one "$name" --headless --wipe)"
  wait_for_boot 200 || die "$name did not finish its first boot"

  # A first boot keeps working for minutes after it reports itself booted:
  # compiling system apps, scanning storage, verifying packages. Freezing
  # it mid-way would make every run from the snapshot start by finishing
  # that work, so wait for the device to go quiet.
  echo -n "          settling" >&2
  local load
  for _ in $(seq 1 36); do
    load="$(adb_sh cat /proc/loadavg | cut -d' ' -f1)" || load=9
    awk "BEGIN{exit !(${load:-9} < 1.0)}" && break
    echo -n "." >&2
    sleep 10
  done
  echo " (load ${load:-?})" >&2

  apply_base_settings
  if [ "$snapshot" = 1 ]; then
    adb_s emu avd snapshot save "$SNAPSHOT" >/dev/null \
      || die "could not save the $SNAPSHOT snapshot of $name"
  fi
  stop_serial "$SERIAL"
  date '+%Y-%m-%d %H:%M' > "$stamp"
  echo "prepared: $name ($(du -sh "$(avd_dir "$name")" | cut -f1)$([ "$snapshot" = 1 ] && echo ", with snapshot"))"
}

cmd_prepare() {
  local force=0 snapshot=1 targets=() a n
  for a in "$@"; do
    case "$a" in
      --force) force=1 ;;
      --no-snapshot) snapshot=0 ;;
      *) targets+=("$a") ;;
    esac
  done
  [ "${#targets[@]}" -gt 0 ] || die "usage: $0 prepare <avd>|matrix [--force] [--no-snapshot]"
  for a in "${targets[@]}"; do
    if [ "$a" = matrix ]; then
      for n in $(names_in matrix); do prepare_one "$n" "$force" "$snapshot"; done
    else
      prepare_one "$a" "$force" "$snapshot"
    fi
  done
}

case "${1:-doctor}" in
  doctor) cmd_doctor ;;
  images) shift; cmd_images "$@" ;;
  sparsify)
    for d in "$ANDROID_HOME"/system-images/*/*/x86_64; do sparsify "$d"; done
    echo "free: $(free_gb) GB" ;;
  disk) cmd_disk ;;
  create) shift; cmd_create "$@" ;;
  configure) cmd_configure ;;
  prepare) shift; cmd_prepare "$@" ;;
  list)   shift; cmd_list "$@" ;;
  start)  shift; cmd_start "$@" ;;
  boot)   shift; cmd_boot "$@" ;;
  stop)   shift; cmd_stop "$@" ;;
  serial) shift; cmd_serial "$@" ;;
  *) die "unknown command: $1" ;;
esac
