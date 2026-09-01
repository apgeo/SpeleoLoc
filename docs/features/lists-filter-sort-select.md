# Filtering, sorting and selecting in lists

[← Back to index](../README.md)

The cave list on the home screen and the cave places list inside a cave share
one list header: a filter box, a **Sort by** picker and a selection mode with
bulk actions. This page describes that header once; other pages link here
instead of repeating it.

## Where this header appears

Only two lists in the app use the full header. Other lists offer some of the
same ideas in their own arrangement, described at the end of this page.

| List | Filter | Sort by | Selection mode |
| --- | --- | --- | --- |
| Cave list, on the [home screen](home-screen.md) | yes | yes | yes |
| [Cave places](cave-places.md) list, inside a cave | yes | yes | yes |
| [Documents](documents.md) browser | a permanent search box | its own menu | no |
| Places strip above a [raster map](raster-maps.md) | its own magnifier | its own dialogs | no |
| Raster maps screen of a cave | no | drag to reorder | no |

## The header row

The header sits directly above the list and reads, on the left, the name of
what is listed followed by a count in brackets — **Caves:** on the home
screen, **Cave places:** inside a cave. The count is live: it shows `(45)`
normally, and `(5 /45)` while a filter is narrowing the list, so you can
always see how much you are hiding.

On the right sit **Selection mode**, **Sort by** and **Show filter**, in that
order. The cave list adds two more buttons after them, **Generate QR codes
for caves** and the **Hide action toolbar** / **Show action toolbar**
toggle. **Sort by** and **Show filter** draw themselves inside a tinted
rounded box while they are active, and the **Selection mode** icon turns the
accent colour while selection is on, so you can tell at a glance why a list
looks the way it does.

While selection mode is on, the name and count on the left disappear and
the bulk-action buttons join the row of icons on the right.

## Filtering

The filter box is hidden until you ask for it.

1. Tap **Show filter**. A box appears between the header and the list —
   labelled **Filter** on the cave list and **Filter cave places** inside a
   cave.
2. Type. The list narrows as you type; there is nothing to confirm.
3. Tap **Show filter** again to close the box. Closing it also clears what
   you typed and brings the whole list back.

Matching is case-insensitive and matches anywhere in the text, not just at
the start, and leading and trailing spaces are ignored. What each list
searches:

| List | The filter matches |
| --- | --- |
| Cave list | the cave title and the name of its surface area |
| Cave places list | the place title, its place code and the name of its cave area |

Typing a surface-area name on the home screen is therefore the quickest way
to reduce the list to one region, and typing a cave-area name inside a cave
reduces it to one part of the system.

If nothing matches, the list is simply empty and the count reads `(0 /45)`.
The filter is not remembered — every visit to the screen starts with the box
closed and the full list showing.

## Sorting

**Sort by** opens a dialog with two sections, **Primary** and **Secondary**.
The secondary field only decides the order of rows that tie on the primary
one.

To choose a field:

- tap its name to sort by it, ascending;
- tap the name again to flip it to descending;
- or tap the **Ascending** / **Descending** arrows on its right directly.

A tick marks the field in use and the arrow in use is coloured. Under
**Secondary** there is a **None** entry, chosen by default; the same field
cannot be both primary and secondary, so whichever you pick as primary drops
out of the secondary list. Secondary fields stay greyed out until a primary
field is chosen.

The dialog's buttons are **Clear sort**, **Cancel** and **OK**. **OK** stays
greyed out until you have picked a primary field. **Clear sort** is offered
only when a sort was already in force when you opened the dialog; it returns
the list to the order the records happen to be stored in, which is rarely
what you want — pick a field again to get a predictable order.

Your choice is saved separately for each of the two lists and restored the
next time you open the screen. Both lists start on **Last modified**, newest
first.

### The fields

| Cave list | Cave places list |
| --- | --- |
| **Last modified** (default) | **Last modified** (default) |
| **Title** | **Title** |
| **Surface area** | **Cave area** |
| **Number of cave places** | **Depth** |
| | **QR code identifier** |
| | **Entrance** |
| | **Has QR code** |
| | **Maps with location** |

Places with no depth recorded, and places with no place code, sort to the end
of the list when the order is ascending.

### Group headings

Some fields also break the list into groups, each under a small grey heading:

- **Title** — one heading per initial letter;
- **Surface area** (cave list) and **Cave area** (places list) — one heading
  per area, with anything unassigned collected under a heading that reads
  `—`;
- **Entrance** — **Main entrance**, **Entrance** and **Non-entrance**;
- **Has QR code** — **Has QR code** and **No QR code**.

Headings only appear for the primary field, and sorting descending reverses
the order of the headings.

## Selection mode

Tap the checklist icon (**Selection mode**) to put a tick box on every row.
While it is on, tapping a row ticks or unticks it instead of opening it, and
three buttons appear in the header:

| Button | What it does |
| --- | --- |
| **Select all** | Replaces the selection with every row the filter currently leaves visible — not the whole database. |
| **Invert selection** | Flips the tick on each visible row, leaving any other ticks alone. |
| **Delete selected** | Deletes the ticked records. Greyed out while nothing is ticked. |

Tapping the checklist icon again leaves selection mode and clears every tick.

Ticks survive a change of filter. If you tick three caves and then type
something that hides them, they stay ticked and still count as selected —
including for **Delete selected**. **Select all** clears any such hidden
ticks because it replaces the selection outright; **Invert selection** does
not. When in doubt, clear the filter and look at what is ticked before
deleting.

### Deleting several records at once

Bulk deletion is permanent and cannot be undone. Every list asks first:

> Delete the selected N item(s)?

Deleting cave places stops there. Deleting caves takes their places, cave
areas, raster maps, map points, trips and beacon registrations with them, so
the cave list asks twice more:

> Permanently delete N cave(s) and all their data? This cannot be undone.

> Confirm again: delete N cave(s) with all their places, maps, and records?

The buttons on that last dialog are deliberately swapped — **Delete** on the
left, **Cancel** on the right — so read it before tapping.

**Delete selected** appears on the cave list only while **Settings → General
→ Allow bulk deletion of caves** is on. It is on by default; turning it off
removes the only way to delete caves from the home screen. The places list is
not affected by that setting.

## Actions that follow the selection or the filter

Several buttons quietly work on a *set* of records rather than on everything,
and the set is decided by this header. Nothing on screen says so.

| Action | With selection mode on | Otherwise |
| --- | --- | --- |
| **Cave map**, **Import cave documents**, **Export places (GPX/KML)**, **Generate QR codes for caves** (home screen) | the ticked caves | every cave the filter leaves visible |
| **Cave map** (cave places list) | the ticked places | every place the filter leaves visible |
| **Print QR codes** (cave places list) | the ticked places | every place in the cave — this one ignores the filter |

So narrowing the list with the filter, or ticking a few rows, is the way to
limit a map view, an export or a printed QR sheet to just those records.

Take care when the set comes out empty — selection mode on with nothing
ticked, or a filter that matches nothing. **Import cave documents**,
**Generate QR codes for caves** and **Export places (GPX/KML)** stop with a
short message, for example "No caves to import documents to." **Cave map**
and **Print QR codes** read an empty set as no restriction at all and fall
back to showing, or printing, everything.

## Lists that work differently

**The documents browser.** Its search box is always visible, is labelled
**Search documents...** and matches the document title, the file name and the
description. Its **Sort by** menu offers **Title**, **Type**, **File size**
and **Date**; picking the field that is already in use flips the direction
instead of changing the field. The choice is not remembered between visits,
and there is no selection mode or bulk delete. See [Documents](documents.md).

**The places strip above a raster map.** The magnifier on the map's side
toolbar opens a **Filter cave places** box that matches the place title, its
description, its place code and its cave area; places that do not match stay
on the map as faint unlabelled dots rather than disappearing. The map's menu
also has **Sort cave places list** and **Sort maps**, each a small dialog
with a list of fields and **Ascending** / **Descending** chips, confirmed
with **Apply**. There is no selection mode. See [Raster
maps](raster-maps.md) and the [Map viewer](map-viewer.md).

**The Raster maps screen of a cave.** It has neither a filter nor a selection
mode. Instead **Reorder maps** switches the list into a mode where you drag
rows into the order you want and the button then reads **Done reordering**.
That hand-set order is the order maps are listed in elsewhere in the app
unless **Sort maps** overrides it.

## See also

- [Home screen](home-screen.md) — the cave list and its scoped actions
- [Cave places](cave-places.md) — the places list inside a cave
- [Documents](documents.md) — the search box and sort menu of the browser
- [Raster maps](raster-maps.md) — filtering and sorting around a map
- [Settings](settings.md) — where bulk deletion of caves is switched on and off
