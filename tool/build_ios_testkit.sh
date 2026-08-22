#!/usr/bin/env bash
# Builds the iOS test kit (.ipa) for installing on physical iPhones.
#
# macOS + Xcode only: the iOS toolchain does not exist on Windows/Linux, so
# `flutter build ipa` is not even a registered subcommand there. Run this on a
# Mac or a macOS CI runner.
#
# Usage:
#   tool/build_ios_testkit.sh [--dev-tools] [--method <export-method>]
#
#   --dev-tools   Compile in the developer tooling (test-archive import,
#                 DB reinitialize, manual QR entry, SQL runner). Off by
#                 default, matching a store build.
#   --method      Xcode export method. Default: ad-hoc (installs on devices
#                 whose UDID is registered in the provisioning profile).
#                 Xcode 15.4+ renamed these: development -> debugging,
#                 ad-hoc -> release-testing, app-store -> app-store-connect.
#                 Use app-store/app-store-connect for a TestFlight upload.

set -euo pipefail

cd "$(dirname "$0")/.."

DEV_TOOLS=false
METHOD=ad-hoc

while [ $# -gt 0 ]; do
    case "$1" in
        --dev-tools) DEV_TOOLS=true; shift ;;
        --method) METHOD="${2:?--method needs a value}"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done

if [ "$(uname -s)" != "Darwin" ]; then
    echo "This script needs macOS with Xcode: the iOS toolchain is unavailable" >&2
    echo "on $(uname -s), where 'flutter build ipa' does not exist." >&2
    exit 1
fi

if ! xcodebuild -version >/dev/null 2>&1; then
    echo "Xcode command line tools not ready. Install Xcode, then run:" >&2
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
fi

# Signing must be configured once in Xcode (Runner > Signing & Capabilities >
# Team); the project ships without a team so it cannot be committed per-machine.
if ! grep -q 'DEVELOPMENT_TEAM' ios/Runner.xcodeproj/project.pbxproj; then
    echo "NOTE: no DEVELOPMENT_TEAM in the Xcode project yet."
    echo "      Open ios/Runner.xcworkspace in Xcode, select the Runner target,"
    echo "      and pick your team under Signing & Capabilities (automatic"
    echo "      signing). Without it the archive step cannot sign the app."
    echo
fi

# The test archive is bundled into every build; for a test kit that may be
# deliberate (on-device demo data), so report rather than refuse.
archive_files=$(find assets/test_archive -type f ! -name '.gitkeep' 2>/dev/null || true)
if [ -n "$archive_files" ]; then
    echo "NOTE: assets/test_archive is not empty - it will be bundled into the"
    echo "      .ipa (adds its full size to the app):"
    echo "$archive_files" | sed 's/^/        /'
    echo
fi

echo "Dev tooling: $DEV_TOOLS"
echo "Export method: $METHOD"
echo

flutter build ipa --release     --dart-define=DEV_TOOLS="$DEV_TOOLS"     --export-method "$METHOD"

ipa=$(find build/ios/ipa -name '*.ipa' -maxdepth 1 2>/dev/null | head -1)
echo
if [ -n "$ipa" ]; then
    echo "Test kit: $ipa ($(du -h "$ipa" | cut -f1))"
    echo
    echo "Install it on an iPhone with ONE of:"
    echo "  * Apple Configurator (Mac App Store): connect the iPhone, drag the"
    echo "    .ipa onto the device. The device UDID must be in the profile."
    echo "  * Xcode > Window > Devices and Simulators > select device >"
    echo "    'Installed Apps' > + > pick the .ipa."
    echo "  * TestFlight (built with --method app-store): upload the .ipa via"
    echo "    Xcode Organizer or 'xcrun altool', then testers install from the"
    echo "    TestFlight app - no UDID registration, no cable."
else
    echo "Build finished but no .ipa was found under build/ios/ipa." >&2
    exit 1
fi
