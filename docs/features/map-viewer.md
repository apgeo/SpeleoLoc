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
