#!/usr/bin/env bash
# Put a device into one of the conditions a phone meets in the field, or
# back out of all of them.
#
# A caving app spends hours in a pocket: out of coverage, with the battery
# saver on, sometimes with the process killed underneath it, sometimes
# carried across a time-zone or daylight-saving boundary between taking a
# photo and logging the trip. Each of these is one command from outside
# and a class of bug that no amount of screen-opening finds.
#
# Usage:
#   tool/android/platform_state.sh <state> [serial]
#   tool/android/platform_state.sh reset [serial]
#   tool/android/platform_state.sh states          # list them
#
# States:
#   offline           no Wi-Fi and no mobile data
#   battery_saver     battery saver on, as if unplugged
#   doze              the device forced into deep idle
#   tz_utc            system time zone UTC
#   tz_bucharest      system time zone Europe/Bucharest
#   tz_far_east       system time zone Pacific/Auckland (a day ahead of UTC
#                     for half of it — the case that moves a date)
#   locale_ro         system language Romanian (dates and numbers formatted
#                     by the system follow it)
#   locale_en         system language English (US)
#
# Not here because they act on a running app rather than set a condition:
# killing the process and reinstalling over old data. See run_cell.sh.
set -euo pipefail

. "$(dirname "$0")/lib.sh"

STATES=(offline battery_saver doze tz_utc tz_bucharest tz_far_east locale_ro locale_en)

# Time zone and locale are system properties an ordinary shell may not set;
# the emulator images used here allow adb to become root, a real phone does
# not, so say which it was.
as_root() {
  adb_s root >/dev/null 2>&1 || true
  sleep 2
  "$ADB" -s "$SERIAL" wait-for-device
  [ "$(adb_sh id -u)" = "0" ]
}

set_timezone() {
  as_root || { echo "unsupported: setting the time zone needs root on $SERIAL"; return 0; }
  adb_sh setprop persist.sys.timezone "$1"
  adb_sh am broadcast -a android.intent.action.TIMEZONE_CHANGED >/dev/null
  echo "applied: time zone $1"
}

set_locale() {
  as_root || { echo "unsupported: setting the system language needs root on $SERIAL"; return 0; }
  adb_sh settings put system system_locales "$1"
  adb_sh setprop persist.sys.locale "$1"
  # The system language is read at start-up; restart the framework so
  # every process sees it.
  adb_sh "stop; start"
  sleep 5
  wait_for_boot 90 || die "$SERIAL did not come back after the language change"
  echo "applied: system language $1"
}

apply() {
  case "$1" in
    offline)
      adb_sh svc wifi disable
      adb_sh svc data disable
      echo "applied: offline" ;;
    battery_saver)
      adb_sh dumpsys battery unplug >/dev/null
      adb_sh settings put global low_power 1
      echo "applied: battery saver" ;;
    doze)
      adb_sh dumpsys battery unplug >/dev/null
      adb_sh dumpsys deviceidle force-idle >/dev/null
      echo "applied: doze" ;;
    tz_utc) set_timezone UTC ;;
    tz_bucharest) set_timezone Europe/Bucharest ;;
    tz_far_east) set_timezone Pacific/Auckland ;;
    locale_ro) set_locale ro-RO ;;
    locale_en) set_locale en-US ;;
    *) die "no such state: $1 (see: $0 states)" ;;
  esac
}

reset() {
  adb_sh svc wifi enable
  adb_sh svc data enable
  adb_sh settings put global low_power 0
  adb_sh dumpsys deviceidle unforce >/dev/null 2>&1 || true
  adb_sh dumpsys battery reset >/dev/null
  echo "applied: network on, battery saver off, charging state restored"
}

case "${1:-}" in
  states) printf '%s\n' "${STATES[@]}" ;;
  reset) use_serial "${2:-}"; reset ;;
  "") die "usage: $0 <state>|reset|states [serial]" ;;
  *) use_serial "${2:-}"; apply "$1" ;;
esac
