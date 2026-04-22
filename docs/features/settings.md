# Settings

[← Back to index](../README.md)

Settings group global preferences into a few sub-pages. Open from
**Home → ⋮ → Settings** (or the gear icon, depending on layout).

## General

- **App language** — current choice and available translations (English,
  Romanian, …).
- **Show home toolbar** — display a visible action toolbar on the home
  screen instead of tucking actions into the end-drawer menu.
- **Enable QR manual input (long-press)** — allows long-pressing the
  scan icon to open a typed-input dialog. Useful when labels are
  damaged.
- Other visual/ergonomic toggles (compact nav bar, tap-auto-save, …).

## QR generation

Controls the appearance and technical quality of generated QR codes.
Fields:

- **QR size (px)** — final pixel size of each QR image.
- **Image padding (px)** — white space around each QR image.
- **Label font size** and **label font family**.
- **QR background color** — ARGB hex, e.g. `0xFFFFFFFF` (white).
- **QR foreground color** — ARGB hex, e.g. `0xFF000000` (black).
- **DPI** — generation DPI; higher = sharper print, bigger files.
- **Error correction** — L / M / Q / H. Higher tolerates more damage.
- **Label template** — see [QR codes](qr-codes.md#label-template).

## PDF output

Controls the printable PDF layout:

- **Columns × Rows per page** — the grid.
- **PDF QR padding (horizontal / vertical)** — spacing between labels.
- Plus defaults inherited from QR generation.

## Image compression

Controls compression / resizing applied to photos captured or imported
into the app. Tune down for long expeditions when storage is tight; up
for archival quality.

## Database

Critical actions for managing your data:

- **Export database** — write the raw SQLite file to an external folder.
- **Export archive** — full zip (DB + files + maps) with include/exclude
  options; see [Database export, import and backup](database-export-import.md).
- **Restore database from file** — replace the current DB with a file
  you pick (confirmation required; app restarts).
- **Import (merge / sync)** — merge an archive into the current DB with
  conflict prompts.
- **Reinitialize database (empty)** — wipe all data; app restarts.
- **Reinitialize database (with test data)** — wipe + populate with a
  built-in sample dataset; app restarts.
- **SQL command runner** (debug-mode-only) — run arbitrary SQL against
  the local DB; power-user tool, use with care.

Destructive operations always prompt twice and clearly announce that
the application will restart.

## See also

- [Database export, import and backup](database-export-import.md)
- [QR codes](qr-codes.md)
- [Home screen](home-screen.md)
