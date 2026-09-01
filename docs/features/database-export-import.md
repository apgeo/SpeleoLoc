# Database export, import and backup

[← Back to index](../README.md)

Everything the app knows — caves, places, maps, trips, document records —
lives in one database file, with the document and map images beside it.
This page covers the screens that copy that whole set off the device and
put it back: **Settings → Data Export / Import** and
**Settings → Database**.

Labels below are the English ones. The app starts in Romanian; English is
chosen in **Settings → General → App language**.

## Which route to use

The app has two quite different ways of moving data, and they are not
interchangeable.

| | **Data Export / Import** | **Man. sync** |
|---|---|---|
| Archive contains | a copy of the whole database, plus media | one line per record, plus the change history |
| Rebuilding a device from scratch | yes — **Replace all data** | no |
| Routine team exchange | clumsy — prompts on every clash | yes — newest edit wins, no prompts |
| Deletions made elsewhere | never applied | replayed on your device |
| Covers beacons, users, templates | only on **Replace all data** | yes |

Use **Data Export / Import** for backups, for moving to a new phone, and
for handing a complete dataset to someone starting from nothing. Use
[Manual sync and the change log](sync-and-change-log.md) for the
back-and-forth between trips, and [FTP sync](ftp-sync.md) when a server
does that exchange for you.

## What travels and what does not

Almost everything can be packaged and exchanged, but there are three
exceptions worth knowing before you rely on an archive as a backup.

- **Photos attached to BLE tags** (taken in tag management, see
  [BLE beacons](ble-beacons.md)) are kept as ordinary image files beside
  the database and are put into *no* archive at all. They stay on the
  device that took them.
- **Ruuvi sensor history** downloaded from a tag sits inside the database
  file, so it survives a **Replace all data** import or a raw database
  restore, but **Merge with existing data** and manual sync both ignore
  it. To hand it to someone, use **Export CSV** on the history screen —
  see [Ruuvi sensors](ruuvi-sensors.md).
- **Tag registrations** — which tag is fixed at which place — travel with
  the database file, with a **Replace all data** import and with manual
  sync, but **not** with a merge import. A merged place can therefore
  arrive without its tags.

## Exporting

### An archive (database plus media)

**Settings → Data Export / Import → Export Archive**. The app builds a
single zip named for the moment you made it, for example
`speleo_loc_2026-09-01_14-32-07.zip`. On Android it then opens your
device's save dialog with that name already filled in, and you say where
the file goes — if you cancel there, nothing is saved. On iOS and desktop
you choose the destination folder first instead. Inside the zip are the
database, the media you asked for, and a small manifest describing the
export.

Under **Export Settings**, three switches control what goes in; a fourth
appears only in special builds. The first two are on when you open the
screen.

| Switch | Effect |
|---|---|
| **Include documentation files** | Adds the photos, sketches and PDFs attached to caves and places. |
| **Include raster map images** | Adds the scanned map images behind your raster maps. |
| **Diff export (only new files)** | Trims the media to what is new since your last full export — see below. |
| **Include FTP account passwords** | Special builds only — see the warning below. |

There is no cave picker: every export covers the whole database. On
Android the app never asks for a storage permission — it builds the
archive privately and then opens the system save dialog, where you choose
the destination and the dialog grants the write itself.

#### What a diff export really is

**Diff export (only new files)** does *not* make a smaller database. The
database always goes out in full. The switch only affects the attached
media, and it bundles just the documentation files and raster-map images
**added** since your last *full* export.

Two consequences bite people:

- Replacing an image in place does not make it a "new file". A re-scanned
  map that reuses the old file name is not in the diff.
- A diff export does not move the baseline. Your next diff is still
  measured from the same full export, not from the diff you just made.

So a diff is a convenience for topping up a team-mate who already has last
month's full archive. It is not a backup.

#### The FTP password switch

**Include FTP account passwords** is not present on a normal install — it
appears only in special test builds, and ordinary builds refuse to write
passwords into an archive even so. Where it does appear and is switched
on, the archive carries your server logins in readable form, and importing
it on another device installs them into that device's saved
[FTP profiles](ftp-sync.md) without asking, on **both** Replace and Merge
imports. Never pass such an archive to anyone.

The same rule applies in reverse: only import archives from people you
would trust with your own server login.

### A raw database copy

**Settings → Database → Export database**. Writes a copy of the database
as `speleo_loc_export.sqlite` — on Android and desktop your device's save
dialog opens with that name filled in and you choose where it goes; on iOS
you pick the folder.

It is small and fast, but it contains **no** documentation files and **no**
raster map images. Restoring it on a device that does not already hold
those files leaves every photo and map showing as missing. Use it for
quick snapshots you intend to restore on the **same device**.

### Smaller, focused exports

Several screens export one thing rather than everything:

- **Generate QR codes for caves** produces a PDF, or a zip of images —
  see [QR codes](qr-codes.md).
- A trip's **Export report** produces a single report file — see
  [Trip reports](trip-reports.md).
- Ruuvi history has its own **Export CSV** — see
  [Ruuvi sensors](ruuvi-sensors.md).

## Importing an archive

**Settings → Data Export / Import → Import Archive**, then pick the zip.
There is one button for both modes; the app asks which you want *after*
you have chosen the file.

The **Import Mode** dialog offers:

- **Replace all data** — "Replaces the current database and all files.
  Application will restart."
- **Merge with existing data** — "Merges imported data with existing data.
  You can resolve conflicts."

That question is only asked when your device already holds at least one
cave. On a device with no caves, the archive is imported in **Replace all
data** mode without offering the choice.

### Replace all data

One confirmation, then the archive's database takes the place of yours and
its media files overwrite anything of the same name. The app restarts.

**This is destructive and there is no undo.** Everything currently on the
device is gone. Export an archive first if you are not certain.

Your device keeps its own identity through a replace — it does not start
pretending to be the device that made the archive, which is what stops
sync from getting confused afterwards.

### Merge with existing data

The importer walks the incoming records and adds the ones you do not have.
When an incoming record collides with one of yours, it stops and shows a
**Conflict in …** dialog naming the record type, listing the conflicting
fields, and showing **Existing** and **Imported** side by side.

Five buttons:

| Button | What it does |
|---|---|
| **Skip** | Keep the record you already have. |
| **Overwrite** | Replace it with the incoming one. |
| **Skip All** | Keep yours for every remaining conflict in this import. |
| **Overwrite All** | Take the incoming one for every remaining conflict. |
| **Cancel Import** | Stop immediately — see the warning below. |

**Skip All** and **Overwrite All** are wider than they look: they apply to
every remaining conflict in the whole import, across all record types, not
just the type you were looking at.

Records are matched by name and by what they belong to — a cave by its
title within its surface area, a place by its title within its cave and
cave area — not by any hidden identity. So the same place created
independently on two phones turns up as a conflict rather than merging
quietly, and a genuinely different cave that happens to share a title with
one of yours in the same surface area will collide too.

#### What a merge does not bring across

A merge covers a fixed list of record types: surface areas and surface
places, caves, cave areas, entrances, cave places, raster maps, map point
definitions, documentation files and their links, trips and trip points,
and the shared settings.

Anything else in the archive is silently left behind:

- **BLE tag registrations**,
- **users**,
- **trip report templates**,
- **the change history**,
- **Ruuvi sensor history**,
- device-local settings such as which cave you had open.

All of those arrive only with a **Replace all data** import — or, for most
of them, through [manual sync](sync-and-change-log.md).

A merge also never *deletes* anything. If a team-mate removed a cave and
sent you an archive, the cave stays on your device. Manual sync behaves
the opposite way and does replay their deletions.

#### Media files are never overwritten by a merge

A merge copies a photo, sketch or map image out of the archive only when
no file of that name already exists on your device. An incoming file that
shares a name with one you have is skipped — so if someone re-shot a photo
or re-exported a map image under the same name, you keep the old picture
and the **Files copied** count comes out lower than you expected. Only
**Replace all data** overwrites media.

#### The Import Complete summary

When a merge finishes, an **Import Complete** dialog reports four numbers:
**Records imported**, **Records skipped**, **Records overwritten** and
**Files copied**. If anything went wrong along the way — a record that
could not be reconnected to its cave, a file that failed to copy, a record
type missing from an older archive — up to ten **Warnings** are listed
underneath in orange, with a "… and N more" line if there were others.

Read them. Warnings here are the only sign that part of the archive did
not land.

#### Cancelling a merge leaves the database half-merged

**Cancel Import** stops the merge where it stands. Everything already
imported or overwritten before that point **stays in your database** and
is not rolled back; you get only a short "Import cancelled" message and no
summary. Media files are not copied at all, because that step runs after
the records.

If you cancel a merge here, treat the database as half-merged: re-run the
same import to completion, or restore a backup. (Cancelling on the
**Man. sync** screen is safe by comparison — that import is undone
entirely and says so.)

## Restoring a raw database file

**Settings → Database → Restore database from file**. It asks for
confirmation first, then opens a file picker that accepts `.sqlite` and
`.db` files only — an archive zip cannot be selected here. To restore
everything from an archive, use **Data Export / Import → Import Archive →
Replace all data** instead.

The chosen file then replaces the current database and the app restarts.
Your device keeps its own identity. Any documentation
files or map images the restored database refers to must already be on the
device, or they will show as missing.

**This is destructive and irreversible.** The database you had is deleted,
not archived.

## Reinitializing the database

One button at the top of **Settings → Database** — **Reinitialize
database**, which wipes everything and leaves an empty database. Developer
builds add a second one above it, **Reinitialize database with test
data**, which wipes everything and loads the bundled sample dataset.

Each asks twice: a first confirmation, then a bluntly worded second one
warning that all data will be erased. After that the app restarts. Nothing
is backed up on your behalf.

## Loading the ready-made test dataset

In a developer build, the bottom of **Settings → Data Export / Import**
has a **Test Data** section with a **Download and load test data** button.
It fetches a sample dataset from wherever this build was pointed at —
usually a download over the internet — and installs it as a **full
replacement**: caves, maps and documents currently on the device are
permanently deleted first. You are warned once — but only if there is
something to lose — and the app restarts afterwards.

The released app has no **Test Data** section on this page at all. The
section exists only in developer builds, where it shows an orange note
saying the test data archive URL is not configured if that build was given
no test-data source.

## The SQL command runner

In a developer build, and only when debug mode is switched on, an extra
**Open SQL command runner** button appears at the bottom of
**Settings → Database**. The released app does not contain it, so turning
debug mode on will not reveal it. It sends raw commands straight to the
database with no confirmation and no safety net. It exists for diagnosing
a problem with a developer's help. There is nothing here a caver needs in
normal use, and one mistyped command can destroy data that no backup
covers.

## Backup habits that work

1. **Before anything risky** — reinitializing, a large
   [CSV import](csv-import.md), trying a new version — export a full
   archive with both media switches on, and keep it dated. The file name
   already carries the date and time.
2. **Keep the archive off the device.** A backup that lives only on the
   phone you dropped in the sump is not a backup.
3. **Before going underground**, make sure every device on the team has
   the data it needs. For that exchange use
   [manual sync](sync-and-change-log.md), not a merge import.
4. **Take a full export now and then**, not only diffs — a diff is
   meaningless without the full export it was measured against.
5. **Never share an archive made by a build that offers the FTP password
   switch.**

## See also

- [Sharing data between teams](../workflows/sharing-data.md)
- [Manual sync and the change log](sync-and-change-log.md)
- [FTP sync](ftp-sync.md)
- [Settings](settings.md)
- [Documents](documents.md)
- [Ruuvi sensors](ruuvi-sensors.md)
