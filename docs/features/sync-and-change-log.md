# Sync dashboard & change log

[← Back to index](../index.md)

The **Sync dashboard** is the central place to exchange data between
devices and to audit what changed locally. Open it from
**Settings → Sync dashboard** or, on supported screens, the
**cloud-sync icon** in the home toolbar.

The dashboard has two tabs:

1. **Archive sync** — produce and import device-to-device sync
   archives (see [Archive sync](#archive-sync)).
2. **Change log** — read-only audit trail of every record change made
   on this device (see [Change log](#change-log)).

For the related setup, see [Users](users.md) and [FTP sync](ftp-sync.md).
For the older, broader "export everything" flow used for backups, see
[Database export, import and backup](database-export-import.md).

## Archive sync

Archive sync produces a row-level zip with timestamps so a receiving
device can merge it into its own database using **last-writer-wins**
semantics (per row). It is the recommended way to keep multiple
devices in step between trips.

### Producing a sync archive

1. **Sync dashboard → Archive sync tab**.
2. Choose options:
   - **Include documentation files** — embed photos/audio/text files.
   - **Include raster maps** — embed map images.
   - **Conflict mode** (on import):
     - **Auto** — silent last-writer-wins by `updated_at`.
     - **Manual** — prompt on every overwrite that actually changes a
       user-visible field.
3. **Export sync archive** writes a single zip to a folder of your
   choice.

### Importing a sync archive

1. **Sync dashboard → Archive sync tab → Import**.
2. Pick the archive.
3. The importer merges rows according to your conflict-mode setting.
4. A summary lists rows added, updated, skipped, and conflicts.

### Device UUID and schema

Each device has a stable **device UUID** stamped into every archive it
exports. The importer:

- **Refuses** archives produced by a device on a **different schema
  version** of the database — sync only works between devices on the
  same app version.
- **Warns** before applying an archive from an unknown device.
- Optionally **preserves the local device UUID** during import (see
  the option in **Settings → Data export/import**).

### Archive sync vs the full export

| | Archive sync (this page) | [Full data export/import](database-export-import.md) |
|---|---|---|
| Granularity | Row-level merge | Whole-database replace or coarse merge |
| Conflict handling | Last-writer-wins or manual per row | Per-type prompts |
| Includes change log? | Yes | Optional |
| Best for | Frequent device-to-device updates between trips | Backups, sharing with a new device, version upgrades |

## Change log

Every insert, update or delete of a synced row generates an entry in
the **change log** table. The change log is used:

- to detect what to ship in **diff** / **incremental** sync archives,
- to power the **FTP sync** delta upload (see [FTP sync](ftp-sync.md)),
- as an **audit trail** so you can see *who* changed *what* on this
  device.

### Reading the change log

**Sync dashboard → Change log tab** (or **Settings → Sync dashboard**
→ Change log).

Each entry shows:

- **When** the change happened.
- **Who** made it (the [current user](users.md) at the time).
- **Which table** and **which entity** (with the entity's title looked
  up where possible).
- **Operation** — insert / update / delete.
- Expanding a row reveals the **field-level diff** (old → new value)
  for updates.

Filters along the top let you narrow by time, table, or operation.

### Sessions and FTP

Each FTP sync run starts a **new session** in the change log; a visual
separator marks where sessions begin. This makes it easy to see "what
changed between the last sync and now".

### Clearing the change log

The change log is **never cleared automatically**. You may safely
ignore it; in extreme cases (very long-running devices with millions
of changes) a debug-mode action is available to truncate it.

## See also

- [Users](users.md)
- [FTP sync](ftp-sync.md)
- [Database export, import and backup](database-export-import.md)
- [Sharing data between teams](../workflows/sharing-data.md)
