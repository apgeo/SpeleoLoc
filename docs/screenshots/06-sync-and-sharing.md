# Sync and sharing

[← Screenshot index](README.md) · [← Wiki index](../README.md)

Manual archive exchange, the change history, and FTP/SFTP sync from profile to finished run.

> The app runs in **Romanian** by default, so the screenshots show Romanian labels. Each entry lists the on-screen wording next to its English equivalent.

**On this page:** [Manual sync — the archive tab](#sync-dashboard-archive-tab) · [Manual sync — the change history tab](#sync-dashboard-change-log-tab) · [The list of FTP profiles](#ftp-sync-profile-list) · [Editing an FTP profile](#ftp-sync-profile-edit) · [An upload starting](#ftp-sync-upload-start) · [An upload running](#ftp-sync-upload-running) · [An upload finishing](#ftp-sync-upload-finishing) · [A completed sync run](#ftp-sync-complete) · [The sync log tab](#ftp-sync-log-tab) · [The change history tab during a sync](#ftp-sync-change-log-tab) · [An expanded change-history entry](#ftp-sync-change-log-details)

---

<a id="sync-dashboard-archive-tab"></a>

## Manual sync — the archive tab

![Manual sync — the archive tab](../images/sync-dashboard-archive-tab.jpg)

*The Archive sync tab: export settings, conflict resolution and the import action.*

The Archive sync tab of the Man. sync dashboard, where a device-to-device sync archive is produced or read back in. Under Export Settings the Include documentation files and Include raster map images switches decide what goes into the zip, and Export sync archive writes it out. Conflict resolution selects between Automatic (last writer wins), which silently overwrites older entries using the updated_at timestamp, and Manual (review each conflict), which prompts per differing row; Import sync archive then merges a received archive using that rule.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sinc. man. — Man. sync (app bar title)
- Arhivă sincronizare — Archive sync (selected tab)
- Istoric modificări — Change log (tab)
- Setări export — Export Settings (section heading)
- Include fișiere documentație — Include documentation files (switch, on)
- Include imagini hărți — Include raster map images (switch, on)
- Exportă arhivă de sincronizare — Export sync archive (button)
- Rezolvarea conflictelor — Conflict resolution (section heading)
- Automat (ultima modificare câștigă) — Automatic (last writer wins) (radio, selected)
- Suprascrie automat datele mai vechi folosind câmpul timp de actualizare. — Silently overwrite older entries using the updated_at timestamp. (radio subtitle)
- Manual (revizuiește fiecare conflict) — Manual (review each conflict) (radio)
- Cere confirmare pentru fiecare rând ale cărui câmpuri diferă de cel local. — Prompt for each row whose fields differ from the local copy. (radio subtitle)
- Importă arhivă de sincronizare — Import sync archive (button)
- Intro paragraph (sync_description) explaining last-writer-wins on updated_at

</details>

**Described in:** [Sync and change log](../features/sync-and-change-log.md) · [Sharing data](../workflows/sharing-data.md)

---

<a id="sync-dashboard-change-log-tab"></a>

## Manual sync — the change history tab

![Manual sync — the change history tab](../images/sync-dashboard-change-log-tab.jpg)

*The Change log tab listing recent record changes with author and timestamp.*

The Change log tab of the Man. sync dashboard, a read-only audit trail of every record change recorded on this device. Each row names the operation — Added with a green plus icon, Edited with a blue pencil — followed by the affected table and record, then the timestamp and the author after by. Rows marked Edited carry an expand chevron that opens the changed fields with their old and new values.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sinc. man. — Man. sync (app bar title)
- Istoric modificări — Change log (selected tab)
- Arhivă sincronizare — Archive sync (tab)
- Adăugat — Added (row label, green plus icon)
- Modificat — Edited (row label, blue pencil icon, expandable)
- de — by (author prefix in the row subtitle)
- Entry targets such as 'cave place to raster map definitions', 'raster maps: plan', 'cave places: p10'
- Timestamps in the form 2026-09-01 08:44:54 with user names adig (adi ghita) and congres1
- Expand chevrons on edited rows revealing the changed fields

</details>

**Described in:** [Sync and change log](../features/sync-and-change-log.md)

---

<a id="ftp-sync-profile-list"></a>

## The list of FTP profiles

![The list of FTP profiles](../images/ftp-sync-profile-list.jpg)

*The FTP / SFTP sync settings screen listing the configured server profiles.*

This screen manages the server profiles used for FTP sync. Each profile is a card showing a protocol icon, the profile's display name and a subtitle combining protocol, user, host, port and remote folder; the highlighted card is the profile currently set as default. The per-row overflow menu offers Use as default, Edit and Delete, and tapping a card opens the profile editor. The Add profile button at the bottom right creates a new FTP, FTPS or SFTP profile.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sincronizare FTP / SFTP — FTP / SFTP sync (app bar title, truncated)
- speotopo1 (profile display name on the highlighted default profile card)
- FTP · speleoloc_public_test_1@speotopo.ro@ftp.speotopo… (protocol, user, host and folder subtitle)
- Adaugă profil — Add profile (extended floating action button)
- Per-row overflow menu: Setează ca implicit — Use as default, Editează — Edit, Șterge — Delete

</details>

**Described in:** [Ftp sync](../features/ftp-sync.md) · [Settings](../features/settings.md)

---

<a id="ftp-sync-profile-edit"></a>

## Editing an FTP profile

![Editing an FTP profile](../images/ftp-sync-profile-edit.jpg)

*Editing an FTP sync profile after a successful connection test.*

The FTP profile editor, reached from Settings → FTP sync settings by tapping an existing profile. The user fills in Name, Protocol (FTP, FTPS or SFTP), Host and Port, Username and Password, and the Remote folder the app reads and writes archives in; Passive mode is enabled, which is recommended when the server is behind NAT. Tapping Test connection dials the server without saving, and the green snackbar confirms 'Connection successful'. The save icon in the app bar stores the profile; leaving the password blank keeps the stored one.

<details><summary>On-screen wording (Romanian → English)</summary>

- Editează profil — Edit profile (app bar title)
- save icon in the app bar — Save
- Nume — Name (value: speotopo1)
- Protocol — Protocol (dropdown, value FTP)
- Server — Host (value: ftp.speotopo.ro)
- Port — Port (empty, protocol default)
- Utilizator — Username
- Parolă — Password (masked, with reveal eye)
- Lasă gol pentru a păstra parola curentă — Leave blank to keep the current password
- Folder pe server — Remote folder (value: /)
- Mod pasiv — Passive mode (toggle, on)
- Recomandat când serverul e în spatele NAT — Recommended when the server is behind NAT
- Testează conexiunea — Test connection (button)
- Conexiune reușită — Connection successful (success snackbar)

</details>

**Described in:** [Ftp sync](../features/ftp-sync.md) · [Settings](../features/settings.md)

---

<a id="ftp-sync-upload-start"></a>

## An upload starting

![An upload starting](../images/ftp-sync-upload-start.jpg)

*The Progress tab at the start of an archive upload to the FTP server.*

This is the Progress tab of the FTP sync screen while the app is uploading its own sync archive to the shared server. The phase header reads Uploading archive and names the FTP profile in use (speotopo1) plus the Started at time, then an Overall progress bar and a Current file section show the archive file name with its own bar and the Transferred / Speed / ETA figures underneath. The upload has only just begun here, with 960 KB of a 72.1 MB archive sent. The app bar carries Pause sync and Cancel sync buttons, a shortcut to FTP sync settings and the app menu, and the Log tab badge shows 5 entries so far.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sincronizare FTP — FTP sync (app-bar title, truncated on screen to "Sincro…")
- Progres — Progress (selected tab)
- Jurnal (badge 5) — Log (tab, badge counts log entries)
- Istoric modificări — Change log (third tab, partly cut off)
- Se încarcă arhiva — Uploading archive (phase header with cloud-upload icon)
- speotopo1 — name of the FTP profile being synced
- Început la 02:44:55 — Started at 02:44:55
- Progres total — Overall progress (bar)
- Fișier curent — Current file (archive name plus per-file bar)
- Transferat — Transferred (960.0 KB / 72.1 MB)
- Viteză — Speed (8.0 MB/s)
- Rămas — ETA (8s)
- Pauză — Pause sync (app-bar icon)
- Anulează sincronizarea — Cancel sync (app-bar icon)
- Setări sincronizare FTP — FTP sync settings (gear icon)

</details>

**Described in:** [Ftp sync](../features/ftp-sync.md)

---

<a id="ftp-sync-upload-running"></a>

## An upload running

![An upload running](../images/ftp-sync-upload-running.jpg)

*Archive upload underway, with live Transferred, Speed and ETA readings.*

The same FTP sync Progress tab a few seconds later, with the upload running steadily: 11.2 MB of the 72.1 MB archive has been Transferred at 7.7 MB/s and the ETA reads 7s. Both the Overall progress bar and the per-file bar under Current file advance as bytes are sent, which is how you confirm the transfer is alive rather than stalled. Pause sync and Cancel sync stay available in the app bar throughout the transfer.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sincronizare FTP — FTP sync (app-bar title, truncated on screen to "Sincro…")
- Progres — Progress (selected tab)
- Jurnal (badge 5) — Log (tab with entry-count badge)
- Istoric modificări — Change log (third tab, partly cut off)
- Se încarcă arhiva — Uploading archive (phase header)
- speotopo1 — name of the FTP profile being synced
- Început la 02:44:55 — Started at 02:44:55
- Progres total — Overall progress (bar)
- Fișier curent — Current file (speleo_loc_sync_… archive name)
- Transferat — Transferred (11.2 MB / 72.1 MB)
- Viteză — Speed (7.7 MB/s)
- Rămas — ETA (7s)
- Pauză — Pause sync (app-bar icon)
- Anulează sincronizarea — Cancel sync (app-bar icon)

</details>

**Described in:** [Ftp sync](../features/ftp-sync.md)

---

<a id="ftp-sync-upload-finishing"></a>

## An upload finishing

![An upload finishing](../images/ftp-sync-upload-finishing.jpg)

*The upload nearing completion, both progress bars almost full.*

The FTP sync Progress tab as the archive upload approaches completion: 53.8 MB of 72.1 MB has been Transferred, the Speed reading has jumped to 87.5 MB/s and the ETA has fallen to 0s. The Overall progress bar and the Current file bar are both close to full, and the screen will switch to the Sync complete phase once the transfer finishes. From here the Log tab records what happened step by step and the Change log tab shows the edits the sync carried.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sincronizare FTP — FTP sync (app-bar title, truncated on screen to "Sincro…")
- Progres — Progress (selected tab)
- Jurnal (badge 5) — Log (tab with entry-count badge)
- Istoric modificări — Change log (third tab, partly cut off)
- Se încarcă arhiva — Uploading archive (phase header)
- speotopo1 — name of the FTP profile being synced
- Început la 02:44:55 — Started at 02:44:55
- Progres total — Overall progress (bar nearly full)
- Fișier curent — Current file (speleo_loc_sync_… archive name)
- Transferat — Transferred (53.8 MB / 72.1 MB)
- Viteză — Speed (87.5 MB/s)
- Rămas — ETA (0s)
- Pauză — Pause sync (app-bar icon)
- Anulează sincronizarea — Cancel sync (app-bar icon)
- Setări sincronizare FTP — FTP sync settings (gear icon)

</details>

**Described in:** [Ftp sync](../features/ftp-sync.md) · [Sync and change log](../features/sync-and-change-log.md)

---

<a id="ftp-sync-complete"></a>

## A completed sync run

![A completed sync run](../images/ftp-sync-complete.jpg)

*The Progress tab after a successful FTP sync run.*

This is the Progress tab of the FTP sync screen, shown just after a run finished. The phase header reads Sync complete with a green cloud tick, naming the FTP profile used (speotopo1) and the Started at time, and the Overall progress bar is full. Because nothing is running, the app bar offers Start sync (play), FTP sync settings (gear) and the app menu; while a sync is in flight those become Pause, Resume and Cancel sync instead. The three tabs — Progress, Log and Change log — stay available throughout.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sincronizare FTP — FTP sync (app bar title, truncated)
- Progres — Progress (tab, selected)
- Jurnal 8 — Log (tab, with a badge counting log entries)
- Istoric modificări — Change log (tab)
- Sincronizare reușită — Sync complete (phase header)
- Început la 02:44:55 — Started at (run start time)
- Progres total — Overall progress (progress bar, full)
- speotopo1 (name of the FTP profile that was synced)
- Pornește sincronizarea — Start sync (play icon in app bar)
- Setări sincronizare FTP — FTP sync settings (gear icon in app bar)
- overflow icon opening the global app menu drawer

</details>

**Described in:** [Ftp sync](../features/ftp-sync.md)

---

<a id="ftp-sync-log-tab"></a>

## The sync log tab

![The sync log tab](../images/ftp-sync-log-tab.jpg)

*The Log tab listing each step of the last FTP sync, newest first.*

The Log tab of the FTP sync screen shows a reverse-chronological timeline of everything the sync did, each line stamped with its time and an icon for its severity (info, warning, error). Here it records connecting to the server, finding 0 new archives to import out of 23 on the server, detecting local changes, generating a 72.1 MB sync archive, uploading it plus its .sha256 checksum, and finally Sync complete. The tab label carries a badge with the number of entries; when there is nothing to show it reads No log entries yet. Users read this tab to diagnose a failed or partial sync before opening FTP sync settings.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sincronizare FTP — FTP sync (app bar title, truncated)
- Progres — Progress (tab)
- Jurnal 8 — Log (tab, selected, badge showing 8 entries)
- Istoric modificări — Change log (tab)
- log line "Starting sync to speotopo1 (ftp.speotopo.ro)" with timestamp
- log line "Connected"
- log line "0 new archive(s) to import of 23 on server"
- log line "Local changes since last upload: true (reference: local record at …)"
- log line "Generated speleo_loc_sync_….zip (72.1 MB)"
- log lines "Uploaded speleo_loc_sync_….zip" and "Uploaded …zip.sha256"
- log line "Sync complete"
- info icon on each row marking the log level
- Pornește sincronizarea — Start sync (play icon in app bar)
- Setări sincronizare FTP — FTP sync settings (gear icon in app bar)

</details>

**Described in:** [Ftp sync](../features/ftp-sync.md)

---

<a id="ftp-sync-change-log-tab"></a>

## The change history tab during a sync

![The change history tab during a sync](../images/ftp-sync-change-log-tab.jpg)

*The Change log tab auditing local record changes before they are synced.*

The third tab of the FTP sync screen embeds the Change log, a read-only audit trail of every record change made on this device. Each row is labelled Added, Edited or Deleted, names the affected table and record (cave places, caves, cave trips, cave trip points, documentation files), and carries the change time plus by <user>. Rows for edits have a chevron that expands the changed fields with their old and new values. It is the same list reached from Settings, shown here so you can see what a sync is about to push. The list is empty until something changes, when it reads No changes recorded yet.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sincronizare FTP — FTP sync (app bar title, truncated)
- Progres — Progress (tab)
- Jurnal 8 — Log (tab)
- Istoric modificări — Change log (tab, selected)
- Adăugat — Added (green plus rows, e.g. "cave places: Intrare", "caves: Avenul Guguiova", "cave trip points", "documentation files")
- Modificat — Edited (blue pencil rows, e.g. "cave trips: P. Ponorul Suspendat 2026/08/22")
- de adig (adi ghita) — by <user> (author shown in each row subtitle)
- timestamp on every row (date and time of the change)
- chevron on edited rows expanding the changed field values
- Pornește sincronizarea — Start sync (play icon in app bar)
- Setări sincronizare FTP — FTP sync settings (gear icon in app bar)

</details>

**Described in:** [Sync and change log](../features/sync-and-change-log.md) · [Ftp sync](../features/ftp-sync.md)

---

<a id="ftp-sync-change-log-details"></a>

## An expanded change-history entry

![An expanded change-history entry](../images/ftp-sync-change-log-details.jpg)

*The Change log tab of the FTP sync screen, listing recorded record changes.*

This is the third tab of the FTP sync screen, which embeds the change-log list. Each row shows an operation badge (Added, Edited or Deleted) with the table and record title, the timestamp and the user who made the change. Rows for edits can be expanded with the chevron to reveal a Fields changed block naming the exact columns that differ, such as trip_ended_at or place_code_identifier. The app bar keeps the Start sync, FTP sync settings and overflow-menu actions available while the user reviews history.

<details><summary>On-screen wording (Romanian → English)</summary>

- Sincronizare FTP — FTP sync (app bar title, truncated)
- Progres — Progress (tab)
- Jurnal — Log (tab, with an 8-entry count badge)
- Istoric modificări — Change log (tab, selected)
- Adăugat — Added (change rows, green plus icon)
- Modificat — Edited (change rows, blue pencil icon)
- Câmpuri modificate — Fields changed (expanded detail heading)
- de — by (author prefix on each row, e.g. "de adig (adi ghita)")
- Pornește sincronizarea — Start sync (play icon in app bar)
- Setări sincronizare FTP — FTP sync settings (gear icon in app bar)

</details>

**Described in:** [Sync and change log](../features/sync-and-change-log.md) · [Ftp sync](../features/ftp-sync.md)

---

[← Screenshot index](README.md)
