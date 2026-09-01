# Manual sync and the change log

[← Back to index](../README.md)

**Man. sync** is the screen where you hand your data to another device as
a single archive file, and where you look back at every record change
recorded on this device. It has two tabs: **Archive sync** and
**Change log**.

Two other routes move data without a file you carry: [FTP / SFTP
sync](ftp-sync.md) leaves the same whole-device archives in a shared
folder for the team, and [Club server (SilexGIS)](silexgis-sync.md), at
**Settings → Club server (SilexGIS)**, exchanges caves, cave areas,
places and surface areas — and nothing else — row by row with a cave
registry your club runs.

## Opening the screen

Three ways in, all leading to the same place:

- **Settings → Man. sync**
- the **sync icon** (plain circular arrows) in the home toolbar
- **Man. sync** in the app menu, opened with the ⋮ button at the
  top right of most screens

Beware the **cloud icon** sitting right next to the sync icon in the home
toolbar. It does *not* open this screen: it starts an FTP sync with the
default server profile straight away and opens the FTP sync screen. See
[FTP sync](ftp-sync.md).

> 📷 [The settings list, bottom](../screenshots/07-settings.md#settings-main-bottom) — Settings scrolled down to the data-sharing and beacon entries.

## Archive sync

A sync archive is a `.zip` holding one line per record, each stamped with
the time it was last edited. The receiving device merges those records
into what it already has instead of replacing anything, so both devices
end up with the union of the two datasets, with the **newest edit
winning** on any record they both changed.

That makes it the right tool between trips: two cavers survey different
parts of the same cave on their own phones, swap archives, and each ends
up with both halves.

> 📷 [Manual sync — the archive tab](../screenshots/06-sync-and-sharing.md#sync-dashboard-archive-tab) — The Archive sync tab: export settings, conflict resolution and the import action.

### What travels in a sync archive

| Carried | Not carried |
|---|---|
| Caves and cave areas, cave places and their beacon assignments | Your device's own identity |
| Raster maps and the places pinned on them | Which user is currently signed in on this device |
| Trips and the points recorded on them | Which cave was last open |
| Documents and their links to places and trips | Anything not listed on the left |
| Trip-report templates, users, surface areas | |
| The shared place-code and QR settings, so every device generates codes the same way | |
| The whole change log, always | |

The documentation files themselves (photos, sketches, PDFs) and the
raster map images are large, so they are optional — see the two switches
below.

### Exporting a sync archive

1. Open **Man. sync → Archive sync**.
2. Under **Export Settings**, decide what to bundle:
   - **Include documentation files** — the actual photos, sketches and
     other files attached to places and trips.
   - **Include raster map images** — the scanned survey images.

   Both are on by default. Turning them off produces a much smaller
   archive that still carries every record, but the receiving device
   will show placeholders where the images should be.
3. Tap **Export sync archive** and pick a folder ("Select folder for the
   archive").
4. The archive is written as a single `.zip` whose name starts with
   `speleo_loc_sync_`, and the path appears at the bottom of the screen
   next to **Archive exported**.

Send that file however you like — cable, cloud drive, messaging app. See
[Sharing data between teams](../workflows/sharing-data.md).

### Importing a sync archive

Before you import, choose a **Conflict resolution** mode. It sits in the
lower half of the tab, above the import button, and it is the *importing*
device's choice — nothing about it is stored in the archive.

| Mode | What happens |
|---|---|
| **Automatic (last writer wins)** | Older entries are silently overwritten, using the edit timestamp. The default. |
| **Manual (review each conflict)** | You are prompted for every record whose fields differ from your local copy. |

Then:

1. Tap **Import sync archive** and pick the `.zip`.
2. Confirm the **Import sync archive?** prompt. Read it: it warns that
   newer local edits are kept, older ones overwritten, and that
   **deletions carried by the archive are applied to your database**.
3. The merge runs. In Manual mode a dialog appears for each conflicting
   record (see below).
4. A one-line summary appears under the buttons, for example
   `Import complete: +12 / ~3 / -1 (57 Change history, 8 files)` —
   records added, records updated, records deleted, change-log entries
   merged, and media files copied.

### Reviewing a conflict by hand

In **Manual (review each conflict)** mode, each clashing record opens a
dialog headed **Conflict in** *(record type)*. It lists the fields that
differ, the two edit times (**Local updated** / **Incoming updated**) and
a side-by-side table with a **Local** and an **Incoming** column, so you
can see exactly what you would be trading away.

| Button | Effect |
|---|---|
| **Keep local** | Discard the incoming version of this one record. |
| **Use incoming** | Overwrite your version of this one record. |
| **Keep all local** | Answer "keep local" for this record and every remaining conflict, without asking again. |
| **Use all incoming** | Answer "use incoming" for the rest of the import. |
| **Cancel import** | Abandon the whole import. |

**Cancel import** here is safe: the entire import is rolled back and the
screen reports *Import cancelled — no changes were applied*. (This is
**not** true of the **Merge with existing data** import on the Data
Export / Import screen, which leaves behind whatever it had already
written — see
[Database export, import and backup](database-export-import.md).)

### Importing can delete your records

A sync archive carries what the other device *deleted* as well as what it
added and edited, and importing replays those deletions on your device. A
cave, place, map or document your team-mate removed will be removed from
your database too.

This is irreversible and nothing prompts you record by record:

- The record survives only if you edited it **strictly after** they
  deleted it. If the two happened at the same moment, the deletion wins.
- **Manual (review each conflict)** does not help here. The conflict
  dialog only covers edits; deletions are always applied silently.

If you are unsure about an archive, export your own data first (or take a
database backup) so you can get a deleted record back.

### Other things worth knowing before you import

- **Media files are never overwritten.** A photo or map image is copied
  out of the archive only when no file of that name already exists on
  your device. If someone re-shot a photo and kept the file name, you
  keep your old picture, and the "files" count in the summary will be
  lower than you expected.
- **Two people with the same user name become one.** An incoming user
  whose user name already exists on your device is treated as the same
  person, and their records are attached to your local user. That is
  what lets the built-in default user work across devices — but if two
  cavers independently picked the same user name on different phones,
  syncing quietly merges them and the change log will credit both to one
  name.
- **A partly damaged archive still imports.** A record that is corrupt,
  or that collides with an unrelated local record on a unique code, is
  skipped and the rest of the archive is merged anyway. That is usually
  what you want in a hut with one bar of signal, but it means an import
  can report success while a few records quietly stayed behind. The
  counts in the summary line are your only clue — compare them against
  what you expected to receive.
- **Only the archive format and the database version are checked.** The
  app never asks which device an archive came from, and shows no warning
  for an unfamiliar one. An archive produced by a *newer* app than yours
  is refused with a message telling you which version to update to; one
  from a much older app is refused too, and must be re-exported from the
  source device with an up-to-date app.

### Your device keeps its own identity

Whenever the database is replaced wholesale — restoring a raw database
file, or importing an archive with **Replace all data** — the app puts
this device's own identifier back afterwards, so it does not start
impersonating the device the file came from. No screen offers a switch
for it, and it does not arise when importing a sync archive, which merges
records rather than swapping the database.

### Archive sync vs the full data export

|  | Archive sync (this page) | [Full data export/import](database-export-import.md) |
|---|---|---|
| What is in the file | One line per record | A copy of the whole database plus the media |
| Granularity | Record-by-record merge | Whole-database replace, or a coarse record-by-record merge |
| Conflict handling | Newest edit wins, or a prompt per record | Skip / Overwrite prompts per duplicate name or code |
| Deletions replayed? | Yes, always | No (a **Replace all data** import simply discards everything you had) |
| Includes change log? | Always | Arrives with **Replace all data**, dropped by **Merge with existing data** |
| Best for | Frequent device-to-device updates between trips | Backups, setting up a new device, moving everything at once |

## Change log

Every record you add, edit or delete is written to the change log, with
the time, the user who was signed in and — for edits and deletions — the
values the record held before. Nothing you do in the app is recorded
twice, and importing an archive does not fill the log with entries of its
own: it merges the *original* entries from the other device instead, so
the history stays honest about who changed what and where.

The log is not just an audit trail. It is what makes two other things
work:

- it **carries deletions** to other devices, so a place you delete here
  also disappears there;
- it lets **FTP sync** decide whether this device has anything worth
  uploading — when nothing has changed locally since the last sync, no
  archive is built or sent at all (see [FTP sync](ftp-sync.md)).

A [club server sync](silexgis-sync.md) leaves no mark here at all. The
caves and places it brings down are written into your database without an
entry of their own, and so are the ones it removes — so a cave deleted on
the club's registry disappears from this device, but that deletion is not
carried on to your other devices in an archive. What it sends is worked
out from the records themselves rather than from this log.

### Reading it

Open **Man. sync → Change log**. It is a plain list, newest first; pull
down to refresh. Each entry shows:

| Part of the entry | Meaning |
|---|---|
| Operation | **Added**, **Edited** or **Deleted**, with a colour-coded icon — green plus, blue pencil, red bin. |
| Record | The kind of record and, where the app can still find it, its title. |
| When | Date and time of the change, to the second. |
| Who | The user who was signed in at the time (see [Users](users.md)), shown as the user name with the full name in brackets. |

> 📷 [Manual sync — the change history tab](../screenshots/06-sync-and-sharing.md#sync-dashboard-change-log-tab) — The Change log tab listing recent record changes with author and timestamp.

### Expanding an entry

An **Edited** entry opens to show **Fields changed**: the fields that were
touched, each with the value it held *before* the edit. The new value is
not stored — it is simply whatever the record shows now.

Two limits are worth knowing:

- Any previous value longer than about 20 characters is not kept, and
  shows as *(value truncated)*. Descriptions and long titles therefore
  leave no readable history, only the fact that they changed.
- **Deleted** entries expand to the record's last known values, which is
  often enough to recreate it by hand. **Added** entries have nothing to
  expand and do not open.

> 📷 [An expanded change-history entry](../screenshots/06-sync-and-sharing.md#ftp-sync-change-log-details) — The Change log tab of the FTP sync screen, listing recorded record changes.

### What the change log cannot do

- **No filters.** There is no way to narrow the list by date, by record
  type or by user.
- **Only the 200 most recent entries** are loaded. Older history is
  still in the database and still travels in sync archives, but this
  screen will not show it to you.
- **It is never cleared.** There is no button for it and nothing purges
  it in the background; it grows with every edit you make. The only way
  to be rid of it is to replace the database entirely — reinitialize it,
  or import an archive with **Replace all data**.
- **No session markers.** It is one continuous list.

### The change log during an FTP sync

The FTP sync screen carries the same **Change log** tab as a third tab
beside **Progress** and **Log**, so you can see what your device is about
to send while it sends it.

Do not confuse it with the **Log** tab next door: that one is the FTP
sync's own activity log, and it marks each run with a
`─── new sync. session ───` separator line. Those separators belong to
that log only — the change log itself has no notion of a session.

## See also

- [FTP sync](ftp-sync.md)
- [Club server sync](silexgis-sync.md)
- [Database export, import and backup](database-export-import.md)
- [Users](users.md)
- [Sharing data between teams](../workflows/sharing-data.md)
- [Place code identifiers](place-code-identifiers.md)
- [Settings](settings.md)
