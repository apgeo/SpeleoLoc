# Workflow: Sharing data between teams

[← Back to index](../README.md)

Data moves between phones as **zip archives** — either passed by hand,
or dropped in a shared FTP/SFTP folder that the app reads and writes for
you. A club that runs its own SilexGIS registry has a third route, where
caves travel to and from that server instead of in a file. This page walks
through all three and the blunter whole-database tools underneath them.

## Two kinds of archive — do not mix them up

The app makes two different archives on two different screens, and
neither screen can read the other's file. Picking the wrong one is the
most common way a data exchange fails.

| | Sync archive | Full archive |
|---|---|---|
| Made on | **Man. sync → Archive sync**, and by FTP sync | **Data Export / Import** |
| File name | `speleo_loc_sync_1756738327000.zip` | `speleo_loc_2026-09-01_14-32-07.zip` |
| Contents | one line per record, each stamped with the time it was last edited, plus the change history | a copy of the whole database, plus the media files |
| Merging | automatic, **newest edit wins**, no questions asked (unless you ask for them) | asks you about every duplicate name or code |
| Deletions | **replayed** on your device | none travel in the file — but **Replace all data** wipes what is already on the phone |
| Import it on | **Man. sync → Import sync archive** | **Data Export / Import → Import Archive** |

Import each kind on the screen that produced it. A sync archive fed to
**Import Archive** fails because there is no database inside it; a full
archive fed to **Import sync archive** fails because it lacks the sync
description the importer looks for.

Rule of thumb: **sync archives for teamwork between trips**, **full
archives for moving to a new phone or handing over a whole dataset**.

## Route 1: hand a sync archive to another device

This is the everyday case — two cavers surveyed different passages on
their own phones and want to end up with both halves.

Three ways to the screen, all the same place:

- **Settings → Man. sync**
- the plain circular-arrows **sync** icon in the home toolbar
- **Man. sync** in the app menu (the ⋮ button at the top right of most
  screens)

Careful with the **cloud** icon sitting next to the sync icon in the home
toolbar: it does not open this screen, it starts an FTP sync immediately
(see route 2).

> 📷 [Manual sync — the archive tab](../screenshots/06-sync-and-sharing.md#sync-dashboard-archive-tab) — The Archive sync tab: export settings, conflict resolution and the import action.

### Export

1. Open **Man. sync** and stay on the **Archive sync** tab.
2. Under **Export Settings**, decide whether to include
   **Include documentation files** (photos, sketches, notes) and
   **Include raster map images**. Both are on by default; turning them
   off makes a much smaller zip that still carries every record.
3. Press **Export sync archive**. On Android the zip is built first and
   your device's save dialog then asks where to put it; on iOS and
   desktop you pick a destination folder first.
4. The screen prints **Archive exported** followed by the saved file's
   name on Android, or its full path on iOS and desktop. Send that zip by
   any means you like — chat, email, cloud folder, cable.

### Import

1. On the receiving phone, open **Man. sync → Archive sync**.
2. Choose a **Conflict resolution** mode:
   - **Automatic (last writer wins)** — the newer edit of any record
     silently wins. This is the normal choice.
   - **Manual (review each conflict)** — you are shown each record whose
     fields differ, side by side, with the two edit times, and choose
     **Keep local**, **Use incoming**, **Keep all local**,
     **Use all incoming** or **Cancel import**.
3. Press **Import sync archive** and pick the zip.
4. Confirm the **Import sync archive?** prompt. Read it — it is the only
   warning that deletions travel too.
5. When it finishes you get one line: **Import complete** followed by
   how many records were added, updated and deleted, and how many change
   history entries and files came across.

**Cancel import** here is safe: the whole import is undone and the
message says *Import cancelled — no changes were applied*.

### What an import can quietly do to your data

- **It can delete your records.** A sync archive carries what the other
  device deleted as well as what it added. Those deletions are replayed
  on your phone: a cave, place, map or document your team-mate removed
  disappears from yours too. Your copy survives only if you edited it
  *strictly after* they deleted it; if the two happened in the same
  instant, the delete wins. This happens in **Manual** mode as well —
  the review dialog only ever covers edits, so you are never asked
  before something vanishes.
- **Two people with the same user name become one.** An incoming user
  whose name already exists on your device is treated as the same
  person, and their records are attached to your local user. That is
  what lets the default user work across phones — but if two cavers
  independently made accounts with the same name, the change history
  will from then on credit both of them under one name.
- **Photos and map images are never overwritten.** A file is copied out
  of the archive only if you do not already have one with that name. If
  someone re-shot a photo or re-exported a map image under the same file
  name, you keep the old picture, and the "files" count is lower than
  you expected.
- **A damaged archive still imports.** A corrupt record, or one that
  clashes with an unrelated local record on a unique code, is skipped
  and the rest is merged rather than failing the whole import. Compare
  the counts in the result line against what you expected to receive.
- **An archive from a newer app version is refused** outright, with a
  message naming the version you need to update to. One from a much
  older version is refused too — re-export it from an up-to-date phone.

## Route 2: let a shared FTP/SFTP folder do the passing

Same sync archives, but nobody has to carry files around: every phone
uploads its own archive to a folder on a server you control and imports
the ones the others left there.

1. **Settings → FTP / SFTP sync** → **Add profile**. Fill in **Name**,
   **Protocol** (FTP, FTPS (explicit TLS) or SFTP (over SSH)), **Host**,
   **Port**, **Username**, **Password** and **Remote folder**, then use
   **Test connection** before saving.
2. With more than one profile, open a profile's ⋮ menu and pick
   **Use as default** — every one-tap sync uses the default.
3. Make sure this device has an identity: syncing refuses to upload
   without one and tells you to open **Settings → Users** first.
4. Start a run, either from the **cloud** icon in the home toolbar, from
   the FTP sync card at the bottom of the app menu (**Sync now**), or
   with the play button on the **FTP sync** screen itself.

A run lists the folder, downloads the newest unseen archive each other
device left there (an older one from the same device is skipped, because
every archive is a full snapshot), imports each one **automatically** —
the last-writer-wins rule, no conflict prompts — and only then uploads an
archive of its own, and only if something changed locally since its last
upload. A phone that has
merely received data leaves the server untouched.

The **FTP sync** screen has three tabs: **Progress** (phase, overall
progress, current file, transferred bytes, speed, ETA), **Log** (every
step of every run, newest entry first, with a *new sync. session*
divider between runs) and **Change log**. **Pause sync** restarts the
current step from the beginning when you resume, so a paused run costs a
little bandwidth, never data.

Everything an FTP import does to your database is exactly what
"What an import can quietly do to your data" above describes —
including replaying deletions, without a prompt. Full details of the
profile fields and the log are in [FTP sync](../features/ftp-sync.md).

## Route 3: sync caves with your club's server

If your club already runs a SilexGIS installation — a cave registry with a
web interface, its own accounts and permissions — this device can exchange
caves with it directly, with no archive changing hands.

1. **Settings → Club server (SilexGIS)** → **Add a server**, and give it a
   **Name** and the installation's **Address**.
2. **Sign in** with your account on that installation — the same one you
   use in its web interface.
3. Press **Choose** on **Caves this device carries** and pick a selection.
   Selections are made on the server, not in the app: if your account owns
   none, the picker says so and there is nothing to sync yet.
4. **Sync now** sends what changed here, then reads what changed there.
   **Read everything** re-reads the whole selection, which is what brings
   down a cave somebody has just given your account access to.

A cave the server has never heard of goes up only if you turn on **Send
caves I survey elsewhere**; left off, the sync carries the caves you were
given and whatever you added inside them.

This route does not replace the other two. Only caves, cave areas, cave
places and surface areas travel; documents, photos, raster map images,
trips, beacon registrations, users and the change log do not, so a team
that needs those still passes archives. Deletions travel both ways without
a prompt, and take with them what hangs off the deleted cave or place.

There is no button for it anywhere else in the app, so a run happens only
when you open that screen and ask for one. This is recent work with rough
edges, and it is worth having only if the installation already exists —
leave the screen alone and the app behaves exactly as it always has. Full
details in [Club server sync](../features/silexgis-sync.md).

## Route 4: hand over the whole dataset

**Settings → Data Export / Import** is the "everything, in one file"
route: a new phone, a handover, an off-device backup.

### Export a full archive

1. Open **Settings → Data Export / Import**.
2. Under **Export Settings** choose:

   | Switch | What it does |
   |---|---|
   | **Include documentation files** | bundles the photos, sketches, audio and notes |
   | **Include raster map images** | bundles the scanned cave maps |
   | **Diff export (only new files)** | the database still goes out **in full**; only documentation files and map images *added since your last full export* are bundled. A diff export does not move that baseline, so the next diff still measures from the same full export. |
   | **Include FTP account passwords** | present only in specially built copies of the app; stores your server logins inside the archive |

   There is no cave picker: every export covers the whole database, and
   you cannot export a single cave.
3. Press **Export Archive**. On Android the zip is built first, then your
   device's save dialog opens with its name filled in and you choose
   where it goes; on iOS and desktop you pick the folder first.
4. You get one zip named for the moment it was made —
   `speleo_loc_2026-09-01_14-32-07.zip`, or `..._diff.zip` for a diff
   export.

### Import a full archive

Press **Import Archive**, pick the zip, and the app asks **Import
Mode**. (On a phone with no data yet it skips the question and replaces
straight away.)

**Replace all data** — *destructive and irreversible.* It throws away the
current database and puts the archive's in its place — everything the old
one held is gone — then copies the archive's photos and map images over
the top, overwriting any file of the same name, and restarts the app.
Confirm the warning first. Your phone keeps its own device identity
rather than adopting the sender's.

**Merge with existing data** — walks the archive record by record and
adds what is missing:

1. Records that do not clash are added.
2. On a clash — a duplicate title, a duplicate place code — a dialog
   headed **Conflict in Caves** (or Cave Places, Raster Maps, Cave
   Trips, Documentation Files, …) shows **Existing** and **Imported**
   side by side and offers **Skip**, **Overwrite**, **Skip All**,
   **Overwrite All** or **Cancel Import**. **Skip All** and **Overwrite
   All** apply to every remaining conflict in the whole import, across
   all record types — there is no per-type setting.
3. Media files are copied only where you do not already have a file of
   that name.

> **Cancelling a merge leaves the job half done.** Unlike Man. sync,
> **Cancel Import** here stops where it stands and everything already
> imported or overwritten stays in your database. If you cancel, either
> run the import again or restore a backup.

A merge deliberately covers only part of the data. Users, beacon
assignments, trip report templates and the change history come across
**only** with **Replace all data**.

### The Import Complete summary

After a merge, a dialog headed **Import Complete** reports
**Records imported**, **Records skipped**, **Records overwritten** and
**Files copied**. If anything went wrong — a record that could not be
linked back to its cave, a file that failed to copy, a kind of record
missing from an older archive — up to ten **Warnings** are listed
underneath in orange, with an "… and N more" line for the rest. Read
them: they are the only sign that part of the archive did not land.

### Download and load test data

Developer builds carry a **Test Data** section at the bottom of the same
screen, offering **Download and load test data**, which fetches a
ready-made sample dataset. This is a **full replacement**: everything on
the device — caves, maps, documents — is permanently deleted first, you
are warned once, and the app restarts. A developer build with no
test-data source shows an orange notice there instead of the button. The
released app has no such section at all — no button and no notice. See
[Working with a local test archive](local-test-archive.md).

## Settings → Database: the blunt tools

| Action | What it does |
|---|---|
| **Export database** | writes a raw `speleo_loc_export.sqlite` copy through your device's save dialog (a folder you pick, on iOS). No photos, no map images — a same-device snapshot only. |
| **Restore database from file** | replaces the database with a `.sqlite` or `.db` file you pick, after one confirmation, then restarts the app. It cannot take a zip — restore a whole archive from **Data Export / Import** instead. |
| **Reinitialize database** | erases everything and leaves an empty app. |

Developer builds add a **Reinitialize database with test data** button
above it, which erases everything and fills the app with sample data
instead; the released app does not have it.

Reinitializing is **irreversible**, asks twice, and restarts the app
afterwards. Whenever the database is replaced wholesale, this phone keeps
its own device identity instead of adopting the one in the file.

An **Open SQL command runner** button appears at the bottom of this
screen only in a developer build, and there only when debug mode is on
(nine quick taps on the home screen title); the released app does not
have it. It runs raw database commands with no confirmation and no undo;
it is there for diagnosing a problem with a developer, and a mistyped
command can destroy data no backup covers.

## Which route should I use?

| You want to… | Use |
|---|---|
| swap a trip's worth of survey work with a team-mate | Man. sync, or FTP sync |
| keep a whole club in step without passing files | FTP sync |
| keep your caves in step with a registry your club already runs, edited in its web interface as well as in the app | Club server (SilexGIS) — needs an account there and a selection of caves chosen there |
| move photos, maps, trips, beacons or the change log | anything but the club server: it carries only caves, areas and places |
| move everything to a new phone | Data Export / Import → export, then **Replace all data** |
| fold a whole outside dataset into yours, deciding case by case | Data Export / Import → **Merge with existing data** |
| take a quick backup you will restore on this same phone | Settings → Database → **Export database** |

## Practical tips

- **Before going underground**, make sure everyone has imported the
  latest archive (or run an FTP sync). Missing places and stale maps are
  discovered at the worst possible moment.
- **After a trip**, export a sync archive and share it, or let FTP sync
  do it.
- **Back up before any Replace or Merge.** Both can lose data — Replace
  by design, Merge if you cancel halfway.
- **Only import archives from people you trust.** An archive made by a
  specially built copy of the app can contain that person's FTP or SFTP
  server passwords, and importing it — Replace *or* Merge — writes those
  server logins into your phone without asking.
- **Trim the payload** when only the records matter: turn off
  **Include documentation files** and **Include raster map images**, and
  a large dataset becomes a small zip.
- **Leave the file names alone.** They already carry the date and time,
  which is what makes a pile of archives readable later.
- **Any channel works** — these are ordinary zip files. Chat, email, a
  cloud folder, a USB cable.

## See also

- [Manual sync and the change log](../features/sync-and-change-log.md)
- [FTP / SFTP sync](../features/ftp-sync.md)
- [Club server sync](../features/silexgis-sync.md)
- [Database export, import and backup](../features/database-export-import.md)
- [Users](../features/users.md)
- [Working with a local test archive](local-test-archive.md)
- [Settings](../features/settings.md)
