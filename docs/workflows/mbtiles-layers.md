# Using offline MBTiles layers on the surface map

[← Back to index](../README.md)

How to put your own offline map onto the surface map — a scanned topo
sheet, or an area exported from MOBAC, QGIS or SAS Planet — so the map
still draws underground, in a valley with no signal, or abroad with data
switched off.

Control names below are the English ones, chosen in
**Settings → General → App language**; the app starts in Romanian.

## Before you start

Only **raster** `.mbtiles` files work (PNG, JPEG or WebP tiles). A
**vector** (`pbf`) file is not refused on import, but it cannot be
drawn: it ends up listed with a red icon and the note *vector MBTiles
not supported*, with no role to choose and no entry in the map's layer
picker. When you export from MOBAC, QGIS or SAS Planet, pick the
raster/tiled-image output.

Size matters more than you would like: there is no way to delete a file
from inside the app once it is imported (see *Replacing and removing
files* below), so cut the export down to the area you actually walk
before you copy it over.

## Add an MBTiles file

1. **Produce a raster `.mbtiles` file** on a computer, covering the area
   you need and only the zoom levels you need.

2. **Import it from inside the app.** Open **Settings → Map** and tap
   **Import MBTiles file** (the row, or the upload button in the app
   bar), then browse to the file. It is checked and copied into the app's
   own folder for you.

   The picker deliberately offers *every* file type, because Android's
   file picker does not recognise `.mbtiles` — so choose carefully. A
   file whose name does not end in `.mbtiles` is refused with *Please
   choose a .mbtiles file*, and a file that is not a readable MBTiles
   database is refused with *That file is not a readable MBTiles
   database*; neither one lands in the folder. If a file of that name is
   already there, **File already exists** asks before overwriting. On
   success you get *Imported <name>* — or, for a vector file, *Imported
   <name>, but vector MBTiles are not supported on the map*.

   This route needs no storage permission and works on debug or
   sideloaded installs, where the app's folder is not reachable by a file
   manager at all. On a phone it is the only practical route.

3. **Or copy the file in yourself** (file manager, USB cable, `adb
   push`). **Settings → Map → MBTiles folder** shows the exact path, with
   a **Copy path** button next to it — it differs per platform and
   device. On Android and iOS that folder is app-private storage, usually
   reachable only with adb or on a rooted device.

4. **Check it in the list and give it a role.** Files appear under
   **Detected files**, each showing its name, then the file name, the
   tile format and the zoom range stored in the file (for example
   *z8–16*).

   - After an in-app import the list has already refreshed itself.
   - After a manual copy, tap **Rescan folder** (the refresh button in
     the app bar) or leave and reopen the page.

   Then set the file's role with the dropdown on its row — **Overlay** or
   **Base map**, described in the next section. New files start as
   **Overlay**.

5. **Turn it on from the map.** Open the surface map, tap **Map layers**
   in the top toolbar, and your file is there: **Base map** files as
   extra entries in the **Base layer** list, **Overlay** files as
   checkboxes under **Overlays**. Tap or tick it and the panel updates
   the map immediately. The choice is remembered, so the map comes back
   with the same layers next time.

   Each file is listed under the name stored *inside* it, with the file
   name underneath — MOBAC and QGIS exports routinely carry an internal
   name that has nothing to do with the file name, so read the second
   line if you cannot find your file.

## Base map or overlay

| Role | What it does |
|---|---|
| **Overlay** | Drawn on top of whichever base layer is selected, as a tick box under **Overlays**. The default, and the right choice for a small local or cave-area map: outside its coverage the base layer below simply shows through. |
| **Base map** | Selectable in the **Base layer** list instead of the online sources. The whole map is that file, so outside its coverage you get blank tiles — right for a full offline sheet, wrong for a small patch. |

Several overlays can be on at once. They stack in alphabetical order of
the name shown in the picker, and nothing is drawn semi-transparent, so
an opaque overlay hides whatever sits under it — including another
overlay whose name sorts earlier.

## Replacing and removing files

- **There is no delete.** A file's row offers only the Base map /
  Overlay dropdown; nothing in the app removes an imported file, and on
  Android and iOS the folder is app-private, so a file manager cannot
  reach it either. Getting a 2 GB mistake off the device generally means
  adb or a rooted phone. Import deliberately.
- **To replace a file** with a newer export, import it under the same
  file name and accept the **Overwrite** prompt. Roles are remembered by
  file name, so the replacement keeps the role you gave the old one.
- **Auto-load MBTiles** in **Settings → Map** is the master switch:
  turn it off and the map stops scanning the folder, so no MBTiles layer
  appears in the layer picker at all. It is all-or-nothing, not a way to
  hide one file. The **Detected files** list still shows the files while
  it is off.

## When something looks wrong

- **The bottom-left credit line names the layer actually being drawn** —
  the online provider's attribution, or your file's name when it is
  acting as the base map. Glance at it: if an MBTiles base map turns out
  to be corrupt or unreadable, the map falls back to **OpenTopoMap**,
  the default base layer, without any error, and that line is the only
  sign. A file that is still opening shows its own name over blank tiles
  for a moment before the first tiles appear.
- **The file is not in the list at all.** Its name must end in
  `.mbtiles` — anything else in the folder is ignored — and a corrupt
  file is skipped silently by the rescan rather than listed.
- **Blank map after switching base layer.** You are outside that file's
  coverage. Switch back to an online base layer, or give the file the
  **Overlay** role instead.
- **Zooming in further than the file goes** does not go blank: the last
  available tiles are scaled up, so they turn soft rather than
  disappearing.
- **The tile cache is a different thing.** **Tile cache** in
  **Settings → Map** holds downloaded *online* tiles and can be cleared
  with the bin icon; that never touches your MBTiles files.

## See also

- [Surface map](../features/surface-map.md)
- [Settings](../features/settings.md)
- [GPS and coordinates](../features/gps-and-coordinates.md)
- [Raster maps](../features/raster-maps.md)
- [Workflow: Navigating underground with QR codes](navigating-underground.md)
- [Settings screenshots](../screenshots/07-settings.md)
