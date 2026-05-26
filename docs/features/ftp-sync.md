# FTP / SFTP sync

[← Back to index](../README.md)

SpeleoLoc can push and pull sync archives via **FTP** or **SFTP** in
addition to manual file exchange. This page covers how to configure
endpoints, run a sync and watch progress.

> FTP sync is the closest SpeleoLoc currently gets to "automatic team
> sync". There is still no SpeleoLoc-specific server — the app simply
> reads/writes archives in a folder on a generic FTP/SFTP server you
> control.

For the higher-level "what is a sync archive" topic, see
[Sync dashboard & change log](sync-and-change-log.md). For purely
manual file sharing, see [Sharing data](../workflows/sharing-data.md).

## Setting up an FTP profile

**Settings → FTP sync** opens the list of configured **FTP profiles**.
A profile contains:

| Field | Notes |
|---|---|
| **Title** | Free-form label, used in pickers and logs. |
| **Protocol** | `ftp`, `ftps` (FTP over TLS) or `sftp` (SSH). |
| **Host** / **Port** | Standard ports are pre-filled per protocol. |
| **Username** / **Password** | Stored using the platform's secure storage. The password is shown as `*` and never echoed in logs. |
| **Remote path** | Folder on the server where SpeleoLoc reads/writes archives. |
| **Default profile** | Optional flag — used when no profile is explicitly chosen. |

Actions per profile:

- **Edit** / **Delete** (with confirmation).
- **Test connection** — opens a connection, lists the remote path and
  reports success or a specific error.
- **Set as default**.

## Running a sync

From the home toolbar's **cloud-sync icon**, or from
**Settings → FTP sync → Sync now**:

1. Pick the FTP profile (or use the default).
2. The **FTP sync progress page** opens, with tabs:
   - **Progress** — current step, bytes transferred, speed, ETA.
   - **Change log** — embedded view of the local change log,
     auto-refreshed during sync.
3. Buttons available during a run:
   - **Pause / Resume**.
   - **Stop** — aborts cleanly at the next safe boundary.
   - **Settings shortcut** — jump back to the FTP profile if you
     spotted a misconfiguration.
4. On completion the page shows a per-phase summary (upload, download,
   merge, asset extraction) and any errors.

### What the sync actually transfers

- **Upload**: a sync archive containing only **rows changed since the
  device's last successful sync**, plus any new/changed
  documentation files and raster-map images you opted to include.
- **Download**: archives from other devices found in the remote path,
  applied locally with the same last-writer-wins semantics as the
  manual [archive sync](sync-and-change-log.md#archive-sync).

If nothing has changed locally, the upload phase is **skipped** to
save bandwidth.

## Replay and resume

- **Play** — start a fresh sync.
- **Replay** — re-run the last sync (useful after a transient error).
- **Resume** — continue an interrupted sync from where it stopped.

Progress is persisted across app restarts; killing the app mid-sync
will not corrupt the local database.

## Conflict handling

FTP sync uses the same **last-writer-wins** rules as the manual
archive importer. To review conflicts, switch to **manual conflict
mode** in the [Archive sync tab](sync-and-change-log.md#archive-sync)
before triggering the FTP run — the FTP sync respects this setting.

## Security notes

- Use **SFTP** or **FTPS** whenever possible. Plain **FTP** is offered
  for legacy servers but transmits credentials in clear.
- Passwords are encrypted at rest by the platform's secure storage
  (Keychain on iOS/macOS, Keystore on Android, DPAPI on Windows, etc.).
- Exported data archives **do not contain** FTP passwords unless you
  explicitly opt in via **Settings → Data export/import → Include FTP
  account passwords** — keep that option **off** when sharing archives
  with other teams.

## Troubleshooting

- **Authentication failed** — verify username/password; for SFTP,
  ensure the server allows password authentication (key-based auth is
  not yet supported).
- **Cannot list remote folder** — wrong remote path, or your user
  lacks list permissions.
- **Schema mismatch on download** — the remote archive was produced
  with a different app version; update both devices.
- **Slow on large archives** — toggle off raster-map images or
  documentation files for a leaner incremental sync.

## See also

- [Sync dashboard & change log](sync-and-change-log.md)
- [Users](users.md)
- [Sharing data between teams](../workflows/sharing-data.md)
