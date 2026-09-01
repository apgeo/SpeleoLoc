# Local test-archive dev workflow

[← Back to index](../README.md)

> **For maintainers, not for cavers.** Unlike the rest of this wiki, this page
> is about building and seeding the app rather than using it. If you are
> looking for how to move real data around, see
> [Database export, import and backup](../features/database-export-import.md).

Load a full **DataArchive export** (a `.zip` produced by *Settings → Data
export/import → Export*) as seed data — either automatically on a fresh app
start, or on demand via *Settings → Data export/import → Import test data*.

This is a developer/QA convenience for booting the app with a known dataset.
It is driven by the `test_archive_url` build setting and handled by
`TestArchiveImportService` (`lib/services/test_archive_import_service.dart`),
which imports the archive with a **full replace** of the local database.

## How `test_archive_url` is resolved

`TestArchiveImportService.fetchArchiveBytes` tries three things, in order:

1. **`http(s)://…`** → download over the network.
2. **An existing file on disk** → read it directly. Use this for a quick
   desktop run: point `test_archive_url` at an absolute path (e.g.
   `C:\dev\exports\seed.zip`). Works only where the run target can reach that
   path — i.e. the **desktop build** or the dev machine. A mobile device
   cannot read a host filesystem path, so on Android/iOS this falls through
   to (3).
3. **A bundled asset key** (e.g. `assets/test_archive/seed.zip`) → loaded from
   the app bundle via `rootBundle`. This is the only option that works
   **on-device**, because the archive is compiled into the app.

## Bundled-asset setup (works on-device)

The repo is wired for option (3):

- `assets/test_archive/` is declared under `flutter: assets:` in
  `pubspec.yaml`, so everything in it is bundled into the app.
- The heavy archive `.zip` is **git-ignored** (it is machine-local — a real
  export can be tens of MB). Only `assets/test_archive/.gitkeep` is tracked,
  so the directory exists on a fresh clone and the asset entry is valid even
  when no archive is present.
- `build_settings_local_archive.json` sets `test_archive_url` to the asset
  **key** (path relative to the project root), e.g.
  `assets/test_archive/speleo_loc_2026-05-26_15-17-33.zip`.
- The launch config `speleo_loc_local_archive` (`.vscode/launch.json`) runs
  with `--dart-define-from-file=build_settings_local_archive.json`.

### Use it

1. Drop your export zip into `assets/test_archive/` (it stays local — ignored
   by git).
2. Set `test_archive_url` in `build_settings_local_archive.json` to the asset
   key `assets/test_archive/<your-file>.zip`.
3. Run with the archive config:
   ```
   flutter run --dart-define-from-file=build_settings_local_archive.json
   ```
   (or pick the **speleo_loc_local_archive** launch configuration).
4. On first start with an empty DB you'll be offered to load the test data;
   you can also trigger it any time from *Settings → Data export/import →
   Import test data*.

### Swapping archives

Replace the file in `assets/test_archive/` and update the filename in
`test_archive_url`. There is no need to touch `pubspec.yaml` (it references the
whole directory).

## ⚠️ Release-build caveat

Anything in `assets/test_archive/` is bundled into **every** build, including
release — a multi-MB test archive will bloat the release binary. For lean
release builds, either empty the directory or comment out the
`- assets/test_archive/` line in `pubspec.yaml`. (This mirrors why the legacy
`test_data/maps/` and `test_data/db/binaries/` asset lines are kept commented
out.)

If you only ever run this on desktop, you can skip bundling entirely: point
`test_archive_url` at an absolute file path and rely on resolution step (2) —
nothing gets bundled.
