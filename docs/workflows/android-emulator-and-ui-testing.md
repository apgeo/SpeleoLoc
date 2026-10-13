# Android emulators and automated UI checks

[← Back to index](../README.md)

> **For maintainers, not for cavers.** This page is about running the app on
> emulated phones and checking the UI automatically, not about using it
> underground.

Three layers, cheapest first. Most regressions are caught by the first two,
which need no device at all and run in seconds.

| Layer | What it catches | Cost |
|---|---|---|
| Layout checks | Overflow on a narrow phone, a tablet, a landscape phone, a 1.5× system font | ~2 s, no device |
| Golden images | A screen that still fits but no longer looks the way it was designed | ~2 s, no device, one reviewed PNG per case |
| On-device tests | Anything involving a real platform: the media library, QR decoding, permissions | Minutes, needs an emulator |

---

## 1. Layout checks (no device)

`test/support/layout_harness.dart` renders a widget at every profile in
`test/support/device_profiles.dart` and fails if any of them overflows,
naming every failing profile at once.

```dart
testLaysOutEverywhere('a row with a long title', () => myWidget());
```

```bash
flutter test test/widgets/trip_media_layout_test.dart
```

The profiles bracket what the app meets rather than enumerating devices: the
narrowest phone still in use, the common and large phone shapes, the
landscape phone shape the trip screen has a branch for, a tablet, and a 1.5×
font scale. **Add a case here whenever you build a row that packs several
controls beside variable-length text** — that is the shape that breaks.

## 2. Golden images (no device)

```dart
testGoldenAcrossDevices('the media rows', 'trip_media_rows', () => rows());
```

Goldens live in `test/widgets/goldens/`. They cover the two profiles that
break first (narrowest phone, large font) rather than all six, because each
one is a binary a human has to review.

```bash
# compare (what CI does)
flutter test test/widgets/trip_media_golden_test.dart
# regenerate after an intentional UI change — then LOOK at the diff
flutter test --update-goldens test/widgets/trip_media_golden_test.dart
```

The harness loads the project's fonts plus the SDK's Roboto and
MaterialIcons, so goldens are readable rather than a grid of tofu boxes.
They are generated on Linux; glyph rasterisation differs per platform, so a
golden produced on another OS will not match.

## 3. On-device tests

### What the machine needs

The emulator needs `/dev/kvm`. `tool/android/avd.sh doctor` says whether it
is there and what the access rests on.

On a Hyper-V guest, KVM appears once nested virtualization is exposed to the
VM — a host-side setting, applied with the VM shut down:

```powershell
Set-VMProcessor -VMName <vm-name> -ExposeVirtualizationExtensions $true
```

**Dynamic Memory can stay on.** Microsoft's restriction applies while
Hyper-V itself runs inside the guest; this guest runs KVM. Measured on the
development VM: the setting is accepted with Dynamic Memory enabled, an AVD
boots in about 35 s, and the balloon keeps growing under memory pressure
with an emulator live.

Three things to know about running this way:

- **The emulator warns that nested virtualization "is not recommended".**
  That is printed whenever it detects it is inside any VM; it is a caution,
  not a detected fault. Treat the setup as *works, keep an eye on it*: one
  good session is not a guarantee about sustained load.
- **KVM access may rest on a desktop-session ACL rather than group
  membership.** That covers anything started while the desktop session is
  up — a terminal, an agent — and silently disappears for a systemd service,
  a CI runner or a container. Before launching emulators from one of those,
  `sudo usermod -aG kvm "$USER"` and log in again.
- **There is no GPU**, so rendering is software (`swiftshader_indirect`).
  Unrelated to KVM and will not change.

### The emulators

`tool/android/avd.sh` owns the matrix. It brackets what the app supports —
`minSdk 24`, the API 33 boundary where photo access moved from
`READ_EXTERNAL_STORAGE` to `READ_MEDIA_*`, `compileSdk 36` — plus one tablet
so screen size varies as well as version.

| AVD | API | Device |
|---|---|---|
| `speleo_api24_pixel2` | 24 | Pixel 2 (1080×1920, 420 dpi) |
| `speleo_api30_pixel4` | 30 | Pixel 4 (1080×2280, 440 dpi) |
| `speleo_api34_pixel7` | 34 | Pixel 7 (1080×2400, 420 dpi) |
| `speleo_api34_tablet` | 34 | Medium tablet (2560×1600, 320 dpi) |
| `speleo_api36_pixel7pro` | 36 | Pixel 7 Pro (1440×3120, 560 dpi) |

```bash
tool/android/avd.sh doctor      # can this machine run one?
tool/android/avd.sh create      # create them all (idempotent)
tool/android/avd.sh boot speleo_api34_pixel7              # start, wait for boot
tool/android/avd.sh boot speleo_api34_pixel7 --headless   # the same, no window
tool/android/avd.sh stop        # stop everything
```

With a display the emulator opens a window on the desktop; with none it goes
headless on its own. Each uses about 4 GB while running, so several can run
side by side — but stop them when done rather than leaving a set up.
VSCode's `speleo_loc @ …` launch configurations target them directly.

### Which data the app runs on — read this before looking at a screenshot

`build_settings.json` points `test_archive_url` at an export of the real
cave register. A build launched with it shows real data, and so does every
screenshot of it. **Automated runs therefore never use it.**

They use `build_settings.automation.json` and an **invented** fixture:

```bash
flutter test tool/android/generate_fixture_archive.dart
# -> assets/test_archive/automation_fixture.zip
```

Three made-up caves with areas, entrances, coded places, and one ended and
one open trip each. It is built through the app's own database class, so its
schema is right by construction, and its manifest carries a marker saying it
is invented. (It runs under `flutter test` rather than `dart run` because
that class pulls in the Flutter framework.)

`tool/android/seed_app_data.sh` puts an archive on the device **without
going through the app** — the in-app import ends by restarting the process,
which would kill a test mid-run. It always wipes the app's data first, so a
device someone used by hand cannot leak what it held into a run, and it
records what it seeded in `build/screenshots/.data-origin`:

| `DATA_ORIGIN` | Meaning |
|---|---|
| `invented` | The archive's manifest carries the fixture marker. Screenshots are safe for anyone, including an agent, to read. |
| `unmarked` | Anything else. Treated as real data: screenshots are for a person to review, and an agent must not read them into its context. |

#### Using a curated dataset

Drop-in, no code change. Hand the archive to the same script, or to the
whole check:

```bash
tool/android/seed_app_data.sh /path/to/curated.zip
SPELEO_TEST_ARCHIVE=/path/to/curated.zip tool/ui_check.sh
```

Any DataArchive the app can export works. Because it will not carry the
fixture marker it is reported `unmarked`: only the content-blind smoke test
runs against it (the fixture flows assert on invented names it will not
contain), and its screenshots are flagged as not for an agent. If a curated
set is itself invented and should be readable, add
`"fixture": "invented …"` to its `manifest.json` — that is the one switch.

Mind the existing rule for `assets/test_archive/`: whatever sits there is
bundled into every build, release included. Keep a curated archive
elsewhere and pass its path.

### Pictures for the device's library

The points-from-pictures screen reads the device's own media library, so a
fresh emulator shows an empty list. Generate invented photos and push them:

```bash
dart run tool/android/generate_test_media.dart /tmp/media a1 a2   # place codes
tool/android/seed_test_media.sh /tmp/media
```

The codes are the fixture's: `a1` is the first cave's entrance, `a2` and
`a3` chambers in it. The photos are dated on that cave's fixture trip day,
and one two days earlier, so a date-range filter has something to exclude.

Two things measured on an API 34 emulator that the scripts now account for:

- **The capture time the app sees comes from the file's modification time,
  not its EXIF.** Android's scanner filled `date_taken` from mtime and
  ignored a well-formed `DateTimeOriginal`. The generator stamps each file's
  mtime, and `adb push` preserves it.
- **Shell-triggered media scans do not complete.** Every variant left rows
  pending with no size or date. The seeding script tries the cheap scan,
  checks whether it worked, and reboots the device when it did not.

### Running the tests

```bash
tool/ui_check.sh
```

does all of it on the connected device: builds the fixture, builds the test
app once, installs it, seeds data and pictures, and drives
`integration_test/suite_test.dart`. The order is forced — seeding needs the
package installed, and `flutter drive` uninstalls the app when it ends.
Screenshots land in `build/screenshots/`.

`integration_test/support/driver.dart` holds the shared plumbing: `launch()`
starts the real `main()` and polls for the first frame (startup awaits the
database and i18n bundle, so settling alone is not enough), `settle()`
tolerates the timers a real screen leaves running, `pumpUntil()` waits on
work the frame loop cannot see finishing, and `shoot()` captures a
screenshot.

### A note on Playwright

Playwright drives browsers and cannot drive a Flutter app. The equivalent
here is `integration_test` + `flutter drive`, which is what the section
above sets up; it runs the same way against an emulator, a physical device
or the desktop build. Playwright would only become relevant for Flutter Web,
which this app does not target — `photo_manager`, `mobile_scanner` and the
beacon plugins have no web implementation.

### What an emulator still cannot test

- **BLE beacons.** The emulator has no usable Bluetooth radio; beacon work
  needs real hardware.
- **The camera.** There is no webcam on this host, so live QR scanning falls
  back to the emulator's synthetic scene. Reading a QR *out of a photo* —
  what the media import does — works fine, because it analyses a file.
