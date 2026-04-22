# Database export, import and backup

[← Back to index](../README.md)

SpeleoLoc stores all structured data (caves, places, raster map
metadata, trips, document records, …) in a single **SQLite database**
file, and keeps document binaries and raster-map images in the app's
data directory. All of this can be packaged and exchanged.

## Where your data lives

- **SQLite database** — `speleo_loc.sqlite` in the application
  documents directory (platform-dependent).
- **Documentation files** — under the application documents directory.
- **Raster map images** — same location.
- **Trip report templates** — same location.

You normally never interact with these files directly — use the
options below.

## Exporting

Three options, from most targeted to most comprehensive.

### 1. Export raw database file

**Settings → Database → Export database**. Writes the `.sqlite` file
to a folder of your choice. Small, fast, but does **not** include any
documentation files or raster map images — importing it elsewhere will
result in missing media.

Use for: quick backup snapshots you will restore on the **same
device**.

### 2. Export an archive (full)

**Settings → Database → Export archive**. Produces a single
`speleoloc_export_*.zip` containing:

- the database,
- optionally documentation files,
- optionally raster-map images,
- a manifest.

In the export dialog, choose:

- **Which caves** to include (all or a selection).
- Whether to include **documentation files**.
- Whether to include **raster-map images**.
- Whether to export **diff-only** (only items changed since the last
  export, when timestamp information is available).

Use for: sharing with another device or team.

### 3. Export individual items

Some screens offer focused exports:

- **Raster maps → export images as zip** — bundle all raster images.
- **QR codes → PDF / images** — see [QR codes](qr-codes.md).
- **Trip → export report** — see [Trip reports](trip-reports.md).
- **Documents** — per-file "open externally" / share actions.

## Importing

### Full replace

**Settings → Database → Restore database from file**. Pick a `.sqlite`
file or an archive zip. The current database is replaced. The app
**restarts** to pick up the new database. All previous local data is
lost unless you backed it up.

### Merge / sync import

**Settings → Database → Import (merge)**. Pick an archive. The
importer walks through the incoming records:

- New items are added.
- Conflicts (duplicate titles, duplicate QR identifiers, same primary
  key with different content) trigger a decision prompt:
  - **Keep local**,
  - **Take incoming**,
  - **Skip this one**,
  - **Apply to all remaining conflicts of this type**.

After processing, documents and raster images are unpacked into the
app's data directory so they are immediately available.

## Backup strategy recommendations

- **Before any risky operation** (DB reinit, large CSV import, trying a
  new version), export an archive and keep it dated.
- **Before going underground**, make sure every device on the team has
  imported the latest archive.
- **After the trip**, export a diff and share it with the team.

## Reinitializing the database

Two destructive-but-useful options in **Settings → Database**:

- **Reinitialize (empty)** — wipes everything, leaves an empty DB.
- **Reinitialize (with test data)** — wipes and loads sample data.

Both show two confirmation dialogs and restart the app on success.

## See also

- [Sharing data between teams](../workflows/sharing-data.md)
- [Settings](settings.md)
