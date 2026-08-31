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
| Linux desktop toolchain | clang, cmake, ninja, GTK 3 headers | ~400 MB | `flutter run -d linux`, host tests |
| OpenJDK | 17 | ~350 MB | Android Gradle builds only |
| Android command-line tools | 22.0 | ~180 MB | Android builds only |
| Android platform + build-tools | android-36, build-tools 37.0.0 | ~1.5 GB | Android builds only |

**The Android half is optional for most work.** `flutter test` runs on the host, and this project
has a `linux/` target, so `flutter run -d linux` gives a real running application. The sync engine,
HTTP client, database layer and archive logic can all be built and tested without an Android SDK or a
phone. Install phase 2 when you reach the camera, BLE beacon or GPS code, which cannot be exercised
on a desktop.

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
