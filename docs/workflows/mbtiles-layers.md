# Using offline MBTiles layers on the surface map

1. Produce a **raster** `.mbtiles` file (MOBAC, QGIS, SAS Planet, …).
   Vector (`pbf`) MBTiles are not supported.
2. Find the folder path in **Settings → Map** (copy button next to it).
   It is the `mbtiles/` folder inside the app's documents directory, e.g.
   on Android: `Android/data/com.example.speleoloc/…/mbtiles/` as shown in
   the settings page.
3. Copy the file into that folder (file manager, USB cable, adb push).
4. In **Settings → Map**, tap refresh: the file appears in the list.
   Choose its role — **Overlay** (drawn on top of the online base layer;
   the default, best for small local/cave-area maps) or **Base map**
   (selectable instead of the online layers; blank outside its coverage).
5. Open the surface map → layers button: base-role files appear in the
   base-layer list, overlay-role files as toggleable overlays. Selections
   persist across sessions.

Auto-loading can be disabled entirely with the **Auto-load MBTiles**
switch in Settings → Map.

See docs/features/surface-map.md for the full feature description.
