# Settings

[← Back to index](../README.md)

Settings group global preferences and data-management actions into a
small tree of pages. Open from **Home → ⋮ → Settings** (or the gear
icon, depending on layout).

The list mirrors the order shown in the app:

## General

- **App language** — current choice and available translations
  (English, Romanian, …). Changing the language restarts the UI
  to apply the new locale.
- **Show home toolbar** — display a visible action toolbar on the home
  screen instead of tucking actions into the end-drawer menu.
  This is a **persistent** setting (survives app restarts).
- **Auto-add entrance place** — when creating a new cave, automatically
  add a cave place pre-flagged as the main entrance. On by default;
  disable if you prefer to create the entrance place manually.
- **Allow main object bulk deletes** — enables bulk-delete actions for
  caves, cave areas, and cave places. Turn off to reduce the risk of
  accidental mass deletion.
- **Ask on QR scan ambiguity** — when a scanned QR code matches places
  in more than one cave, show a dialog to let you choose the target
  cave. When disabled, the app silently picks the most recently opened
  cave instead.
- **Ask on deep-link ambiguity** — same policy applied to `sp://`
  deep-links opened from outside the app.
- **Reset product tours** — clears the "already shown" flag for every
  highlight tour in the app, so first-visit overlays will reappear on
  the next visit to each screen.

## Image compression

Controls compression / resizing applied to photos captured or imported
into the app. Tune down for long expeditions when storage is tight; up
for archival quality.

## QR generation

Controls the appearance and technical quality of generated QR codes.
Fields include:

- **QR size (px)**, **image padding (px)**, **DPI**.
- **QR foreground / background color** — picked via an RGB color
  picker.
- **Error correction** — L / M / Q / H. Higher tolerates more damage.
- **Module shape** — square modules (default).
- **Label font** and **label font size**.
- **Label template** — see [QR codes](qr-codes.md#label-template).

## Place codes

Choose the **assignment strategy** for generating PCIs, configure its
parameters (country code, organization code, digit widths, separator,
…), and set the **QCRI mode** (mirror or hash, with length, salt and
entrance-hash options). The page also exposes a global **Generate
codes** action.

See [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md).

## PDF output

Controls the printable PDF layout:

- **Columns × Rows per page** — the grid.
- **PDF QR padding (horizontal / vertical)** — spacing between labels.
- Plus defaults inherited from QR generation.

## Database

Core data management actions:

- **Reinitialize database (empty)** — wipe everything, leave an empty
  DB.
- **Reinitialize database (with test data)** — wipe and populate with
  the built-in sample dataset.
- **Download test archive** — fetch the latest sample dataset from the
  configured URL and apply it.
- **Restore database from file** — replace the current DB with a file
  you pick (confirmation required; app restarts).
- **SQL command runner** *(debug-mode only)* — run arbitrary SQL
  against the local DB.

Destructive operations always prompt twice and clearly announce that
the application will restart.

## Users

Manage the list of caver/operator identities used for audit
attribution and pick the **current user**. See [Users](users.md).

## Sync dashboard

Combined view with two tabs:

- **Archive sync** — produce/import device-to-device sync archives.
- **Change log** — read-only audit trail.

See [Sync dashboard & change log](sync-and-change-log.md).

## FTP sync

Configure FTP/FTPS/SFTP endpoints and run automatic sync against a
shared server folder. See [FTP sync](ftp-sync.md).

## Data export / import

Full export and import of the database + assets, with options for
documentation files, raster maps, diff exports and (opt-in) FTP
password export. Also the entry point for **merge / sync import**
prompts. See [Database export, import and backup](database-export-import.md).

## Debug info *(debug mode only)*

Visible only after enabling debug mode (tap the home title 9 times).
Shows the database file path, app data directory, the raw
configurations table (editable inline) and per-row sync flags. Useful
for troubleshooting; safe to ignore in normal use.

## See also

- [Database export, import and backup](database-export-import.md)
- [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
- [Sync dashboard & change log](sync-and-change-log.md)
- [FTP sync](ftp-sync.md)
- [Users](users.md)
- [QR codes](qr-codes.md)
- [Home screen](home-screen.md)
