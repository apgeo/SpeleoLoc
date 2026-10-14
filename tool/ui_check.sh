#!/usr/bin/env bash
# One command to check the UI, for a person or an agent iterating on a change.
#
# Runs the cheap layers first and always: analysis held against its
# recorded backlog, the layout and golden widget tests. Then the `pulse`
# tier of the test matrix: every core screen in every phone shape on the
# app's Linux build, and the same screens plus the media flow on one
# Android emulator, which it boots itself.
#
# Usage:
#   tool/ui_check.sh                  # everything above
#   tool/ui_check.sh --no-device      # skip the emulator half
#   tool/ui_check.sh --update-goldens # after an intentional UI change
#   tool/ui_check.sh --update-analyze-baseline
#
# To run on another dataset than the invented fixture — an anonymized
# export, say — point it at that archive:
#   SPELEO_TEST_ARCHIVE=/path/to/curated.zip tool/ui_check.sh
# Output from an archive that is not marked invented or anonymized is
# flagged as not for an agent to read.
#
# The wider tiers, for a finished feature or a release:
#   tool/test_matrix.sh --tier ring
#   tool/test_matrix.sh --tier full
set -euo pipefail

cd "$(dirname "$0")/.."

WANT_DEVICE=1
GOLDEN_ARGS=()
ANALYZE_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --no-device) WANT_DEVICE=0 ;;
    --update-goldens) GOLDEN_ARGS+=(--update-goldens) ;;
    --update-analyze-baseline) ANALYZE_ARGS+=(--update-baseline) ;;
    *) echo "unknown flag: $arg" >&2; exit 64 ;;
  esac
done

status=0
step() { echo; echo "=== $* ==="; }

step "analyze"
tool/analyze_check.sh "${ANALYZE_ARGS[@]}" || status=1

step "ui lint: hard-coded strings, icon buttons without a tooltip"
python3 tool/ui_lint.py || status=1

step "layout across device profiles"
flutter test --no-pub test/widgets/trip_media_layout_test.dart || status=1

step "golden images"
flutter test --no-pub "${GOLDEN_ARGS[@]}" test/widgets/trip_media_golden_test.dart || status=1

step "test matrix: pulse"
matrix_args=(--tier pulse)
[ "$WANT_DEVICE" = 1 ] || matrix_args+=(--only desktop)
[ -n "${SPELEO_TEST_ARCHIVE:-}" ] && matrix_args+=(--archive "$SPELEO_TEST_ARCHIVE")
matrix_status=0
tool/test_matrix.sh "${matrix_args[@]}" || matrix_status=$?
case "$matrix_status" in
  0) ;;
  2) echo "the matrix could not run everything it was asked to; see the report's NOT RUN section" ;;
  *) status=1 ;;
esac
[ "$WANT_DEVICE" = 1 ] || echo "device half: skipped (--no-device)"

exit "$status"
