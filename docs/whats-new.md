# What's new

[← Back to index](README.md)

What each SpeleoLoc release brought, newest first. Every release is
published on GitHub; the [latest release](https://github.com/apgeo/SpeleoLoc/releases/latest)
always has the newest APK — see [Installing the Android APK](getting-started.md#installing-the-android-apk).

> SpeleoLoc is alpha software. A release marked *changes the database* or
> *changes the archive format* cannot be undone by installing an older
> version: export your data before you update, and update every device
> that syncs together.

## Coming in the next release

Already in the app's source, not yet in a published APK:

- **CSV import** reads files separated by semicolons, as spreadsheets set
  to Romanian write them, taking the separator from the header line. Place
  names now match whether they were typed with the cedilla (ş, ţ) or the
  comma-below (ș, ț) letters. See [CSV import](features/csv-import.md).
- **Trips**: a trip can no longer be started while another one is
  recording on this phone.
- **Sync and archives**: an archive entry that cannot be extracted is
  reported instead of failing the whole import; an FTP run that fails
  remembers the archives it had already imported, and cleans up after
  itself however it ends. Large archives are handled with less memory.
- **Restore**: copies of the database that failed replacements set aside
  are deleted after 30 days; the newest copy is always kept.
- Missing Romanian labels added.

## 0.4.2-alpha — 9 November 2026

*Changes the database and the archive format.* The published APK is a
full-options build: every feature switched on, including the developer
tools and the downloadable sample data.

### Highlights

- **BLE beacons and Ruuvi tags** — the phone recognises the tags at your
  cave places, also in the background on Android, with a loud alert.
- **3D survey models** — Therion `.lox` and Survex `.3d` surveys in a 3D
  viewer, with your cave places on the stations.
- **Surface map** — every cave entrance on an offline-capable geographic
  map, with GPS, measuring and GPX/KML exchange.
- **Trips** grow up — participants, corrected times, points from your
  photos and videos, editable points.
- **Club server (SilexGIS)** — two-way sync with a SilexGIS installation
  your club runs.
- **SFTP** with pinned host keys replaces FTPS for file-server sync.
- **The app asks who is using it** on first start.

### All additions

**BLE beacons and Ruuvi tags** — [BLE beacons](features/ble-beacons.md), [Ruuvi sensors](features/ruuvi-sensors.md)

- Register beacons at cave places and detect them automatically while the
  app is open, and in the background on Android with a loud alert. Scan
  interval down to 5 s, sound on or off, a quick switch in the drawer.
- Tag management with title, description and photo; a Beacon Lab
  diagnostics screen.
- Ruuvi tags: live sensor page, download of the history stored on the
  tag, with a chart and CSV export.

**3D survey models** — [3D survey models](features/3d-models.md)

- View `.lox` and `.3d` survey models attached to a cave: turn, zoom,
  plan and side views.
- Map cave places to survey stations and splay ends; marks, station
  information and trails.
- Open a cave's model from its places, raster maps, the places list and
  trips.

**Surface map** — [Surface map](features/surface-map.md), [GPS and coordinates](features/gps-and-coordinates.md)

- Full-screen map of cave entrances and places, with online base maps,
  an offline tile cache and imported MBTiles layers
  ([offline MBTiles layers](workflows/mbtiles-layers.md)).
- GPS position and averaged GPS fixes; place entrances and points on the
  map with a draggable pin.
- Distance and bearing measuring, marker clusters, filtering and grouping
  by cave area.
- UTM and DMS coordinates, shown and typed; GPX and KML export and import
  of cave places ([place transfer](features/place-transfer.md)).

**Raster maps** — [Raster maps](features/raster-maps.md), [Map viewer](features/map-viewer.md)

- Full-screen mode, image filters, a side toolbar, a landscape phone
  layout, and fading for filtered-out markers.

**Trips** — [Trips](features/trips.md), [Running a trip](workflows/running-a-trip.md)

- Participants and details for each trip; start and end times that can
  be corrected afterwards.
- **Points from pictures**: read the capture times and QR labels of the
  photos and videos you took underground, and turn them into trip
  points, documents and links.
- Add, move and remove trip points. The trip log is kept as written,
  with a warning when it falls behind the points.
- A paused trip stays paused across an app restart and a database
  replace.

**Documents** — [Documents](features/documents.md)

- Attach several files at once, bulk-import a folder into caves, and
  swipe through a zoomable image gallery.

**QR codes** — [QR codes](features/qr-codes.md), [Place code identifiers](features/place-code-identifiers.md)

- Batch label generation for caves from the home list; range generation
  for entrances and places not yet recorded; labels that a phone without
  SpeleoLoc can open.

**Club server (SilexGIS)** — [Club server sync](features/silexgis-sync.md)

- Sign in to your club's SilexGIS installation and sync caves, cave
  areas, places and surface areas both ways; where the installation
  offers them, also trip recordings, raster maps and their points, photos
  and documents, people and 3D survey models.
- One page to settle conflicts and reviewers' decisions, including
  sending your version over a newer one, or sending again a row the
  server deleted.
- A question before files travel over mobile data.

**FTP / SFTP sync** — [FTP sync](features/ftp-sync.md), [Sync and change log](features/sync-and-change-log.md)

- SFTP host keys are recorded on the first connection and a changed key
  is refused. FTPS is gone; its profiles are moved to SFTP.
- An import asks before it deletes records, and a record whose name is
  already taken here waits for your decision.
- Many fixes to sync and archives.

**Users** — [Users](features/users.md)

- The app asks who is using it on first start, and again when the
  selected user is missing after a data replace or was deleted by a
  sync. The selected user is kept across a dataset replace.

**CSV import** — [CSV import](features/csv-import.md)

- A cave's local index and area identifier, an automatic main entrance,
  and a confirmation before matched caves are updated.

**Language and platforms**

- The app's built-in widgets, the text editor and the photo editor follow
  the app language; missing translations added.
- Optional crash reporting, iOS build support, adaptive launcher icons.

## 0.2.1-alpha — 26 May 2026

*Changes the database.* Sync archives must now carry a device id; older
archives without one are refused.

### Highlights

- Place code identifiers and QR code identifiers with configurable
  assignment strategies.
- FTP sync and manual sync partly redesigned.
- Trip report text generation; trips start and stop on entrance scans.
- Cave and place lists can be sorted, grouped and batch-selected.
- One QR scanning workflow everywhere.

### All additions

**Place code identifiers** — [Place code identifiers](features/place-code-identifiers.md)

- Place codes (PCI) and QR code reference identifiers (QCRI), generated
  in batches from the cave places list, the cave form and the surface
  areas list, with a settings page for the strategy and its parameters.
- QCRI in QR label templates and deep-link lookup; CSV import and sync
  carry both.

**FTP sync** — [FTP sync](features/ftp-sync.md), [Sync and change log](features/sync-and-change-log.md)

- A combined sync dashboard with a change log tab.
- The FTP progress page can pause and resume, shows speed and time
  left, and links to the settings on a connection error.
- The upload is skipped when nothing changed locally; change-log entries
  for places, cave areas, surface areas and documents.
- Option to include FTP account passwords in a data export.

**Trips** — [Trips](features/trips.md), [Trip reports](features/trip-reports.md)

- A trip starts and stops automatically when you scan a cave entrance.
- Trip log generation; QR scans from the home screen are recorded as
  trip points.

**Raster maps** — [Raster maps](features/raster-maps.md)

- Reorder maps by dragging; duplicate pictures are recognised by their
  hash.
- Full-screen viewer, zoom buttons, a confirmation before deleting a map
  that has place definitions, and the first map with the scanned place
  selected after a QR scan.

**Lists and screens** — [Lists: filter, sort, select](features/lists-filter-sort-select.md), [Home screen](features/home-screen.md)

- Filtering, sorting and grouping in the cave and place lists; bulk cave
  delete with a double confirmation.
- A compact drawer, toolbar buttons for sync, surface areas and CSV cave
  import, a quick-action toolbar on documents, and a prompt about unsaved
  changes when leaving an editor.
- A new cave gets an entrance place automatically.

**QR codes** — [QR codes](features/qr-codes.md)

- QR scanning and deep links share one lookup; links are stripped to
  their code with configurable delimiters.
- Square QR modules and colour pickers for the label colours.

**Other**

- GPS recording with altitude for cave places, meant for entrances.
- Sample data downloadable and importable from within the app.
- A debug information page.

## 0.1.2-alpha — 23 April 2026

*Changes the database.*

- **Trip reports** from ODT and DOCX templates — [Trip reports](features/trip-reports.md).
- **Trip map** playback, zoom to the trip, and export as PNG.
- **Help tours** on most screens, with menu actions to replay, reset or
  turn them off.
- **CSV import** of caves, besides places, with surface areas and
  duplicate detection — [CSV import](features/csv-import.md).
- **Entrances**: places can be marked as an entrance or the cave's main
  entrance.
- The first version of this user documentation.

## 0.1.1-alpha.2 — 8 April 2026

*Changes the database.*

- **Cave trips**: start, pause, resume and stop; trip history, details
  and an editable log; points recorded from QR scans; documents linked
  to the trip — [Trips](features/trips.md).
- **Trip route on raster maps**, with direction arrows and numbered
  points.
- **Global menu** as a popup or a drawer.
- A choice screen when a QR code matches several places.
- The sound recorder can pause, resume and record over part of a
  recording.
- Selection mode in the cave places list, with batch delete and QR
  labels for the selected places.

## 0.1.0-alpha — 5 April 2026

The first public release: caves and cave places, raster maps with a point
editor, QR-based positioning, documentation media, QR code generation,
database export and import, and CSV data import.
