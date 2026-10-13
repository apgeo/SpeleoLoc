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

### ⚠️ This VM cannot run an emulator yet

`/dev/kvm` is absent: this is a Hyper-V guest and nested virtualization is
not exposed to it, so `/proc/cpuinfo` has no `vmx`. The kernel already ships
`kvm-intel`, so the only missing piece is a host-side setting.

```powershell
# On the Windows host, with this VM SHUT DOWN:
Set-VMProcessor -VMName <vm-name> -ExposeVirtualizationExtensions $true

# Hyper-V also requires Dynamic Memory OFF on a VM with nested
# virtualization, so RAM becomes static — this is the real cost of the
# change, since it ends the 32–120 GB balloon described in CLAUDE.md.
Set-VMMemory -VMName <vm-name> -DynamicMemoryEnabled $false -StartupBytes 32GB
```

Then `tool/android/avd.sh doctor` should report `/dev/kvm is present`.

Everything below is installed and ready; only the boot is blocked.

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
tool/android/avd.sh boot speleo_api34_pixel7   # start and wait for boot
tool/android/avd.sh stop        # stop everything
```

They render in software (`swiftshader_indirect`) because this host has no
GPU. VSCode's `speleo_loc @ …` launch configurations target them directly.

### Giving the app something to find

The points-from-pictures screen reads the device's own media library, so a
fresh emulator shows an empty list. Generate invented photos — EXIF capture
times, some carrying a cave place's QR label — and push them in:

```bash
dart run tool/android/generate_test_media.dart /tmp/media a1 a2   # place codes
tool/android/seed_test_media.sh /tmp/media
```

Pass the place codes that exist in the database you are testing against. One
file is dated the previous day, so a date-range filter has something it must
exclude. Clear them again with `tool/android/seed_test_media.sh --clear`.

Grant library access without tapping through the dialog:

```bash
adb shell pm grant <applicationId> android.permission.READ_MEDIA_IMAGES
adb shell pm grant <applicationId> android.permission.READ_MEDIA_VIDEO
# API 32 and below use READ_EXTERNAL_STORAGE instead
```

### Running the tests

```bash
# assertions only
flutter test integration_test/app_smoke_test.dart

# assertions + screenshots into build/screenshots/
flutter drive \
  --driver test_driver/integration_test.dart \
  --target integration_test/app_smoke_test.dart \
  --dart-define-from-file=build_settings.json
```

`integration_test/support/driver.dart` holds the shared plumbing: `launch()`
starts the real `main()` and polls for the first frame (startup awaits the
database and i18n bundle, so `pumpAndSettle` alone is not enough),
`settle()` tolerates the timers a real screen leaves running, `shoot()`
captures a screenshot, and `tapIfPresent()` walks past a screen that may or
may not appear, such as the first-run tour.

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
