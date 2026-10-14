# Android emulators and automated UI checks

[← Back to index](../README.md)

> **For maintainers, not for cavers.** This page is about running the app on
> emulated phones and checking the UI automatically, not about using it
> underground.

## The short version

```bash
tool/ui_check.sh                       # every change: ~10 minutes
tool/test_matrix.sh --tier ring        # a finished feature, or weekly
tool/test_matrix.sh --tier full        # a milestone or a release: hours
```

Each run leaves `build/matrix/<run>/report.md`; `build/matrix/latest` points
at the newest.

## Layers, cheapest first

| Layer | What it catches | Cost |
|---|---|---|
| Analysis and UI lint | New analyzer issues; user-visible strings that bypass translation; icon buttons with no tooltip | Seconds |
| Layout and golden widget tests | One widget overflowing on a narrow phone, a tablet, landscape, a 1.5× font; a widget that no longer looks as designed | Seconds |
| Desktop sweep | Every screen opened in every phone shape and language on the app's Linux build: layout errors, crashes, cut-off text, accessibility | Minutes, no emulator |
| Emulator cells | The same screens on real Android versions, plus what only a platform has: the media library, permissions, a QR code read out of a photo, random input | Minutes per cell |
| Release gates | Native libraries that will not load on 16 KB-page phones, a permission a plugin slipped in, test data bundled in a store build | Minutes, once per release |

## Tiers

`tool/matrix/tiers.json` says exactly what each tier contains;
`tool/test_matrix.sh plan --tier <name>` lists its cells without running
anything.

| Tier | Also called | When | What runs |
|---|---|---|---|
| `pulse` | `pulse-minimal-avd` | Every change (this is what `tool/ui_check.sh` runs) | Core screens in five shapes on the desktop build, in Romanian and in the pseudo-locale; core screens, smoke and the media flow on one API 34 emulator |
| `ring` | `ring-medium-avd` | A finished feature; weekly | Every screen, every shape, both languages and the pseudo-locale on the desktop build; four Android versions and form factors (24, 33, tablet, foldable) sampled pairwise over shape, language and settings; permission journeys on API 33; random input |
| `full` | `full-avd` | A milestone, before a release | Everything on all nine emulators, including the largest font size with bold text, dark system UI, every permission journey, offline / battery saver / other time zone and language, and random input on four versions |

Breadth and depth are not multiplied together. The sweep goes wide —
every screen, every shape — and stays shallow; the flows that exercise a
feature run once per Android version.

Narrower runs:

```bash
tool/test_matrix.sh --tier ring --only desktop
tool/test_matrix.sh --tier ring --avd speleo_mx_api33
tool/test_matrix.sh --tier pulse --flows smoke
```

Exit code: 0 passed, 1 something failed, 2 part of the tier could not run.
A cell that did not run is listed as NOT RUN and is never counted as a pass.

### What a run checks

- **Flows** (`integration_test/`): `smoke` (the app starts),
  `sweep_core` / `sweep_all` (open every screen in the catalogue),
  `trip_media` (pictures from the device library become trip points),
  `scanner_live_qr` (the live scanner reads a QR label the emulator's camera
  shows), `ble_scan` (the BLE plugin hears the emulated radio's test
  beacons), `beacon_detect` (the app's own detection finds the fixture's
  iBeacon and Ruuvi tag and stamps them as seen), `deep_cave_create` (a cave created through the UI gets its
  entrance), `deep_trip_lifecycle` (a trip started and stopped from the
  trip list is active, then closed), `monkey` (random taps, swipes and
  keys; fails on a crash or an ANR).
- **Skipped screens say why**: a screen that needs hardware the platform
  lacks, a PDF renderer (none on Linux), or a person to answer a system
  dialog it opens on arrival (the folder picker of the document import,
  the system camera of camera capture) is recorded as skipped with that
  reason. Screens whose only errors are failed network requests (map
  tiles, normal underground) are recorded as `network`, not as broken.
  After a broken screen the sweep starts the app again, so one failure
  does not cascade.
- **Known issues**: a screen error listed in `tool/matrix/known_issues.json`
  is reported under its own heading and does not fail the run. Remove the
  entry when the bug is fixed.
- **For every screen the sweep opens**: a build or layout error, with the
  widget and the file and line it came from; text the framework had to cut
  off; Flutter's accessibility guidelines — tap targets under 48 dp,
  tappable things with no label, low-contrast text. Errors fail the run;
  cut-off text and accessibility are findings, counted in the report so the
  numbers can only go down.
- **Shapes** (`tool/matrix/shapes.json`): narrow, common and landscape
  phone, tablet portrait and landscape, 1.5× font, and — best effort,
  reported but never failing — 2× font with bold text. The desktop build
  takes each shape inside one process. An emulator is reshaped from outside
  (`wm size`, `wm density`, font scale) by `tool/android/device_profile.sh`,
  with the status bar pinned by demo mode so screenshots compare.
- **Settings profiles**: `default`, `busy` (every optional toolbar, the
  compact navigation bar, the widest coordinate format) and `tours` (the
  first-run tour left on). The app keeps settings in its database, so a
  profile is a variant of the fixture archive, not a test-only switch.
- **Languages**: Romanian, English, and a pseudo-locale — English made about
  40% longer, accented and bracketed — that shows today where a longer
  future translation would overflow.

### Adding a screen

Add it to `integration_test/catalogue/screens.dart`. A screen missing from
that list is a screen nothing looks at.

## The desktop build

The sweep's breadth comes from the app's Linux build: it starts in seconds,
needs no emulator and can take any screen shape. It is given Roboto and the
Android platform behaviour so it measures text and lays out widgets like a
phone, and it runs in a private home layout under a virtual display, so it
never touches the real `~/Documents`. Phone hardware — camera, Bluetooth,
media library, location — has no Linux plugin, so screens that need it are
skipped there with the reason and opened on an emulator instead.

Needs `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev xvfb`.

## The emulators

`tool/android/avd.sh` manages two sets, kept apart on purpose:

| Set | Names | Used for |
|---|---|---|
| hand | `speleo_api*` | Working by hand, from a terminal or the VSCode launch configurations. Never wiped by any script. |
| matrix | `speleo_mx_*` | Owned by the test matrix. `avd.sh prepare` wipes one, boots it once, waits for first-boot work to settle and saves a `pristine` snapshot; every run starts from that and writes nothing back. Do not use them by hand. |

The matrix set brackets where Android changed under the app: 24 (minSdk,
legacy storage), 30 (scoped storage, one-time permissions), 31 (Bluetooth
permissions, approximate location), 33 (notification and media permissions),
34 (partial photo access; also a tablet and an AOSP image without Google
services), 35 on a 16 KB page-size image (edge-to-edge enforced), and 36 on a
foldable.

```bash
tool/android/avd.sh doctor              # can this machine run one?
tool/android/avd.sh images --install    # download what the sets need
tool/android/avd.sh prepare matrix      # create and snapshot the matrix set
tool/android/avd.sh boot speleo_api34_pixel7 --headless
tool/android/avd.sh disk                # what they cost on disk
tool/android/avd.sh stop
```

A prepared AVD with its snapshot takes about 2.5 GB. Installed images are
made sparse — an unpacked image is mostly empty filesystem — which saves
several GB each.

### What the machine needs

The emulator needs `/dev/kvm`. On a Hyper-V guest it appears once nested
virtualization is exposed to the VM — a host-side setting, applied with the
VM shut down:

```powershell
Set-VMProcessor -VMName <vm-name> -ExposeVirtualizationExtensions $true
```

**Dynamic Memory can stay on.** Microsoft's restriction applies while
Hyper-V itself runs inside the guest; this guest runs KVM.

**Join the `kvm` group** (`sudo usermod -aG kvm "$USER"`). Without it,
access to `/dev/kvm` comes from the desktop session, and that moves to the
login greeter the moment the screen locks or a remote desktop detaches —
which is exactly when unattended runs happen. A shell started before
joining picks the group up through `sg`, which the scripts do on their own.

**There is no GPU**, so rendering is software. An idle emulator costs
about 60% of one core; three run side by side comfortably.

### Single cells and device scripts

`tool/android/run_cell.sh` runs one cell on one booted emulator and is the
way to reproduce a failure the report names:

```bash
tool/android/run_cell.sh --serial emulator-5554 --flows sweep_core \
  --shape phone_small --lang en --settings busy
```

The pieces it uses work on their own too:
`device_profile.sh <shape>`, `permissions.sh journey <name>` (a permission
taken away the way a user can on that Android version),
`platform_state.sh <state>` (offline, battery saver, doze, another time zone
or system language), `seed_app_data.sh`, `seed_test_media.sh`.

## Which data the app runs on — read this before looking at a screenshot

`build_settings.json` points `test_archive_url` at an export of the real
cave register. A build launched with it shows real data, and so does every
screenshot of it. **Automated runs therefore never use it.**

They use `build_settings.automation.json` and an **invented** fixture, built
through the app's own database class:

```bash
flutter test tool/android/generate_fixture_archive.dart
FIXTURE_VARIANTS_DIR=build/fixtures flutter test tool/android/generate_fixture_archive.dart
```

Four made-up caves with areas, entrances with positions in open sea,
coded places, survey drawings with the places marked on them, documents,
beacon tags, and trips; one cave title and one place title are long, one
place title carries every Romanian diacritic. The second command also
writes one archive per settings profile and language.

Every run records the origin of its data in each output folder, in
`.data-origin`:

| Origin | Meaning |
|---|---|
| `invented` | The archive's manifest carries the fixture marker. Safe for anyone, including an agent, to read. |
| `anonymized` | A real export passed through the anonymizer and its verifier. Safe for an agent to read. |
| `unmarked` | Anything else. Treated as real data: for a person to review; an agent must not read it. |

To run on another dataset:

```bash
SPELEO_TEST_ARCHIVE=/path/to/archive.zip tool/ui_check.sh
tool/test_matrix.sh --tier ring --archive /path/to/archive.zip
```

Mind the rule for `assets/test_archive/`: whatever sits there is bundled
into every build, release included. The matrix refuses to build when an
archive there is not marked invented or anonymized, and the release gates
fail when anything but `.gitkeep` is bundled.

## Pictures for the device's library

The points-from-pictures screen reads the device's own media library. The
matrix generates invented photos and pushes them for the cells that need
them. By hand:

```bash
dart run tool/android/generate_test_media.dart /tmp/media a1 a2
tool/android/seed_test_media.sh /tmp/media
```

Measured on an API 34 emulator: the capture time the app sees comes from
the file's modification time, not its EXIF, and shell-triggered media scans
do not complete — the script reboots the device when the cheap scan fails.

## Reviewing a run

The mechanical checks cannot judge whether a screen looks right. For that:

```bash
python3 tool/matrix/review.py               # the latest run
python3 tool/matrix/review.py --accept      # record it as the baseline
```

`review.py` picks the screens that failed, have findings, or changed since
the accepted baseline, lays each one's shapes side by side on a contact
sheet, and writes `review/REVIEW.md` with a checklist and the cost of reading
the sheets. An agent (or a person) reads the brief and the sheets and writes
`verdicts.md`. Only invented or anonymized output is ever offered.

## Release gates

```bash
tool/matrix/release_gates.sh
```

Builds a release APK and checks 16 KB alignment of every native library (in
the zip and in its segments — required by Play for apps targeting Android
15+), that the merged permission list matches
`tool/matrix/permissions.allow`, and that no test data is bundled.

## Real phones in the cloud

The emulators are Google images; a manufacturer's build of Android only
shows on its phones. `tool/android/cloud_ftl.sh` runs the same tests on
Firebase Test Lab devices, with only the debug test build and the invented
fixture leaving the machine. The test seeds itself there from the bundled
fixture. It needs the Google Cloud CLI, a login and a project with Test Lab,
and says NOT RUN until those exist. `--build-only` builds and checks
without uploading.

## Continuous integration

On GitHub, `lint.yml` runs analysis against its baseline, the UI lint,
formatting, guardrails and the unit tests; `ui.yml` runs the desktop half of
`pulse` on every push; `android-weekly.yml` runs one cell on API 24, 33 and
34 every Sunday. Nothing local depends on them.

## A note on Playwright

Playwright drives browsers and cannot drive a Flutter app. The equivalent
here is `integration_test` + `flutter drive`. Playwright would only become
relevant for Flutter Web, which this app does not target.

## What the emulators can and cannot stand in for

- **The camera.** Matrix emulators boot with `-camera-back imagefile:` and
  a picture of six copies of a QR label, so the live scanner has a code to
  read; one centred label was half cropped away by the preview.
- **Bluetooth.** API 33 and newer images get an emulated radio through
  netsim; the matrix boots them with netsim's test beacons, and the
  `ble_scan` flow checks the app's BLE plugin hears them. For the app's
  own detection, `tool/android/netsim_beacons.dart` advertises the
  fixture's iBeacon and Ruuvi tag while a `beacon_detect` cell runs: it
  connects to netsim's HCI socket as two extra Bluetooth controllers and
  has them advertise. (netsim's gRPC control API would be the obvious way
  to add beacons, but the daemon the emulator ships keeps it switched off.)
  Every emulator on the machine hears these beacons. Older images have no
  radio.
- **Battery management and manufacturer builds** of Android only show on
  real phones: use the cloud devices, or the phones you have.
