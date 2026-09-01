# Users

[← Back to index](../README.md)

SpeleoLoc stamps every change to your data with the caver who made it.
This page covers the list of caver identities in **Settings → Users**
and how the **current user** — the identity those stamps point at — is
chosen and handed over.

> A "user" here is a caver identity, not a login account. There is no
> password and nothing is locked: switching the current user is a
> single button press that anyone holding the phone can make.

## What the current user is used for

While a user is selected, everything you create, edit or delete carries
that identity, and each of those changes also produces an entry in the
[change log](sync-and-change-log.md#change-log) (**Settings → Man.
sync → Change log**). Every entry is labelled *by* the user's username,
so after a trip you can answer "who added this place?" or "who moved
that point?" without anyone taking notes.

That is all the current user does. It does not filter what you see, it
does not restrict what you may change, and no screen behaves
differently depending on who is selected.

## The users list

**Settings → Users** lists every caver known to this database. On a
device where nothing has been written yet the list is empty and shows
*No users yet*.

Each row shows:

- a person icon — filled and in the accent colour for the current
  user, outlined for everyone else;
- the **username** as the row title;
- the first and last name underneath, or the **Details** text when no
  name was entered;
- at the right, a **Current** chip for the current user, or a
  **Select** button for everyone else.

There are exactly two things a row does:

- **Select** — press it to make that person the current user. From
  that moment on, changes are recorded under their name.
- **Tap the row** — opens the **Edit user** dialog for that person. It
  does *not* select them.

## Adding a caver

1. Open **Settings → Users**.
2. Press the person-add button at the bottom right (**Add user**).
3. Fill in the fields below and press **Save**.
4. Back in the list, press **Select** on the new row — adding a user
   does not select them.

| Field | Required | What it is for |
| --- | --- | --- |
| **Username** | yes | The short handle this person is known by. It is the row title, the label in the change log, and the key used when devices sync. Must be unique; surrounding spaces are trimmed. |
| **First name** | no | Shown under the username in the list, and in brackets in the change log. |
| **Last name** | no | Same; the two names are shown together. |
| **Details** | no | A free-text note, three lines — club, phone number, role, whatever is useful. Shown under the username when no first or last name was entered. |

Two things to expect from the dialog:

- With **Username** empty, **Save** does nothing at all and gives no
  message. Type a username, or press **Cancel**.
- If the username is already taken, the dialog stays open and a
  technical error message appears at the bottom of the screen. Choose a
  different username and press **Save** again.

## Editing a caver

Tap any row to reopen the dialog as **Edit user** and change the
username, the names or the details.

Renaming is **retroactive**. The change log looks each entry's author
up when the list is drawn, so an entry made months ago is relabelled
with whatever the username is now. That cuts both ways: filling in a
first and last name later also improves old entries, which then read
`anna (Anna Popescu)` instead of the bare `anna`.

## Users cannot be deleted

There is no delete anywhere on this screen — no long-press, no menu.
Once created, an identity stays in the list, because rows and change-log
entries keep pointing at it. If someone was added by mistake, edit the
row and reuse it for a real caver instead.

## The automatic "system" user

SpeleoLoc creates no user for you when it first starts, and the
device's own identifier is never used as a person.

The first change to any data — adding a cave, adding a place,
starting a trip — creates a user named **system** (first name *System*,
details *Auto-generated default user.*) and selects it, so the
who-changed-what stamps are never empty. Until then, **Settings →
Users** shows *No users yet*.

On a fresh device, add yourself and press **Select** early. Anything
done before that stays attributed to *system* and cannot be
re-attributed afterwards.

## Handing the phone to someone else

The current user can be changed at any time; nothing needs restarting,
and changes already recorded keep their original author.

1. Open **Settings → Users**.
2. Press **Select** on the new person's row.
3. Hand the phone over.

Make that part of the hand-over ritual, because **no other screen shows
who is currently selected**. If the switch is forgotten, nothing looks
wrong — the mistake only surfaces later, when someone opens the change
log and finds a morning's work under the wrong name.

## Usernames across devices

Users travel between devices in [sync archives](sync-and-change-log.md)
like any other record, and the **username is what identifies a person**.

When data from another device is merged in, an incoming user whose
username already exists here is folded into the local one, and every
row and change-log entry that pointed at them follows. That is also
what merges the automatic *system* user each device makes for itself.

The match is exact, capitalisation included. So agree on one spelling
per caver and use it on every device: `anna` and `Anna` are two
separate people, and once both exist there is no way to merge them from
inside the app.

## See also

- [Sync dashboard & change log](sync-and-change-log.md)
- [FTP sync](ftp-sync.md)
- [Settings](settings.md)
- [Trips](trips.md)
- [Running a trip](../workflows/running-a-trip.md)
- [Getting started](../getting-started.md)
