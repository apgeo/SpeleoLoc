# Glossary

[← Back to index](README.md)

Terms used throughout SpeleoLoc and this wiki.

### Surface area
A named geographic region on the surface (e.g. a karst plateau or massif)
that can group several caves together. Optional.
See [Surface areas](features/surface-areas.md).

### Cave
The top-level entry representing an individual cave. Has a title, an
optional surface area, an optional entrance place code (QCRI), and
contains cave places, cave areas, raster maps and trips.
See [Caves and cave areas](features/caves-and-areas.md).

### Cave area
A named zone *inside* a cave (e.g. "Main gallery", "Lake room"). Used to
group cave places for filtering and display. Optional.

### Cave place
A single, named point of interest inside a cave — the **unit** SpeleoLoc
is built around. Has a title, optional description, depth in cave, optional
GPS coordinates, an optional place code (PCI/QCRI), and may be
flagged as an
**entrance** or **main entrance**.
See [Cave places](features/cave-places.md).

### Place code identifier (PCI)
The **human-readable** code attached to each cave place (printed on
labels, shown in lists, used in reports). Replaces the older "QR code
identifier" integer field. Strings, not just numbers; can encode
country / organization / area / cave / place hierarchy.
See [Place codes](features/place-code-identifiers.md).

### QR code resource identifier (QCRI)
The actual payload **encoded inside the QR pixels** (and in
`sp://<qcri>` deep links). Either equal to the PCI (mirror mode) or a
short hash of it (hash mode).
See [Place codes](features/place-code-identifiers.md).

### Place code strategy
The algorithm SpeleoLoc uses to compute PCIs in bulk. Pluggable —
choose one in **Settings → Place codes**. Bundled strategies: **global
hierarchical**, **per-cave sequential**, **per-area sequential**.

### Deep link
A URI of the form `sp://<qcri>`. Opening it (via the scanner
or externally) navigates to the matching cave place. See
[Deep links](features/deep-links.md).

### Raster map
A bitmap image (plan view, projected profile, extended profile, …) of a
cave that has been imported into the app. SpeleoLoc does **not** draw maps
— it consumes existing ones. See [Raster maps](features/raster-maps.md).

### Map type
Classifies a raster map: **plane view**, **projected profile**, or
**extended profile**.

### Point definition
The (x, y) pixel coordinate of a cave place on a specific raster map.
A cave place can have zero, one or many point definitions — one per raster
map it appears on. See [Map viewer](features/map-viewer.md).

### Documentation file (a.k.a. document)
A file linked to a geofeature (cave place, cave, or cave area). Types
supported: photo, audio recording, text, rich text, image (edited sketch),
web link, or arbitrary file. See [Documents](features/documents.md).

### Geofeature
Generic term for anything documents can be attached to: a cave place, a
cave, or a cave area.

### Trip
A recorded caving session inside one cave. Has a start time, optional end
time, a free-form log, and an ordered list of **trip points**
(cave places visited, in scan order). See [Trips](features/trips.md).

### Trip point
An entry in a trip's point sequence: cave place + timestamp. Created every
time a QR is scanned during an active trip.

### Trip report template
An ODT or DOCX document with placeholder variables used to generate a
printable/exportable report from a trip's data.
See [Trip reports](features/trip-reports.md).

### Product tour
A first-run highlight-and-explain overlay available on most screens. Can
be re-triggered from the screen's **⋮ menu**.

### Archive
A zip file produced by SpeleoLoc containing the database plus (optionally)
documentation files and raster-map images. Used for sharing data between
devices/teams. See [Database export, import and backup](features/database-export-import.md).

### Sync archive
A specialised archive used by the [sync dashboard](features/sync-and-change-log.md)
and [FTP sync](features/ftp-sync.md). Row-level, with timestamps, merged
on import using last-writer-wins (or manual conflict resolution).

### Change log
The append-only audit table that records every insert, update or
delete of a synced row, with timestamp and user. Powers diff/FTP sync
and the **Sync dashboard → Change log** tab.
See [Sync dashboard & change log](features/sync-and-change-log.md).

### User (current user)
A caver/operator identity tracked locally for audit/attribution. Not a
login. Selected in **Settings → Users**; stamped on every change and
change-log entry. See [Users](features/users.md).

### FTP profile
A saved FTP/FTPS/SFTP endpoint configuration used by automatic sync.
See [FTP sync](features/ftp-sync.md).

### Device UUID
A stable identifier assigned to this installation. Embedded in sync
archives so receivers can distinguish them. Preserved across imports
unless explicitly overridden.
