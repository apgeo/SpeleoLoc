# Glossary

[← Back to index](README.md)

Every term this wiki uses, with a short definition and a link to the page
that covers it properly. Labels are the English ones; the app starts in
Romanian, and English is chosen in **Settings → General → App language**.

## Caves, areas and places

### Surface area
A named geographic region on the surface — a karst plateau, a massif, a
valley — that groups several caves together. Optional: a cave can have
none. It can also carry a general area identifier used when building
structured place codes.
See [Surface areas](features/surface-areas.md).

### Cave
The top-level record. It holds a **Cave title**, a **Description**, an
optional surface area and an optional **Cave local index** — and nothing
else: the cave itself carries no QR code and no place code. Everything
else (places, cave areas, raster maps, trips, beacons, documents) hangs
off it.
See [Caves and cave areas](features/caves-and-areas.md).

### Cave local index
The optional short number that identifies a cave inside its surface area
when the app composes structured place codes. **Generate cave place QR
codes (range)** on a cave's places list refuses to run until the cave has
one.
See [Caves and cave areas](features/caves-and-areas.md).

### Cave area
A named zone *inside* one cave — "Main gallery", "Lake room" — used to
group its places for filtering, sorting and display. Optional, and never
shared between caves.
See [Caves and cave areas](features/caves-and-areas.md).

### Cave place
A single named point inside one cave, and the unit SpeleoLoc is built
around: QR labels, documents, map pins, BLE beacons and trip points all
point at a cave place. It has a **Title**, a **Description**, an optional
**Depth '+/-'**, an optional cave area, optional codes, an optional
position, and the two entrance checkboxes.
See [Cave places](features/cave-places.md).

### Cave entrance / Main cave entrance
Two checkboxes at the bottom of the cave place form. An entrance gets a
door icon and an **Entrance** caption in the places list; the main
entrance is captioned **Main entrance** in blue and is the one drawn as
the large waymark on the cave map. A cave should have exactly one main
entrance.
See [Cave places](features/cave-places.md).

### Depth '+/-'
The optional signed depth of a cave place relative to the entrance, in
metres — negative below, positive above. Accepted range is ±5000, and
anything beyond ±1800 asks you to confirm it is not a typo.
See [Cave places](features/cave-places.md).

## Codes, labels and links

### Place code identifier (PCI)
The **human-readable** code attached to a cave place: what is printed on
the label, and what the places list filters and sorts on. Any string, not
just a number, and it can encode a country / organization / area / cave /
place hierarchy. It should be unique within a cave.
See [Place codes](features/place-code-identifiers.md).

### QR code resource identifier (QCRI)
The payload actually **encoded inside the QR pixels**, and the part after
`sp://` in a deep link. It is either a copy of the place code (mirror
mode) or a short hash of it (hash mode).
See [Place codes](features/place-code-identifiers.md).

### Mirror mode / Hashed mode
The two settings of **QR code resource identifier mode**. **Mirror PCI**
copies the place code into the QR payload, so a person reading the label
can read the code. **Hashed** puts a short hash there instead, which
keeps the numbering scheme off the label.
See [Place codes](features/place-code-identifiers.md).

### Place code strategy
The rule the app follows when it fills in place codes in bulk. Chosen in
**Settings → Place code identifiers → Strategy**: **Global
hierarchical**, **Per-cave sequential** or **Per-area sequential**. The
choice travels in sync archives, so a whole team numbers alike.
See [Place codes](features/place-code-identifiers.md).

### Deep link
A link of the form `sp://<code>`. Opening one — from the scanner, or, on
Android, from a message, note or file outside the app — takes you to the
matching cave place.
See [Deep links](features/deep-links.md).

### QR label
The printed sticker or tag mounted in the cave. SpeleoLoc lays labels out
on a printable sheet with **Print QR codes**, and the text under each one
follows the **QR code label template** set in **Settings → QR Code
Generation**.
See [QR codes](features/qr-codes.md).

## Maps inside the cave

### Raster map
A bitmap image of a cave — a scanned survey or an export from survey
software — imported into the app. SpeleoLoc does **not** draw maps; it
displays the ones you give it.
See [Raster maps](features/raster-maps.md).

### Map type
What a raster map shows, chosen on the map form: **plane view**,
**projected profile** or **extended profile**.
See [Raster maps](features/raster-maps.md).

### Point definition
The position of a cave place on one particular raster map. A place can
have no point definition, one, or one per map. The **Raster maps
definitions** report on a place's pin counter shows which maps already
hold a point for it.
See [Map viewer and point editor](features/map-viewer.md).

## The surface map

### Cave map
The full-screen geographic map of every cave place that has coordinates,
opened with **Cave map** from the home screen or from a cave's places
list. Older notes call the same screen the *surface map*.
See [Cave map](features/surface-map.md).

### Base layer
The single background map the cave map draws on — one of ten public
online sources, or one of your own MBTiles files given the **Base map**
role. Picked in **Map layers**.
See [Cave map](features/surface-map.md).

### Overlay
A layer drawn *on top of* the base layer. Any number can be ticked at
once in **Map layers**; only MBTiles files given the **Overlay** role
appear there.
See [Cave map](features/surface-map.md).

### MBTiles layer
One of your own offline map files — a `.mbtiles` file holding pre-cut
map tiles, produced on a computer from a scanned sheet or an export.
Raster files only; vector ones are listed but cannot be drawn. Managed
under **Settings → Map**.
See [Using offline MBTiles layers](workflows/mbtiles-layers.md).

### Tile cache
The store of online base-map tiles the app keeps on the device so an
area you have already visited still draws with no signal. Filled while
**Cache online map tiles** is on, and emptied with **Clear tile cache**
in **Settings → Map**. Clearing it never touches your MBTiles files.
See [Cave map](features/surface-map.md).

## Positions and coordinates

### Position
The latitude, longitude and optional altitude of a cave place. Latitude
and longitude are stored as decimal degrees, altitude in metres. Any
place can carry one, not only an entrance, and every place that has one
is drawn on the cave map.
See [GPS and coordinates](features/gps-and-coordinates.md).

### GPS recorder
The **Record GPS point** screen, which averages many satellite fixes
while you stand still and hands the average to the cave place form when
you tap **Capture** and then **Use this**. Of the three coordinate helpers
on the place form it is the only one that fills the altitude field, though
you can always type an altitude in yourself.
See [GPS and coordinates](features/gps-and-coordinates.md).

### Coordinate format
How a position is written. **Enter coordinates** accepts decimal
degrees, degrees-minutes-seconds and UTM and works out which you typed;
**Settings → Map → Coordinate display format** chooses which of the
three positions are *shown* in. It is a display setting only — the
stored fields and exported files always hold decimal degrees.
See [GPS and coordinates](features/gps-and-coordinates.md).

## Beacons and sensor tags

### BLE beacon
A small battery-powered Bluetooth tag mounted at a point of interest.
Once registered on a cave place, walking past it identifies that place
hands-free — no phone in your hand, no camera. Two families are
recognised: iBeacon-style tags and Ruuvi sensor tags.
See [BLE beacons](features/ble-beacons.md).

### Tag
The physical beacon hardware, as opposed to the cave place it stands
for. **Settings → Beacon detection → Tag management** lists every tag
you have registered and lets you give each one a **Title**, a
**Description** and a photo of it in place — the photo stays on the
phone that took it and is in no archive.
See [BLE beacons](features/ble-beacons.md).

### Beacon detection
The background listening that turns a passing tag into a place
identification. Off by default; switched on with **Detect beacons
automatically** in **Settings → Beacon detection**, or from the
**Beacon detection** switch in the app menu. Its options set how strong
a signal must be, how long the same tag stays quiet afterwards, whether
the place opens, whether a sound plays, and whether scanning continues
in the background on Android.
See [BLE beacons](features/ble-beacons.md).

### Ruuvi sensor tag
A beacon that also measures temperature, humidity, air pressure, battery
voltage and motion, and broadcasts them continuously. Used as a place
marker like any other tag, with **Live sensor data** and **Sensor
history** screens on top.
See [Ruuvi sensor tags](features/ruuvi-sensors.md).

### Sensor history
The measurement log a Ruuvi tag keeps on board — roughly its last ten
days. **Download from tag** copies it into the app, where it is charted
and listed and can leave as a CSV file with **Export CSV**. **Clear
stored history** deletes the copy on the phone and cannot be undone; the
tag's own log is untouched.
See [Ruuvi sensor tags](features/ruuvi-sensors.md).

### Beacon Lab
The diagnostics screen at **Settings → Beacon detection → Beacon Lab**.
It shows what the radio actually hears, in raw form, and is the tool for
checking a mounting position or chasing a tag that will not be seen. It
registers nothing and changes no cave data.
See [BLE beacons](features/ble-beacons.md).

## Trips and documents

### Trip
One recorded caving session in one cave: a start time, an optional end
time, an ordered list of trip points, a generated trip log and the
documents made while it ran. Only one trip is active at a time on a
device, across all caves.
See [Trips](features/trips.md).

### Trip point
An entry in a trip's point sequence: a cave place plus a timestamp.
One is created when you scan the QR code of a place in the active trip's
cave — scanning an entrance asks first whether you are leaving — and also
whenever automatic beacon detection recognises a tag registered on a place
in that same cave. Both sources produce identical points, and neither adds
one while the trip is paused.
See [Trips](features/trips.md).

### Trip log
The text account of a trip, regenerated from its recorded events —
started, point added, restarted, ended. Opened with **Trip log** on the
trip screen; the book icon on the log screen picks the wording style.
See [Trips](features/trips.md).

### Trip report template
An ODT or DOCX file containing placeholder variables, kept under
**Manage templates**. Picking one when exporting a trip fills the
placeholders with that trip's data and produces a finished document.
See [Trip reports and templates](features/trip-reports.md).

### Documentation file
What the app calls a document: a photo, a video, an audio recording, a
plain-text or rich-text note, a web link or any other file, attached to
a cave place or to a cave. Documents arriving from another device may
also be attached to a cave area.
See [Documents](features/documents.md).

## Sharing and bookkeeping

### Archive
The `.zip` produced by **Settings → Data Export / Import → Export
Archive**: a copy of the whole database, optionally with the document
files and raster map images beside it. This is the backup format and the
way to set up a new device from nothing.
See [Database export, import and backup](features/database-export-import.md).

### Sync archive
The `.zip` produced by **Man. sync → Export sync archive**, holding one
line per record with the time it was last edited. The receiving device
*merges* it into what it already has rather than replacing anything, so
two cavers who swap archives end up with both halves of the work.
See [Manual sync and the change log](features/sync-and-change-log.md).

### Conflict resolution
The importing device's choice of what to do when both sides have edited
the same record: **Automatic (last writer wins)** silently keeps the
newer edit, **Manual (review each conflict)** shows you the two versions
side by side and asks. Nothing about the choice is stored in the
archive.
See [Manual sync and the change log](features/sync-and-change-log.md).

### Change log
The running record of every addition, edit and deletion made on this
device, with the time and the user who made it. It is what lets a merge
replay someone else's deletions. Read it in the **Change log** tab of
**Man. sync**, or during a run on the FTP sync screen. It always travels
in a sync archive.
See [Manual sync and the change log](features/sync-and-change-log.md).

### Sync session
One run of an FTP sync. The **Log** tab of the FTP sync screen keeps the
last 200 lines of activity and marks the start of each run with a
`─── new sync. session ───` divider. The change log has no notion of a
session — it is one continuous list.
See [FTP / SFTP sync](features/ftp-sync.md).

### Server profile
A saved FTP, FTPS or SFTP endpoint — name, host, port, credentials and
remote folder — added under **Settings → FTP / SFTP sync**. One profile
is marked as the default, and that is the one a sync run uses.
See [FTP / SFTP sync](features/ftp-sync.md).

### Club server (SilexGIS)
A cave registry a club runs on its own server, with a web interface,
accounts and permissions, that this device can sync with **row by row**
rather than by whole snapshots. Only caves, cave areas, cave places and
surface areas travel; documents, raster maps, trips and beacons never do.
Added under **Settings → Club server (SilexGIS)**, and needed only if
your club already runs such an installation.
See [Club server (SilexGIS)](features/silexgis-sync.md).

### Selection
The named list of starting points on a club server that decides which of
its caves this device carries — everything inside those points comes too,
including whatever is added inside them later. Selections are made in the
server's web interface, never in the app; **Choose** on the sync screen
picks among the ones your account owns. The installation's own interface
calls one a *set*. Unrelated to **Selection mode** on lists.
See [Club server (SilexGIS)](features/silexgis-sync.md).

### Root
One starting point of a selection: a surface area or a cave the selection
begins from, counted beside each selection in the picker — *3 roots*.
Only something the server already holds can be a root, which is why a
cave the server has never heard of reaches it through **Send caves I
survey elsewhere** and not by being added to a selection.
See [Club server (SilexGIS)](features/silexgis-sync.md).

### Caving club
The club a row belongs to in a club server's registry. A selection that
names none can still be read through perfectly well, but everything you
send is refused, because the server cannot tell which club should own the
new row. The cure is on the server: give that selection a club in the web
interface.
See [Club server (SilexGIS)](features/silexgis-sync.md).

### Read everything
The second of the two run buttons on the club server sync screen. It runs
exactly as **Sync now** does, except that the reading half starts the
selection from the beginning instead of from where this device left off.
Always safe, only slower — and the only thing that brings down a cave
your account has just been granted access to.
See [Club server (SilexGIS)](features/silexgis-sync.md).

### Needs your attention
The card a club server run leaves behind when something is for you to
decide: a row changed on the server as well, a row the server refused, a
cave you created that sits close to one the server already holds, or rows
it could not store. It is not written down — it lives while the app is
running, and the next run surfaces anything still outstanding.
See [Club server (SilexGIS)](features/silexgis-sync.md).

### User
A caver's identity, kept in the app so every change can be attributed. It
is not a login and there is no password. Chosen in **Settings → Users**
and stamped on every record you touch; before you pick one, the app
creates and uses a **system** user.
See [Users](features/users.md).

### Device UUID
The identifier the app gives this installation on first run. You never
normally see it: it stamps change-log entries so an edit can be traced
back to the device that made it, and it is not overwritten when you
import someone else's archive.
See [Users](features/users.md).

## Working with lists and screens

### Filter
The search box opened with **Show filter** above a list. It narrows the
list as you type, matching more than the title — on the cave places list
it also matches the place code and the cave area name — and the header
count changes to show how many of how many are left.
See [Lists: filter, sort and selection](features/lists-filter-sort-select.md).

### Sort by
The picker that orders a list, with the fields depending on the list.
The choice is remembered for that list between visits, and some fields
also insert grey group headings.
See [Lists: filter, sort and selection](features/lists-filter-sort-select.md).

### Selection mode
The mode that puts a tick box on every row and adds **Select all**,
**Invert selection** and a delete action to the header. Actions such as
**Cave map** then apply to the ticked rows only; with nothing ticked they
fall back to whatever the filter leaves visible. **Print QR codes** also
follows the ticked rows, but with nothing ticked it prints every place in
the cave and ignores the filter.
See [Lists: filter, sort and selection](features/lists-filter-sort-select.md).

### Help tour
The highlight-and-explain overlay that runs the first time you open most
screens. Replay it from that screen's **Help tour** entry in the ⋮ menu,
or bring every tour back with **Reset help tours** in
**Settings → General**.
See [Settings](features/settings.md).

## See also

- [Overview](overview.md)
- [Getting started](getting-started.md)
- [Cave places](features/cave-places.md)
- [Place codes](features/place-code-identifiers.md)
- [Manual sync and the change log](features/sync-and-change-log.md)
- [Settings](features/settings.md)
