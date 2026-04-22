# Glossary

[← Back to index](README.md)

Terms used throughout SpeleoLoc and this wiki.

### Surface area
A named geographic region on the surface (e.g. a karst plateau or massif)
that can group several caves together. Optional.
See [Surface areas](features/surface-areas.md).

### Cave
The top-level entry representing an individual cave. Has a title, an
optional surface area, an optional entrance QR identifier, and contains
cave places, cave areas, raster maps and trips.
See [Caves and cave areas](features/caves-and-areas.md).

### Cave area
A named zone *inside* a cave (e.g. "Main gallery", "Lake room"). Used to
group cave places for filtering and display. Optional.

### Cave place
A single, named point of interest inside a cave — the **unit** SpeleoLoc
is built around. Has a title, optional description, depth in cave, optional
GPS coordinates, an optional QR code identifier, and may be flagged as an
**entrance** or **main entrance**.
See [Cave places](features/cave-places.md).

### QR code identifier
An integer printed on a physical QR label, placed at a cave place. Each
label encodes a `sp://<number>` deep link. Within one cave the identifier
should be unique; the app warns on duplicates.
See [QR codes](features/qr-codes.md).

### Deep link
A URI of the form `sp://<qr-code-identifier>`. Opening it (via the scanner
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
