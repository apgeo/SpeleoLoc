# Caves and cave areas

[← Back to index](../README.md)

A **cave** is the top-level record in SpeleoLoc — places, raster maps,
trips, beacons and documents all hang off one. A **cave area** is a named
zone *inside* a single cave, used to group its places. This page covers
creating, editing and deleting caves, and managing their cave areas.

## The cave record

The **Add new cave** / **Edit cave** form has four fields:

| Field | Notes |
|---|---|
| **Cave title** | Required. The name shown everywhere in the app. |
| **Description** | Free text, three lines tall on the form. Access notes, landowner contact, gear reminders — anything that does not fit the other fields. |
| **Area title (optional)** | The [surface area](surface-areas.md) this cave belongs to. Choose **None** to leave it unassigned. The landscape icon beside the dropdown opens **Manage surface areas** so you can add one without leaving the form. |
| **Cave local index** | Optional short number identifying this cave inside its surface area. Used when building structured place codes. |

A cave title only has to be unique *within* a surface area. Two caves in
different surface areas may share a title, and so may two caves that both
have no surface area assigned. Saving a second cave with the same title in
the same surface area fails and shows an error message.

Everything else belonging to a cave is created after it: its
[cave places](cave-places.md), its cave areas, its
[raster maps](raster-maps.md), its [trips](trips.md) and recorded trip
points, its [BLE beacon](ble-beacons.md) registrations, and the
[documents](documents.md) linked to it.

The cave itself carries no QR code and no place code. The entrance QR
belongs to the cave place flagged as the **main entrance**, and scanning it
opens that place — see [QR codes](qr-codes.md).

> 📷 [Choosing a surface area for a cave](../screenshots/01-home-and-caves.md#cave-form-surface-area-picker) — Choosing the surface area a cave belongs to on the cave form.

### Cave local index

This is the number that identifies the cave inside its area when the app
composes structured place codes (for example the `12` in a code built from
country, organisation, area and cave). It matters in three places:

- The hierarchical place-code strategy uses it. If the field is empty when
  you first generate codes for the cave, the app allocates the next free
  number itself and writes it into this field.
- The **Generate cave place QR codes (range)** tool on the cave's places
  list refuses to run for a cave that has no local index, and says so.
- The **Generate entrance QR codes (range)** tool on the surface areas
  screen treats a number as "already taken" when some cave in that area
  carries it as its local index.

Fill it in for any cave whose places you intend to label with structured
codes. See [Place codes (PCI/QCRI)](place-code-identifiers.md).

## Creating a cave

### From the home screen

1. Tap **⋮ → Add new cave**, or the add button in the home toolbar (the
   toolbar is shown while **Settings → General → Show home toolbar** is on;
   the header's toolbar icon hides and shows it too).
2. Fill in **Cave title**, and optionally **Description**,
   **Area title (optional)** and **Cave local index**.
3. Tap **Add**. On an existing cave the same button reads **Save**.
4. Unless you have turned off **Settings → General → Auto-add entrance when
   creating cave**, the new cave already contains one cave place named
   "Entrance", flagged both as an entrance and as the main entrance.

### From the cave map

1. Open the [cave map](surface-map.md) and tap **Add point**.
2. Choose **New cave** ("Create a cave with an entrance at this point").
3. Set the point — tap the map, long-press it, or use the current GPS fix —
   then confirm on the bar at the bottom.
4. Give a **Cave title** and an **Entrance name** (it defaults to
   "Entrance") and tap **Add**.

This creates the cave and its located main entrance in one step. The path
offers no surface-area choice, so the new cave is unassigned; set
**Area title (optional)** later by editing the cave.

> 📷 [Adding a cave or an entrance from the map](../screenshots/02-cave-map.md#cave-map-add-point-menu) — The Add point menu offering New cave or New entrance at the chosen spot.

### From a CSV file

Whole batches of caves come in through the caves [CSV import](csv-import.md)
on the home screen's **⋮ → Import caves - CSV**. It reads a surface area
column and creates any area named there that does not exist yet, and it can
fill in the description, the cave local index and the surface area of caves
that already exist.

## Editing a cave

Open the cave from the home list, then use either menu on the places list:

- the **⋮** menu, which holds **Edit cave** and **Delete cave** alongside
  **Start trip**, **Import places from CSV**, **Generate codes** and
  **Place positions on map**;
- or the **Cave** (house) button in the toolbar above the list, which holds
  **Edit cave**, the cave's beacons, and **Delete cave**.

Two extras appear on the **Edit cave** screen that are absent while you are
creating a cave:

- a **Documents** (folder) icon in the top bar, which opens the document
  browser filtered to this cave, so you can attach or read surveys, photos,
  notes and permits without going back out;
- **⋮ → Generate codes**, which runs place-code generation for every place
  in this one cave. It asks for confirmation and, when places already carry
  a code, how to handle them, before writing anything.

## Deleting a cave

Deleting a cave is permanent and there is no undo.

**One cave:** open it and choose **Delete cave** from either menu, then
answer *Yes* to "This will delete the cave. Are you sure?".

**Several at once:** on the home list, tap the **Selection mode**
(checklist) icon in the list header, tick the caves, then tap
**Delete selected**. This walks through three confirmations in a row — and
note that the third dialog swaps the button order, putting **Delete** on the
left, so read them rather than tapping the same spot. The delete button only
appears while **Settings → General → Allow bulk deletion of caves** is on,
which it is by default.

> 📷 [Selection mode on the cave list](../screenshots/01-home-and-caves.md#home-cave-list-selection-mode) — The home cave list in selection mode, with two caves checked.

Deleting a cave removes everything under it: its cave places, its cave
areas, its raster maps and the pin positions of places on them, its trips
and recorded trip points, and its BLE beacon registrations (including ones
already unregistered). Documents attached to the cave, to its areas or to
its places are **unlinked**, but the files themselves stay in the app's
documentation library.

## Finding caves in the list

The cave list has the shared filter, sort and selection controls described
in [Lists: filter, sort and select](lists-filter-sort-select.md). Two of
them behave in a cave-specific way:

- The filter box matches the cave title **and** its surface area name, so
  typing an area name narrows the list to the caves in that area.
- **Sort by** offers **Last modified** (the default, newest first),
  **Title**, **Surface area** and **Number of cave places**. Sorting by
  Title groups the rows under initial-letter headings; sorting by
  **Surface area** groups them under area headings, with the unassigned
  caves gathered together. Your choice is remembered between sessions.

The QR icon in the list header generates labels for many caves at once. It
works on the caves you have ticked in selection mode, or — if you are not
selecting — on every cave the current filter leaves visible. When any of
those caves holds places that are not entrances, it asks whether to produce
**Entrances only** or **All places** first.

## Cave areas

A **cave area** is a named zone *within* one cave: "Entrance zone", "Main
gallery", "Lake room". Cave areas are:

- optional — a place with no area is perfectly normal;
- titled only, and nothing else: the add/edit dialog asks for
  **Enter area title** and has no other field;
- unique by title within the cave. If you re-use a name, **Save** appears to
  do nothing — the dialog simply stays open instead of reporting the clash.

What they are actually used for:

- **Filtering the places list.** Typing an area name in the cave places
  list's filter box finds the places assigned to it.
- **Grouping the places list.** Choosing the **Cave area** sort option
  puts the rows under area headings.
- **Grouping the place strip on a raster map.** When a map's places are
  sorted by **Cave area**, the horizontal strip along the bottom of the map
  splits into labelled groups, one heading per area, so you can jump
  straight to "Lake room" instead of scanning one long row. Places with no
  area are collected under a "—" heading.

Cave areas do **not** appear in QR labels, trip logs or exported trip
reports.

### Managing cave areas

Open the cave, then tap the **layers** icon in the toolbar above the places
list — its tooltip reads *Cave areas*. The same icon sits next to the
**Area title (optional)** dropdown while you are adding or editing a cave
place, so you can create a missing area without losing your place.

The screen is titled **Cave areas**. From there:

- **+** in the top bar opens **Add cave area** — type a title and **Save**.
- The pencil icon on a row renames the area.
- The bin icon deletes it, after "This will delete the cave area. Are you
  sure?".

### Deleting an area that is still in use

An area can only be deleted once **no cave place is still assigned to it**.
Open those places first and set **Area title (optional)** back to *None*.

Deleting an area that is still in use currently fails silently: the
confirmation dialog closes, no message appears, and the area is still in the
list afterwards. If a delete seems to do nothing, that is why.

### Assigning a place to an area

There are three ways, and no way to re-assign several existing places at
once:

- On the cave place form, the **Area title (optional)** dropdown. Clearing
  an area that is already set asks "Clear assigned area for this place?"
  first.
- In the **Quick add cave place** popup you get when adding a place by
  tapping a raster map, where the same dropdown is labelled **Cave area**.
- In bulk through the cave places [CSV import](csv-import.md), whose
  **Cave area** column creates any area that does not exist in the cave yet.
  Matching is case-insensitive, so "Main gallery" and "main gallery" land in
  the same area.

## Cave area or surface area?

They are independent, and most surveys end up using both.

| | Cave area | Surface area |
|---|---|---|
| Where | Underground, inside one cave | On the surface, across a region |
| Groups | Cave places of that cave | Caves |
| Fields | Title | Title, general area identifier, description |
| Managed from | The layers icon above a cave's places list | **Manage surface areas** — home **⋮**, the home toolbar, or the landscape icon on the cave form |

Only the surface area feeds structured place codes, through its general
area identifier — see [Surface areas](surface-areas.md).

## See also

- [Cave places](cave-places.md)
- [Surface areas](surface-areas.md)
- [Home screen](home-screen.md)
- [Place codes (PCI/QCRI)](place-code-identifiers.md)
- [Raster maps](raster-maps.md)
- [Documenting a new cave](../workflows/documenting-a-new-cave.md)
