# Settings

[← Back to index](../README.md)

Settings gathers every global preference and data-management action into
one list of sub-pages. This page is the map of that list: what each
entry holds, and where the full description of it lives.

## Opening settings

Open **Settings** from the ⋮ menu in the app bar of almost any screen.
If **Show home toolbar** is on, the home screen also shows a gear button
in its toolbar that goes straight there.

Every choice you make in Settings is stored in the app and survives a
restart. Most of them stay on the device; the place-code strategy and
the QR-code-resource-identifier settings are the exception — they travel
inside sync archives, so a team can share one numbering scheme.

## The settings list

The list mirrors the order shown in the app.

| Entry | What it covers |
|---|---|
| **General** | Language and general preferences |
| **Image compression** | Compress and resize images on import |
| **QR Code Generation** | QR code size, colors, error correction |
| **Place code identifiers** | Strategy, rules, and QCRI mode for cave place codes |
| **PDF Output** | Grid layout, label template |
| **Map** | Surface map layers and offline MBTiles files |
| **Database** | Reinitialize, export database |
| **Users** | Manage users and select the current one |
| **Man. sync** | Exchange data with other devices via archive files |
| **FTP / SFTP sync** | Sync with a shared FTP or SFTP server |
| **Club server (SilexGIS)** | Sync caves with a SilexGIS installation your club runs |
| **Data Export / Import** | Export or import all application data |
| **Beacon detection** | Automatic place detection via BLE beacons, thresholds, diagnostics |
| **Debug Info** *(debug mode only)* | Database path, data directory, configuration table |

> 📷 [The whole settings list](../screenshots/07-settings.md#settings-main-full) — The complete Settings menu, all twelve categories in one capture.

## General

- **App language** — a dropdown of the languages the app ships with,
  listed by their two-letter codes: `en` (English) and `ro` (Romanian).
  The app starts in Romanian, so this is where you switch to English.
  The choice takes effect immediately — nothing restarts — and a screen
  still open behind Settings shows the new language once you go back to
  it.
- **Show home toolbar** — displays the scan / add / documents / settings
  buttons in a toolbar on the home screen. With it off, **Scan QR**,
  **Add new cave** and **FTP / SFTP sync** move up into the top bar
  instead; the ⋮ menu holds the same entries either way. The small
  toolbar button above the cave list ("Show action toolbar" / "Hide
  action toolbar") flips the same setting without coming here.
- **Auto-add entrance when creating cave** — automatically creates an
  entrance cave place whenever you add a new cave. On by default; turn
  it off if you prefer to create the entrance yourself.
- **Allow bulk deletion of caves** — shows a delete button in the home
  screen's cave-list selection mode, so every selected cave can be
  deleted at once. Turn it off to reduce the risk of an accidental mass
  deletion. It has no effect on cave areas or cave places.
- **Ask which cave on ambiguous QR scan** — when a scanned code matches
  places in more than one cave, a dialog asks which one you meant. With
  it off the app silently opens the match from the last-opened cave.
- **Ask which cave on ambiguous deep link** — the same policy for
  `sp://` links opened from outside the app. See
  [Deep links](deep-links.md).
- **Reset help tours** — clears the "already shown" flag for every
  guided highlight tour, so the first-visit overlays appear again the
  next time you open each screen. A message confirms: "All help tours
  have been reset".

## Image compression

Controls the compression and resizing applied to photos as they are
taken or imported.

- **Enable image compression** — the master switch. While it is off the
  originals are stored untouched and the rest of the page is greyed out.
- **Compression profile** — **Low reduction**, **Medium reduction**,
  **High reduction**, **Very high reduction** or **Manual**.
- **Max resolution (px)** and **Image quality (%)** — editable only when
  the profile is **Manual**. With any preset the two fields are greyed
  out and the values that preset produces are shown as read-only text
  underneath.

Tune it down for long expeditions when storage is tight; up for archival
quality.

## QR Code Generation

Controls how QR labels are produced, and how scanned codes are read.

- **QR output** — whether printing produces a **PDF** or **Images**.
- **QR size (px)** and **QR image padding (px)**.
- **Label font size** and **Label font family**.
- **QR background color** and **QR foreground color** — entered as
  `0xAARRGGBB` values, with a colour swatch you can tap to pick.
- **DPI (quality)**.
- **Error correction** — L, M, Q or H. Higher tolerates more damage to a
  printed label but makes the code denser. QR modules are always square;
  there is no shape setting.
- **Export images as zip** — bundle the generated images into a single
  zip file instead of writing them out loose. Easier to move off the
  phone.
- **Include deep link prefix** — writes `sp://` into the encoded value.
  `sp://` is SpeleoLoc's own link scheme, so a phone without SpeleoLoc
  gets nothing usable out of such a label. With it off the code carries
  the bare identifier, which is the form to print when the same labels
  are also read by another system. The app's own scanner reads both.
- **Landing address for printed labels** — your club server's address for
  printed labels, for example `https://speo.example.org/q/`: the code
  then carries that address plus the identifier, so any phone's camera
  opens it and SpeleoLoc still reads it. Empty by default, and while one
  is set it overrides **Include deep link prefix**, which is greyed out.
  See [QR codes](qr-codes.md).
- **PDF QR code padding (pt)** — **Horizontal padding** and **Vertical
  padding** between printed labels. Note that this lives here, not on
  the PDF Output page.
- **QR code label template** — what is printed under each code, with the
  list of available variables and formatting codes shown below the
  field. See [QR codes](qr-codes.md).

### QR scan settings

At the bottom of the same page, this group decides how codes made by
other systems are read:

- **Strip URL to identifier** — when a scanned code is an HTTP or HTTPS
  address, only the part after the last delimiter character is used as
  the identifier.
- **URL delimiter characters** — the list of single characters that
  count as delimiters, comma- or space-separated (for example `/, =`).
  The field only appears while stripping is on.

> 📷 [QR generation settings](../screenshots/04-places-and-qr-codes.md#settings-qr-generation) — Settings that control how QR labels are rendered and scanned.

## Place code identifiers

Two tabs, each with its own action that runs over the whole dataset.

**Strategy** — pick the assignment **Strategy** and set its rules. A
short description sits under the dropdown and **More info** opens the
full explanation.

- **Global hierarchical** — **Country code**, **Organization code**,
  **General area identifier width**, **Cave local index width**,
  **Cave-place local index width**, **Main entrance suffix**, **Segment
  separator** and **Allow non-digit segments**. A `/` or an `=` in the
  **Segment separator** truncates every printed code when it is scanned
  back; the field warns you, but nothing stops you saving it. See [Place
  codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md).
- **Per-cave sequential** and **Per-area sequential** — **Start at**,
  **Step**, **Zero-pad width** and **Main entrance first**.

**Generate codes for entire dataset** assigns codes to every cave place.

**QR code res. ids** — sets the **QR code resource identifier mode**,
either **Mirror PCI** or **Hashed**, with **Hash length**, **Hash salt**
and, in mirror mode, **Use hash for entrances**. A worked example under
the fields previews the result. **Recompute all QCRIs** rebuilds the QR
payload of every cave place with the current mode.

Both dataset-wide actions ask for confirmation first, and then ask what
to do each time they are about to overwrite a value that already exists.
Recomputing changes the payloads, so QR labels you have already printed
stop matching — reprint them.

See [Place codes (PCI) and QR payloads
(QCRI)](place-code-identifiers.md).

## PDF Output

A single group, **QR codes per page**: **Columns** (1–10) and **Rows**
(1–20), each set with a stepper or by typing the number.

The spacing between printed labels and the label template are on the QR
Code Generation page, not here.

## Map

- **Coordinate display format** — how positions are written throughout
  the app: **Decimal degrees** (the default), **Degrees, minutes,
  seconds (DMS)** or **UTM**. It changes readouts only — the surface
  map's info card and placement bar, and the extra formatted line under
  a cave place's latitude and longitude. The entry fields themselves
  stay in decimal degrees, and coordinate entry accepts all three
  formats whatever this is set to. UTM readouts fall back to decimal
  degrees for positions beyond roughly 80° S / 84° N. See [GPS and
  coordinates](gps-and-coordinates.md).
- **Cache online map tiles** — keep downloaded base-map tiles on the
  device so visited areas still work underground or out of signal. The
  **Tile cache** row underneath shows how much space it uses and has a
  button to clear it.
- **Auto-load MBTiles** — offer the offline map files found in the app's
  MBTiles folder as map layers.
- **MBTiles folder** — the folder to copy `.mbtiles` files into, with a
  copy-path button and an explanation of what belongs there. Raster
  files only; vector files are listed but cannot be drawn.
- **Import MBTiles file** — browse for a file and copy it in. If a file
  of the same name is already there, the app asks before overwriting.
- **Detected files** — every file found. Each raster file has a dropdown
  choosing whether it is used as a **Base map** or an **Overlay**; a
  vector file is listed as unsupported and has no dropdown. The app bar
  also has a rescan button.

See [Surface map](surface-map.md) and [MBTiles
layers](../workflows/mbtiles-layers.md).

## Database

The blunt tools. Everything here except **Export database** destroys
data that is not backed up somewhere else.

- **Reinitialize database** — wipes everything and leaves an empty
  database. (Developer builds have a second button above it,
  **Reinitialize database with test data**, which wipes everything and
  fills the database with the bundled sample dataset; it is not in the
  released app.)
- **Restore database from file** — replaces the current database with a
  `.sqlite` or `.db` file you pick.
- **Export database** — saves a copy of the database file through your
  device's save dialog, offered as `speleo_loc_export.sqlite` (on iOS,
  into a folder you choose). This is the quick snapshot to take before
  anything risky, and it is exactly what **Restore database from file**
  expects back. It contains the database only: photos, documents and
  raster map images are not in it, so for a complete backup use Data
  Export / Import instead.
- **Open SQL command runner** *(developer builds, with debug mode on)* —
  runs SQL commands directly against the local database. Nothing here is
  checked or undoable, and the released app does not include it.

Reinitializing asks for confirmation **twice**. Restore asks **once**
and then opens the file picker — so a restore is easier to trigger than
a reinitialize, and it is just as irreversible. The first confirmation
of each of these actions warns that the application will be restarted,
and it does restart automatically once the operation finishes.

See [Database export, import and backup](database-export-import.md).

## Users

The list of caver identities used for change attribution, and the
picker for the current user. See [Users](users.md).

## Man. sync

Manual, file-based exchange with other devices. Two tabs: **Archive
sync**, which produces and imports sync archives, and **Change log**,
the read-only record of what changed and who changed it. See [Sync
dashboard & change log](sync-and-change-log.md).

## FTP / SFTP sync

Manages the connection profiles only: add a profile, edit or delete one,
run **Test connection**, and mark one as the default with **Use as
default** from its ⋮ menu. Sync runs themselves are started from the
home screen or from the FTP sync card in the app menu, not from this
page. See [FTP sync](ftp-sync.md).

> 📷 [The list of FTP profiles](../screenshots/06-sync-and-sharing.md#ftp-sync-profile-list) — The FTP / SFTP sync settings screen listing the configured server profiles.

## Club server (SilexGIS)

The connection to a cave registry your club runs on its own server: add
the server, sign in, choose which caves this device carries, and start a
run. Only caves, cave areas, cave places and surface areas travel —
documents, photos, raster maps, trips and the change log do not. Unlike
FTP sync there is no button for it anywhere else in the app, so a sync
happens only when you ask for one here. This is recent work with rough
edges, and it is worth having only if your club already runs such an
installation. See [Club server sync](silexgis-sync.md).

## Data Export / Import

Full export and import of the database plus its files.

- **Export Settings** — **Include documentation files**, **Include
  raster map images**, and **Diff export (only new files)**, which packs
  only the files added since the last full export. **Export Archive**
  builds the zip and then, on Android, opens your device's save dialog
  for you to place it; on iOS and desktop it asks for a destination
  folder first. Saved FTP passwords are never written into an exported
  archive.
- **Import** — **Import Archive** reads an archive back, asking whether
  to replace or merge, and prompting on each conflict.

The released app has no **Test Data** section on this page. Developer
builds add one: **Download and load test data** fetches the sample
dataset and replaces everything you currently have with it, after a
confirmation, and shows a warning that the test data archive URL is not
configured when the build was given no test-data address.

See [Database export, import and backup](database-export-import.md) and
[Sharing data](../workflows/sharing-data.md).

## Beacon detection

Recognises where you are from Bluetooth beacons placed in the cave,
without scanning anything.

- **Detect beacons automatically** — the master switch. Turning it on
  the first time asks for the Bluetooth and location permissions the
  scan needs. Every slider and switch below it stays greyed out until
  this is on.
- **Signal trigger threshold** — a slider from −100 to −40 dBm, −75 by
  default. Closer to 0 means you must be nearer the beacon before it
  counts as reached.
- **Re-trigger cooldown** — 1 to 30 minutes, 5 by default: how long the
  same beacon stays quiet after it has fired, so it does not keep
  triggering while you linger.
- **Open place on detection** — off by default. On, a detection opens
  the place as a QR scan would; off, it only tells you.
- **Detection sound** — on by default; plays an alert when a beacon is
  recognised.
- **Keep detecting in background** — scanning continues with the screen
  off or another app in front, alerting through a notification. Turning
  it on asks for notification permission and for an exemption from
  battery optimisation.
- **Background scan interval** — 5 to 60 seconds, 30 by default. Longer
  intervals save battery. This slider needs background detection on as
  well as the master switch.

Two sub-pages sit at the bottom, and both stay reachable whether or not
detection is switched on:

- **Tag management** — titles, photos and the place each registered tag
  belongs to.
- **Beacon Lab** — live scan diagnostics, for when detection is not
  firing and you need to know whether the phone hears the beacon at all.

See [BLE beacons](ble-beacons.md).

## Debug Info *(debug mode only)*

Debug mode is off until you turn it on: tap the home screen title nine
times in quick succession — a pause of more than about three seconds
resets the count — and a message confirms "Debug mode activated". It is
not remembered, so it is off again after the app restarts; switching it
off by hand takes twenty taps.

While it is on, a **Debug Info** entry appears at the bottom of
Settings. In a developer build an **Open SQL command runner** button
also appears on the Database page; the released app never shows it.
Debug Info shows the application data directory and the database file
path, each with a copy button and, for the database, whether the file is
actually there. Below that it lists every stored setting as a key and a
value: tap a row to edit the value in a dialog, use the + button to add
an entry, copy any value with its copy button, and read the cloud icon
that says whether that entry is included in sync.

This is a support and troubleshooting tool. A mistyped value here can
stop a feature working until it is corrected, and nothing warns you
first.

## See also

- [Home screen](home-screen.md)
- [Database export, import and backup](database-export-import.md)
- [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
- [Sync dashboard & change log](sync-and-change-log.md)
- [FTP sync](ftp-sync.md)
- [Club server sync](silexgis-sync.md)
- [BLE beacons](ble-beacons.md)
