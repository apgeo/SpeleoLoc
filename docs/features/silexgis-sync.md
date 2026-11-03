# Club server (SilexGIS)

[← Back to index](../README.md)

SpeleoLoc can talk to a SilexGIS installation your club runs, so that the
caves on your phone and the caves in the club's registry stay in step —
and, where the installation offers them, the photos, trips and raster maps
that go with them. This page covers adding a server, signing in, choosing
what this device carries, what travels and how, running a sync, and reading
what came of it.

> **This is new.** The screen is recent work and has rough edges, which are
> pointed out where they matter. Nothing else in the app depends on it: if
> you never open this screen, SpeleoLoc behaves exactly as it always has.

## What a club server is, and when you want one

A SilexGIS installation is a cave registry a club runs on its own server,
with a web interface, accounts and permissions. Where an FTP folder just
holds files, a registry holds *rows*: it knows who may see which cave, which
caving club a cave belongs to, and who changed what. Syncing with one means
your device and the registry exchange caves, places, trips, maps and the
rest one by one, each with its own answer.

You want one only if your club already runs such an installation. With
nothing configured the screen says so plainly:

> **No club server configured**
> SpeleoLoc works without one. Add a server only if your club runs a
> SilexGIS installation and you want this device to carry some of its caves.

That is the ordinary state, not a fault. Everything on your device is yours
whether a server exists or not — the app never needs one to work. Other
screens change only where the server brought something: a section of server
files under a cave's documents, another phone's trips in the trips list, a
caver to choose for a phone user.

**Settings → Club server (SilexGIS)** is the only way in. There is no club
server button in the home toolbar and no card for it in the app menu, so a
sync only ever happens because you opened this screen and asked for one.
Some builds of the app are made without the club server; in those the entry
is simply missing from **Settings**.

## What travels

Caves, cave areas, cave places and surface areas always travel, both ways,
with their names, descriptions, coordinates, depth, place codes, QR payloads
and the entrance flag. Everything else travels only when the installation
offers that part:

| What | Which way | The installation must offer |
|---|---|---|
| Photos and documents | Down on request; up during a sync, if you let files go | **Photos and documents** to list and fetch them; **Sending photos and documents** to send them |
| Trips and their scans | Both ways | **Trips** |
| Raster maps and their points | Both ways | **Raster maps**; their pictures come down only if **Photos and documents** is offered too |
| Which club caver a phone user is | Both ways | **People** |
| A reviewer's decisions on what you sent | Down | **Review** |
| 3D survey models, and places at their stations | Both ways | **3D survey models** — see [3D survey models](3d-models.md#with-silexgis) |

The **What the server offers** card at the bottom of the screen lists these
parts. Before the first sync it reads **Not known until the first sync.**;
after one it reads **As of the last sync, and what this device does with
each part.**, and each part says **Offered** or **Not offered** and, in one
line, what your phone does with it. The card records the last answer only:
every sync asks again, and an installation can switch a part off between
two syncs. A part that stops being offered disappears from the other screens
too — the list of server files, the caver choice.

What never travels: beacon registrations, the change log, a trip's
participants list, the users on your phone (apart from the names of those
who made something you send — see [People](#people)), and your settings.

## Which sync route to use

SpeleoLoc has three ways of moving data, and they do not overlap much.

| Route | What travels | Reach for it when |
|---|---|---|
| [Manual sync](sync-and-change-log.md) | A complete snapshot of the device, documents and raster maps included, as a file you carry by hand | You are handing data to one person, by stick or e-mail, or you want to import an archive with conflicts shown to you |
| [FTP / SFTP sync](ftp-sync.md) | The same complete snapshots, through a shared folder | A team of SpeleoLoc devices keeps itself in step and there is no registry involved — a club NAS, a web host |
| **Club server (SilexGIS)** | Caves, cave areas, places and surface areas, row by row; and, where the installation offers them, photos and documents, trips, raster maps, people and 3D survey models | Your club's registry is the reference copy, several people edit it through its web interface, and the phone should carry part of it into the field |

They are independent and can be used together: a club server sync does not
touch your FTP profiles, and vice versa. What arrives from the club server
is not recorded as edits of your own, so bringing it down does not by itself
make your device upload a new FTP archive.

One exception to "complete snapshot": a file fetched from the club server
as a copy without location or as a reduced picture stays on the phone that
fetched it, and so does a raster map whose picture is such a copy, with its
points. Manual and FTP sync archives leave them out. Another device gets
them from the server, or not at all. See [Server copies](#server-copies).

## Adding a server

Press **Add a server** on the empty state, or the pencil on the server card
to change one you already have. The form is short.

| Field | What to put in it |
|---|---|
| **Name** | Free-form label for the installation, e.g. "Clubul Speo Example". It is what the card and the sign-in message call it. |
| **Address** | The installation's full web address, starting with `https://` — the box is pre-filled with that much. If it sits under a subdirectory, keep the subdirectory: the path is used as given. |

A bad address is refused when you press **Save**: the box turns red under
the field with the reason, and the dialog stays open until you fix it.

| What is wrong | What the box says |
|---|---|
| No host, an empty box, or a space in the address | **Enter a full address, for example https://speo.example.org** |
| It does not start with `https://` — plain `http://` included | **The address must start with https://** |
| It carries a user name or password (`https://name:pass@…`), or a part after `?` or `#` | **Leave out any user name, password, and any part after ? or #** |

Plain `http://` is refused because your password and the credential the
server hands back would cross the network in clear. A trailing slash is
dropped when the address is saved.

Beyond that only the *shape* is checked. An address that is well formed but
points at nothing, or at something that is not a SilexGIS installation, is
accepted quietly; you find out when you try to sign in.

There is no **Test connection** button here, as there is on the FTP screen.
Signing in is the first thing that actually contacts the server.

**A profile saved with an `http://` address by an older version** keeps
it, but the app no longer contacts it: the server card says **This address
is no longer accepted. Edit it so that it starts with https:// before you
sign in or sync.**, and a sign-in or a sync stops with the same advice.
Nothing is sent to the old address. Correct it with the pencil; that counts
as a change of server, below.

### Changing the address

Pressing the pencil and saving a different server — another host, port,
`http`/`https`, or subdirectory — asks first:

> **Point this profile at another server?**
> The new address may be a different installation. The stored sign-in, the
> chosen selection and everything this device remembers about its
> conversation with the old address are removed, and you will need to sign
> in again. Your caves stay on this device.

**Change address** goes ahead; **Cancel** leaves the profile as it was.
What goes is what [Forget](#forget) removes, except the profile itself: the
name and the photo and Wi-Fi settings stay, while **Send caves I survey
elsewhere** goes back to off, because what to publish is decided per
server. Then sign in, choose a selection, and sync; the first run behaves
like the first run after a forget and re-add, so read the note at the end
of [Forget](#forget) before you change the address of a server you still
have unsent edits for.

Changing only the name, or the address's letter case or trailing slash,
asks nothing and keeps you signed in. The pencil is greyed out while a sync
is running.

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

The selection decides more than caves: the trips, maps, photos and models
that travel are those of the caves it carries.

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

## Photos and documents

### Sending them, and mobile data

Three switches on their own card, under the selection. All three are **on
by default**.

| Switch | What it does |
|---|---|
| **Send photos and documents** | *Off, only caves and places are sent; your photos and documents stay on this device.* Off also holds back a new raster map, whose picture is a file. Trips, points and edits of maps already on the server still go. |
| **Only over Wi-Fi** | *Files wait for Wi-Fi; everything without a file still goes. A phone's hotspot counts as Wi-Fi.* A cable counts as Wi-Fi too. |
| **Ask before using mobile data** | Used only while **Only over Wi-Fi** is on. *Off, files simply wait for Wi-Fi.* |

With all three on and the phone away from Wi-Fi, a sync that has files to
send stops to ask:

> **Send files over mobile data?**
> 3 photos and documents (12.4 MB) are ready to send, and this device is not
> on Wi-Fi.

Press **Send now** or **Wait for Wi-Fi**. Tick **Remember my choice** first
and the answer becomes a setting: remembering **Send now** turns **Only over
Wi-Fi** off, remembering **Wait for Wi-Fi** turns **Ask before using mobile
data** off. Both show on the card, where you can switch them back. You are
asked at most once per sync, and the answer covers photos, documents and map
pictures alike. If you leave the screen before the question comes, the files
wait.

The phone goes by what the system reports. Wi-Fi from a phone's hotspot is
Wi-Fi, and a Wi-Fi that charges by the megabyte is not told apart. When the
system reports mobile data alongside Wi-Fi, or cannot say what the network
is — a VPN on its own, for example — the phone treats it as mobile data and
asks.

Whatever waits is listed under **Needs your attention** as **3 photos and
documents were not sent**, with the reasons: waiting for Wi-Fi, no room left
for you on the server, too large, of a type the server does not accept, no
longer on this device, or interrupted (**the next sync carries on**). A
cave, place or trip that a waiting photo hangs on goes up regardless.

### What goes up

Your own photos, documents, sound recordings and videos go up when they hang
on something the server holds or that the same sync sends: a cave, an area,
a place, a trip or one of its scans. After that, an edited title or
description goes up as an edit, and a file you delete here goes up as a
removal.

A photo goes up as it is on your phone, including where it was taken if the
photo records that. The installation decides who may see the location: an
account that may not is handed a copy without it.

### What comes down

Nothing is downloaded by itself. The server's list of photos and documents
comes down with the sync, and the documents list of a cave, a cave area or
a place gets an **On the server** section at the end, under the
installation's name, listing the files there that this phone does not hold.
Each line shows the kind (**Photo**, **Video**, **Sound**, **Document**,
**Other file**), the size where it is known, and **You have this file** when
the phone holds the same file under another entry (it is not fetched again)
or **Not available to you** when your account may not fetch it.

Tick the ones you want and press **Download (2)**, or press **Download the
usual files** for those whoever curates the cave marked as worth carrying.
A **Download at** question then asks for a size: **Original, full size**, or
a reduced picture of **2400 px**, **1200 px**, **480 px** or **160 px**
across — only the sizes on offer are listed. **Download the usual files**
shows what each choice would cost, for example *8 files, 15.2 MB*; a copy
the server makes on request has no size until it arrives.

A download goes over whatever network the phone is on — the Wi-Fi switches
are about sending. When it ends, a message counts what happened: downloaded,
already on this device, no longer on the server for you, not handed to this
account, or could not be downloaded (**try again to continue**).

### Server copies

What your account is handed depends on the installation's rules, file by
file:

- **the original**, the file exactly as stored;
- a copy **without location** — the whole picture, rewritten without where
  it was taken; such files carry a **without location** tag in the list;
- only **reduced pictures** the server draws at the fixed sizes above.

A copy without location and a reduced picture stay on the phone that fetched
them. They are never sent back up as if they were the original, and manual
and FTP sync archives leave them out, with what hangs on them.

## People

The club's registry knows its cavers; your phone knows its users. When the
installation offers **People**, you can say which caver a phone user is.

Open **Settings → Users** and tap a user. The **Edit user** dialog then ends
with **Caver on Clubul Speo Example** — the installation's name — listing
the club's cavers; the one your account belongs to is marked
*Invented Caver (you)*. Pick one. Under the box the app says **Sent with the
next sync** until it has gone, or **Chosen on the server** when the link was
made in the web interface.

- The box appears only for a user that already exists — save a new one
  first — and only once a sync has brought the club's list of cavers.
- There is no way to clear the choice from the phone, only to pick another
  caver. Undoing a link is done in the web interface.
- What goes up about a phone user is their username, first name and last
  name, and only for users who made something the sync sends or for whom you
  chose a caver. The **Details** field never travels.

## Trips

When the installation offers **Trips**, your trips of the caves you carry go
up with their scans: the title, the details, the trip log, the start and
end, and for each scan its place, time and notes. Photos and documents made
during the trip go with them when **Send photos and documents** allows. The
participants list does not travel.

Trips recorded on other phones come down too, but they are kept out of your
way. In a cave's **Past / active trip(s)** list a switch reads **Show trips
from Clubul Speo Example**, with **2 from Clubul Speo Example hidden** under it. Turn it on
to list them. Each then carries a small cloud badge (**Recorded on another
phone, read from Clubul Speo Example**), and the line under its title says
**recorded by Invented Caver** when the club's list of cavers names who
recorded it. Another phone's trip that is still running there is listed
with **still open**. The switch is off again each time you open the list.

A trip that arrives with the name of one already on this phone, or a scan
of the same place at the same moment, is not stored; the one here is kept,
and **Needs your attention** says **2 trip recordings or scans were not
stored**.

## Raster maps

When the installation offers **Raster maps**, the maps of the caves you
carry come down with their points, and yours go up the same way. Points
added, moved or removed in the web interface arrive with the next sync like
any other change — except a point you have edited here and not yet sent,
which stays as you left it.

A new map goes up only while **Send photos and documents** is on, because
its picture is a file; otherwise it waits, with its points.

A map's picture comes down during the sync, on any network, and only if the
installation also offers **Photos and documents**. It is the original where
your account is handed it, else the copy without location, else the
largest reduced picture the server draws. On a reduced picture the app
scales the points to fit, and a note above the map says what you can do:

- **This is a reduced picture from the server. Points are shown on it but
  cannot be placed or moved.**
- **This is a reduced picture from the server. Points cannot be shown or
  placed on it; the points stay stored.** — when the app cannot tell where
  they go, for example a picture stored on its side.

When a map's picture is turned or flipped in the web interface, the reduced
picture is fetched again, unless you have changed the map here since.

Under **Needs your attention**, **2 raster maps or map points were not
stored** means one with the same name, or a point of the same place on the
same map, was already on this phone and was kept. **2 map pictures were not
fetched** means those maps are here without a picture; the next sync tries
again.

## 3D survey models

When the installation offers **3D survey models**, the club's models of the
caves you carry, and the places put at their stations, travel too. That has
its own page: [3D survey models — With SilexGIS](3d-models.md#with-silexgis).

## Running a sync

Two buttons on the **Sync** card, both disabled until a selection is chosen
and while a run is in progress (a small spinner shows beside the heading):

| Button | What it does |
|---|---|
| **Sync now** | The ordinary run. Sends what changed here, then reads what has changed on the server since this device last read it. |
| **Read everything** | The same run, except the reading half starts every part from the beginning instead of from where it left off. |

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
  updated from the server's version: caves, places, trips, scans, maps,
  points, models.
- **sent** — rows the server took from you.
- **removed** — rows deleted here because they were deleted on the server.

When an account's uploads wait for a reviewer, the sentence adds how many
are waiting (*2 waiting for review*). With nothing to do either way it reads
**Already level with the server**. A part the installation switched off
during the run is named at the end — *The server does not offer the trip
recordings at the moment.* — and the rest of the run went on. A run that
failed shows the reason in red, in the server's own words where there is
one.

There is no progress bar, no per-file detail and no log tab as there is on
the FTP screen; a run either finishes with counts or fails with a sentence.

### Deletions travel, and they take things with them

This is the destructive part, in both directions.

- A cave or place **deleted on the server** is deleted here on the next
  read, together with what hangs off it on this device — its map bindings,
  trip points, document links and beacon registrations. It is not put in a
  bin; it is gone. Trips, maps and points deleted on the server go the same
  way; a deleted map's picture file stays.
- A cave or place **you delete here**, if the server already knew it, is
  sent as a deletion on the next run, and the server removes it *with
  everything inside it*.

Neither asks for confirmation at sync time. The confirmation was the delete
itself. If you are unsure, take a backup before syncing — see
[Database export, import and backup](database-export-import.md).

## Needs your attention

When a run leaves something for you to decide or to know, a **Needs your
attention** card appears under the Sync card. It stays there while the app
is running, including if you leave the screen and come back, but the card
itself is not written down: closing the app loses it. What waits for a
reviewer or for your decision *is* written down, and the next run counts it
again; refusals and nearby reports are not, and the next run surfaces only
what is still outstanding.

The entries it can hold:

- **2 need your decision** — opens the **Needs a decision** page; see
  [Reviews and decisions](#reviews-and-decisions).
- **2 waiting for review** — see [Reviews and decisions](#reviews-and-decisions).
- **3 photos and documents were not sent** — see
  [Sending them, and mobile data](#sending-them-and-mobile-data).
- **Changed on the server as well**, **Refused**, **Something was already
  nearby** and **rows that could not be stored**, below.
- Trips, maps and map pictures not stored or not fetched — see
  [Trips](#trips) and [Raster maps](#raster-maps).

### Changed on the server as well

Somebody edited the same cave or place after this device last read it, so
your version was **not** applied — nothing of yours was lost, and nothing of
theirs was overwritten. The entry carries the server's own wording, and
then either:

- **On the server: *name*** — the server's version of that row, so you can
  see what you are up against; or
- **Read everything to see the server's version.** — the server did not hand
  its version back, because your account may not have that cave's position.

The row is also put on the **Needs a decision** page and is not sent again
until you choose there: go back to the server's version, or keep yours. The
same happens to a trip, a map, a photo or a point that met a later version
on the server.

There is no merge view in this version: nothing shows the two versions side
by side. To end up with a mix of the two, take the server's version and then
edit it here.

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

## Reviews and decisions

### When uploads wait for a reviewer

An installation can mark an account so that its uploads need review. What
that account sends is then held by the server for a reviewer instead of
being written. The phone counts it under **Needs your attention**:

> **2 waiting for review**
> This account's uploads are checked by a reviewer before they land. Until
> then you keep seeing your own version.

A held change is not sent again while it waits. Edit it again and the new
version goes up and waits in its place.

When the installation offers **Review**, every sync reads the reviewers'
decisions at its end. An accepted change becomes the server's, and nothing
more is asked of you; when the reviewer accepted only part of it, the
server's version replaces yours here. A change that was turned down, or that
was accepted but could not be written, goes to the **Needs a decision**
page.

### The Needs a decision page

Reached from **2 need your decision** on the **Needs your attention** card:

> Turned down by a reviewer, or changed on the server as well. Choose what
> to do with each one.

Each item shows its name (or **(no name)**), what it is — **Cave, area or
place**, **Phone user**, **Photo or document**, **Where a photo or document
hangs**, **Trip recording**, **Trip scan**, **Raster map**, **Point on a
raster map**, **Place at a station of a 3D model** — and why it is there:

- **Turned down** — a reviewer said no, with their note under it when they
  wrote one;
- **Could not be written** — accepted, but refused when the server wrote it,
  with the server's code; often the account has lost a right;
- **Changed on the server as well** — see above;
- **Another point marks this place on the server's map** — your point and
  one already on the server stand for the same place; its 3D counterpart is
  **The server already puts this place at another station of this model**.

**Your removal** marks a deletion of yours, and **New here; the server never
had it** something that exists only on your phone. The buttons, as they
apply:

| Button | What happens |
|---|---|
| **Use the server's version** | Your version is replaced by the server's: **The server's version is back.** When the phone was not handed the server's version, the button reads **Re-read from the server** and the answer is **The server's version arrives with the next sync.** |
| **Keep mine, don't send** | **Kept on this device. It is sent again when you edit it.** |
| **Delete** | For something the server never had. **Delete this draft?** — *The server never had it. Deleting it removes it from this device.* |
| **Remove my point** | For a second point on the same place. Your point goes, and the server's arrives with the next sync. A place at a 3D model's station gets **Remove my station** instead. |

Nothing is decided for you. Until you choose, each item stays on the phone
as you left it and is not sent again — a turned-down new cave stays a local
draft. With nothing left, the page says **Nothing waits for your
decision.**

## Forget

**Forget** on the server card asks first:

> **Forget this server?**
> Your caves stay on this device. What is removed is the stored sign-in and
> everything this device remembers about its conversation with that server.

Press **Forget** to confirm, or **Cancel**.

**What it removes:** the server's name and address, your stored sign-in for
it, the selection you chose, the **Send caves I survey elsewhere** setting
and the three file switches, this device's reading positions, its record of
which rows the server already holds and at which version, the changes
waiting for review and the items on **Needs a decision**, the club's list of
cavers and the caver chosen for each phone user, the server's list of photos
and documents, files half-sent to it, and what it knew of the trips and maps
the two share.

**What it does not remove:** a single cave, area, place, document, photo,
map or trip — including the files you downloaded and the trips and maps
read from the server. Nothing is deleted from your database, and nothing at
all is deleted from the server — the club's registry is untouched, and
other devices signed in to it carry on as before. A change held for a
reviewer stays held there; the phone just stops counting it.

It cannot be undone, but nothing valuable is lost: you can add the server
again and sign in.

Things to expect if you do. The trips list no longer tells another phone's
trips apart from yours, so they stop being hidden. And the device has
forgotten what it and the server had agreed each shared row said, so the
next sync starts that conversation from scratch, and on that first read the
server's version of a row the two sides both hold is written over the local
one. Where the two copies came from the same origin — which is exactly the
case after a forget and re-add — an edit you made on the phone in the
meantime can be replaced by the server's text. Sync before forgetting, or
push your changes up again afterwards.

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
  new cave is not sent unless **Send caves I survey elsewhere** is on. If
  the result says something is *waiting for review*, it reached the server
  and waits for a reviewer.
- **Photos never go up** — check **Send photos and documents**, and that
  **What the server offers** lists **Sending photos and documents** as
  **Offered**. Away from Wi-Fi with **Ask before using mobile data** off,
  they wait for Wi-Fi.
- **No "On the server" section under a cave's documents** — the
  installation does not offer **Photos and documents**, there is nothing
  there you do not already hold, or no sync has run since it was added.
- **No "Caver on …" box when editing a user** — the user is new (save it
  first), or the installation does not offer **People** to your account.
  Run a sync after it starts offering it.
- **Another phone's trips are missing** — they are hidden; turn on **Show
  trips from …** in the trips list.
- **Points missing on a map** — it is showing a reduced picture from the
  server; the note above the map says so. The points are still stored.
- **The Needs a decision page cannot be found** — it opens only from the
  **Needs your attention** card. Run a sync; anything still waiting is
  counted again.
- **The counts look smaller than expected** — the card counts what was
  received, sent and removed. Rows the server sent that this version of the
  app does not model, and rows held back because you have an unsent edit of
  your own, are not counted anywhere on the screen. Files you download from
  **On the server** are not counted either.

## Rough edges in this version

Said plainly, so you are not surprised:

- The screen holds a single server; there is no list and no default picker.
- After a selection is chosen the row shows its identifier, not its name.
- There is no progress detail and no log of a run — only the final counts.
- There is no merge view for a row that changed on both sides.
- Duplicate reports and refusals live only until the app closes.
- The **Needs a decision** page opens only from the **Needs your attention**
  card, so after the app restarts you need a sync to reach it.
- Map pictures come down during a sync on any network; the Wi-Fi switches
  only hold back what is sent.
- A caver chosen for a phone user can be changed but not cleared from the
  phone.
- The switch that shows another phone's trips is not remembered.
- Sets, roots and caving clubs are created and edited in the installation's
  web interface, never here.

## See also

- [FTP / SFTP sync](ftp-sync.md)
- [Manual sync and the change log](sync-and-change-log.md)
- [Sharing data between teams](../workflows/sharing-data.md)
- [Database export, import and backup](database-export-import.md)
- [Caves and cave areas](caves-and-areas.md)
- [Documents and photos](documents.md)
- [Trips](trips.md)
- [Raster maps](raster-maps.md)
- [Users](users.md)
- [3D survey models](3d-models.md)
- [Settings](settings.md)
