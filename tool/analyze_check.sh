#!/usr/bin/env bash
# `flutter analyze`, judged against the recorded backlog instead of zero.
#
# The tree carries a known backlog of analyzer infos and warnings, and
# `flutter analyze` exits non-zero on any of them — so taking its exit code
# at face value makes every check that runs it permanently red, and a
# permanently red check is one nobody reads. What a change must not do is
# ADD to that backlog: an error always fails, and the issue count is held
# against tool/analyze_baseline.txt.
#
# Usage:
#   tool/analyze_check.sh                     # local and CI
#   tool/analyze_check.sh --update-baseline   # after the backlog shrinks
#
# The count depends on the Flutter version's lint set, which is why CI pins
# the same version as the machine the baseline was recorded on.
set -euo pipefail
cd "$(dirname "$0")/.."

BASELINE=tool/analyze_baseline.txt
out="$(flutter analyze --no-pub 2>&1 || true)"
errors="$(printf '%s\n' "$out" | grep -cE '^ *error ' || true)"
count="$(printf '%s\n' "$out" | sed -nE 's/^([0-9]+) issues? found.*/\1/p' | tail -1)"
count="${count:-0}"

if [ "${1:-}" = "--update-baseline" ]; then
  echo "$count" > "$BASELINE"
  echo "analyze baseline set to $count"
fi
baseline="$(cat "$BASELINE" 2>/dev/null || echo 0)"

if [ "$errors" -gt 0 ]; then
  printf '%s\n' "$out" | grep -E '^ *error ' >&2
  echo "analyze: $errors error(s)" >&2
  exit 1
fi
if [ "$count" -gt "$baseline" ]; then
  echo "analyze: $count issues, up from the baseline of $baseline — this change added some:" >&2
  echo "  run \`flutter analyze\` and fix what is new" >&2
  exit 1
fi
echo "analyze: $count issues, none of them errors (baseline $baseline)"
if [ "$count" -lt "$baseline" ]; then
  echo "  the backlog shrank; lower the baseline with: tool/analyze_check.sh --update-baseline"
fi
