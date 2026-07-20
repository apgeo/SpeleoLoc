# Using offline MBTiles layers on the surface map

1. Produce a **raster** `.mbtiles` file (MOBAC, QGIS, SAS Planet, …).
   Vector (`pbf`) MBTiles are not supported.
2. Get the file into the app's `mbtiles/` folder. Easiest is **in-app
   import**: in **Settings → Map**, tap the upload button (or the "Import
   MBTiles file" row), browse to the file, and it is copied into the folder
   for you. This uses the system file picker, so it needs no storage
   permission and works even on debug/sideloaded installs where the folder
   is app-private and not reachable by a file manager. The file is
   validated on import (rejected if it is not a readable MBTiles database);
   a name clash asks before overwriting.
3. Alternatively, copy the file into the folder yourself (file manager, USB
   cable, adb push). The folder path is shown in **Settings → Map** with a
   copy button — it is the `mbtiles/` folder inside the app's documents
   directory. On Android this is app-private storage, usually only reachable
   with adb (`adb push file.mbtiles <path>`) or on a rooted device.
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
