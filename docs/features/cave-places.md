# Cave places

[← Back to index](../README.md)

A **cave place** is a named point inside one cave. It is the record
everything else hangs off: QR labels, documents, map pins, BLE beacons
and trip points all point at a cave place.

## The cave places list

Tapping a cave on the home screen opens its places list. From top to
bottom the screen holds a strip of tool buttons, an optional
**Past / active trip(s)** button, the list header, and the places
themselves.

> 📷 [A cave's places list](../screenshots/01-home-and-caves.md#cave-places-list) — the cave places list for one cave, with its action toolbar and status icons.

### What a row shows

Each row shows the place title. Entrances get a door icon in front of
the title, a caption underneath (**Entrance**, or **Main entrance** in
blue), and a faint grey background so they stand out in a long list.

To the right of the title sit three things:

| Element | Meaning |
|---|---|
| QR icon | Green when the place already has a place code, grey when it has none. |
| Pin counter | On how many of the cave's raster maps this place has been located. Red at zero, green once it is pinned on every map of the cave, grey in between. |
| Trash button | **Delete cave place** — see [Deleting a cave place](#deleting-a-cave-place). |

Depth, area and the code text itself are **not** shown on the row. Use
the **Sort by** picker or the filter box if you need to find a place by
one of those.

Tapping the pin counter opens the **Raster maps definitions** report: a
list of every raster map in this cave, each with a green tick if this
place is pinned on it or a red circle if it is not. Tapping an entry
closes the report and opens that map's point editor for this place, so
it is the quickest way to work through the maps a place is still
missing from. If the cave has no maps yet you get "No raster maps for
this cave".

### The tool strip

The strip above the list scrolls sideways and the buttons carry icons
only — press and hold one to read its label.

| Button | What it does |
|---|---|
| **Scan QR** | Opens the camera scanner and jumps to the place in *this* cave that the code belongs to; a code from another cave is reported as not found here. Press and hold it for about two and a half seconds to type a code by hand instead. |
| **Add place** | Opens an empty cave place form. |
| **View raster maps** | The cave's raster maps — see [Raster maps](raster-maps.md). |
| **Cave map** | Opens the surface map with this cave's places highlighted — see [Surface map](surface-map.md). |
| **Print QR codes** | Builds printable QR labels for the cave — see [QR codes](qr-codes.md). |
| **Manual QR code search** | Shows a **QR code identifier** box under the strip with a **Search place by QR code id** button. |
| **Cave areas** | Manage the zones places can be grouped into — see [Caves and cave areas](caves-and-areas.md). |
| **Place positions on map** | Opens the map point editor for the whole cave, for pinning several places in one sitting. |
| **Import places from CSV** | Bulk import — see [CSV import](csv-import.md). |
| **Generate codes** | Generates place codes for every place in the cave, asking first before it overwrites one that is already set — see [Place codes](place-code-identifiers.md). |
| **Generate cave place QR codes (range)** | Pre-prints labels for place numbers that do not exist yet (below). |
| **Cave** | A small menu with **Edit cave**, **Cave beacons** and **Delete cave**. |

The screen's ⋮ menu repeats **Edit cave**, **Delete cave**, **Import
places from CSV**, **Generate codes** and **Place positions on map**,
and adds **Start trip** when no trip is running.

### Counting, filtering, sorting and selecting

The list header carries a live count of places — it reads `(45)`
normally and `(5 /45)` while a filter is narrowing the list — plus
three buttons:

- **Show filter** opens a **Filter cave places** box that matches the
  place title, the place code **or** the cave area name.
- **Sort by** orders the list by **Last modified** (the default,
  newest first), **Title**, **Cave area**, **Depth**, **QR code
  identifier**, **Entrance**, **Has QR code** or **Maps with
  location**. Sorting by title, cave area, entrance status or code
  presence also inserts grey group headings, so you can see at a glance
  which places still have no code or which belong to which area. Places
  with no depth and places with no code sort last when the order is
  ascending. Your choice is remembered for this list between visits.
- **Selection mode** puts a tick box on every row and adds **Select
  all**, **Invert selection** and **Delete selected** to the header.
  While places are ticked, **Print QR codes** prints only those, and
  **Cave map** highlights only those. Outside selection mode **Cave
  map** falls back to whatever the filter leaves visible, while
  **Print QR codes** always falls back to every place in the cave,
  filter or no filter.

The full behaviour is described in
[Lists: filter, sort and selection](lists-filter-sort-select.md).

### Trips from this screen

Once at least one trip in this cave has ended, a **Past / active
trip(s)** button with the count appears above the list; it opens the
cave's trip history. There is no trip banner on this screen — while a
trip is running, the app-wide ⋮ menu shows an active-trip card with the
trip name, the cave, elapsed time, the point count, the last few
scanned places and **View trip** / **Pause** (or **Resume trip**) /
**Stop trip**. See [Trips](trips.md).

## Adding a cave place

Four ways, pick the one that fits:

1. **The full form** — the **Add place** button on the tool strip.
   Every field is available. Use this when you are documenting a place
   properly.
2. **Quick add cave place** — reached only from the raster map point
   editor. It asks for a title, a **Depth '+/-'** value, a cave area
   and a place code (which you can scan off a label instead of typing),
   then saves straight away. It refuses a title that already exists in
   this cave, and a place code already used by another place in this
   cave.
3. **By tapping on a raster map** — in the map point editor press the
   **Quick add cave place** button; the app tells you "Tap on the map
   to define the point for the new cave place". Tap the spot, the quick
   add dialog opens, and on save the new place is pinned exactly where
   you tapped. The mode stays on afterwards, so you can add one place
   after another without pressing the button again. See
   [Map viewer and point editor](map-viewer.md).
4. **CSV import** — bulk, from a spreadsheet. See
   [CSV import](csv-import.md).

### Pre-printing labels for places that do not exist yet

**Generate cave place QR codes (range)** asks for a **From index** and
a **To index** and produces printable labels for that whole span of
place numbers, whether or not those places exist in the app. It is
meant for a trip where you carry a sheet of numbered labels
underground and record afterwards what you attached each one to.
Numbers already used by an existing place are skipped, as is the index
reserved for the main entrance, and you are told how many were skipped.
It works only with the hierarchical place code strategy, and only once
the cave has a local index and the country and organization codes are
set — otherwise the app says which one is missing.

## The cave place form

Tapping a row opens the cave place form. It is one long scrolling page,
not a set of tabs. Top to bottom it holds:

1. **Title** and **Description** (the button beside the description
   adds a line to it, up to five).
2. A row with the **Depth '+/-'** field, the **Area title (optional)**
   dropdown and a button to manage the cave's areas.
3. The **Place code identifier** row and the **QR code resource
   identifier** row, each behind a padlock.
4. **BLE beacons** — only after the place has been saved once.
5. **Latitude / Longitude / Altitude** — hidden until you show them.
6. **Raster maps** — one tab per raster map of the cave, for pinning
   this place on each.
7. The **Cave entrance** and **Main cave entrance** checkboxes.

The app bar carries a save button, a globe **Pick coordinates on map**
button, the ⋮ menu, and — once the place has been saved — a folder
**Documents** button. Documents are not a tab on this form; see
[Documents](documents.md).

Any field whose value differs from what was loaded takes a faint green
tint, so before saving you can see at a glance exactly what you
changed. The tint clears when the place is saved. Trying to leave with
unsaved edits asks "Discard changes and leave without saving?".

> 📷 [The cave place form: codes and beacon](../screenshots/04-places-and-qr-codes.md#cave-place-form-codes-and-beacons) — the cave place form, scrolled from Title through BLE beacons to the Raster maps tabs.

### Field reference

| Field | Notes |
|---|---|
| **Title** | Required — saving without one warns "Title is required". The quick add dialog refuses a title that already exists in the cave; the full form does not check, so keep titles distinct yourself. The title is what you see in lists, on printed labels and in trip logs. |
| **Description** | Free-form text, several lines. |
| **Depth '+/-'** | Optional signed number, up to four whole digits and one decimal. Negative values (for example `-45`) are usual for points below the entrance, positive for above. Comma and dot both work as the decimal separator. Beyond ±5000 the app refuses to save ("Depth must be between -5000 and +5000"); beyond ±1800 it asks you to confirm the value is not a typo. Leave it empty if you do not know. |
| **Area title (optional)** | Links the place to a [cave area](caves-and-areas.md). Choosing **None** on a place that already had an area asks "Clear assigned area for this place?" first. |
| **Place code identifier** | The human-readable code printed on the label — any string, depending on the active [strategy](place-code-identifiers.md). It should be unique within a cave: if another place in the same cave already uses it, saving warns you but lets you keep the duplicate. The same code reused in a *different* cave is not flagged on save; scanning it later offers you the matching places to choose from. |
| **QR code resource identifier** | The payload actually embedded in the QR pixels and in the `sp://` deep link. It equals the place code in mirror mode, or a short hash in hash mode — and in mirror mode an entrance is hashed anyway when the **Use hash for entrances** setting is on. The app computes it for you when you save, but **only if you left the field empty**; anything you type there is saved exactly as typed. Clearing the place code also clears this. See [Place codes](place-code-identifiers.md). |
| **Latitude / Longitude / Altitude** | Optional position, hidden until you show the row. Latitude and longitude are decimal degrees; altitude is in metres. See [GPS and coordinates](gps-and-coordinates.md). |
| **Cave entrance** / **Main cave entrance** | Two checkboxes at the bottom of the form (below). |

### The two code rows

Both the **Place code identifier** and the **QR code resource
identifier** fields open **locked every time** — including on a
brand-new place — so a knock on the phone in a wet passage cannot
overwrite a code that is already printed on a label. Tap the padlock to
the left of a field to unlock it; its tooltip flips between **Enable QR
edit** and **Disable QR edit**. The **Auto-generate** button beside
each field stays greyed out until you unlock that field.

In the default mirror mode the QR payload is only a copy of the place
code, so the form hides the **Place code identifier** row when you open
a place whose two values are already identical. Tap the eye button
(**Show place code identifier**) at the right of the depth / area row to
bring it back. The row is always shown when the two values differ, when
the place carries no code yet, or when hash mode is in use.

The **Scan** button at the end of the QR code resource identifier row
adopts a code from a label already mounted in the cave:

1. If the scanned code is already used by another place anywhere in the
   database, the app refuses it and names that place.
2. If this place already holds a different code, it asks **Replace QR
   code?** — "A different QR code is already set for this place. Do you
   want to replace it?". This changes only the value in the form in
   front of you, never a code stored on another place.
3. Once accepted, the field is unlocked and filled. In mirror mode the
   place code field is filled with the same value too, but only if it
   was still empty — and not if another place anywhere already uses
   that code, in which case you are warned and only the payload field
   is filled.
4. For a place that has already been saved, a preview of the resulting
   QR code is shown.

Press and hold the **Scan** button for about two and a half seconds to
type a code by hand instead of scanning it. When the place is saved and
has a payload, a **View QR code** button at the start of the row shows
its label at any time.

### BLE beacons

Once a place has been saved at least once, the form shows a **BLE
beacons** section listing the Bluetooth tags mounted at that point.

- **Assign beacon** opens **Nearby beacons**, which scans for tags
  around you — hold the phone next to the one you are mounting and pick
  it from the list. Tags already registered anywhere in this cave are
  greyed out and marked "already assigned", so you cannot attach the
  same tag twice.
- Each row shows the tag's identity — major/minor and the proximity
  identifier for an iBeacon, the MAC address and model for a Ruuvi
  sensor — plus its last reported battery voltage. Tapping a Ruuvi row
  opens its live readings; see [Ruuvi sensors](ruuvi-sensors.md).
- The unlink button at the right of a row asks "Remove beacon … from
  this place?" and then frees the tag for another place.

**These changes are written immediately, not when you press Save**, and
they are not undone by discarding the rest of your edits. See
[BLE beacons](ble-beacons.md).

### GPS coordinates

The coordinate row is hidden by default. Tick **Show/Hide GPS
coordinates** in the ⋮ menu to reveal it. The choice is not remembered
— the row is hidden again next time you open the place — but picking a
position on the map reveals it for you.

Three icon buttons sit at the end of the row:

- **Record GPS point** opens the recorder. It streams fixes from the
  device and keeps a running average, showing the sample count, the
  accuracy in metres and a quality word (Excellent, Good, Fair, Poor,
  Very poor). Tap **Capture** once the live reading has settled, then
  **Use this** to copy the result into the form — this is the only
  route that also fills **Altitude**.
- **Pick coordinates on map** opens the surface map as a picker and
  returns latitude and longitude. The same button is on the globe icon
  in the app bar, where it works even while the coordinate row is
  hidden.
- **Enter coordinates** opens a single box that accepts decimal
  degrees, degrees-minutes-seconds or UTM — the format is detected from
  what you type, and the three example lines under the field show the
  accepted shapes. It fills latitude and longitude only.

The three fields themselves take plain decimal numbers, so use **Enter
coordinates** for anything in DMS or UTM. If your coordinate display
format is set to something other than decimal, the converted position
appears live under the fields. Nothing is stored until you save the
place. See [GPS and coordinates](gps-and-coordinates.md).

### Raster maps

When the cave has raster maps, a **Raster maps** strip appears near the
bottom of the form with one tab per map (arrow buttons on either side
step through them) and a preview of the current one. Tapping the
preview, or the **Define place on map** button on it, opens the point
editor for this place and that map.

If the place has never been saved, the app saves it first and stays on
the form, so you can create a place and pin it in one pass — every
normal save prompt (missing title, unusual depth, duplicate code) still
appears at that moment. See
[Map viewer and point editor](map-viewer.md).

### Entrance flags

The two checkboxes at the bottom of the form are **Cave entrance** and
**Main cave entrance**. **Main cave entrance** stays greyed out until
**Cave entrance** is ticked, and unticking **Cave entrance** clears it
again.

Every change of either box asks for confirmation first. In addition:

- Ticking **Cave entrance** when the cave already has other entrances
  lists them under **Other cave entrances exist** and asks whether you
  really mean it.
- Ticking **Main cave entrance** when another place already holds that
  flag is **refused**: the app shows **Main cave entrance already
  defined**, names the place that holds it, and leaves your tick
  unapplied. Open that place, demote it to a regular entrance, then
  come back.

Entrance flags drive the door icons in the list, the reports, and the
entrance QR workflow described in [QR codes](qr-codes.md).

### What happens when you save

Pressing save runs these checks in order, and any of them can stop the
save:

1. **Title is required.**
2. The depth must be a readable number, and within ±5000.
3. A depth beyond ±1800 asks "Depth value (…) is outside the typical
   range (-1800 to +1800). Are you sure it is correct?".
4. If another place in the **same cave** already uses this place code,
   a **Duplicate QR code** warning appears: "Cave place "…" already
   uses QR code …. Save with duplicate?". **Yes** saves anyway and
   leaves both places holding the same code; **Cancel** abandons the
   save, so nothing is written. The app never edits or clears the code
   on the other place — if you want the code moved, open that place and
   clear it yourself.
5. If you hand-edited the QR code resource identifier to a value
   already used **anywhere in the database**, the same warning appears
   for that field.
6. If the title is exactly "entrance" and the place is not flagged yet,
   the app offers to mark it as an entrance.
7. If the place is being saved as an entrance and the cave has no main
   entrance yet, the app offers to make this one the main entrance.

The last two decisions are applied to the saved record but the
checkboxes on screen are deliberately not re-ticked — re-open the place
if you want to see the result.

## Deleting a cave place

Deletion happens on the **cave places list** only; there is no delete
action on the cave place form. Either tap the trash button at the right
of a row and confirm "Are you sure you want to delete this cave
place?", or turn on **Selection mode**, tick several places and use
**Delete selected**.

**Deleting is irreversible.** Along with the place it removes:

- its pins on every raster map of the cave,
- its document links — the documents themselves are not deleted, and
  stay reachable from any other place or cave they are linked to,
- every BLE beacon assignment on that place, including tags that had
  already been unassigned. The physical tag mounted there stops being
  recognised until you assign it to another place, and the removal
  travels to the other devices on the next sync.

Trip points that recorded the place are **not** deleted: they stay in
their trips, but they no longer name a place.

## See also

- [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
- [QR codes](qr-codes.md)
- [Map viewer and point editor](map-viewer.md)
- [BLE beacons](ble-beacons.md)
- [GPS and coordinates](gps-and-coordinates.md)
- [Lists: filter, sort and selection](lists-filter-sort-select.md)
