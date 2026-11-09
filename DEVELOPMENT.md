# Development environment

This is the developer-facing setup guide. The user documentation is the wiki in
[`docs/`](docs/README.md); nothing here is needed to *use* SpeleoLoc, only to build it.

Written against Ubuntu 26.04 on 2026-08-31 and verified end to end on that date by running the
project's own CI gate. Every tool below installs into your home directory except the system build
libraries, so nothing here needs root beyond `apt-get`, and nothing collides with a distro package.

## What gets installed, and what it costs

| | Version installed | Size | Needed for |
|---|---|---|---|
| Flutter SDK (stable) | 3.47.2 | ~1.5 GB after first run | everything |
| Dart 3.13.2 | bundled with Flutter | — | `dart format`, `dart test` |
| Linux desktop toolchain | clang, cmake, ninja, GTK 3 headers | ~400 MB | host tests (`flutter test`); **not** a runnable desktop build — see below |
| OpenJDK | 17 | ~350 MB | Android Gradle builds only |
| Android command-line tools | 22.0 | ~180 MB | Android builds only |
| Android platform + build-tools | android-36, build-tools 37.0.0 | ~1.5 GB | Android builds only |

**The Android half is optional for most work.** `flutter test` runs on the host, so the sync engine,
HTTP client, database layer and archive logic can all be built and tested without an Android SDK or a
phone — widget tests included, which is how the screens are checked here. Install phase 2 when you
reach the camera, BLE beacon or GPS code, which cannot be exercised on a desktop.

⚠️ **`flutter run -d linux` does not work in this project, and an earlier revision of this file said
it did.** The `linux/` directory exists, but `flutter_sound` ships no Linux implementation and its
plugin CMake references a target that is never defined, so the build fails at the generate step:

```
$<TARGET_FILE:flutter_sound_plugin>
  No target "flutter_sound_plugin"
```

Nothing short of dropping or replacing that dependency fixes it. Two smaller gaps sit in front of it
and are worth fixing anyway, because they block the desktop build before it reaches this one — add
`libsecret-1-dev libjsoncpp-dev` (for `flutter_secure_storage`) and `libcurl4-openssl-dev` (for
`sentry-native`) to the apt line above if you want to get that far.

---

## Phase 1 — Flutter and the Linux desktop target

```bash
# System build libraries (the only step needing root)
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-14-dev curl git unzip xz-utils zip

# Flutter, as a userspace checkout so 'flutter upgrade' works and no root is involved
mkdir -p ~/.local/opt
git clone --depth 1 -b stable https://github.com/flutter/flutter.git ~/.local/opt/flutter
```

`libstdc++-14-dev` tracks the distro's GCC. If apt cannot find it, run `apt-cache search
'^libstdc++-[0-9]+-dev$'` and take the highest available — or just run `flutter doctor`, which names
whatever is missing.

### Put it on PATH — in three places, not one

```bash
echo 'export PATH="$HOME/.local/opt/flutter/bin:$PATH"' >> ~/.profile
echo 'export PATH="$HOME/.local/opt/flutter/bin:$PATH"' >> ~/.bashrc
```

**If you drive this repository with an agent (Claude Code or similar), a shell-profile edit is not
enough.** Agent tool calls run in non-interactive shells, which never read `.bashrc`, so `flutter`
stays invisible to them however well it works in your terminal. Add it to the agent's own
environment as well — for Claude Code that is the `env.PATH` entry in `~/.claude/settings.json`:

```json
{
  "env": {
    "PATH": "/home/YOU/.local/opt/flutter/bin:/usr/local/bin:/usr/bin:/bin",
    "ANDROID_HOME": "/home/YOU/.local/opt/android-sdk"
  }
}
```

Keep whatever was already in that string and prepend to it; do not replace it.

### Verify

```bash
flutter --version          # Dart must satisfy pubspec.yaml's 'sdk:' constraint
flutter config --no-analytics
flutter doctor -v
```

The first `flutter` command downloads the Dart SDK and engine artifacts and takes a few minutes.
Android and Chrome will report red until you do phase 2; the Linux toolchain and Flutter itself
should be green.

---

## Phase 2 — Android (only when you need a device build)

```bash
sudo apt-get install -y openjdk-17-jdk
```

**Java 17 specifically** — `android/app/build.gradle.kts` pins `JavaVersion.VERSION_17` for source,
target and JVM target. A newer JDK will fail the Gradle build with a version mismatch.

Take the current "Command line tools only" Linux zip from
<https://developer.android.com/studio#command-line-tools-only> (the build number changes; the one
used here was `commandlinetools-linux-15859902_latest.zip`, ~174 MB), then note the directory
nesting, which `sdkmanager` requires and which the zip does not itself produce:

```bash
mkdir -p ~/.local/opt/android-sdk/cmdline-tools
cd /tmp && curl -O https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip
unzip commandlinetools-linux-*.zip                                   # unpacks a 'cmdline-tools' folder
mv cmdline-tools ~/.local/opt/android-sdk/cmdline-tools/latest       # this exact path is required

export ANDROID_HOME="$HOME/.local/opt/android-sdk"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

yes | sdkmanager --licenses
sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;37.0.0"

flutter config --android-sdk "$ANDROID_HOME"
yes | flutter doctor --android-licenses
flutter doctor
```

Add `ANDROID_HOME`, `JAVA_HOME` and those two PATH entries to the same three homes as before.

For the platform and build-tools versions, `compileSdk` is delegated to `flutter.compileSdkVersion`
rather than pinned in this repo, so Flutter's stable channel decides it. If a build complains, run
`sdkmanager --list` and install what it asks for rather than guessing.

---

## Running the project's own gate

These are exactly the steps `.github/workflows/lint.yml` runs, so a green result locally means CI
should agree:

```bash
flutter pub get
flutter analyze --no-fatal-infos
dart format --output=none --set-exit-if-changed lib test tool
bash tool/check_appdatabase_leakage.sh
flutter test
```

### Verified result on 2026-08-31 (Flutter 3.47.2 / Dart 3.13.2)

| Step | Result |
|---|---|
| `flutter pub get` | ok — auto-migrated `analysis_options.yaml` to exclude `build/` and the platform directories |
| `flutter analyze --no-fatal-infos` | **exit 0** — 156 issues, every one `info` (119 `prefer_const_constructors`, 13 `unnecessary_import`, 12 `prefer_const_declarations`, a few others); no warnings, no errors |
| `dart format --set-exit-if-changed` | **exit 1 — 54 of 327 files would change.** See the trap below; nothing was reformatted |
| `tool/check_appdatabase_leakage.sh` | passed, no new call-sites |
| `flutter test` | **536 passed, 2 skipped, 0 failed** — after the dependency bump below |

### One dependency needed a patch bump before the suite would even compile

On a clean install, **nine test files failed to load** — not assertion failures, compilation failures,
all with the same cause:

```
flutter_quill-11.5.0/lib/src/editor/raw_editor/raw_editor_state.dart:42:7:
Error: The non-abstract class 'QuillRawEditorState' is missing implementations for these members:
 - TextInputClient.onFocusReceived
```

Flutter 3.47 added `onFocusReceived` to `TextInputClient`; `flutter_quill` 11.5.0 predates it and does
not implement it. **`flutter_quill` 11.5.1 fixes this** and satisfies the existing `^11.4.0`
constraint, so only `pubspec.lock` moves:

```bash
flutter pub upgrade flutter_quill
```

After that the whole suite passes. This is the shape of problem to expect from a `stable` channel that
moves faster than a dependency — when a test file fails to *load* rather than to assert, look for a
package that has not caught up with the framework, not at your own code.

**One trap worth knowing before your first run.** The repository was bulk-formatted with the Dart
3.10 "tall" style. If your Flutter stable is newer and its formatter has changed defaults, that third
command can report the entire repository as unformatted. That is a formatter-version difference, not
your code — reformatting everything would bury your real diff in thousands of lines. Check what CI's
`stable` resolves to before accepting a mass reformat.

---

## Build variants and release builds

A build is shaped by compile-time defines (`lib/utils/build_config.dart`), passed with
`--dart-define-from-file=<file>`. Every switch hides entry points only: code and stored data stay,
so a build that turns a feature back on loses nothing.

| Define | Default | Effect |
|---|---|---|
| `DEV_TOOLS` | on in debug/profile, off in release | Test-archive loading, reinitialize-with-test-data, manual QR entry, the SQL runner. Tree-shaken out when off. |
| `SAMPLE_DATA` | follows `DEV_TOOLS` | Offers the sample archive at `test_archive_url` (first-start prompt on an empty database, button on the export/import page) without the rest of the dev tooling. Downloaded on request, never bundled. |
| `FEATURE_SILEXGIS` | `true` | The club-server settings and every SilexGIS entry point. |
| `FEATURE_BEACONS` | `true` | Beacon settings, the drawer's detection toggle, per-place and per-cave beacon screens, background detection. Detection never starts when off. |
| `FEATURE_MODEL_3D` | `true` | "3D model" / "View in 3D" buttons and the viewer's settings page. |
| `DEFAULT_LOCALE` | `ro` | Language until the user picks one; a language already saved on the device wins. |

The define files in the repository root:

- `build_settings.json` / `build_settings_local_archive.json` — development builds, pointing at the
  test data on this machine or at a local test archive
  ([local test archive](docs/workflows/local-test-archive.md)).
- `build_settings.automation.json` — the test matrix's invented fixture.
- `build_settings.store.json` — closed testing: no dev tools, sample data offered as an `https://`
  download, crash reporting, SilexGIS and beacons hidden (testers have neither), English first.
- `build_settings.store.production.json` — the public release: no dev tools, no sample data, no
  crash reporting, English first.

Release artifacts come from two PowerShell scripts that refuse a configuration that must not ship —
files left in `assets/test_archive/`, `DEV_TOOLS` not `false`, a sample archive that is not an
`https://` URL, any `ftp_seed_*` key, a missing `android/key.properties` (debug signing), or an empty
`SENTRY_DSN` on the closed-testing build unless `-AllowEmptySentryDsn` is passed:

- `tool/build_store_release.ps1 [-Production]` — the Google Play `.aab`.
- `tool/build_store_apk.ps1 [-Production] [-SplitPerAbi]` — a release-signed APK for sideloading,
  universal by default or one per CPU architecture.

Hand-out builds that carry a shared sync account are a separate case; see
[seeded sync profile](docs/workflows/seeded-sync-profile.md).

---

## The 3D model viewer

The viewer is the SilexGIS fork of CaveView.js in a WebView (`webview_flutter`, Android and iOS
only — the Linux build shows a placeholder). Three pieces are checked separately:

- **The vendored build** in `assets/caveview/v<version>/` comes from
  `tool/refresh_caveview.sh <fork-commit>`, which builds the fork at that commit and writes
  `BUILD.txt` with checksums; `test/services/cave_model/caveview_assets_test.dart` fails if a file
  was changed by hand or pubspec.yaml lists another version. Never edit the vendored files: change
  the fork (`/home/devuser1/projects/caveview`, branch `silexgis`), stamp a new `slx.<n>`, refresh.
- **The host page** `assets/caveview/host/` speaks the app's message protocol (header of
  `bridge.js`). `node tool/caveview/host_page_check.mjs --focus test_cave.main.3` loads it in
  headless Chromium with the invented survey and checks taps, marks, the splay picker and trails;
  it needs Playwright, taken from the SilexGIS client's `node_modules` unless
  `PLAYWRIGHT_NODE_MODULES` says otherwise. `--model <file>` checks another survey, printing counts
  only.
- **On a device**: `flutter test integration_test/cave_model_viewer_test.dart -d <device>` (draws
  both formats, a real tap) and `integration_test/cave_model_mapping_test.dart` (maps a place).

`FEATURE_MODEL_3D` (`build_settings*.json`) shows or hides the entry points only. Store builds
have passed `true` since 2026-11-04; set it to `false` there to ship a build without the viewer.

With SilexGIS (`features` names `surveyModels`), the sync reads the survey-models stream into the
local-only `silexgis_survey_model` table and fetches each model's file into a documentation file
under the model's `documentId` (`silexgis_survey_model_fetcher.dart`, verified against the listed
size and SHA-256). Such a copy is never uploaded back as a document. Place mappings travel in the
`placeStations` upload section and come back on the same stream (`silexgis_survey_model_applier.dart`,
`silexgis_place_stations_upload_part.dart`); a mapping arrives only once its model's file is here,
so a run that fetched a new model reads the stream again from the beginning. The replays are
`test/services/silexgis/contract_survey_models_test.dart`; the dev server seeds no model yet.

---

## Notes for this machine

- **No GPU.** Everything renders through software GL. `flutter doctor` warns `Unable to access
  driver information using 'eglinfo'` and that is expected. An Android emulator will work but be
  slow, and it cannot meaningfully exercise the camera or scanner — **prefer a physical phone over
  USB** (`adb devices`, then `flutter run -d <id>`).
- **Chrome is not installed**, so `flutter doctor` reports the web target red. Nothing needs it
  unless you want `flutter run -d chrome`; install `chromium` or set `CHROME_EXECUTABLE` if you do.
- **Emulator system images are not installed.** Add them with
  `sdkmanager --install "emulator" "system-images;android-36;google_apis;x86_64"` and budget several
  more gigabytes.
