# Map viewer and point editor

[← Back to index](../README.md)

The map viewer displays a [raster map](raster-maps.md) with cave-place
pins overlaid, and lets you pan, zoom, add and move points. It is used
throughout SpeleoLoc:

- on the cave place page's **Raster maps** tab,
- on the **Raster map place selector** screen (bulk placement),
- on the cave's **trip map** view (route playback),
- on the standalone **map viewer** screen (read-only navigation).

## Gestures and controls

- **Pinch / scroll wheel** — zoom.
- **Drag** — pan.
- **Tap** — depending on the tap-mode (see below), either selects the
  closest place or defines a new point.
- **Zoom buttons** (+/-) — discrete zoom steps.
- **Fit to points** — auto-zooms so all pins on this map are visible.
- **Reset view** — returns to the original zoom/pan.

## Tap modes

Many map screens offer a tap-mode toggle:

- **Select existing place** — tapping near a pin selects/opens that
  cave place.
- **Define new point / new place** — tapping creates a new point
  definition or invokes quick-add for a new cave place.

The chosen mode is shown in a floating label and in the legend.

## Legend

Points can appear in different colors:

| Color | Meaning |
|---|---|
| Green | Current / saved point |
| Orange | New, unsaved change |
| Grey | Original position (before edit) |
| Blue | Existing point of a different place |

Toggle the legend from the menu; colors and hit threshold are app
constants.

## Map side toolbar

Every screen that hosts the map (the cave place **Raster maps** tab, the
**Raster map place selector**, the standalone **map viewer**, and the
**trip map**) shows a vertical, semi-transparent **side toolbar** anchored
to the left edge of the image. A **chevron** above it hides or reveals the
whole toolbar so it never gets in the way of the map. From top to bottom it
offers:

- **Go to next undefined place** (target icon) — jumps to the next cave
  place that has no point defined on the current map. Greyed out once every
  place is placed; shows the remaining count in its tooltip.
- **Filter cave places** (magnifier) — toggles the cave-place filter in the
  navigation bar.
- **Nav-bar view options** (layers) — a checkable menu to show or hide the
  **maps list** and the **places list** inside the navigation bar.
- **More actions** (⋮) — filter / sort cave places, sort raster maps, and
  open **Manage raster maps**. Mirrors the screen's drawer menu.
- **Full-screen** — see below.
- **Invert colours** — see [Image effects](#image-effects-view-only).
- **Image processing** (sliders) — see [Image effects](#image-effects-view-only).

The exact button set adapts to the screen (e.g. the read-only map viewer
omits editing-only actions).

## Full-screen mode

The **full-screen** button (expand icon) hides the navigation bar and the
parent app bar to give the map image the maximum possible area; the bottom
action bar stays available. Tap the button again (now a collapse icon) to
return to the normal layout. Any nav-bar visibility changes you make while
full-screen are remembered when you exit.

## Landscape-phone layout

On phones held in **landscape** (short side &lt; 600 dp), the screen
automatically collapses secondary UI to give the map more room. Rotating
back to portrait restores the full layout.

## Image effects (view-only)

The **image processing** button (sliders icon) applies non-destructive
display filters to the raster-map image — handy for reading faint pencil
lines, dark scans, or for dark-adaptation underground. It offers single-tap
**presets** plus a **custom** panel:

| Preset | Effect |
|---|---|
| **Normal** | Raw image, no processing. |
| **Invert** | Inverts all RGB channels (dark map → light). Also available as the standalone **invert colours** toolbar button. |
| **Grayscale** | Luminosity-weighted desaturation. |
| **Sepia** | Warm sepia tone. |
| **High contrast** | Sharpens contrast and reduces saturation — good for faint lines. |
| **Night red** | Removes green/blue, leaving a red tint friendly to dark-adapted eyes. |
| **Custom** | Opens a bottom-sheet panel (see below). |

The **custom** panel lets you stack effects additively: checkboxes for
invert / grayscale / sepia / high-contrast / night-red, plus a
**brightness** slider (−1.00 … +1.00) and a **contrast** slider
(0.20 … 3.00), with **Reset**, **Cancel** and **Apply**.

> Image effects are purely visual: they never modify the stored image file
> or the point definitions, and they are **not** saved to disk. The chosen
> effect is remembered **per raster map for the current app session** only.

## Point-definition workflow (on the cave place page)

1. Open the cave place.
2. Switch to the **Raster maps** tab.
3. Pick a map from the nav bar.
4. Tap on the map where the place physically is — an orange (pending)
   pin appears where you tapped. The previous position, if any, stays
   visible in grey.
5. Save (via the save icon or when leaving the page, if auto-save is
   enabled).
6. The pin becomes green.

To remove a placement: **⋮ → Remove point definition** on that map.

To reset an in-progress edit back to the saved point: **⋮ → Reset
point**.

## Auto-save on navigation

When enabled, switching between places or maps while having unsaved
edits asks:

> *Save the current point automatically when switching to another place
> or map?*

Answer yes to make multi-place pinning sessions smooth.

## Route playback (trip map)

On a trip's map view, the viewer can **animate the route** from the
first visited place to the last. A play button starts the animation;
numbered pins and a connecting line are drawn progressively.

## Compact navigation bar

A toggle collapses the raster map picker into a narrow strip (thumbs
only), freeing screen area for the map itself. Remembered per screen.

## Zoom memory

On some screens (e.g. the standalone map viewer) zoom can be
**retained when navigating between places** instead of resetting, so
you can keep examining the same region at a steady scale.

## Exporting the map view

The trip map can be **exported as an image** (PNG) with the visible
route drawn on top — used as an attachment in trip reports.

## See also

- [Raster maps](raster-maps.md)
- [Cave places](cave-places.md)
- [Trips](trips.md)
