# Workflow: Sharing data between teams

[← Back to index](../README.md) · [Overview](../overview.md)

SpeleoLoc has **no central server** in the traditional sense. Data is
shared between devices in two complementary ways:

- by exchanging **archive files** manually (zip with the database plus
  optional documentation files and raster-map images), or
- by pointing several devices at a shared **FTP/SFTP folder** which
  the app fills with archive entries automatically.

The two modes can be mixed — they both use the same archive format
and the same conflict-resolution rules.

## What an archive contains

An exported archive can include any subset of:

- the **SQLite database** (caves, places, trips, metadata, …) — always
  included,
- **documentation files** (photos, audio, sketches, rich text, etc.),
- **raster-map images**,
- a **manifest** file describing the contents.

The exporter also supports a **diff-only** mode that includes only
files changed since the last export — useful when sending incremental
updates.

## Export an archive

1. **Settings → Data export/import → Export archive**.
2. In the dialog, choose:
   - which caves to include (all, or specific ones),
   - whether to include documentation files,
   - whether to include raster map images,
   - whether to export only diffs since last export,
   - whether to include **FTP profile passwords** (opt-in, off by
     default — only enable when sharing with your other devices).
3. Pick an output folder and confirm.

The result is a single `speleoloc_export_*.zip` you can share by email,
cloud storage, chat, USB transfer, FTP or any other channel.

See [Database export, import and backup](../features/database-export-import.md).

## Import an archive (full replace)

> Full replace **discards** the current database in favor of the
> imported one. Use when you want to overwrite everything.

1. **Settings → Database → Restore from file**.
2. Pick the archive or raw database file you received.
3. Confirm the warning prompt. The app restarts when done.

## Import an archive (merge / sync)

> Merge import preserves local data and adds the incoming items,
> resolving conflicts as they appear.

1. **Settings → Data export/import → Import (merge)**.
2. Pick the archive.
3. On conflicts (duplicate titles, duplicate place codes, …) the app
   asks you to keep local, keep incoming, or skip. You can apply
   decisions per-type or per-row.
4. The merged documents and raster map images are written into the
   app data directory and linked to the corresponding records.

For a less manual workflow — where the app continuously reads/writes
archives against a shared server — see [FTP sync](../features/ftp-sync.md)
and the [Sync dashboard](../features/sync-and-change-log.md).

## Practical tips

- **Before every underground session**: have the latest archive
  imported by every team member (or run an FTP sync). This avoids
  surprise missing places or stale pictures.
- **After every underground session**: run a diff export and share
  it, or rely on the FTP sync to do the same automatically.
- **Naming**: include date and cave name in the archive file name; it
  makes history obvious.
- **Large archives**: toggle off "include documentation files" if the
  team is only interested in the latest metadata/routes.

## Alternative channels

Because archives are ordinary zip files, any file-sharing method
works: FTP/SFTP, cloud sync folders, messaging apps with large-file
support, or removable media.

- **FTP/SFTP**: configure once in **Settings → FTP sync** and the app
  will push & pull archive entries automatically. See
  [FTP sync](../features/ftp-sync.md).
- **Other channels**: export an archive and share the resulting zip
  through your preferred medium; the recipient imports it the same
  way.

---

See also: [Database export, import and backup](../features/database-export-import.md),
[Sync dashboard & change log](../features/sync-and-change-log.md),
[FTP sync](../features/ftp-sync.md),
[Trips](../features/trips.md), [Documents](../features/documents.md).
