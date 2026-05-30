# Users

[← Back to index](../index.md)

SpeleoLoc records **who** made each change to the database (audit
columns + [change log](sync-and-change-log.md#change-log)). The list
of known **users** and the **current user** identity are managed in
**Settings → Users**.

> "User" here is a **caver/operator identity**, not a login/security
> account. There is no password; switching the current user is a
> simple selection.

## What the current user is used for

Every insert / update / delete done while a specific user is selected
is stamped with that user's UUID into:

- the row's `created_by` / `updated_by` audit columns,
- the corresponding [change-log](sync-and-change-log.md#change-log)
  entry.

When multiple devices sync, this lets teams answer questions like
*"who attached this photo?"* without manual annotation.

## Managing users

**Settings → Users** shows the list of all known users, with the
**current user** marked.

- **Add user** (`+` floating action) — enter a display name; a fresh
  UUID is allocated.
- **Tap a user** — select them as **current user**.
- **Edit / Delete** (long-press a row) — rename or remove. Deleting a
  user does **not** delete the rows they created; their audit-column
  UUID is kept as-is (the change log still shows the original name
  captured at the time of the change).

User entries are **synced** between devices like other records.

## Switching users mid-trip

You can change the current user at any time without restarting the
app. Changes made afterwards are attributed to the newly selected
user. This is convenient when several team members share one device:
hand the phone over, tap the new name in **Settings → Users**, and
they immediately become the recorded author.

## Bootstrapping on a fresh device

On first run, SpeleoLoc seeds a default user (the device's own UUID)
so that audit columns are never null. Replace it with a real name in
**Settings → Users** the first time you use the device for caving
work.

## See also

- [Sync dashboard & change log](sync-and-change-log.md)
- [FTP sync](ftp-sync.md)
- [Settings](settings.md)
