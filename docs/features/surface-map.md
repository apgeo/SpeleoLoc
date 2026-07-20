# Surface map

A full-screen geographic map (`CaveMapPage`, `lib/screens/cave_map/`) that
plots every cave place with GPS coordinates (`cave_places.latitude` /
`longitude`). It has no AppBar; a compact toolbar sits on top of the map.

## Opening the map

- **Home screen** — toolbar globe button (or the screen menu): shows the
  places of the caves currently in scope — the checked caves when the list
  is in selection mode, otherwise the caves left visible by the filter.
- **Cave places list** — toolbar globe button: shows this cave's
  filtered/checked places *highlighted* among the places of all other
  caves.
- **Cave place form** — globe button in the app bar or next to the GPS
  recorder button: opens the map as a **coordinate picker**. Tap the map
  to set (or move) the position, then save; the picked coordinates fill
  the latitude/longitude form fields and are persisted only when the place
  itself is saved — exactly like the GPS recorder flow.

## Markers and labels

- Entrances are drawn with a cave-arch waymark (main entrances slightly
  larger and darker), other places with a small dot. Places outside the
  opened-for scope are grey.
- Every place has a label. Labels are decluttered greedily by priority
  (main entrance > entrance > other places; the tapped place always wins),
  so on crowded/zoomed-out views non-entrance labels disappear first.
- Label text: the sole entrance of a single-entrance cave shows the cave
  title alone; every other place shows `<cave title> - <place title>`.
- Tapping a marker opens an info card with coordinates and a button to the
  cave-place page.

## Toolbar

Back · layer picker · show/hide other caves · show/hide non-entrance
places (the two toggles combine) · list of all places · list of entrances.
The two lists open as inline panels on the same screen (`<place title> -
<cave title>`, tap to fly to the place). In pick mode a confirm button is
added.

## Layers

Base layers (pick one): OpenTopoMap (default), OpenStreetMap, Google
Streets/Satellite/Hybrid, Esri World Imagery, Esri World Topo, Carto
Positron, CyclOSM, OSM Humanitarian — plus any MBTiles file configured as
a base map. MBTiles files configured as overlays can be toggled on top of
the base layer. The Google endpoints (mt0–mt3) are public but not an
officially licensed API; they are included by explicit owner decision.

The selected base layer, enabled overlays and last camera position are
persisted (`map_screen_prefs` configuration key).

## MBTiles layers

Offline layers are read from the app-managed folder

    <application documents directory>/mbtiles/

next to `speleo_loc.sqlite`. Drop `.mbtiles` files there (file manager,
USB, etc.) and they are picked up automatically when the map opens —
governed by **Settings → Map**:

- **Auto-load MBTiles** — master switch for scanning the folder.
- The exact folder path is displayed there (with a copy button), since it
  differs per platform/device.
- Per file: **Base map** or **Overlay** (default) role.

Only **raster** MBTiles are supported (png/jpg/webp tiles — e.g. exports
from MOBAC, QGIS, SAS Planet). Vector (`pbf`) files are listed in settings
but flagged unsupported. Tiles are served straight from the SQLite file
(TMS y-flip handled by `MbTilesReader`); areas outside a file's coverage
render transparent.

Configuration lives under the `map_mbtiles_config` key. Roles are keyed by
file name, so replacing a file with a newer export keeps its role.
