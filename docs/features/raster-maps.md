# Raster maps

[← Back to index](../README.md)

A **raster map** is a picture of a cave survey — a scan, a photo of a
drawing, or an image exported from surveying software — that you attach
to a cave. SpeleoLoc never draws a map itself: you supply the picture,
then pin cave places onto it so that a QR scan or a beacon can later
show you where you are.

The labels used below are the English ones. The app starts in Romanian;
switch it in **Settings → General → App language**.

## Opening a cave's raster maps

1. Open the cave from the home screen.
2. Tap the **map icon** in the toolbar above the cave places list
   (tooltip *View raster maps*).

The **Raster maps** screen lists every map attached to that cave, in
the order you have arranged them. Each row shows a small square
thumbnail of the picture and the map's title — and nothing else; the
map type is not shown here, and raster maps are not tied to cave areas.

| Control | What it does |
|---|---|
| Tap the row | Opens the picture full screen, where you can pinch-zoom and pan to inspect the scan. No pins are drawn and nothing can be edited there. If the image file has gone missing, tapping the row opens **Edit raster map** instead, so you can pick the picture again. |
| Pencil | **Edit raster map** — change the title or the map type, or replace the picture. |
| Bin | **Delete raster map** — see [Deleting a map](#deleting-a-map). |
| **+** in the app bar | **Add raster map**. Unavailable while reorder mode is on. |
| Sort icon in the strip below the app bar | Switches the list into **Reorder maps** mode. |

The same screen is also reachable while you are working on a map: the
⋮ button on the map's side toolbar, and the screen menu, both offer
**Manage maps**.

> 📷 [A cave's raster maps](../screenshots/03-raster-maps.md#cave-raster-maps-list) — The Raster maps list for a cave, with per-map edit and delete actions.

## Adding a map

1. On the **Raster maps** screen, tap **+** (tooltip *Add raster map*).
2. Tap **Select image** and pick the map from your device's photos.
   The picker offers pictures only, so a PDF or a map file that is not
   in your photo library has to be saved as a picture first.
3. Type a **Title**. This is the name you will see on every map strip
   and tab, so it is worth filling in — if you leave it empty the app
   invents a name from its own copy of the file, something like
   `raster_1756713600000`.
4. Choose the **Map type** (see below). New maps start out as
   *plane view*.
5. Tap **Save**.

Leaving out either the picture or the type shows *Please select an
image and map type* and nothing is saved.

SpeleoLoc copies the picture into its own storage, so the map keeps
working after you move, rename or delete the original photo. The copy
keeps the resolution you picked — the app does not shrink it.

### Map types

| Type | Meaning |
|---|---|
| **plane view** | Top-down plan of the cave. |
| **projected profile** | Vertical section, projected onto one plane. |
| **extended profile** | Vertical section, unrolled along the passage. |
| **Other** | Anything else — a photo of a survey sketch, a cross-section, a rigging topo. |

The type is a label you pick for your own benefit. It is not shown
anywhere outside the add/edit form, it has no effect on where points
go, and the map list is neither ordered nor grouped by it. Its one
practical effect is that a cave cannot hold two maps that share both
the same title *and* the same type — which is exactly what lets you
keep a "Main system" plane view and a "Main system" extended profile
side by side.

### When the app pushes back

SpeleoLoc tries to stop you attaching the same map twice.

- If another map in this cave already has that title **and** that type,
  saving is refused with *A raster map with this title and type already
  exists for this cave*. Change the title or the type and try again.
- If the picture you picked is byte-for-byte identical to one already
  attached to this cave, a **Duplicate map image** dialog names the
  existing map and offers **Save anyway** or **Cancel** — so a
  deliberate second copy is still possible.

## Ordering and sorting the map list

### Manual order

Tap the sort icon in the strip above the list on the **Raster maps**
screen. The hint *Drag rows to reorder* appears, the pencil and bin are
replaced by a drag handle, and you can drag rows into any order you
like. Each drop is saved immediately. Tap the icon again (tooltip *Done
reordering*) to leave reorder mode.

This manual order is the order the maps appear in everywhere else —
the map strips, the map tabs on a cave place, the map viewer — as long
as map sorting is left on *Manual order*.

### Sort maps

Any map screen offers **Sort maps**, from the screen menu or from the
⋮ button on the map's side toolbar. Pick one field and a direction:

| Sort field | Orders by |
|---|---|
| **Manual order** | The order you set by dragging (the default). |
| **Number of places** | How many cave places are pinned on each map. |
| **Title (alphabetical)** | The map title. |
| **Map size** | The size of the picture file. |

Chosen on the read-only map viewer or on a trip's **Map view**, the
setting is remembered between sessions. Chosen on **Place positions on
map** it only reorders the strip for the current visit.

### Why the order matters

When you scan a place's QR code, or SpeleoLoc picks up its BLE beacon,
the app does not simply open the place's page: it walks the cave's maps
in this order and opens the **first** map that already has a point for
that place, centred on the pin. So the map you want to see underground
should be the first one that carries your points. If no map has a point
for that place you get the cave place page instead — after a QR scan
with the message *No map has a point defined for this cave place*.

## Placing cave places on a map

Pinning places is done on **Place positions on map**. You can get there
in three ways:

- from a cave place's **Raster maps** section — pick the map's tab and
  tap the pin button on the preview (tooltip *Define place on map*), or
  just tap the preview itself. This starts in *define new point* mode,
  ready for the place you were looking at;
- from the cave's screen menu, **⋮ → Place positions on map**, or the
  pin icon in the cave toolbar. This opens the cave's first map with
  the first place in the list selected, in *select existing place*
  mode;
- from a cave place row's pin counter — see
  [Checking which maps a place is on](#checking-which-maps-a-place-is-on).

If the cave has no maps yet you get *No raster maps for this cave*; if
it has no places, *No cave places in this cave*.

### The two strips above the image

- The **maps strip** is a row of map thumbnails. Tap one to switch the
  picture underneath without leaving the screen.
- The **cave places strip** is a row of round badges, each showing the
  first letter of a place's name. The colour tells you its state *on
  the map you are currently looking at*: grey means no point yet,
  reddish means already pinned. The current place is drawn larger, and
  turns blue once it has a point. Scanning the strip for grey badges is
  the quickest way to see how much of a cave is still unpinned.

Tapping a badge makes that place current, pans the map to its pin and
scrolls the strip. If the place has no point on this map there is
nothing to pan to — the place still becomes current, so you can drop
its point straight away.

Either strip can be hidden to give the height back to the picture: the
layers button on the side toolbar has tick boxes **Show maps list** and
**Show cave places list**. Anything that needs a hidden strip brings it
back on its own, so you cannot get stuck.

### Dropping a point

1. Select the place you want in the strip.
2. Make sure the tap mode button reads *Tap mode: Define new point*
   (tap it to switch; a label at the bottom-left of the image confirms
   the mode for a few seconds).
3. Tap the picture where the place actually is.

The point is written when you **move on** — to the next place, to
another map, or when you use the quick-add, legend, tap-mode, *Open
cave place* or *Documents* buttons. The first time this happens in an
app run, a dialog asks *Save the current point automatically when
switching to another place or map?*; answer **Yes** and it is not asked
again until you restart the app. Answering **Cancel** abandons both the
save and the switch. There is no separate save button, and backing out
of the screen straight after tapping does **not** store the point.

Two corrections are available while a place is selected:

- **Reset point to initial position** (undo arrow) — throws away the
  point you have just tapped and returns to where the place was
  before; it also drops back into *select existing place* mode so a
  stray follow-up tap cannot redefine it.
- **Remove point definition** (bin) — asks *Remove the point definition
  for this cave place on the current raster map?* and, on **Yes**,
  deletes the place's point on this map. The place itself and its
  points on other maps are untouched.

> 📷 [Defining a point on a raster map](../screenshots/03-raster-maps.md#raster-map-define-point) — Placing cave places on a scanned survey with the raster map point editor.

### Working through a whole cave

The first button on the map's side toolbar (a target) is *Next place
without location*. It jumps to the next place that has no point on this
map, wrapping round at the end, reveals the places strip and scrolls to
that place. Its tooltip counts what is left — *Next place without
location (7 remaining)* — and it greys out with *All cave places
already have a location defined* when you are done.

The magnifier next to it (also **Filter cave places** in the menu)
opens a search box above the strip. Typing narrows the strip to places
whose name, description, place code or cave area contains what you
typed. On the picture itself the non-matching places do not disappear:
they stay as faint dots without labels, so you keep your bearings.
Clear the box, or tap the magnifier again, to bring everything back.

**Sort cave places list** reorders the strip — by last modified, title,
cave area, depth, QR code identifier, entrance type, whether the place
has a QR code, or how many maps it is already pinned on, ascending or
descending. The choice is remembered; until you make one, the strip
follows the sorting you last used on the cave places list. Sorting by
cave area does something extra: the strip is split into small bordered
boxes, one per area with the area's name above it, so you can work
through one part of the cave at a time.

### Adding a new place from the map

The action bar has a pin-with-a-plus button, *Quick add cave place*.
Tap it and it turns green with the message *Tap on the map to define
the point for the new cave place*. Tap the picture and a short add-place
dialog opens; confirm it and the place is created **and** its point
stored at the spot you tapped, in one step. The mode stays armed, so
you can walk a passage adding place after place. Tap the green button
again to switch it off.

### Reaching the place itself

Once a place is selected, two more buttons appear at the end of the
action bar: **Open cave place**, which jumps to that place's full page,
and **Documents**, which opens the photos and files attached to it.
Both store a point you have just tapped before they navigate, so
nothing is lost. They are present on the read-only map viewer too,
which makes it a practical way to browse a cave: find the pin, read the
place, look at its photos, come back.

Press and hold any pin to get a brief message naming the place it
belongs to — handy in a crowded corner of a survey where the labels
overlap.

## Checking which maps a place is on

Every row in the cave places list carries a pin icon with a number: how
many of the cave's maps that place is pinned on. It is red at zero,
green when the place is on every map of the cave, grey in between.

Tap it and the **Raster maps definitions** dialog lists all the cave's
maps, each with a green tick or a red circle for this place. Tapping a
map in that list opens **Place positions on map** on that map, with
this place selected.

## Reading a scan underground

The image effects on the map's side toolbar make faint or dark scans
readable without ever changing the stored picture: **Invert colors**
has its own button, and the sliders button opens **Image processing**
with *Normal (no filter)*, *Invert colors*, *Grayscale*, *Sepia*,
*High contrast*, *Night red* and *Combine effects…*, the last opening a
panel where effects can be stacked and brightness and contrast dialled
in. Each map keeps its own last-used effect until you close the app.

**Full screen** hides the strips and the app bar so the picture gets
the whole display. While full screen is on, the phone's Back button or
back gesture exits full screen rather than leaving the screen; press it
again afterwards to leave.

Gestures, the zoom buttons in the bottom-right corner, the points
legend and the rest of the side toolbar are described in
[Map viewer and point editor](map-viewer.md).

> 📷 [A raster map in the full-screen viewer](../screenshots/03-raster-maps.md#raster-map-full-screen) — A cave raster map opened full screen for pinch-zoom inspection.

Very large scans (tens of megapixels) work, but they take longer to
open on a modest phone; down-sampling to the resolution you can
actually read is worth it before importing. Once opened, a picture is
kept decoded in memory, so switching back and forth between maps is
fast.

## When a picture goes missing

If a map's image file is gone — after restoring a database without the
pictures, for example — SpeleoLoc says so instead of showing a blank
screen. The thumbnail in the strips becomes a broken-image icon,
**Place positions on map** shows *Image not found*, and tapping the map
on the **Raster maps** screen takes you straight to **Edit raster map**,
where *Warning: Image file not found* tells you what happened, so you
can pick the picture again. Every point already placed on that map is
kept.

To avoid this when moving data between devices, tick **Include raster
map images** when exporting — see
[Database export and import](database-export-import.md).

## Deleting a map

Deleting a raster map is permanent and removes every cave place's point
definition on that map. The cave places themselves, and their points on
*other* maps, are unaffected.

You are always asked to confirm. If the map carries points, the
question tells you exactly how many will be lost; otherwise it is a
plain yes/no. The picture file itself stays in the app's storage, so
deleting a map does not free up space.

## See also

- [Map viewer and point editor](map-viewer.md)
- [Cave places](cave-places.md)
- [Caves and cave areas](caves-and-areas.md)
- [QR codes — placing, scanning, printing](qr-codes.md)
- [Documenting a new cave](../workflows/documenting-a-new-cave.md)
- [Navigating underground](../workflows/navigating-underground.md)
