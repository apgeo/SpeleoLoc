# CSV import

[← Back to index](../README.md)

When your data already lives in a spreadsheet, SpeleoLoc can read it in
bulk from a CSV file. There are two separate imports — one that creates
caves, one that fills a single cave with places — and they share the
same file-picking and column-mapping screen.

Control names on this page are the English ones. The app starts in
Romanian; English is chosen in **Settings → General → App language**.

## The two imports

| Import | Where you start it | What it writes |
|---|---|---|
| Caves | **Home → ⋮ → Import caves - CSV** | Caves, and the surface areas they sit in |
| Cave places | Open a cave, then **⋮ → Import places from CSV** | Places inside that one cave |

Both also have a one-tap upload icon: on the home toolbar (the row of
icon buttons under the app bar, switched with **Settings → General →
Show home toolbar**) and on the toolbar of a cave's places list. The
icons open exactly the same screens as the menu entries.

The places import always works on the cave you opened it from — there
is no way to spread one file over several caves. To fill several
caves, import each cave's file from inside that cave; if the caves do
not exist yet, create them first with the caves import.

## File format

- Plain text saved as **UTF-8**, with the extension `.csv` or `.txt` —
  the file chooser offers nothing else, and a file saved in another
  encoding fails to load with an error message.
- The first row must be a **header row** with column names. The names
  themselves do not matter: you always pick which column feeds which
  field from a dropdown.
- **Comma separated.** Semicolon-separated files, which many European
  spreadsheet settings produce by default, load as a single column, with
  nothing to map the individual fields onto — re-export with commas.
- Values that contain a comma or a line break must be wrapped in
  double quotes.
- Windows and Unix line endings both work.
- Columns you do not map are ignored. Extra columns such as depth or
  survey references do no harm, but nothing in them is imported.

An empty file is refused with "The selected CSV file is empty."

## The import screen

Both imports open the same screen, and the steps are always these:

1. Tap **Select CSV File** and pick the file. Its name appears next to
   the button.
2. The **Column mappings** section appears, headed by **Data rows
   found** — the number of lines after the header, including any the
   import will later drop.
3. Set one dropdown per field. Each dropdown lists your file's header
   names plus **None**. Fields marked with `*` are required.
4. Check the **Data preview** table under the button: the first ten
   data rows, exactly as the file was read, scrolling sideways if the
   file is wide. Use it to confirm the separator and the header row
   were understood before you import anything.
5. Tap **Start import**. If a required field is still unmapped, a
   message names it ("Cave name column must be selected.") and nothing
   happens.

The first time you open this screen a short guided walkthrough points
out the file picker, the column mappings and the preview. It only
shows the parts that are on screen at the time, so run it again from
**⋮ → Help tour** after loading a file to see the mapping and preview
steps.

## Importing caves

### Columns you can map

| Field | Required | What it does |
|---|---|---|
| **Cave name** | Yes | The cave's name. Also half of every duplicate check. |
| **Description** | No | Free text stored on the cave. |
| **Cave local index** | No | The cave's short catalogue number. Also a matching key — see below. |
| **Surface area** | No | The area the cave sits in. An area of that name is created if you do not have one yet. |
| **General area identifier** | No | The area's short code. |

There is no cave-area column here, and no CSV import creates cave
areas — add those on the place itself.

### How the surface area is chosen

If one of your [surface areas](surface-areas.md) already carries the
code in **General area identifier**, that area is used whatever it is
called, so you can rename areas in the app without breaking later
imports. Otherwise the area named in **Surface area** is used, and the
code is written onto it if it had none; an area that already carries a
different code is never overwritten. If you map only the identifier
column and no name column, a new area is created named after the code.
Capitalisation is ignored when codes and area names are compared.

### How rows are matched against caves you already have

A row counts as a cave you already have when the cave name plus the
cave local index match, or when the cave name plus the surface area
match. Capitalisation is ignored throughout. A row naming a surface
area you do not have yet counts as a new cave, unless the cave name and
cave local index match a cave you already have.

This makes the two optional key columns worth mapping:

- **With a cave local index**, a row is recognised as the same cave
  even if it is filed under a different area. This is the reliable way
  to update a catalogue you have already imported once.
- **Without one**, matching falls back to name plus area, and a
  mismatch there produces a second copy of the cave: a file with no
  area column does not recognise caves that are stored in an area, and
  a file that moves a cave to another area does not recognise it
  either.

### The questions the import asks

First, if any rows matched, an **Existing entries found** dialog
reports "Matching entries already in database" with the count, lists
the first five and asks whether to continue. **Cancel** abandons the
whole import.

Then, for every matched cave whose stored values differ from the file,
an **Update existing cave** dialog appears, numbered (for example
3/12) so you can see how many are left. It lists each field that would
change as "old → new" — Description, Cave local index and Surface
area — and offers four buttons:

- **Update** — apply the file's values to this cave.
- **Skip** — leave this cave as it is; it is counted under Caves
  skipped (duplicates).
- **Update all** / **Skip all** — answer every remaining cave the same
  way.

The dialog cannot be dismissed by tapping outside it, so nothing is
decided by accident.

Approving an update can also move the cave into the surface area named
in the file, and the move is listed like any other change. One case is
left alone on purpose: if a different cave with the same name already
sits in the target area, the move is dropped so the two cannot
collide, and the remaining fields are still applied.

### Every cave the import touches gets an entrance

Unless you turn it off, each cave the import creates is given a main
entrance place called **Entrance** — the same default you get when
adding a cave by hand. Caves the file matched are given one too if
they have none, even when you chose to skip updating them. The switch
is **Settings → General → Auto-add entrance when creating cave**, which
is on by default. Turn it off before importing if you plan to add
entrances yourself, or you will have an extra place to clean up in
every cave.

### Repeated rows for the same cave

If your file lists the same cave more than once, the first row creates
it and later rows quietly apply any description or cave local index
they carry — filling in what the first row left blank, and replacing a
value that disagrees. You are not asked about these, because the cave
was created by this same import; they are counted under Caves updated.
Rows matching a cave that was already in the database go through the
update question instead.

### What the summary reports

An **Import complete** dialog ends the run with four counters:

- **Caves created**
- **Caves updated**
- **Surface areas created**
- **Caves skipped (duplicates)**

## Importing cave places

Open the cave, then **⋮ → Import places from CSV** on its places list.
Every row goes into that cave.

### Columns you can map

| Field | Required | What it does |
|---|---|---|
| **Cave place name** | Yes | The place's name. |
| **QR code** | No | Becomes the place's [place code](place-code-identifiers.md). |

Descriptions, depths, coordinates and cave areas cannot be imported
this way — add them on the place afterwards.

A code brought in by the import is immediately turned into the
matching QR payload, so the places are ready to print, scan and open
by [deep link](deep-links.md) straight away. You do not need to run a
code generation pass over them.

### How rows are matched against places you already have

A row whose name is exactly the name of a place in this cave counts as
that place; every other row creates a new place. The match is exact,
capitalisation included.

The warning dialog counts matches differently: it ignores
capitalisation. So "Sump" and "sump" are reported as one existing
place and then imported as two.

### The questions the import asks

**Existing entries found** lists the places in this cave whose names a
row already matches, with the code each of them currently holds, and
asks whether to continue. Continuing imports the new rows and leaves
the existing places where they are — though their code can still be
replaced by the next question.

**QR code conflicts** appears when you mapped the QR code column and
some place in the database already holds one of the codes in the file.
It lists the code, the place holding it and that place's cave, then
asks "Do you want to overwrite existing QR codes?":

- **Skip QR updates** — places you already have keep the code they
  have. This only protects existing places: a row that creates a new
  place is given the code from the file whichever button you press.
- **Overwrite QR codes** — when a row matches a place that already
  exists in this cave, that place's code is replaced by the one in the
  file. The place that previously carried that code is left alone, so
  afterwards two places can hold the same code — check the ones the
  dialog listed.

The conflict check does not exclude the very places you are
re-importing, so importing the same file a second time raises this
dialog even though nothing has changed.

### Two cases that stop the import

Both leave your data untouched, show an error message and close the
screen:

- The cave already holds two places with exactly the same name
  (possible when they sit in different cave areas).
- Two places in the database already hold the same code as a row in
  the file.

### What the summary reports

The **Import complete** dialog reports:

- **Cave areas created** — always 0 here, since this import has no
  cave area column.
- **Cave places created**
- **QR codes updated** — codes replaced on places you already had, not
  codes given to new places.

## Nothing is written until every question is answered

Every warning comes before any data is written, and the import itself
runs as a single operation. Pressing **Cancel** at the existing-entries
dialog or at the QR conflict dialog abandons the whole import and
leaves your database exactly as it was. That makes it safe to start an
import just to see what it would report. (The per-cave update question
has no Cancel: it only decides that one cave, and backing out of it
counts as **Skip**.)

Once you do let it run, the import is not undoable — there is no undo
button and no "revert last import". Take a
[database export](database-export-import.md) first if the file is
large or you are unsure of it.

## Rows that are dropped without comment

A row with no cave name (caves import) or no place name (places
import) is skipped silently and appears in no counter, so blank
trailing lines from a spreadsheet export are harmless. If every row is
dropped you get "No valid rows found in the CSV file." and the screen
closes without doing anything.

## Tips

- Keep a **trial file** of three to five rows to check your column
  mapping before committing a full import.
- Map **Cave local index** if you expect to import the same catalogue
  again later; it is what makes the second import an update instead of
  a duplicate.
- After importing places, open the cave's places list and the raster
  maps for a quick visual check.

## See also

- [Caves and cave areas](caves-and-areas.md)
- [Cave places](cave-places.md)
- [Surface areas](surface-areas.md)
- [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
- [QR codes — placing, scanning, printing](qr-codes.md)
- [Database export, import and backup](database-export-import.md)
