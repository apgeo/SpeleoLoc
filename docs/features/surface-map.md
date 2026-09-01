# Cave map

[← Back to index](../README.md)

The cave map is a full-screen geographic map of every cave place that has
coordinates — it is where you look at entrances in the field, and where you
create caves, add entrances and fix a place's position without typing a
single number. Older notes call the same screen the *surface map*.

## Opening the map

- **Home screen → Cave map** (the toolbar button, or the same entry in the
  home menu). It shows the places of the caves currently in scope: the
  checked caves when the list is in selection mode, otherwise every cave
  left visible by the filter.
- **A cave's places list → Cave map**. This cave's places — the checked
  ones in selection mode, otherwise the filtered ones — are drawn
  highlighted among the places of all other caves.
- **A cave place → Pick coordinates on map**. The map opens as a
  coordinate picker and hands the position you confirm back to the form
  — see [below](#using-the-map-as-a-coordinate-picker).

### Where the map opens

The map frames what it was opened for, not where you left it last time:

- one place in scope — centred on it, zoomed in close;
- several places — all of them fitted on screen, never zoomed in further
  than a street-level view;
- the coordinate picker — on the place's existing position when it has
  one, otherwise on its cave's places.

Only when nothing at all can be framed does it fall back to the camera
position it remembers from your last visit, and if there is no such
memory either, it opens over central Romania at a wide zoom.

## What you see on the map

> 📷 [The cave map on a topographic base layer](../screenshots/02-cave-map.md#cave-map-topo-entrances) — The surface map showing cave entrances on a topographic base layer.

### Markers

| Marker | Meaning |
| --- | --- |
| Dark cave-arch waymark, larger | Main entrance |
| Cave-arch waymark, smaller | Other entrance |
| Small blue dot | A cave place that is not an entrance |
| Grey waymark or grey dot | A place belonging to a cave the map was not opened for |

Tapping a marker selects it: it is drawn highlighted, its label is forced
to stay visible, and an info card appears at the bottom of the screen.

### Labels

The sole entrance of a single-entrance cave is labelled with the cave
title alone — on a surface map the entrance *is* the cave. Every other
place is labelled `Cave title - Place title`.

Labels are dropped when they would collide, in a fixed order of
precedence: the place you last tapped always keeps its label, then
everything belonging to the caves or places the map was opened for, and
only inside each of those two groups does main entrance beat entrance
beats plain place. So on a crowded view the other caves' labels go first,
their main entrances included.

### Clusters

Zoom out far enough and nearby markers collapse into a numbered bubble —
blue when at least one of its members is one of the caves the map was
opened for, grey otherwise. Tap a bubble to zoom onto exactly its
members. Clustered markers carry no labels; labels come back as you zoom
in and the bubbles break apart.

### The place info card

Tapping a marker opens a card showing the place title, its cave with its
**Main entrance** / **Entrance** role, its coordinates, and its altitude
and depth in cave when those were recorded. Coordinates appear in
whichever format is chosen in **Settings → Map** (see
[GPS and coordinates](gps-and-coordinates.md)).

The card's three buttons are **Close**, **Open cave place** (the full
cave-place page — coordinates or titles changed there are picked up when
you come back) and **Set location** (re-position this place on the map).
No card appears at all while the map is being used as a coordinate
picker — the placement bar has the bottom of the screen to itself.

## The toolbar

A compact toolbar replaces the usual app bar at the top of the screen. It
scrolls sideways when the buttons do not all fit.

| Button | What it does |
| --- | --- |
| **Back** | Closes the map. |
| **My location** | Asks for location permission the first time, then shows your position as a blue dot with a translucent accuracy circle and keeps the map centred on it. Panning the map stops the following; tapping the button again also stops it. |
| **Map layers** | Opens the base layer / overlay picker. |
| **Show places from other caves** / **Hide places from other caves** | Shows or hides the greyed-out places of every cave the map was not opened for. |
| **Show non-entrance places** / **Hide non-entrance places** | Shows or hides places that are not entrances. |
| **All cave places** | Opens the list of every mapped place. |
| **Entrances** | Opens the same list, filtered to entrances. |
| **Measure distance** | Starts the measuring tool. Hidden while a point is being placed. |
| **Add point** | Opens the New cave / New entrance menu. Hidden while a point is being placed and in coordinate-picker mode. |

The two visibility toggles combine, so hiding both leaves only the
entrances of the caves you opened the map for.

If **My location** reports *Location services are off*, the app also
opens the system location settings for you. *Location permission denied*
is a warning on its own — your own settings page for the app is opened
only when permission has been refused for good. Either way no position is
shown until location is available.

### The place lists

The two list buttons open an inline panel over the map. Entries read
`Place title - Cave title`, sorted alphabetically, each with its marker
icon and an **Entrance** or **Main entrance** note underneath. Tap an
entry and the map flies to that place and selects it.

The lists are built from every place that has coordinates and ignore the
two visibility toggles, so a place you have hidden is still listed —
tapping it switches the toggle that was hiding it back on. When no place
has coordinates at all the panel shows *No cave places with coordinates*.

While a panel is open it covers the map and the bottom cards; tap the
same toolbar button again to close it.

## Measuring a distance

> 📷 [Measuring a distance on the map](../screenshots/02-cave-map.md#cave-map-measure-distance) — Measure mode: a multi-leg path on the map with its total distance and bearing.

1. Tap **Measure distance**.
2. Tap the map to add points to the path. Tapping a **marker** instead
   snaps the point exactly onto that place, so distances between recorded
   points are exact rather than eyeballed.
3. The bar at the bottom shows **Total** for the whole path and **Last
   leg** with its length and its bearing in degrees.
4. **Remove last point** undoes one tap; **Close** ends measuring.

Distances read in metres below one kilometre and in kilometres above it.
The path is temporary — it is not saved, and it is discarded when you
close measuring or start placing a point.

## Adding and moving points

> 📷 [Adding a cave or an entrance from the map](../screenshots/02-cave-map.md#cave-map-add-point-menu) — The Add point menu offering New cave or New entrance at the chosen spot.

Every "create" and "set location" action on the map runs through the same
placement flow: you position a red pin, then confirm.

### Placing the point

Start a placement by tapping **Add point**, by long-pressing the map at
the spot you want (this opens the same menu with the point already
there), or from a place's info card with **Set location**.

Once the placement bar is showing at the bottom, the point can be set
three ways:

- **tap** the map;
- **drag** the red pin — it moves under your finger without panning the
  map, which is the finer adjustment;
- **Use my location**, which is *not* a single reading. It starts an
  averaged capture: the pin jumps to your position and then keeps moving
  to the running average of every fix that arrives, so the longer you
  stand still the tighter the position becomes. While the capture runs
  the button reads **Stop averaging**, and the bar shows a live readout —
  *Samples* so far and the best *Accuracy* reached, with a bar and a word
  (Excellent, Good, Fair, Poor, Very poor) rating it; before the first
  fix arrives it reads *Waiting for GPS fix…*. Tap **Stop averaging** to
  stop and keep the averaged point; tapping the map or dragging the pin
  also stops it and hands control back to you, and confirming freezes
  whatever the average had reached. The readout stays on the bar after
  you stop, so you can check the sample count before you confirm.

Long-press only *starts* a placement. Once the placement bar is up it
does nothing, and it is switched off entirely while measuring and in
coordinate-picker mode.

Tapping another marker while placing simply identifies it — the card is
not shown, but the place is highlighted and labelled, and your pending
point stays where it is. That makes it easy to place a new entrance a
known distance from an existing one.

**Cancel** abandons the placement. **Confirm** is only enabled once a
point exists.

### New cave

> 📷 [Placing the point for a new cave](../screenshots/02-cave-map.md#cave-map-new-cave-placement) — Placing the entrance point for a new cave on the surface map.

1. **Add point → New cave** ("Create a cave with an entrance at this
   point").
2. Position the point and press **Confirm**. The names are asked for
   *after* confirming, deliberately — you can walk around and refine the
   position before committing to anything.
3. Fill in **Cave title** (required) and **Entrance name** (pre-filled
   with *Entrance*) and press **Add**.

The cave is created together with an entrance place at the point, and
that entrance becomes the cave's main entrance. The map confirms with
*Cave added*, selects the new entrance and keeps it in scope so it is not
greyed out.

### New entrance

1. **Add point → New entrance** ("Add an entrance to an existing cave at
   this point").
2. Position the point and press **Confirm**.
3. A **Choose a cave** sheet slides up with the search box already
   focused — type a few letters of the cave title instead of scrolling.
4. Name the entrance (pre-filled with *Entrance*) and press **OK**.

The new place is flagged as an entrance, and as the *main* entrance when
the cave did not have one yet. The map confirms with *Entrance added*.

If the cave already has a place with the name you typed, the app neither
refuses nor overwrites it: it silently adds a number, so a cave you add
three entrances to from the map ends up with *Entrance*, *Entrance 2* and
*Entrance 3*. Type meaningful names as you go if you want to recognise
them later in lists and on labels.

If there are no caves in the database at all, the app says *There are no
caves yet — add a cave first* and leaves your point in place; use **New
cave** instead, which creates the cave and its entrance in one step.

Backing out of any of these prompts cancels the creation but leaves the
point on the map, so you can press **Confirm** again without re-placing
it.

### Moving an existing place

Tap the place's marker, then **Set location** on its info card. The pin
starts at the place's current position; move it and press **Confirm**.
The map reports *Location updated*.

Only latitude and longitude are written. A place moved this way **keeps
whatever altitude it already had**, recorded at its old position — clear
or correct it on the cave-place form if that matters.

### Altitude is not recorded here

Caves and entrances created from the map are stored with no altitude —
even when you positioned the point with an averaged GPS capture that had
a perfectly good altitude reading; moving an existing place leaves the
altitude it already had untouched. If you need the altitude, open the
place afterwards and use **Record GPS point** on the cave-place form,
which captures and fills it. See
[GPS and coordinates](gps-and-coordinates.md).

### Using the map as a coordinate picker

From a cave place, **Pick coordinates on map** opens the map already in
placement mode for that place. Measuring, **Add point** and long-press
are all switched off, and tapping a marker only highlights it instead of
opening its info card — the screen exists only to return one position.

**Confirm** closes the map and fills the latitude and longitude fields on
the form; nothing is stored until you save the place. **Cancel** closes
the map and leaves the form untouched.

## Base layers and overlays

The **Map layers** button opens a panel with a **Base layer** list (pick
one) and an **Overlays** list (tick any number).

Base layers are ten public online sources — OpenTopoMap (the default,
contours and terrain shading suit field work best), OpenStreetMap, Google
Streets, Google Satellite, Google Hybrid, Esri World Imagery, Esri World
Topo, Carto Positron, CyclOSM and OSM Humanitarian — plus any offline
`.mbtiles` file you have given the **Base map** role. Files given the
**Overlay** role appear in the second list and draw on top of the base
layer; when you have none, the panel says *No MBTiles files found*.

Your base layer and your enabled overlays are remembered between
sessions.

A small credit line in the bottom-left corner always names the layer
actually being drawn. It is worth a glance: if an offline base map turns
out to be unreadable, the map quietly falls back to the online source
instead of showing an error, and that line is the only place the switch
is visible.

### Gestures

Pan with one finger, zoom by pinching or double-tapping. There are no
on-screen zoom buttons, and **rotation is disabled on purpose** — north
is always up, and a two-finger twist does nothing rather than leaving the
map askew. Zooming in past a layer's own maximum keeps working: the last
available tiles are scaled up rather than going blank.

## Using the map offline

Two independent mechanisms:

- **Cached online tiles.** Every online tile you have looked at is kept
  on the device: for its first week it renders without any network
  request, and after that an older copy is still served whenever the
  network fails — so an area you browsed at home keeps rendering
  underground or out of signal. It only covers areas and zoom levels you
  actually viewed.
- **MBTiles files.** A raster `.mbtiles` file gives you real, deliberate
  offline coverage of a whole region at every zoom it contains. See
  [Using offline MBTiles layers](../workflows/mbtiles-layers.md) for how
  to produce and install one.

## Settings → Map

| Row | What it does |
| --- | --- |
| **Coordinate display format** | Decimal degrees, Degrees, minutes, seconds (DMS), or UTM. Changes how coordinates are *displayed* everywhere — the map's info card, the placement bar, the cave-place form. Nothing is converted in the database, and typing coordinates always accepts any of the three formats. |
| **Cache online map tiles** | Keeps downloaded base-map tiles on the device so visited areas work offline. On by default. |
| **Tile cache** | Shows how much space the cached tiles currently take, with a bin icon that clears them (*Tile cache cleared*). Clearing is safe: the tiles are re-fetched next time you visit the area with a connection, and your MBTiles files are never touched. |
| **Auto-load MBTiles** | Master switch for scanning the app's MBTiles folder and offering the files as layers. |
| **MBTiles folder** | The exact folder the files are read from, with a **Copy path** button — the path differs per platform and device. |
| **Import MBTiles file** | Browses for a `.mbtiles` file with the system file picker and copies it into the folder. This is the supported way to add files on a phone. A name clash asks *File already exists* before overwriting. |
| **Detected files** | Every `.mbtiles` file found, each with a **Base map** / **Overlay** role. Roles are remembered per file name, so replacing a file with a newer export keeps its role. Vector files are listed but marked *vector MBTiles not supported*. |

The app bar of that page also carries an import button and **Rescan
folder**, for when you copied a file in from outside the app.

## See also

- [Cave places](cave-places.md)
- [GPS and coordinates](gps-and-coordinates.md)
- [Using offline MBTiles layers](../workflows/mbtiles-layers.md)
- [Documenting a new cave](../workflows/documenting-a-new-cave.md)
- [Settings](settings.md)
