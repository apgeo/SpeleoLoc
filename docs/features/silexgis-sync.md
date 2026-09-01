# Club server (SilexGIS)

[← Back to index](../README.md)

SpeleoLoc can talk to a SilexGIS installation your club runs, so that the
caves on your phone and the caves in the club's registry stay in step. This
page covers adding a server, signing in, choosing what this device carries,
running a sync, and reading what came of it.

> **This is new.** The screen is recent work and has rough edges, which are
> pointed out where they matter. Nothing else in the app depends on it: if
> you never open this screen, SpeleoLoc behaves exactly as it always has.

## What a club server is, and when you want one

A SilexGIS installation is a cave registry a club runs on its own server,
with a web interface, accounts and permissions. Where an FTP folder just
holds files, a registry holds *rows*: it knows who may see which cave, which
caving club a cave belongs to, and who changed what. Syncing with one means
your device and the registry exchange caves, cave areas and places one by
one, each with its own answer.

You want one only if your club already runs such an installation. With
nothing configured the screen says so plainly:

> **No club server configured**
> SpeleoLoc works without one. Add a server only if your club runs a
> SilexGIS installation and you want this device to carry some of its caves.

That is the ordinary state, not a fault. Everything on your device is yours
whether a server exists or not — the app never needs one to work, and no
other screen changes when you add one.

**Settings → Club server (SilexGIS)** is the only way in. There is no club
server button in the home toolbar and no card for it in the app menu, so a
sync only ever happens because you opened this screen and asked for one.

### What never travels

Only caves, cave areas, cave places and surface areas are exchanged, with
their names, descriptions, coordinates, depth, place codes, QR payloads and
the entrance flag. Documents and photos, raster maps, trips and trip
reports, beacon registrations, users and the change log are **not** part of
this sync at all. If you need those to reach another device, use one of the
two routes below.

## Which sync route to use

SpeleoLoc has three ways of moving data, and they do not overlap much.

| Route | What travels | Reach for it when |
|---|---|---|
| [Manual sync](sync-and-change-log.md) | A complete snapshot of the device, documents and raster maps included, as a file you carry by hand | You are handing data to one person, by stick or e-mail, or you want to import an archive with conflicts shown to you |
| [FTP / SFTP sync](ftp-sync.md) | The same complete snapshots, through a shared folder | A team of SpeleoLoc devices keeps itself in step and there is no registry involved — a club NAS, a web host |
| **Club server (SilexGIS)** | Caves, cave areas, places and surface areas, row by row | Your club's registry is the reference copy, several people edit it through its web interface, and the phone should carry part of it into the field |

They are independent and can be used together: a club server sync does not
touch your FTP profiles, and vice versa. Caves that arrive from the club
server are not recorded as edits of your own, so bringing them down does not
by itself make your device upload a new FTP archive.

## Adding a server

Press **Add a server** on the empty state, or the pencil on the server card
to change one you already have. The form is short.

| Field | What to put in it |
|---|---|
| **Name** | Free-form label for the installation, e.g. "Clubul Speo Example". It is what the card and the sign-in message call it. |
| **Address** | The installation's full web address, starting with `https://` — the box is pre-filled with that much. If it sits under a subdirectory, keep the subdirectory: the path is used as given. |

A bad address is refused when you press **Save**: the box turns red under
the field and reads **Enter a full address, for example
https://speo.example.org**, and the dialog stays open until you fix it.
Only the *shape* is checked — that there is a scheme and a host. An address
that is well formed but points at nothing, or at something that is not a
SilexGIS installation, is accepted quietly; you find out when you try to
sign in.

There is no **Test connection** button here, as there is on the FTP screen.
Signing in is the first thing that actually contacts the server.

Prefer `https://`. A plain `http://` address is accepted, and it would send
your password and your caves across the network in clear.

The screen works with **one** server. Adding a second is not offered.

## Signing in

**Sign in** on the server card asks for **Email** and **Password** — your
account on that installation, the same one you use in its web interface.
The email box is pre-filled with the account you last used.

Your password is used for the sign-in and then thrown away. What the device
keeps is the credential the server hands back, and it goes into the phone's
secure keystore, never into the database — so a database export cannot carry
it off. After that the device renews the credential by itself, and you are
not asked again until it lapses.

A successful sign-in shows a green **Signed in**, and the account's email
appears under the address on the server card. A failure shows the server's
own sentence in red, verbatim — the app does not invent a diagnosis, so what
you see is what the installation said.

### The two-factor step

If the account has two-factor sign-in switched on, a **Two-factor code**
dialog appears before the sign-in finishes.

- A **Code** box for the code itself.
- One button per method the account can use, reading **Send a code by
  email**, **Send a code by sms**, and so on — the word is the server's own.
  Pressing one asks the server to send it and confirms with **Code sent**.
- An authenticator app never gets a button: that code is already in your own
  app and there is nothing to send. Just type it.
- A switch, **Use a recovery code instead**, always offered. Turn it on and
  the box's label becomes **Recovery code**; type one of the codes you were
  given when two-factor was set up. This is the way back in when the phone
  that receives the codes is not with you.

Press **OK** to finish. Cancelling the dialog stops the sign-in; nothing is
stored and you can start again.

### "The server did not grant a lasting session"

Sometimes the sign-in works, and a yellow message says:

> The server did not grant a lasting session; you may be asked to sign in
> again shortly.

That means the installation issued a credential good only for the next few
minutes and nothing to renew it with. You are signed in and can sync now,
but the device will need your password again very soon, and again after
that. Nothing on the phone can fix it — the installation's account settings
decide it, so it is one for whoever administers the server.

### When the credential lapses

A run that finds the stored credential beyond renewal stops and says **Sign
in to *name* again**. Nothing is lost and nothing is re-downloaded: your
caves are on the device regardless. Changing or resetting the account's
password on the server also invalidates the credential on **every** device
signed in with it, so expect to sign in again after a password change.

## Caves this device carries

A phone does not carry the whole registry. What it carries is a
**selection** — a named list of starting points on the server, with
everything inside them. Press **Choose** to pick one. Until you do, the row
reads **Not chosen yet** and both run buttons are greyed out.

You must be signed in first; otherwise the app says **Sign in to the server
first** and stops.

The picker lists the selections, each with its name and a count of its
starting points, for example *3 roots*. A "root" is a surface area or a cave
the selection begins from: everything contained in it comes too, including
anything added inside it later, so the selection does not need maintaining
every time the club adds a passage.

**If the account owns none**, the dialog says so:

> This account owns no selections on that server yet. Create one in the web
> interface.

Selections are made on the server, not in the app — this screen can only
choose among the ones your account already owns. Somebody else's selection
is not shown to you even if you can see its caves.

### The warning about a caving club

A selection can exist without naming a caving club. Those are marked in the
picker with a warning triangle, and choosing one produces:

> That selection names no caving club, so anything you add will be refused.
> Choose a club for it in the web interface.

Reading works perfectly well through such a selection. What fails is
everything you *send*: the server refuses each row because it cannot tell
which club should own it, and the refusal names the selection rather than
your cave, which is why the app warns you at the moment you pick it rather
than after a confused sync. The cure is on the server — open that selection
in the web interface and give it a caving club.

### After you have chosen

The row then shows the selection's **identifier** from the server rather
than the name you picked. It is a rough edge in this version; nothing is
wrong, and the picker still shows names when you go back in.

If somebody edits the selection in the web interface — adds a root, changes
its settings — the device's saved position becomes meaningless and the next
run reads the whole selection again by itself. That is normal and costs only
time.

## Send caves I survey elsewhere

A switch under the selection, **off by default**:

> Off, only the caves you carry and what you add inside them are sent. On,
> a cave you survey somewhere new goes too - which is the only way to get
> one onto the server at all.

With it **off**, what goes up is what the server already gave you, plus
anything you have since put inside it: a new place in a club cave, a new
area, a corrected entrance position. A cave you surveyed in an unrelated
massif stays on your phone. That is deliberate — configuring a club server
should not publish your own unrelated work.

With it **on**, a brand-new cave (and a brand-new surface area) is sent as
well. This is the **only** way a cave that the server has never heard of can
reach it: a selection can only start from something that already exists
there, so a cave nobody has uploaded can never be added to a selection.

Turn it on when you are deliberately contributing new caves to the club
registry, and consider turning it off again afterwards.

## Running a sync

Two buttons on the **Sync** card, both disabled until a selection is chosen
and while a run is in progress (a small spinner shows beside the heading):

| Button | What it does |
|---|---|
| **Sync now** | The ordinary run. Sends what changed here, then reads what has changed on the server since this device last read it. |
| **Read everything** | The same run, except the reading half starts the selection from the beginning instead of from where it left off. |

Both **send first and read second**, on purpose: a cave you deleted here
would otherwise be handed straight back to you by the read that ran before
it.

Use **Read everything** when something you expect is missing — above all
after somebody grants your account access to a cave. Being given permission
does not change the cave itself, so an ordinary run has no reason to notice
it and never will; a full read is what brings it down. It is always safe,
only slower.

### Reading the result

When the run ends the card shows a sentence and, under it, a small line of
counts:

> 3 received, 2 sent, 1 removed

- **received** — rows written into your database, whether newly added or
  updated from the server's version.
- **sent** — rows the server took from you.
- **removed** — rows deleted here because they were deleted on the server.

With nothing to do either way the sentence reads **Already level with the
server**. A run that failed shows the reason in red, in the server's own
words where there is one.

There is no progress bar, no per-file detail and no log tab as there is on
the FTP screen; a run either finishes with counts or fails with a sentence.

### Deletions travel, and they take things with them

This is the destructive part, in both directions.

- A cave or place **deleted on the server** is deleted here on the next
  read, together with what hangs off it on this device — its map bindings,
  trip points, document links and beacon registrations. It is not put in a
  bin; it is gone.
- A cave or place **you delete here**, if the server already knew it, is
  sent as a deletion on the next run, and the server removes it *with
  everything inside it*.

Neither asks for confirmation at sync time. The confirmation was the delete
itself. If you are unsure, take a backup before syncing — see
[Database export, import and backup](database-export-import.md).

## Needs your attention

When a run leaves something for you to decide, a **Needs your attention**
card appears under the Sync card. It stays there while the app is running,
including if you leave the screen and come back, but it is not written down:
closing the app loses it, and the next run will surface anything that is
still outstanding.

Four kinds of entry can appear.

### Changed on the server as well

Somebody edited the same cave or place after this device last read it, so
your version was **not** applied — nothing of yours was lost, and nothing of
theirs was overwritten. The entry carries the server's own wording, and
then either:

- **On the server: *name*** — the server's version of that row, so you can
  see what you are up against; or
- **Read everything to see the server's version.** — the server did not hand
  its version back, because your account may not have that cave's position.

There is no merge view in this version: nothing shows the two versions side
by side. What resolving amounts to is deciding which text is right and
editing the cave here until it says so — and, when it is the server's
version you want, changing it there instead.

### Refused

The server would not take a row. The title is the server's own reason code
where it named one — a technical string such as `access.create_forbidden` —
otherwise just **Refused**, and under it the server's sentence plus one line
saying what moves it forward:

| Line | What to do |
|---|---|
| **Try again later.** | A passing problem — the server was busy or unreachable. Sync again in a while. |
| **Sign in again.** | The credential lapsed mid-run. Press **Sign in** and run again. |
| **It will be sent again on the next sync.** | Nothing to do; the device has kept the row and will retry it. |
| **Someone has to change something on the server.** | The app cannot fix it. Usually a permission, a missing caving club on the selection, or a cave type the installation does not know. Read the server's sentence and take it to whoever administers the installation. |
| **This one cannot be sent as it is.** | Your account is not allowed to write that row, or to write it there. The rest of the run was unaffected, and the row stays safe on your device. |

A refusal is per row. Forty caves edited underground and one refused means
thirty-nine went up.

### Something was already nearby

Not a refusal at all — the entry says so:

> Your row was saved. Whether it is the same cave is yours to decide.

The server noticed that the cave or entrance you just **created** sits close
to something it already holds, and lists what, each with its name and how
far away it is (**120 m away**). Tap the entry to expand the list. You were
offline when you decided to add it and could not ask, so the server tells
you afterwards.

What to do: look at the neighbours in the web interface. If they are the
same cave, merge them there — the app cannot do it for you. If they are
genuinely different, ignore the entry.

Two things to know before trusting it. Only rows the server could show your
account are searched, and an installation can turn the check off entirely
without saying so — so an empty report is not proof there is nothing nearby.

### Rows that could not be stored

> *N* rows could not be stored
> They sit inside a cave this account may not see.

The server sent you a place or an area, but not the cave it belongs to,
because your account may not read that cave. A place with no cave is not
something SpeleoLoc can hold, so those rows were carried and dropped rather
than half-stored. Nothing is wrong with your data.

If you should have access to that cave, ask for it on the server, then come
back and press **Read everything** — an ordinary run will not pick it up.

## Forget

**Forget** on the server card asks first:

> **Forget this server?**
> Your caves stay on this device. What is removed is the stored sign-in and
> everything this device remembers about its conversation with that server.

Press **Forget** to confirm, or **Cancel**.

**What it removes:** the server's name and address, your stored sign-in for
it, the selection you chose, the **Send caves I survey elsewhere** setting,
this device's reading position, and the device's record of which rows the
server already holds and at which version.

**What it does not remove:** a single cave, area, place, document, photo,
map or trip. Nothing is deleted from your database, and nothing at all is
deleted from the server — the club's registry is untouched, and other
devices signed in to it carry on as before.

It cannot be undone, but nothing valuable is lost: you can add the server
again and sign in.

One thing to expect if you do. The device has forgotten what it and the
server had agreed each shared cave said, so the next sync starts that
conversation from scratch, and on that first read the server's version of a
row the two sides both hold is written over the local one. Where the two
copies came from the same origin — which is exactly the case after a forget
and re-add — an edit you made on the phone in the meantime can be replaced
by the server's text. Sync before forgetting, or push your changes up again
afterwards.

## Troubleshooting

- **Both run buttons are grey** — no selection has been chosen. Press
  **Choose** on **Caves this device carries**.
- **"Sign in to the server first"** — pressing **Choose** needs a live
  session. Sign in, then choose.
- **"This installation speaks version X of the sync protocol and this
  application speaks Y. One of them needs updating."** — the server and the
  app are of different generations and will not talk until one of them is
  updated. Nothing on this screen changes that.
- **A run ends "Already level with the server" but a cave is missing** —
  press **Read everything**. Permissions granted on the server are invisible
  to an ordinary run.
- **Everything you send is refused** — check the selection's caving club, as
  above, and check that your account may write in that part of the registry.
- **Nothing you send arrives, but nothing is refused either** — a genuinely
  new cave is not sent unless **Send caves I survey elsewhere** is on.
- **The counts look smaller than expected** — the card counts what was
  received, sent and removed. Rows the server sent that this version of the
  app does not model, and rows held back because you have an unsent edit of
  your own, are not counted anywhere on the screen.

## Rough edges in this version

Said plainly, so you are not surprised:

- The screen holds a single server; there is no list and no default picker.
- After a selection is chosen the row shows its identifier, not its name.
- There is no progress detail and no log of a run — only the final counts.
- There is no merge view for a cave that changed on both sides.
- Duplicate reports and refusals live only until the app closes.
- Sets, roots and caving clubs are created and edited in the installation's
  web interface, never here.

## See also

- [FTP / SFTP sync](ftp-sync.md)
- [Manual sync and the change log](sync-and-change-log.md)
- [Sharing data between teams](../workflows/sharing-data.md)
- [Database export, import and backup](database-export-import.md)
- [Caves and cave areas](caves-and-areas.md)
- [Settings](settings.md)
