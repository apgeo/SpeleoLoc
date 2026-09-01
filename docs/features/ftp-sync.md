# FTP / SFTP sync

[← Back to index](../README.md)

SpeleoLoc can keep a whole team in step through an ordinary FTP, FTPS or
SFTP folder: each device leaves a snapshot of its database there and
picks up the snapshots the others left. This page covers setting up a
server profile, running a sync, and reading what came of it.

> There is no SpeleoLoc server. Any FTP, FTPS or SFTP account will do — a
> club NAS, a web host, a machine at home — as long as everyone on the
> team can read **and write** in the same folder.

For archives you carry by hand (a file on a stick, a file sent by
e-mail), see [Manual sync and the change log](sync-and-change-log.md).

## What one run does

1. Connects to the **default** server profile and lists the folder.
2. Downloads every archive it has not seen before, checks it against its
   checksum, and merges it into your database.
3. If — and only if — you have made changes on this device since your
   last upload, builds a fresh snapshot of your whole database and
   uploads it, along with a small checksum file beside it.

Every archive is a **complete snapshot** of the device that made it, not
a list of recent changes. The receiving device works out what is new
when it merges, so nothing is lost if you skip a few syncs; the price is
that every upload carries the whole dataset again.

## Setting up a server profile

**Settings → FTP / SFTP sync** opens the profile list. Before you have
added anything it reads **No FTP profiles yet**; press **Add profile**.

> 📷 [The list of FTP profiles](../screenshots/06-sync-and-sharing.md#ftp-sync-profile-list) — The FTP / SFTP sync settings screen listing the configured server profiles.

| Field | What to put in it |
|---|---|
| **Name** | Required free-form label, e.g. "Team NAS". It shows on the profile row, on the sync card in the app menu, and under the heading on the sync screen. |
| **Protocol** | **FTP**, **FTPS (explicit TLS)** or **SFTP (over SSH)**. FTPS here means explicit TLS on the normal FTP port; implicit FTPS on port 990 is not supported. |
| **Host** | Required. The server name or address, without a protocol prefix. |
| **Port** | Leave empty to use the protocol's default — 21 for FTP and FTPS, 22 for SFTP. The box is not filled in for you: the default appears only as grey hint text. A number outside 1–65535 is rejected with **Invalid port**. |
| **Username** | Required. |
| **Password** | Required on a new profile. It is kept in the device's secure keystore, not in the database. On a saved profile the box shows a `********` placeholder with the helper text **Leave blank to keep the current password** — tap it to type a new one, or leave it alone to keep the old one. |
| **Remote folder** | The folder where SpeleoLoc reads and writes archives, for example `/speleo_loc/sync/`. Leave it empty and it falls back to the server root, `/`. Everyone on the team must point at the *same* folder. |
| **Passive mode** | FTP and FTPS only, on by default. "Recommended when the server is behind NAT" — it is what makes FTP work through home routers and mobile networks. Turn it off only if your server insists on active mode. |
| **Allow invalid TLS certificate** | FTPS only, off by default, meant for a trusted server with a self-signed certificate. In the current version this switch is remembered with the profile but is **not applied to the connection**, so a self-signed FTPS server may still be refused. |

The eye button beside the password fetches the stored password and shows
it on screen in clear, so use it only when nobody is looking over your
shoulder.

If the remote folder does not exist yet, SpeleoLoc tries to create it the
first time it connects — including during a connection test. If your
account may not create folders, the connection fails; create the folder
by hand, or point at one that already exists.

### Test connection

**Test connection** is a button inside the add/edit form, not an item in
the profile list's menu. It signs in, lists the remote folder, then
writes a tiny probe file and deletes it again — so it proves you can
**write** there, not merely read. The verdict appears as a green
**Connection successful** or a red **Connection failed** /
**Authentication failed** message at the bottom of the screen. On a
brand-new profile you must type the password before the test will run,
otherwise you get **Password is required**.

> 📷 [Editing an FTP profile](../screenshots/06-sync-and-sharing.md#ftp-sync-profile-edit) — Editing an FTP sync profile after a successful connection test.

### The default profile, and the profile menu

There is no "default" switch on the form. From a profile row's ⋮ menu:

- **Use as default** — every sync uses this profile. The default row is
  highlighted in the list.
- **Edit** — same as tapping the row itself.
- **Delete** — asks **Delete profile?** first, then removes the profile
  and its stored password. This cannot be undone.

Your **first** profile becomes the default automatically, and if you
delete the default another profile is promoted in its place. Since every
sync uses the default and there is no picker anywhere, make sure the
right profile is the marked one before you start.

## Running a sync

Start a run from any of these:

- the **cloud icon** in the home toolbar (it moves up into the top bar
  when the toolbar is hidden). Beware the plain circular-arrows **sync
  icon** next to it — that one opens
  [Man. sync](sync-and-change-log.md) instead;
- the sync card near the bottom of the app menu, opened with the ⋮
  button at the top right of most screens. Before a profile exists it
  reads **Configure FTP to enable sync** and takes you to the settings;
  once there is a default it reads **Sync now** with the profile name
  underneath and a play button that starts the run *without closing the
  menu*, so the bar and the current file name run in front of you;
- the play button in the top bar of the **FTP sync** screen itself.

What happens then:

1. The run starts **immediately** — there is no confirmation and no
   profile picker — and, unless you started it from the app menu, the
   **FTP sync** screen opens on top of it. If there is no default
   profile, or it has no stored password, the run fails at once.
2. The header on the **Progress** tab names the current phase:
   **Connecting…**, **Listing remote archives…**, **Downloading
   archive**, **Importing archive**, **Generating local archive…**,
   **Uploading archive**, **Finalizing…**. Underneath it are the profile
   name and **Started at**.
3. **Overall progress** is a single bar for the whole run, with an
   **Archives: 2 / 5** count once the download queue is known. Under
   **Current file** you get the file's name, **Transferred** so far out
   of its total, **Speed** and **ETA** — all for that one file, not for
   the run. The speed is smoothed over the last few moments, so it
   settles down after a second or two instead of jumping about.
4. When it ends, the header reads **Sync complete**, **Sync failed**,
   **Sync cancelled** or **Sync paused**. There is no per-step summary
   here — what the run actually did is on the **Log** tab.

> 📷 [An upload running](../screenshots/06-sync-and-sharing.md#ftp-sync-upload-running) — Archive upload underway, with live Transferred, Speed and ETA readings.

### The three tabs

| Tab | What it shows |
|---|---|
| **Progress** | The phase header, the overall bar and the current file, as above. On a failure, a red banner with the error text. |
| **Log** | A timestamped account of everything the run did, newest first, with blue-grey information lines, orange warnings and red errors, and a badge counting the lines. Runs are separated by a `─── new sync. session ───` divider. The last 200 lines are kept. |
| **Change log** | The local change log — the same view as the **Change log** tab of Man. sync, so you can watch what your device is about to send. |

The **Log** tab is where a sync explains itself: how many new archives
were found, each file downloaded with its size, each checksum verified,
how many rows an import added, changed and skipped, and every archive
that was skipped and why. When a run did not do what you expected, look
there first.

> 📷 [The sync log tab](../screenshots/06-sync-and-sharing.md#ftp-sync-log-tab) — The Log tab listing each step of the last FTP sync, newest first.

### The buttons in the top bar

- **Start sync** (play) — shown when no run is under way or paused;
  starts a fresh run with the default profile.
- **Pause sync** / **Resume sync**.
- **Cancel sync** (stop) — aborts the transfer in progress as soon as it
  notices. Anything not yet imported is simply picked up next time.
- **FTP sync settings** (gear) — opens the profile list, for when you
  spot a misconfiguration mid-run.

## What actually travels

### Coming down

Only the **newest** archive from each other device is downloaded. Since
each one is a full snapshot, older archives from the same device are
redundant; the Log tab notes them as *superseded* and they are written
off only once that device's newest archive has been dealt with, so one
corrupt file cannot strand a good older snapshot. Files in the folder
that are not SpeleoLoc archives are ignored entirely. Archives are
handled oldest first.

Every archive published by a recent version of the app has a companion
checksum file beside it. After downloading, SpeleoLoc recomputes the
fingerprint and compares: if they differ the archive is thrown away
instead of imported, the Log tab says so, and the file is left on the
server for a later attempt. This catches both damage in transit and a
file that has rotted on the server. Older archives that have no
companion file are imported without that check.

### Going up

The upload is a **complete snapshot of this device**: every synced table,
the whole change log, and *all* of your documentation files and raster
map images. Nothing can be left out — the **Include documentation files**
and **Include raster map images** switches live on the Man. sync screen
and the data export screen, and apply only to archives you export by
hand there. A large photo or map library therefore makes every upload
large.

Alongside the archive, SpeleoLoc uploads its checksum file so that other
devices can verify what they download. If that small extra upload fails,
the archive still stands and the Log tab records that it went up without
an integrity hash.

### When nothing is uploaded

If you have made no changes of your own since your last upload, the
upload half is **skipped** and the run just ends with the downloads done.

Only changes made on *this* device count. Importing a team-mate's
archive does not by itself trigger an upload — that is what stops two
devices bouncing the same data back and forth forever. The decision is
taken before anything is imported, by comparing this device's own
change-log entries against the newest archive it already has on the
server (or, if there is none there, its own record of when it last
uploaded).

## How a run ends

Whatever happened, a successful run's header reads **Sync complete**.
The last line of the **Log** tab is more precise, and says one of:

- *already in sync, no transfer needed* — nothing new on the server and
  nothing new of yours to send;
- *downloaded N archive(s); no upload needed* — you took in other
  people's work but had none of your own to publish;
- *Sync complete* on its own — both halves ran: you imported what was
  new and published your own snapshot.

That last distinction matters when you want to be sure your work has
actually reached the server.

A run that hit trouble ends as **Sync failed** with a red banner naming
the first problem — even if most of it succeeded. One archive that
failed to download, failed its checksum or failed to import does not
stop the rest, and does not stop your own upload. So a red result does
not mean nothing worked: read the Log tab to see what did. Everything
that failed is deliberately left unmarked, so simply running the sync
again retries it.

For a connection or sign-in failure the red banner also carries an
**Open Settings** button that jumps straight to the profile list.

> 📷 [A completed sync run](../screenshots/06-sync-and-sharing.md#ftp-sync-complete) — The Progress tab after a successful FTP sync run.

## Pausing, resuming, and what does not survive

**Resume sync** restarts the run **from the beginning**: it reconnects,
lists the server again and re-downloads whatever it had already fetched
before you paused. The app says as much on the paused screen — *"Resume
to restart the current step from the beginning."* Nothing is damaged by
that (importing the same archive twice is harmless), but you pay for the
transfer twice, so on a slow link it is usually better to let a run
finish than to pause it.

The progress display and the sync log live only as long as the app is
running. Close or kill the app and the screen comes back at **Idle** with
an empty Log tab, and a paused run cannot be resumed — start a new one.
Interrupting a sync will not corrupt your database: an archive that was
not fully downloaded and imported is left unmarked, so the next run
collects it.

## Conflicts are resolved silently

FTP sync always merges with **last writer wins** and never asks, whatever
you picked on the Man. sync screen. That automatic/manual choice applies
only to archives you import by hand there, and it resets to automatic
every time you open the screen.

If you need to see what an incoming change overwrote, look at the
[change log](sync-and-change-log.md#change-log), or exchange the archive
by hand and import it on the Man. sync screen with manual conflict
resolution turned on.

## Housekeeping on the server

SpeleoLoc **never deletes anything** from the remote folder. Every sync
that uploads adds one archive plus one small checksum file, so the folder
grows steadily — one pair per device per upload.

Tidying up is yours to do, and it is safe: delete old archives (and their
matching checksum files) from the folder, keeping the newest one from
each device. The app also remembers the names of the archives it has
already handled — the most recent 500 — so it does not fetch them twice.

## Security

- Prefer **SFTP (over SSH)** or **FTPS (explicit TLS)**. Plain **FTP**
  is there for old servers, but it sends your username, your password
  and your entire caving database across the network in clear.
- SFTP uses **password authentication only**; key files are not
  supported yet.
- Passwords go into the device's secure keystore, not the database, and
  are never written into a sync archive.
- Data archives exported from the data export screen **never contain**
  FTP passwords in a normal build — there is no switch for it. (An
  "Include FTP account passwords" option exists only in special test
  builds.)

## Troubleshooting

- **Authentication failed** — check the username and password; for SFTP
  make sure the server allows password logins. Remember that on a saved
  profile the password box only shows a placeholder: the eye button
  reveals what is actually stored.
- **Cannot list or write the remote folder** — wrong folder, or an
  account with no write permission there. SpeleoLoc must list, download
  *and* upload in that folder, so **Test connection** fails if its probe
  file cannot be written, even when listing works.
- **The failure banner shows a short code instead of a sentence** —
  `no_default_profile` means no profile is marked as default, and
  `no_password_stored` means the default profile has no password saved.
  Both are fixed in **Settings → FTP / SFTP sync**.
- **An archive was skipped over its app version** — the Log tab says
  which way round it is. From a *newer* version of SpeleoLoc: the
  message names the version you need, and once this device is updated
  the archive imports itself on the next sync. From an *older* version:
  it is skipped for good on this device, and the only cure is to update
  the app that produced it and let that device sync again. Either way
  the rest of the run carries on.
- **Checksum mismatch** — the archive is corrupt on the server or was
  damaged in transit. It is left in place and retried next time; if it
  keeps failing, ask that device to sync again, and delete the bad file
  from the folder.
- **Slow syncs** — there is nothing to switch off: a run always sends
  every documentation file and raster map. Sync over a good connection
  when you can, and clear old archives out of the remote folder from
  time to time.
- **`ftp_no_device_uuid`** — this device has no identifier of its own.
  Very rare, since the app gives itself one automatically. Downloads still
  work; only the upload is blocked.

## See also

- [Manual sync and the change log](sync-and-change-log.md)
- [Sharing data between teams](../workflows/sharing-data.md)
- [Database export, import and backup](database-export-import.md)
- [Users](users.md)
- [Settings](settings.md)
- [Home screen](home-screen.md)
