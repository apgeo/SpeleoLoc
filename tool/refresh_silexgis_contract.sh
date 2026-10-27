#!/usr/bin/env bash
# Refreshes the mirrored SilexGIS sync contract from one named upstream commit,
# then runs the manifest guard.
#
# The copy is taken from the commit, not from the checkout's working tree, so
# uncommitted upstream edits never reach the mirror. Both trees are deleted
# before the copy so a file renamed or removed upstream does not linger. The
# app-owned files in docs/integrations/silexgis/ are kept.
#
# Usage:
#   tool/refresh_silexgis_contract.sh <silexgis-commit>
#   SILEXGIS_REPO=/path/to/checkout tool/refresh_silexgis_contract.sh <commit>
#
# Afterwards: read the new CHANGELOG.md entries, run the fixture replays
# (flutter test test/services/silexgis/), and commit the refresh on its own.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <silexgis-commit>" >&2
  exit 2
fi

UPSTREAM="${SILEXGIS_REPO:-/home/devuser1/projects/silexgis/silexgis}"
COMMIT="$(git -C "$UPSTREAM" rev-parse --verify "$1^{commit}")"

DOCS_DIR=docs/integrations/silexgis
DATA_DIR=test_data/silexgis_contract/v1
# Written here, not upstream; everything else in DOCS_DIR is a copy.
APP_OWNED=(00-this-copy.md found-defects.md)

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

git -C "$UPSTREAM" archive "$COMMIT" docs/speleoloc-sync contract/speleoloc-sync/v1 \
  | tar -x -C "$STAGE"

for f in "$DOCS_DIR"/*; do
  keep=0
  for owned in "${APP_OWNED[@]}"; do
    [[ "$(basename "$f")" == "$owned" ]] && keep=1
  done
  [[ $keep -eq 1 ]] || rm -rf "$f"
done
cp -r "$STAGE"/docs/speleoloc-sync/. "$DOCS_DIR"/

rm -rf "$DATA_DIR"
mkdir -p "$DATA_DIR"
cp -r "$STAGE"/contract/speleoloc-sync/v1/. "$DATA_DIR"/

sed -i -E "s/^Copied at upstream commit \`[0-9a-f]{40}\`/Copied at upstream commit \`$COMMIT\`/" \
  "$DOCS_DIR/00-this-copy.md"
grep -q "$COMMIT" "$DOCS_DIR/00-this-copy.md" || {
  echo "00-this-copy.md: the commit line was not found; update it by hand" >&2
  exit 1
}

echo "Mirrored SilexGIS $COMMIT (digest $(jq -r .digest "$DATA_DIR/manifest.json"))"
flutter test test/services/silexgis/contract_manifest_test.dart
