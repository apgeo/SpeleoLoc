#!/usr/bin/env bash
# Run tiers of the test matrix on a schedule, from this user's crontab.
#
#   tool/matrix/schedule.sh install ring     # Sundays 03:17
#   tool/matrix/schedule.sh install full     # first Saturday of the month, 01:07
#   tool/matrix/schedule.sh remove [ring|full]
#   tool/matrix/schedule.sh status
#
# ring is meant to run weekly, never nightly, and only once it has been
# green on demand for a week. full is a milestone run; scheduling it is for
# a stretch of work with many milestones.
#
# Cron starts with almost no environment, so the entry carries the PATH the
# tools need. Emulators run headless and reach /dev/kvm through the kvm
# group, which — unlike the desktop session's ACL — holds without anyone
# logged in. Output goes to build/matrix/cron.log; each run's report is in
# build/matrix/<run>/ as usual.
set -euo pipefail

cd "$(dirname "$0")/../.."
ROOT="$PWD"
MARK="# speleoloc test matrix:"

entry() { # tier -> crontab line
  local when
  case "$1" in
    ring) when="17 3 * * 0" ;;
    full) when="7 1 1-7 * 6" ;;
    *) echo "unknown tier: $1" >&2; exit 64 ;;
  esac
  local path="$(dirname "$(command -v flutter)"):$(dirname "$(command -v dart)"):/usr/local/bin:/usr/bin:/bin"
  echo "$when cd $ROOT && PATH=$path tool/test_matrix.sh --tier $1 >> build/matrix/cron.log 2>&1 $MARK $1"
}

current() { crontab -l 2>/dev/null || true; }

case "${1:-status}" in
  install)
    tier="${2:?usage: $0 install ring|full}"
    id -nG | tr ' ' '\n' | grep -qx kvm || getent group kvm | grep -q "$(id -un)" || {
      echo "the user is not in the kvm group; emulators would not start from cron:" >&2
      echo "  sudo usermod -aG kvm \"\$USER\"" >&2
      exit 1
    }
    { current | grep -vF "$MARK $tier"; entry "$tier"; } | crontab -
    echo "scheduled: $(entry "$tier" | cut -d' ' -f1-5) — $tier"
    ;;
  remove)
    if [ -n "${2:-}" ]; then
      current | grep -vF "$MARK $2" | crontab -
    else
      current | grep -vF "$MARK" | crontab -
    fi
    echo "removed"
    ;;
  status)
    lines="$(current | grep -F "$MARK" || true)"
    if [ -z "$lines" ]; then
      echo "nothing scheduled"
    else
      echo "$lines" | sed -E "s/ cd .*$MARK / — /"
    fi
    ;;
  *) echo "usage: $0 install ring|full | remove [ring|full] | status" >&2; exit 64 ;;
esac
