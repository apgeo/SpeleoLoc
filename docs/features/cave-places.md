# Cave places

[← Back to index](../README.md)

A **cave place** is a named point of interest inside a specific cave.
It is the central concept of SpeleoLoc: QR codes are attached to cave
places, documents hang off cave places, and trips are made up of cave
places in visit order.

## Fields

| Field | Notes |
|---|---|
| **Title** | Required. Unique within a cave. |
| **Description** | Free-form text (multi-line). |
| **Depth in cave** | Signed number. Negative values (e.g. `-45`) are typical for points below entrance; positive for above. |
| **QR code identifier** | Integer. Printed on the physical label. Unique within a cave; duplicates across caves are allowed but warned against. |
| **Cave area** | Optional. Links the place to a [cave area](caves-and-areas.md). |
| **Latitude / Longitude** | Optional GPS coordinates. Hidden by default; toggle via the screen menu. |
| **Is entrance** / **Is main entrance** | Flags used for display and reports. |

## Opening the cave places list

From the home screen, tap a cave. The places list shows:

- a filter bar (toggled from the toolbar) that matches title **or** QR
  code number substring,
- a **past trips** button (see [Trips](trips.md)),
- the list of places with their depth, area and QR number.

A banner appears at the top whenever there is an **active trip** in
this cave, with pause/resume/stop controls.

## Adding a cave place

Four ways, pick the one that fits:

1. **Manual (full form)** — list **Add place** button, fill every
   field, save. Use for detailed entry.
2. **Quick add** — available from the map viewer and some dialogs;
   asks only title, area and QR.
3. **By tapping on a raster map** — set tap-mode to "Define new place"
   in the map viewer, tap the image, then fill the quick-add form.
   See [Map viewer](map-viewer.md).
4. **CSV import** — bulk from a spreadsheet. See
   [CSV import](csv-import.md).

## Editing a cave place

Tap a row to open the **cave place page**, which has tabs:

- **Details** — the form above.
- **Raster maps** — pin this place on each raster map of the cave. See
  [Map viewer and point editor](map-viewer.md).
- **Documents** — attached photos, audio, text, etc. See
  [Documents](documents.md).

Unsaved changes trigger a confirmation dialog if you try to leave.

### QR editing safety

The QR code field is locked by default when the place already has a QR
assigned, to prevent accidental overwrites during rough use. Toggle
**Enable QR edit** / **Disable QR edit** from the ⋮ menu to change it.

If you assign a QR that is already used by another place in the cave,
the app warns and asks whether to replace it on the existing place
(leaving it blank), keep both (duplicate warning), or cancel.

### GPS coordinates

Hidden by default. Enable **Show GPS coordinates** in the screen menu.
Useful for the entrance place; not required for interior places.

### Entrance flags

- **Is entrance** — marks the place as one of the cave's entrances.
- **Is main entrance** — marks the single primary entrance (the app
  ensures at most one main entrance per cave).

These flags are used by reports and by the "entrance QR" workflow
described in [QR codes](qr-codes.md).

## Deleting a cave place

From the cave place page's ⋮ menu, or the list's long-press menu.
Deleting a place also removes:

- its point definitions on every raster map,
- its documentation file links (the files themselves may be kept if
  they are also linked to other places/caves),
- any references from trip points (which become orphan entries in
  ended trips).

## See also

- [QR codes](qr-codes.md)
- [Map viewer and point editor](map-viewer.md)
- [Documents](documents.md)
- [Trips](trips.md)
