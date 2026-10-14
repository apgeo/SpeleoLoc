#!/usr/bin/env bash
# Checks a release build for the things that fail at the store or in the
# field rather than in a test: native libraries that will not load on a
# phone with 16 KB memory pages, a permission that crept in through a
# plugin, test data riding along in the bundle.
#
# Usage:
#   tool/matrix/release_gates.sh                 # build a release APK and check it
#   tool/matrix/release_gates.sh --apk FILE      # check an existing build
#   tool/matrix/release_gates.sh --record        # accept today's permission list
#
# Writes build/matrix/release_gates.md. Exit code 0 when every gate passes.
#
# The gates:
#   16k-zip     every native library is stored uncompressed on a 16 KB
#               boundary in the APK (zipalign -P 16)
#   16k-elf     every 64-bit native library's loadable segments are 16 KB
#               aligned — Google Play requires both for apps targeting
#               Android 15+. 32-bit libraries are not checked: no 32-bit
#               device uses 16 KB pages, and Play's rule covers 64-bit only.
#   permissions the permissions the built app declares, after every plugin's
#               manifest is merged in, match tool/matrix/permissions.allow
#   no-test-data nothing from assets/test_archive/ besides its .gitkeep is
#               bundled — whatever sits in that folder ships in every build
set -euo pipefail

cd "$(dirname "$0")/../.."
. tool/android/lib.sh

APK="" RECORD=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --apk) APK="$2"; shift ;;
    --record) RECORD=1 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

BUILD_TOOLS="$(ls -d "$ANDROID_HOME"/build-tools/* | sort -V | tail -1)"
ZIPALIGN="$BUILD_TOOLS/zipalign"
AAPT2="$BUILD_TOOLS/aapt2"
READELF="$(ls "$ANDROID_HOME"/ndk/*/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf 2>/dev/null | sort -V | tail -1)"
ALLOW=tool/matrix/permissions.allow
OUT=build/matrix/release_gates.md

if [ -z "$APK" ]; then
  echo "building a release APK (signed with the debug key unless key.properties exists)"
  # Not --no-pub: `pub get` is what rewrites the plugin registrant, and the
  # test builds leave one behind that registers the test-only
  # integration_test plugin, which a release build cannot compile.
  flutter build apk --release \
    --dart-define-from-file=build_settings.store.json >/dev/null
  APK=build/app/outputs/flutter-apk/app-release.apk
fi
[ -f "$APK" ] || die "no APK at $APK"

declare -A RESULT DETAIL
pass() { RESULT[$1]=pass; DETAIL[$1]="$2"; }
fail() { RESULT[$1]=FAIL; DETAIL[$1]="$2"; }

# --- 16 KB pages ------------------------------------------------------------
if "$ZIPALIGN" -c -P 16 4 "$APK" >/dev/null 2>&1; then
  pass 16k-zip "native libraries are stored uncompressed and 16 KB aligned"
else
  bad="$("$ZIPALIGN" -c -P 16 -v 4 "$APK" 2>&1 | grep -E '\.so.*BAD' | sed -E 's/.*lib\//lib\//; s/ .*//' | sort -u | head -8 | tr '\n' ' ')"
  fail 16k-zip "not 16 KB aligned in the APK: ${bad:-see zipalign -c -P 16 -v 4}"
fi

work="$(mktemp -d)"
trap 'rm -rf "${work:?}"' EXIT
unzip -q -o "$APK" 'lib/*' -d "$work" 2>/dev/null || true
misaligned=()
total=0
while IFS= read -r so; do
  total=$((total + 1))
  # The smallest alignment of any LOAD segment; 2**14 is 16 KB.
  min="$("$READELF" -lW "$so" 2>/dev/null | awk '$1=="LOAD"{print $NF}' | sort -u | head -1)"
  [ -n "$min" ] || continue
  if [ "$((min))" -lt 16384 ]; then
    misaligned+=("${so#"$work"/} ($min)")
  fi
done < <(find "$work/lib/arm64-v8a" "$work/lib/x86_64" -name '*.so' 2>/dev/null)
if [ "$total" -eq 0 ]; then
  pass 16k-elf "no native libraries"
elif [ "${#misaligned[@]}" -eq 0 ]; then
  pass 16k-elf "$total 64-bit native libraries, every LOAD segment 16 KB aligned"
else
  fail 16k-elf "${#misaligned[@]} of $total libraries with 4 KB segments: $(printf '%s; ' "${misaligned[@]:0:8}")"
fi

# --- permissions ------------------------------------------------------------
"$AAPT2" dump permissions "$APK" 2>/dev/null \
  | sed -nE "s/^uses-permission: name='([^']+)'.*/\1/p" | sort -u > "$work/permissions"
if [ "$RECORD" = 1 ] || [ ! -f "$ALLOW" ]; then
  {
    echo "# Permissions the release build declares, after every plugin's manifest"
    echo "# is merged in. tool/matrix/release_gates.sh fails when this changes:"
    echo "# a plugin update can add one that the store then lists and asks"
    echo "# users about. Accept a deliberate change with --record."
    cat "$work/permissions"
  } > "$ALLOW"
  pass permissions "recorded $(wc -l < "$work/permissions") permissions in $ALLOW"
else
  grep -vE '^#|^$' "$ALLOW" | sort -u > "$work/allowed"
  added="$(comm -13 "$work/allowed" "$work/permissions" | tr '\n' ' ')"
  removed="$(comm -23 "$work/allowed" "$work/permissions" | tr '\n' ' ')"
  if [ -z "$added$removed" ]; then
    pass permissions "$(wc -l < "$work/permissions") permissions, as recorded"
  else
    fail permissions "added: ${added:-none}; removed: ${removed:-none}"
  fi
fi

# --- test data --------------------------------------------------------------
bundled="$(unzip -l "$APK" | awk '{print $4}' \
  | grep '^assets/flutter_assets/assets/test_archive/' \
  | grep -v '/\.gitkeep$' | grep -v '/$' || true)"
if [ -z "$bundled" ]; then
  pass no-test-data "assets/test_archive/ is empty in the bundle"
else
  fail no-test-data "bundled from assets/test_archive/: $(echo "$bundled" | sed 's|.*/||' | tr '\n' ' ')— empty that folder before a store build"
fi

# --- report -----------------------------------------------------------------
status=0
mkdir -p "$(dirname "$OUT")"
{
  echo "# Release gates"
  echo
  echo "Build: \`$APK\`, $(du -h "$APK" | cut -f1)."
  echo
  echo "| Gate | Result | Detail |"
  echo "|---|---|---|"
  for gate in 16k-zip 16k-elf permissions no-test-data; do
    echo "| $gate | ${RESULT[$gate]} | ${DETAIL[$gate]} |"
    [ "${RESULT[$gate]}" = pass ] || status=1
  done
} > "$OUT"
cat "$OUT"

# Every release that passes is kept by version, so the next one can be
# checked as an update from it (tool/android/upgrade_check.sh).
if [ "$status" = 0 ]; then
  version="$(sed -nE 's/^version: *([^ ]+).*/\1/p' pubspec.yaml)"
  mkdir -p "build_archive/apk/$version"
  cp "$APK" "build_archive/apk/$version/app-release.apk"
  echo "kept: build_archive/apk/$version/app-release.apk"
fi
exit "$status"
