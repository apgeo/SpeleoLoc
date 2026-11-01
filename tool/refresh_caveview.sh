#!/usr/bin/env bash
# Vendors a build of the SilexGIS fork of CaveView.js into assets/caveview/.
#
# The build is made from the named fork commit (via `git archive`, never the
# checkout's working tree or its own build/ folder), so what ships is exactly
# what that commit builds. Only what the 3D viewer screen loads is copied: the
# minified bundle, its stylesheet, the logo and the Romanian catalogue. The
# terrain and PLY workers stay out — the app shows no terrain and reads only
# .lox and .3d, which the bundle parses on the page's own thread.
#
# A version directory is never replaced in place: a change in the fork is a new
# 2.9.0-slx.<n> stamp there and a new directory here. The previous directory is
# removed, so one version ships at a time.
#
# Usage:
#   tool/refresh_caveview.sh <fork-commit>
#   CAVEVIEW_REPO=/path/to/checkout tool/refresh_caveview.sh <fork-commit>
#
# Afterwards: point pubspec.yaml's assets/caveview/v<version>/ entries and
# CaveViewAssets.version at the new directory, run
# flutter test test/services/cave_model/, and commit the refresh on its own.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <fork-commit>" >&2
  exit 2
fi

UPSTREAM="${CAVEVIEW_REPO:-/home/devuser1/projects/caveview}"
COMMIT="$(git -C "$UPSTREAM" rev-parse --verify "$1^{commit}")"
export PATH="$HOME/.local/opt/node24/bin:$PATH"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

git -C "$UPSTREAM" archive "$COMMIT" | tar -x -C "$STAGE"
VERSION="$(node -p "require('$STAGE/package.json').version")"
[[ "$VERSION" == *-slx.* ]] || {
  echo "$COMMIT is version $VERSION, not a 2.9.0-slx.<n> distribution stamp" >&2
  exit 1
}

(cd "$STAGE" && npm ci --no-audit --no-fund >/dev/null && nice -n 19 npm run build >/dev/null)
grep -q "\"$VERSION\"" "$STAGE/build/CaveView/js/CaveView2.min.js" || {
  echo "the built bundle does not carry the version $VERSION" >&2
  exit 1
}

DEST="assets/caveview/v$VERSION"
if [[ -e "$DEST" ]]; then
  echo "$DEST already exists; a build is never replaced in place" >&2
  exit 1
fi
for old in assets/caveview/v*/; do
  [[ -d "$old" ]] && rm -rf "$old"
done

BUILT="$STAGE/build/CaveView"
FILES=(js/CaveView2.min.js css/caveview.css images/logo.svg lib/lang-ro.json)
for f in "${FILES[@]}"; do
  mkdir -p "$DEST/$(dirname "$f")"
  cp "$BUILT/$f" "$DEST/$f"
done

{
  echo "CaveView.js, SilexGIS fork, bundled with three.js, proj4, wkt-parser,"
  echo "mgrs, x18n and observable_js. All MIT."
  for lic in "$STAGE/LICENSE" "$STAGE"/node_modules/{three,proj4,wkt-parser,x18n}/LICENSE*; do
    echo
    echo "==== ${lic#"$STAGE"/}"
    cat "$lic"
  done
} > "$DEST/LICENSES.txt"

{
  echo "version $VERSION"
  echo "commit $COMMIT"
  (cd "$DEST" && sha256sum "${FILES[@]}" LICENSES.txt)
} > "$DEST/BUILD.txt"

echo "Vendored CaveView $VERSION from $COMMIT into $DEST"
