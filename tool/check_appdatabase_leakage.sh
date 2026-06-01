#!/usr/bin/env bash
# Guardrail: the global `appDatabase` may only be referenced from
# lib/data/, lib/services/ and lib/main.dart during the migration
# towards full Riverpod injection (see docs/REFACTORING_PLAN.md, PR 2).
#
# A baseline file tracks the call-sites that already existed when the
# guardrail was introduced. New leakages outside the allowed roots
# cause this script to exit non-zero so CI fails the PR.
#
# To regenerate the baseline after legitimately removing call-sites:
#   bash tool/check_appdatabase_leakage.sh --update-baseline
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASELINE="$ROOT/tool/appdatabase_leakage_baseline.txt"

# Allowed locations: data layer, services layer, and main.dart bootstrap.
ALLOWED='^lib/(data/|services/|main\.dart$)'

cd "$ROOT"

# Collect current call-sites (file paths) outside the allowed roots.
current=$(grep -RIl --include='*.dart' \
            --exclude-dir='build' \
            --exclude='*.g.dart' \
            -E 'appDatabase\.' lib \
          | grep -vE "$ALLOWED" \
          | LC_ALL=C sort -u || true)

if [[ "${1:-}" == "--update-baseline" ]]; then
  printf '%s\n' "$current" > "$BASELINE"
  echo "Baseline updated:"
  printf '  %s\n' $current
  exit 0
fi

if [[ ! -f "$BASELINE" ]]; then
  echo "Missing baseline file: $BASELINE" >&2
  exit 2
fi

baseline=$(LC_ALL=C sort -u "$BASELINE")
new_leaks=$(comm -23 <(printf '%s\n' "$current") <(printf '%s\n' "$baseline") || true)

if [[ -n "${new_leaks// /}" ]]; then
  echo "::error::New global appDatabase. references found outside the allowed roots:"
  printf '  %s\n' $new_leaks
  echo
  echo "Migrate them to a repository / provider (see docs/REFACTORING_PLAN.md, PR 2)."
  echo "If the file is legitimately a new data-layer or service-layer file,"
  echo "place it under lib/data/ or lib/services/."
  exit 1
fi

removed=$(comm -13 <(printf '%s\n' "$current") <(printf '%s\n' "$baseline") || true)
if [[ -n "${removed// /}" ]]; then
  echo "Note: baseline contains entries no longer present:"
  printf '  %s\n' $removed
  echo "Run 'bash tool/check_appdatabase_leakage.sh --update-baseline' to clean it up."
fi

echo "appDatabase leakage check passed (no new call-sites)."
