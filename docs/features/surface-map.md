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

Back · my-location · layer picker · show/hide other caves · show/hide
non-entrance places (the two toggles combine) · list of all places · list
of entrances · add-point. The two lists open as inline panels on the same
screen (`<place title> - <cave title>`, tap to fly to the place).

## GPS and point management

The map doubles as a GPS/geodata point manager. `LocationService`
(`lib/services/location/`) is the generic device-location primitive
(permission handling, a one-shot fix, and a position stream) that the map's
specific use cases build on. `CaveGeoService` (`lib/services/cave_geo_service.dart`)
performs the creation writes (new entrance, new cave + entrance, set a
place's location) so the rules — e.g. the first entrance of a cave becomes
its main entrance — are unit-tested independently of the UI.

- **My location** — the location button requests permission (once), then
  shows the live position as a blue dot with a translucent accuracy circle
  and follows it. Panning the map releases follow.
- **Measure** — the ruler button starts a measuring path: tap the map (or
  a marker, snapping to the exact place point) to add vertices; the bar
  shows the total distance plus the last leg's length and bearing, with
  undo. Exclusive with point placement.
- **Clustering** — below zoom 14 nearby markers collapse into count
  bubbles (blue when any member is in focus, grey otherwise); tapping a
  bubble zooms onto its members. Labels only ever attach to unclustered
  markers.
- **Offline tile cache** — online base-map tiles are cached on disk
  (7-day freshness, stale tiles served when the network fails), so any
  previously viewed area keeps rendering offline. Toggle and clear it in
  Map settings; MBTiles layers are unaffected.
- **Placing a point** — every "create" or "set location" action enters one
  shared placement flow. The point can be set four ways: **tap** the map,
  **drag** the red pin for fine adjustment, **long-press** the map (which
  also opens the create menu at that point), or **Use my location** (the
  current GPS fix). A bottom bar shows the chosen coordinates and a
  confirm button.
- **Add point** (toolbar +, or long-press) offers:
  - **New cave** — enter a cave title and entrance name; creates the cave
    and its main entrance at the point.
  - **New entrance** — pick an existing cave and a name; adds an entrance
    place at the point (marked main if the cave had none).
- **Set an existing place's location** — tap a place marker → the info
  card's edit-location button re-places that point (tap / GPS).
- **From the cave-place form** — the pick button opens the map in the same
  placement flow and returns the coordinates (tap or GPS) to the form,
  where they are saved with the place.

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

next to `speleo_loc.sqlite`. Add `.mbtiles` files there and they are picked
up automatically when the map opens — governed by **Settings → Map**:

- **Import MBTiles file** — browses for a file via the system document
  picker and copies it into the folder. This is the supported way to add
  files on Android/iOS (no storage permission needed; works on debug or
  sideloaded installs where the folder is app-private). Imports are
  validated and name clashes prompt before overwriting. Files can also be
  placed in the folder directly (adb push / file manager) where reachable.
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
