#!/usr/bin/env bash
# Run a tier of the test matrix.
#
#   tool/test_matrix.sh --tier pulse   every change            ~10 min
#   tool/test_matrix.sh --tier ring    a finished feature      ~45 min
#   tool/test_matrix.sh --tier full    a milestone, a release  hours
#
# The long names work too: pulse-minimal-avd, ring-medium-avd, full-avd.
#
# Each tier has a desktop half (the app's Linux build, every screen shape)
# and an Android half (emulators). Useful narrower runs:
#
#   tool/test_matrix.sh --tier ring --only desktop
#   tool/test_matrix.sh --tier ring --avd speleo_mx_api33
#   tool/test_matrix.sh --tier pulse --flows smoke
#   tool/test_matrix.sh plan --tier full        # what would run, nothing started
#
# Results land in build/matrix/<run>/ with report.md at the top;
# build/matrix/latest points at the newest run. tool/matrix/tiers.json says
# what each tier contains.
#
# Exit code: 0 passed, 1 something failed, 2 part of the tier could not run.
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-}" in
  plan|report|run) exec python3 tool/matrix/matrix.py "$@" ;;
  *) exec python3 tool/matrix/matrix.py run "$@" ;;
esac
