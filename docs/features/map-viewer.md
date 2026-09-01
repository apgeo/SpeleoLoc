# Map viewer and point editor

[← Back to index](../README.md)

This page describes the screens that show a [raster map](raster-maps.md)
with cave-place pins on it — how you move around the image, what the pins
mean, and how you give a cave place its position on a map.

> Control names below are the English ones. The app starts in Romanian;
> switch with **Settings → General → App language**.

## The four places a map appears

| Screen | What you can do |
|---|---|
| **View raster maps** (the map viewer) | Look only. Pan, zoom, tap pins, jump to a place's page or its documents. |
| **Place positions on map** | Everything the viewer does, plus placing, moving and removing points. |
| The **Raster maps** section of a cave place | A still preview of each map. Tapping it opens *Place positions on map*. |
| A trip's **Map view** | Look only, with the trip's route drawn over the map. |

### How you get to each of them

- **Scan a place's QR code, or walk into range of its BLE beacon** —
  SpeleoLoc opens the map viewer on the first map (in your map order,
  see [Sorting the maps](#sorting-the-maps)) that already has a point for
  that place, zoomed out slightly and centred on the pin. If no map has a
  point for it you get the cave place's own page instead — after a QR scan,
  with the message *No map has a point defined for this cave place*.
- **From a cave's places list** — the pin button in the toolbar,
  *Place positions on map*, opens the first map with the first place
  selected. Each row in that list also carries a place-pin icon with a
  number; tapping it lists the cave's maps as *Raster maps definitions*
  with a tick beside the ones that already hold a point for that place,
  and picking one opens it for editing.
- **From a cave place** — scroll to the **Raster maps** section, described
  under [Giving a place a position](#giving-a-place-a-position).
- **From a trip** — the **Map view** button in the trip's toolbar.

> 📷 [The raster map place selector](../screenshots/03-raster-maps.md#raster-map-place-selector) — Placing cave places on a raster map with the map and place navigation bars.

## Moving around the map

- **Pinch** — zoom in and out. The point under your fingers stays put.
- **Drag** — pan.
- **Zoom buttons**, bottom right of the image — **−**, a reset button that
  brings the whole map back into view, and **+**.
- **Tap a pin** — makes that cave place the current one: the pin flashes,
  the map moves onto it without changing your zoom, and the places strip
  scrolls to it. It does *not* open the place; use the **Open cave place**
  button for that.
- **Press and hold a pin** — a short message names the cave place it
  belongs to. Useful in a crowded corner where the labels overlap.
- **Tap the image itself** — nothing happens on a view-only map. On
  *Place positions on map* it either drops a new point or picks the
  nearest pin, depending on the tap mode below.

Moving from one place to another keeps your current zoom and simply pans to
the new pin, so you can work across a survey at a steady scale.

There is no double-tap zoom and no mouse-wheel zoom — pinch and the zoom
buttons are the only ways to change the scale.

## The strips above the map

Two horizontal strips sit between the app bar and the image:

- the **maps** strip — one thumbnail and title per raster map of this cave,
  in your chosen map order;
- the **cave places** strip — a round badge with the first letter of each
  place's name, and the name underneath.

The badge colour tells you the place's state **on the map you are looking
at**:

| Badge | Meaning |
|---|---|
| Grey | No point on this map yet |
| Red | Already has a point on this map |
| Blue, and larger | The place you are working on |

Scanning the strip for grey badges is the quickest way to see how much of a
cave is still unpinned.

### Showing, hiding and shrinking the strips

- **Nav bar views** (the layers button on the side toolbar) opens a menu
  with two tick boxes, **Show maps list** and **Show cave places list**.
  Turning either off gives its height back to the map. Anything that needs
  a hidden strip brings it back on its own — filtering or sorting places
  reveals the places strip, sorting or managing maps reveals the maps
  strip — so you cannot get stuck.
- **Toggle compact navigation**, in the app bar, shrinks *both* strips to
  smaller thumbnails and smaller captions (the titles stay, just smaller).
  This one setting is shared by every map screen and is remembered between
  sessions. The trip map is always compact and has no toggle.

### Filtering the places strip

The magnifier on the side toolbar — also **Filter cave places** in the
screen's ⋮ menu — opens a small search box above the places strip. What you
type is matched against each place's name, description, place code and cave
area. The strip narrows to the matches; on the map itself the places that
do not match stay visible as faint dots without labels, so you keep your
bearings. Clear the box, or tap the magnifier again, to bring everything
back.

### Sorting the maps

**Sort maps** (side toolbar ⋮, or the screen's ⋮ menu) offers **Manual
order**, **Number of places**, **Title (alphabetical)** or **Map size**,
**Ascending** or **Descending**. *Manual order* is the order you set by
dragging rows on the cave's [Raster maps](raster-maps.md) screen.

The choice is remembered between sessions when you make it from the map
viewer or the trip map. It matters beyond tidiness: when you scan a QR code
or a beacon is detected, SpeleoLoc opens the **first map in this order**
that already has a point for that place.

### Sorting the places strip

**Sort cave places list** reorders the badges. The fields are **Last
modified**, **Title (alphabetical)**, **Cave area**, **Depth**, **QR code
identifier**, **Entrance type**, **Has QR code** and **Maps with
location**, ascending or descending. The choice is remembered; if you have
never set one it follows the sorting you last used on the cave places list.

Sorting by **Cave area** does something extra on *Place positions on map*:
the strip is split into small bordered boxes, one per area, with the area's
name above each, so you can work through one part of the cave at a time.

## The side toolbar

Every map screen starts with just a small **chevron** in the top-left
corner of the image. Tap it to slide out a vertical, semi-transparent
toolbar; tap it again to put it away. Your choice carries over to every map
screen until you close the app.

The toolbar is the same on the map viewer, *Place positions on map* and the
trip map:

| Button | What it does |
|---|---|
| **Next place without location** (target) | Jumps to the next cave place with no point on this map, wrapping round at the end, and scrolls the places strip to it. Its tooltip counts what is left — *Next place without location (7 remaining)*. It greys out with *All cave places already have a location defined* when you are done. |
| **Filter cave places** (magnifier) | Opens or closes the search box above the places strip. |
| **Nav bar views** (layers) | Show / hide the maps strip and the places strip. |
| **More actions** (⋮) | Filter cave places, Sort cave places list, Sort maps, Manage maps. |
| **Full screen** | See [Full screen and landscape](#full-screen-and-landscape). |
| **Invert colors** | One-tap inversion, for a dark scan. Tap again (*Restore colors*) to undo. |
| **Image processing** (sliders) | The effects menu, see [Making a faint scan readable](#making-a-faint-scan-readable). |

**Manage maps** leaves the map and opens the cave's
[Raster maps](raster-maps.md) screen, where maps are added, edited,
reordered and deleted.

## The action bar under the map

| Button | Where | What it does |
|---|---|---|
| **Toggle legend** (ⓘ) | Everywhere | Shows or hides the legend in the bottom-left corner. |
| **Tap mode** | *Place positions on map* only | Switches between dropping new points and selecting existing ones. |
| **Reset point to initial position** (↶) | *Place positions on map* only | Undoes a point you have tapped but not yet stored. |
| **Remove point definition** (red bin) | *Place positions on map* only | Deletes this place's point on this map. |
| **Quick add cave place** | *Place positions on map* only | Creates a new cave place at the spot you tap. |
| **Open cave place** | Everywhere, once a place is selected | Opens that place's full page. |
| **Documents** | Everywhere, once a place is selected | Opens the photos and files attached to that place. |

On the view-only screens — the map viewer and the trip map — the four
editing buttons are simply not there, leaving the legend toggle and the two
shortcuts. **Open cave place** and **Documents** store any point you have
just tapped before they navigate, so you cannot lose a placement by using
them. Together they make the map viewer a practical way to browse a cave:
find the pin, read the place, look at its photos, come back.

## The legend

| Marker | Meaning |
|---|---|
| Solid blue dot | **Current** — the place you are working on, as it is stored |
| Blue disc with an orange centre | **New** — the point you have just tapped, not stored yet |
| Hollow blue ring | **Original** — where the point was before you moved it |
| Solid red dot | **Existing** — every other cave place that has a point on this map |

Every pin carries the place's name beside it, except pins faded out by the
filter.

## Tap modes

Only **Place positions on map** has a tap-mode toggle, and only when it was
opened for editing. The button sits in the action bar and shows which mode
you are in:

- **Tap mode: Define new point** (a pin icon, blue) — tapping the image
  drops a point where you tapped.
- **Tap mode: Select existing place** (a hand icon, orange) — tapping picks
  the nearest pin, provided you tap within roughly a fingertip of it.
  Tapping empty map does nothing.

Which mode the screen starts in depends on how you opened it: from a cave
place it starts in *define* mode, from the cave places list in *select*
mode.

When you switch modes a small caption appears in the bottom-left corner —
*Click on the map to define a new point or change the interaction mode* /
*Click on another point to select it* — and fades away after a few seconds.
The button's own icon and colour always show the current mode.

> 📷 [Defining a point on a raster map](../screenshots/03-raster-maps.md#raster-map-define-point) — Placing cave places on a scanned survey with the raster map point editor.

## Giving a place a position

1. Open the cave place and scroll to the **Raster maps** section.
2. Choose a map from the tabs across the top; the **◀ ▶** arrows reach maps
   further along. Each tab shows a still preview of that map.
3. Tap the preview, or the pin button (**Define place on map**) in its
   top-left corner. **Place positions on map** opens.
4. Check that the tap mode reads **Tap mode: Define new point**.
5. Tap the map where the place physically is. A blue disc with an orange
   centre appears there, and the previous position, if any, stays visible
   as a hollow blue ring.
6. The point is stored when you leave the screen, or as soon as you switch
   to another place or map — see [Storing points](#storing-points). Once
   stored it is drawn like every other placed point: red on maps where it
   is not the current place, blue while it is.

To work through a whole cave, stay on this screen and use **Next place
without location** on the side toolbar after each point: it walks you
through every place that is still unpinned on this map.

### Undoing a point you have just tapped

Tap **Reset point to initial position** (the ↶ button). It is greyed out
until you have actually tapped a new point, and using it also flips the tap
mode back to *select existing place*, so a stray tap cannot move the point
again.

### Removing a placement

Tap the red bin, **Remove point definition**, and confirm *Remove the point
definition for this cave place on the current raster map?*

This deletes the point **only on the map you are looking at**. The cave
place itself and its points on other maps are untouched. There is no undo —
to get the point back you have to place it again.

## Storing points

There is no save button. A point you have tapped is written:

- when you leave the screen, and
- as soon as you switch to another cave place or another map.

The first time in each session that you switch while holding an unstored
point, SpeleoLoc asks:

> *Save the current point automatically when switching to another place or
> map?*

**Yes** stores it and stops asking until you restart the app. **Cancel**
abandons the switch and leaves your pending point exactly where it is. A
brief confirmation names the place each time a point is stored this way.

## Quick add cave place

On **Place positions on map**, the pin-with-a-plus button lets you create a
place and pin it in one go.

1. Tap **Quick add cave place**. The button turns green and the message
   *Tap on the map to define the point for the new cave place* appears.
2. Tap the map where the new place is.
3. Fill in the short add-place dialog and confirm. The place is created and
   its point is stored at the spot you tapped.

The mode stays armed afterwards, so you can walk along a passage adding
place after place without going back to the button. Tap the green button
again to turn it off.

## Full screen and landscape

The **Full screen** button on the side toolbar hides the app bar to give
the image the maximum area; on *Place positions on map* it hides both
strips as well. The action bar stays. Tap the button again (now *Exit full
screen*) to return.

While full screen is on, the phone's Back button or back gesture exits full
screen instead of leaving the screen, so you cannot lose your place by
swiping back. Press it again once the normal layout is showing to leave the
map.

Turning a phone to **landscape** puts the map into full screen by itself,
and the action bar moves from under the image to a vertical strip on its
right-hand edge. Turning back to portrait restores the normal layout —
unless you had switched full screen on yourself, in which case it stays on
until you switch it off.

Strip visibility changes you make while in full screen are kept when you
leave it.

> 📷 [A raster map in the full-screen viewer](../screenshots/03-raster-maps.md#raster-map-full-screen) — A cave raster map opened full screen for pinch-zoom inspection.

## Making a faint scan readable

The **Image processing** button on the side toolbar applies display effects
to the map image. They are purely visual: the stored image file and the
points on it are never touched.

| Choice | Effect |
|---|---|
| **Normal (no filter)** | The image as it is. |
| **Invert colors** | Dark map becomes light. Also the standalone toolbar button. |
| **Grayscale** | Drops the colour. |
| **Sepia** | Warm tone. |
| **High contrast** | Pushes the contrast up — good for faint pencil lines. |
| **Night red** | Leaves a red tint, friendly to dark-adapted eyes. |
| **Combine effects…** | Opens the panel below. |

**Combine image effects** is a sheet with a tick box for each of the five
effects — they stack — plus a **Brightness** slider (−1.00 to +1.00) and a
**Contrast** slider (0.20 to 3.00). **Reset** clears everything, **Cancel**
discards your changes and **Apply** puts them on the map.

The chosen effect is remembered per raster map for as long as the app is
running, and is forgotten when you close it.

## The trip map

A trip with at least one raster map available gets a **Map view** button in
its toolbar (**List view** switches back). The trip's route is drawn over
the map as numbered markers joined by blue arrowed lines, in the order the
places were visited. Three more buttons appear while the map is showing:

- **Play route** — animates the route from the first visited place to the
  last, roughly a step per second, drawing the markers and lines as it
  goes. The button turns into a red stop button while it runs.
- **Fit trip** — zooms so that all the places visited on the trip fit on
  screen.
- **Export map** — saves what you see, route included, as a PNG in the
  app's own storage; the message that follows gives the file name. It is a
  standalone picture. Exporting a **trip report** is a separate action and
  does not pick this image up — see [Trip reports](trip-reports.md).

The trip map is view-only: points cannot be moved or added from it.

## When something is missing

- **A place with no point on this map.** Picking it from the strip on the
  map viewer shows *No defined point for this place on the selected map*.
  It still becomes the current place, so on *Place positions on map* you can
  tap the map straight away to give it one; on the map viewer, try another
  map from the strip.
- **A map whose image file has gone**, for example after restoring a
  database without the pictures. Its thumbnail in the strip becomes a
  broken-image icon and *Place positions on map* shows *Image not found*.
  Every point already placed on that map is kept — go to the cave's
  [Raster maps](raster-maps.md) screen and point the map at its image
  again.

## See also

- [Raster maps](raster-maps.md) — adding, editing, reordering and deleting
  a cave's maps
- [Cave places](cave-places.md)
- [QR codes — placing, scanning, printing](qr-codes.md)
- [BLE beacons](ble-beacons.md)
- [Trips — recording your route](trips.md)
- [Navigating underground](../workflows/navigating-underground.md)
