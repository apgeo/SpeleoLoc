# GPX/KML place transfer

[← Back to index](../README.md)

SpeleoLoc can hand its cave places to other mapping tools as a GPX or KML
file, and read waypoints from such a file back in as places of a cave.
Both directions live in the home screen's **⋮** menu.

Control names on this page are the English ones. The app starts in
Romanian; English is chosen in **Settings → General → App language**.

## Where it lives

Open the home screen, tap **⋮**, and the two entries sit at the bottom of
the home part of the menu:

- **Export places (GPX/KML)** — writes the places in scope to a file;
- **Import places (GPX/KML)** — reads a file into one cave.

These entries are the only way to reach GPX/KML transfer: there are no
toolbar buttons for it, and a cave's own places list does not offer it.
The **Import places from CSV** you find inside a cave is a different
feature — see [CSV import](csv-import.md).

## What travels in the file

Four things per point, and nothing else:

| In SpeleoLoc | In the file |
|---|---|
| Place **Title** | the waypoint or placemark name |
| **Latitude**, **Longitude** | the point's position |
| **Altitude** | the point's elevation, in metres |
| **Description** | the waypoint description |

Place codes and QR payloads, the entrance flag, beacons, documents,
photos, trips and everything else stay behind. A place that has gone out
to a GPX file and come back is a plain located place again — which is why
transfer is for exchanging positions with other software, not for backing
up or moving your data. For that, use an archive; see
[Database export, import and backup](database-export-import.md).

## Export places (GPX/KML)

### What ends up in the file

Two rules decide it:

- **Only places that have coordinates.** A place with no position is left
  out, silently.
- **Scope follows the home list**, the same rule as **Cave map** and
  **Generate QR codes for caves**: with selection mode on, only the ticked
  caves; otherwise every cave still visible after the current filter.

An empty scope means *nothing*, never *everything*. If selection mode is
on and you have ticked no cave, or the filter matches nothing, or no place
in scope has coordinates, the export stops there with **No places with
coordinates to export** — no format sheet, no save dialog.

### Doing it

1. On the home screen, narrow the cave list with the filter box, or turn
   on selection mode and tick the caves you want. Leave both alone to
   export everything.
2. **⋮ → Export places (GPX/KML)**.
3. Choose the format in the sheet that opens:
   - **GPX** — *Waypoints for Garmin, Locus, QGIS*
   - **KML** — *Placemarks for Google Earth*
4. The system save dialog opens with the file name `speleoloc_places.gpx`
   or `speleoloc_places.kml` already filled in. Rename it or pick another
   folder, then save.
5. The app confirms with **Files saved** followed by the number of
   waypoints written. Compare that number with what you expected — the
   gap, if any, is the places that carry no coordinates.

### How the waypoints are named

Every waypoint is named `<place title> - <cave title>`, for example
`Entrance - Peștera Mare`. Bare place titles such as "Entrance" or "P1"
repeat across caves and would be useless in a tool that knows nothing
about caves; the cave name makes each point identifiable, and it is also
what lets SpeleoLoc recognise its own file on the way back in.

One file can hold the places of many caves. There is no grouping inside
it — the cave name in each waypoint title is the only marker of which
cave a point came from.

Positions are written to seven decimal places and elevations to a tenth
of a metre, far finer than any phone GPS, so the file loses nothing of
what the app holds.

## Import places (GPX/KML)

### Doing it

1. **⋮ → Import places (GPX/KML)** on the home screen.
2. Pick the file. The picker offers **all** file types, not just GPX and
   KML — Android's file picker often does not know those types — so pick
   carefully. The format is then recognised from the content of the file,
   so a wrong or missing extension does not matter.
3. Choose the cave that receives the points in the **Choose a cave**
   sheet; its **Search** box narrows a long list. Everything in the file
   goes into this one cave.
4. The import runs and reports **Imported N places (M duplicates
   skipped)**.

If something is wrong you get one of these instead, and nothing is
created:

| Message | What it means |
|---|---|
| *The file is not a readable GPX or KML document* | The file is neither format, or cannot be read as text at all — a zipped KMZ, a spreadsheet, a truncated download |
| *No waypoints found in the file* | The file was read, but held no usable point |
| *There are no caves yet — add a cave first* | Import always needs a cave to put the points in; create one first |

### What each waypoint becomes

Each accepted waypoint is created as a **non-entrance place** of the
chosen cave, carrying:

- **Title** — the waypoint name;
- **Latitude** and **Longitude** — the waypoint position;
- **Altitude** — the elevation, when the file has one;
- **Description** — the waypoint description. For GPX, the comment field
  is used when there is no description.

Imported places arrive with no place code and no QR payload, and with the
entrance flag off. Open the cave afterwards to mark whichever ones really
are entrances, and use **Generate codes** if you want them numbered — see
[Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md).
They show on the [cave map](surface-map.md) straight away, as long as
**Show non-entrance places** is switched on there.

Every imported place is recorded in the change log under the current
user, and travels on the next sync like any other change. See
[Manual sync and the change log](sync-and-change-log.md).

### Duplicates, and re-importing your own export

Before names are compared, a trailing ` - <cave title>` belonging to the
cave you are importing *into* is trimmed off — exactly the decoration the
export adds. That is what makes the round trip safe: export a cave, open
the file in another tool, import it back into the same cave, and the
points you already had are recognised instead of being duplicated.

A waypoint is skipped when its name, after that trimming and ignoring
upper and lower case, already belongs to a place of the cave, or has
already been used by an earlier waypoint in the same file. Two things
follow from this:

- **Skipping is never updating.** An existing place keeps its
  coordinates, altitude and description whatever the file says. GPX/KML
  import can add places to a cave; it can never correct them. To move a
  place, edit it in the app.
- **Import an export into a *different* cave and the decoration stays**,
  because only the receiving cave's own title is trimmed. The places are
  created, but named `Entrance - Peștera Mare` and so on; rename them by
  hand, or import the file into the cave it came from.

A waypoint with no name at all becomes *Waypoint 1*, *Waypoint 2*, …,
numbering the unnamed ones in the order they appear. If a place with that
name already exists in the cave, that waypoint counts as a duplicate and
is skipped.

The import is all-or-nothing. If it fails part-way through the list,
nothing at all is created — you never have to clean up half an import
before trying again.

### What import quietly leaves out

Import is forgiving but selective, and it does not report what it left
behind, so the number it announces can be lower than the number of points
you saw in the other tool:

- A point whose position is missing, unreadable, or impossible (latitude
  beyond ±90, longitude beyond ±180) is dropped without a word.
- Lines, polygons, tracks and routes are ignored — only single points
  come across.
- From a placemark with a whole string of coordinates, only the first
  point is read.
- Styles, icons, colours, timestamps, folders and any tool-specific
  extras are ignored.

Files written by other software are read whatever internal naming they
use, so exports from Garmin BaseCamp, Locus, QGIS, Google Earth and
similar tools all come in.

## Tips

- Do the narrowing before you export: filter or tick on the home screen,
  because there is no place-by-place choice later in the flow.
- Check the reported counts. **Files saved: 40** against 52 places means
  twelve of them have no coordinates; **Imported 3 places (37 duplicates
  skipped)** on a re-import means the round trip worked and only three
  points are new.
- Keep the exported file next to your survey data. It is plain text and a
  useful record of where everything is, but it holds positions only — it
  is not a backup.

## See also

- [Home screen](home-screen.md)
- [Cave places](cave-places.md)
- [GPS and coordinates](gps-and-coordinates.md)
- [Cave map](surface-map.md)
- [CSV import](csv-import.md)
- [Database export, import and backup](database-export-import.md)
