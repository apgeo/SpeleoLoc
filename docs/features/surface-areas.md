# Surface areas

[← Back to index](../README.md)

A **surface area** is a named region on the surface — a karst plateau, a
massif, a valley — used to group caves. It is also where the app keeps
the short area code that structured [place codes](place-code-identifiers.md)
are built from, and it hosts two code-generation tools that work on a
whole region at once.

## What a surface area does for you

- Groups caves in the home list: you can sort and group the cave list by
  surface area, and the area title is shown in grey under each cave
  title.
- Narrows the filter box: typing an area name in the cave list filter
  leaves only the caves in that area.
- Supplies the **area segment** of every structured place code generated
  for the caves inside it.
- Gives you a place to run code generation for a whole region at once,
  and to pre-print entrance labels for caves you have not recorded yet.

Surface areas are **optional** for browsing and organising caves — you
can run the app without creating a single one. They stop being optional
once you use structured place codes:

- The **Per-area sequential** strategy skips a cave that has no surface
  area during batch generation, and refuses to accept a code you type by
  hand for it (**This cave has no surface area assigned**).
- The **Global hierarchical** strategy does not skip such a cave; it
  substitutes a placeholder area segment instead — all zeros when the
  cave has no surface area, all nines when the area exists but has no
  general area identifier. The **Generation summary** at the end of a
  batch lists how many caves and places got each placeholder. Those codes
  will not line up with the rest of your dataset.

## Fields

| Field | Notes |
|---|---|
| **Enter surface area title** | Required, and unique across the whole database — two areas cannot share a title. |
| **General area identifier** | The short code (for example `07`) that the Global hierarchical strategy splices into the place code of every cave under this area. |
| **Description** | Free text. Shown in small grey type under the title in the surface areas list. |

The identifier is inserted into a place code **exactly as you type it** —
it is not zero-padded for you. If **Settings → Place code identifiers →
General area identifier width** is 3, type `007`, not `7`, or your codes
will come out a digit short. Leave the identifier empty only if you are
not using structured place codes.

Set the identifier **before** you generate codes for any cave in the
area. Changing it afterwards changes the codes generated from then on,
which invalidates labels you have already printed.

## Opening the surface areas screen

There are three ways in, all leading to the same **Manage surface areas**
screen:

- **Home → ⋮ → Manage surface areas**.
- The landscape icon in the home screen's action toolbar. That toolbar is
  shown by default and is hidden or brought back with the **Hide action
  toolbar** / **Show action toolbar** button in the cave-list header.
- The landscape icon next to the **Area title (optional)** dropdown on
  the **Add new cave** / **Edit cave** form. This is the useful one while
  you are entering a cave: when you come back, the dropdown has been
  reloaded and the area you just created can be picked straight away.

> 📷 [Managing surface areas](../screenshots/01-home-and-caves.md#surface-areas-list) — The surface areas list, where regions that group caves are created and edited.

Each row in the list shows the area title with its description
underneath, and carries its own icons at the right-hand end: a QR icon
(**Generate entrance QR codes (range)**), a pencil (edit) and a bin
(delete), plus a wand icon when generate icons are switched on.

## Adding, editing and deleting areas

### Add an area

1. Tap the **+** icon in the top bar.
2. Fill **Enter surface area title**, and — if you use structured place
   codes — **General area identifier**.
3. Add a **Description** if you want one.
4. Tap **Save**. A *Surface area saved* message confirms it.

If you leave the title empty, **Save** does nothing. The same happens if
the title is already taken by another area: the dialog simply stays open,
so change the title and save again.

### Edit an area

Tap the **pencil** icon at the right-hand end of the row. Tapping the row
itself does nothing. The dialog is the same three fields, pre-filled,
plus a **Generate codes** button (see below).

### Delete an area

Tap the **bin** icon and confirm. Deleting an area cannot be undone — the
area is removed from the database, not archived, and the removal travels
to other devices at the next sync.

An area can only be deleted once **no cave is still assigned to it**.
Assign those caves elsewhere first, or set their **Area title (optional)**
back to *None*. Deleting an area that is still in use currently fails
without telling you: the confirmation closes, no message appears, and the
area is still in the list. If that happens, that is why.

Deleting an area never deletes the caves in it.

> Note: the confirmation text on this screen reads *"This will delete the
> cave area. Are you sure?"*. It is the wording of the cave-area dialog
> being reused; you are deleting the surface area you tapped.

## Assigning a cave to a surface area

When **creating** a cave — **Home → ⋮ → Add new cave**, or the add-cave
icon on the home screen — pick the area from the **Area title
(optional)** dropdown. The dropdown starts on **None**.

When **editing** a cave: tap the cave in the home list to open its places
list, then **⋮ → Edit cave**, and pick from the same dropdown.

> 📷 [Choosing a surface area for a cave](../screenshots/01-home-and-caves.md#cave-form-surface-area-picker) — Choosing the surface area a cave belongs to on the cave form.

Two things to know:

- A cave dropped on the **Cave map** with **New cave** is created with no
  surface area. Open it and edit the cave to assign one.
- The caves CSV import creates areas for you. Map a **Surface area**
  and/or a **General area identifier** column and any area named there
  that does not exist yet is created during the import; the result
  summary counts them under **Surface areas created**. Matching is
  case-insensitive, so "Padiș" and "padiș" land in the same area. An
  identifier in the file is also written onto an existing area of that
  title that has none — but an identifier that differs from the one
  already stored is never overwritten. See
  [CSV import](csv-import.md).

## Surface areas in the cave list

The cave list's sort button offers **Last modified** (the default, newest
first), **Title**, **Surface area** and **Number of cave places**.
Sorting by **Surface area** breaks the list into headings, one per area,
with the caves that have no area gathered under a **—** heading. Your
choice of sort is remembered between sessions. See
[Lists: filter, sort and select](lists-filter-sort-select.md).

## Generating place codes for a whole area

The surface areas screen can generate place codes for every cave place in
every cave under one area, in a single run. Two ways in:

- Open the area with the **pencil** icon and tap **Generate codes** in
  the dialog.
- Turn on **⋮ → Show generate icons**, which adds a **wand** icon to
  every row, and tap the wand on the area you want. The toggle is off
  again every time you open the screen, so the row icons are hidden by
  default.

Either way the run goes:

1. A confirmation — *Generate place codes for every cave place under this
   surface area?* — with **Cancel** and **Generate codes**.
2. A progress dialog while the batch runs.
3. Whenever a place already has a code that differs from the newly
   computed one, an **Overwrite existing value?** prompt showing the
   existing and the new value, with **Keep**, **Keep all**, **Replace**,
   **Replace all** and **Cancel batch**.
4. A **Generation summary**: how many places were updated, skipped,
   refused, how many existing codes were overwritten, how long it took,
   and which caves fell back to a zeros or nines area segment.

This writes to the database. Codes that were already printed on labels
stop matching if you replace them, so use **Keep** unless you mean to
re-label.

The same batch tool is available scoped to a single cave, from the
**Edit cave** screen's **⋮ → Generate codes**.

## Generate entrance QR codes (range)

The QR icon on every area row pre-prints main-entrance labels for caves
that do not exist in the app yet — useful before a survey trip, when you
know you will be tagging a run of new entrances in the field.

1. Tap the QR icon on the area's row.
2. Enter **From index** and **To index** — the cave numbers you want
   labels for. Both must be 1 or more, the start must not be past the
   end, and a single run is limited to 500 codes.
3. Tap **OK**.

The app composes a main-entrance code for every number in that range that
has no cave recorded against it yet, tells you how many it skipped
because they are already taken, and opens the **Generated QR Codes**
screen so you can export and print the sheet. Two areas that share the
same general area identifier share one pool of cave numbers, so a number
used in either counts as taken.

**Nothing is written to the database.** These codes are composed on the
fly; the caves themselves are still to be created, and each will pick up
the matching code once you record it with the same **Cave local index**.

This tool needs the **Global hierarchical** strategy with **Country code**
and **Organization code** filled in under **Settings → Place code
identifiers**. With any other strategy it says *Range pre-generation is
available only with the hierarchical place-code strategy*; with the codes
missing it says *Set the country and organization codes in place-code
settings first*. If every number in the range is already taken, it says
so instead of opening an empty sheet.

## Surface area vs cave area

- A **surface area** is on the surface and groups **caves**. It lives in
  **Manage surface areas** and is shared by the whole database.
- A **cave area** is underground and groups **cave places** inside one
  cave. It lives on the **Cave areas** screen inside that cave.

The two are independent and can be used together. See
[Caves and cave areas](caves-and-areas.md).

## See also

- [Caves and cave areas](caves-and-areas.md)
- [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
- [Home screen](home-screen.md)
- [Lists: filter, sort and select](lists-filter-sort-select.md)
- [CSV import](csv-import.md)
- [QR codes](qr-codes.md)
