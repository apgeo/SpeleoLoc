# Raster maps

[← Back to index](../README.md)

A **raster map** is a bitmap image (JPG, PNG) representing a cave map.
SpeleoLoc does not draw maps itself — you import scanned or rendered
maps produced in your surveying workflow (Therion, Compass, Walls,
hand-drawn scans, etc.).

## Map types

Every raster map has a **map type**:

- **Plane view** (top-down),
- **Projected profile** (vertical cross-section, projected),
- **Extended profile** (vertical cross-section, extended along passage).

The type is metadata only — it does not change coordinates or behavior,
but it drives labels and ordering in the UI and reports.

## Managing a cave's raster maps

From a cave:

1. **⋮ menu → Raster maps** (or the maps icon).
2. The list shows each map with thumbnail, title, type and optional
   area.
3. Actions per map:
   - **Open** — view / edit point definitions.
   - **Edit** — change title, map type, or replace the image file.
   - **Delete** — removes the map *and all cave-place point
     definitions on it*.

## Adding a raster map

1. **Add raster map** button.
2. Pick an image file (JPG/PNG recommended).
3. Choose the map type.
4. Optional: pick a cave area for scoping.
5. Save.

The image is copied into the app's data directory so it survives even
if you move/remove the original file.

## Placing points (cave places) on a raster map

See [Map viewer and point editor](map-viewer.md). In summary:

- Open a cave place → **Raster maps** tab → select a map.
- Tap where the place physically is. The pin turns orange (pending)
  and green once saved.
- Zoom & pan with pinch / scroll / the on-screen controls.

## Quick placement mode (bulk pinning)

From the cave's **Raster map place selector**:

- Set tap-mode to **Select existing place** or **Define new place**.
- For *selecting*: the right column lists unplaced or placed cave
  places; pick one and tap the map to pin it. Use this when you have
  many places to place quickly.
- For *defining*: tap to create a brand-new place directly via the
  quick-add dialog.

The selector offers:

- a **points legend** overlay (current, new, original, existing
  colors),
- a **compact nav bar** toggle to use more screen for the image,
- **zoom-to-fit** and **zoom-to-point** helpers,
- optional **route playback** for trip visualization.

## Image performance

- Very large raster maps (tens of megapixels) are supported but will
  decode slower on low-end devices. Consider down-sampling to the
  actual usable resolution before importing.
- Image decoding is cached while you browse, so switching maps is fast
  after the first open.

## Deleting raster maps

Deleting a raster map is permanent and removes every cave place's
point definition on that map. The cave places themselves and their
definitions on *other* maps are unaffected.

## See also

- [Map viewer and point editor](map-viewer.md)
- [Cave places](cave-places.md)
- [Caves and cave areas](caves-and-areas.md)
