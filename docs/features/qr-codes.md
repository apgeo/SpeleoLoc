# QR codes — placing, scanning, printing

[← Back to index](../README.md)

QR labels are the physical bridge between the real cave and the data in
SpeleoLoc: you print them on the surface, glue them to the rock, and
scan them underground to know exactly where you are.

## What a printed label contains

By default the pixels encode `sp://` followed by the place's QR code
resource identifier — for example `sp://k3f9x2`. `sp://` is
SpeleoLoc's own link scheme: on Android the system offers SpeleoLoc as
the app to open such a link with, while on iOS nothing claims it. A
phone without SpeleoLoc gets nothing usable from an `sp://` label
either way.

Two settings change what gets printed. Neither one changes the
identifier stored in your database.

- Turning off **Settings → QR Code Generation → Include deep link
  prefix** prints the bare identifier with no prefix — useful when the
  same labels are also read by another system.
- Filling in **Landing address for printed labels**, on the same
  settings page, prints that address followed by the identifier
  (`https://speo.example.org/q/k3f9x2`), which any phone's camera can
  open in a browser. A landing address wins over the deep link prefix:
  while one is set, the **Include deep link prefix** switch is greyed
  out.

The app's own scanner reads all three forms.

Underneath the code, the app prints a short line of text built from
the **QR code label template**, which by default is the place title
and its depth (`@place_title, @depth`). The human-readable place code is
*not* printed unless you add `@place_code_identifier` to that template
yourself. See
[Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
for what the two identifiers are and how to choose between them.

## Scanning a code

### Where the scan button is

| Where | Button |
|---|---|
| Home screen | **Scan QR** in the top bar — or the first button of the action toolbar, when **Show action toolbar** is switched on |
| A cave's places list | **Scan QR**, first button of the toolbar across the top |
| The app menu | **Scan** |
| Cave place form | the scanner button on the **QR code resource identifier** row — this one *fills the field*, it does not navigate |

The scanner is a plain camera view titled **Scan QR** with a flash
button in its top bar that switches the phone's torch on and off
without leaving the camera. Underground the torch is usually what
makes a muddy or low-contrast label readable — but it drains the
battery quickly, so switch it off again. The scanner closes by itself
the moment a code is detected.

### What the app does with what it read

The payload is cleaned up before anything is looked up:

- an `sp://` prefix is always removed;
- a plain `http://` or `https://` address is reduced to the part after
  its last `/` or `=`, so a label printed by another system as
  `https://example.org/cave/ABC12` still resolves to `ABC12`.

That URL handling is configurable under **Settings → QR Code
Generation → QR scan settings**: **Strip URL to identifier** turns it
off entirely, and **URL delimiter characters** changes which
characters are used to find the split point.

What is left is matched against **both** the QR code resource
identifier and the place code identifier of your cave places,
ignoring upper/lower case. That is what makes the human-readable code
written beside a label in marker useful: type it into the manual
search and it resolves just as well as the scan would have.

Then:

- **One matching cave place** → the app opens that place **on the
  first raster map that has a point for it**, so you immediately see
  where you are on the survey. If no map carries a point for that
  place, the message "No map has a point defined for this cave place"
  appears and the cave place form opens instead. Either way a
  confirmation follows — "Cave place has been identified" plus the
  place title.
- **Matches in more than one cave** → a **Choose point / cave** dialog
  lists every match with its cave so you can pick the right one; it
  also offers an **Open Settings** shortcut beside **Cancel**. Turning
  off **Settings → General → Ask which cave on ambiguous QR scan**
  replaces the dialog with a silent choice of the match from the last
  cave you opened. A scan started from inside a cave's places list
  only ever searches that cave, so the chooser never appears there.
- **No match** → the brief message "Cave place not found" with the
  code that was read.
- **Nothing left after the clean-up above** → the brief message
  "Invalid QR code (not parsable per rules)".

Those last two are short on-screen messages, not dialogs — the
scanner has already closed by the time they appear.

### Scanning an entrance starts, stops or switches your trip

Entrance labels behave differently from every other label, and this is
the quickest way to run a [trip](trips.md) without touching menus.

- **No trip running** — the app asks "You scanned a cave entrance.
  Would you like to start a new trip?" Answer **Yes** and a **Start a
  new trip** dialog appears with a **Trip title** already filled in
  (the cave name plus today's date); edit it or press **OK**.
- **A trip is running for this cave** — the app asks "You scanned a
  cave entrance. Are you exiting the cave? Stop the active trip?"
  **Yes** stops it and confirms with "Trip stopped". **No** simply
  records the scan as another trip point.
- **A trip is running for a different cave** — the app names that cave
  and asks whether to stop its trip; if you agree, it then offers to
  start a new trip for the cave you are standing in.

While a trip is active, scanning any **ordinary** place in that same
cave silently records a trip point and confirms with "Point added to
trip" — so your route through the cave builds itself as you scan.

### Typing a code instead of scanning

When a label is damaged, or the camera will not focus on a wet
surface, you can enter the code by hand:

1. Open the cave's places list and tap **Manual QR code search** in its
   toolbar.
2. A small search panel opens on the page; type the code into **QR code
   identifier**.
3. Press **Search place by QR code id**.

From that point on the app behaves exactly as if you had scanned the
label. Because the panel stays open, it is the convenient one when you
are working through several hand-written codes in a row.

Developer builds add a shortcut the released app does not have: press
and hold the scan button for about two and a half seconds — on the home
screen, on a cave's places list, or on the scan button of the cave place
form — and the same **Manual QR code search** opens as a dialog. In the
released app that long press does nothing.

### Camera permission

The first time you scan, the phone asks for camera permission. If you
have permanently denied it, the scanner will not open: a **Permission
required** dialog explains this and offers **Open Settings**, which
takes you to the app's system settings so you can grant it. A refusal
that is not permanent produces only the message "Camera permission
denied". Grant this on the surface, before you are underground.

## Printing labels

### For one cave

1. Open the cave's **places list** and tap the printer button
   (**Print QR codes**) in the toolbar across the top. If you have
   ticked individual places in the list first, only those get a
   label; otherwise every place in the cave does.
2. The **Generated QR Codes** screen opens and builds the file
   straight away. In PDF mode the finished A4 sheet is shown right
   there — scroll and pinch to check that the labels are the size you
   want. In Images mode there is nothing to preview and the screen
   reads "No generated files"; exporting still works.
3. The toolbar of that screen carries **Regenerate PDF** plus
   shortcuts to **QR Generation Settings** and **PDF Output
   Settings** — coming back from either one rebuilds the sheet with
   your changes.
4. Tap **Export** at the bottom right and choose where to put the
   file. A PDF is offered as `cave_places_qr.pdf`; images always
   arrive as a single `qr_codes.zip` holding one PNG per label, each
   named after its place.

> 📷 [Previewing generated QR labels](../screenshots/04-places-and-qr-codes.md#qr-labels-pdf-preview) — Preview of the generated QR label sheet before exporting it.

Whether you get a PDF or images is decided beforehand, not on this
screen: **Settings → QR Code Generation → QR output** offers **PDF**
(a multi-page grid sheet) or **Images** (one PNG per label).

### For several caves at once

The home screen's cave list has a **Generate QR codes for caves**
button that produces one printable sheet covering several caves. It
uses the caves you have ticked, or — if none are ticked — every cave
currently left visible by your filter. When any of those caves holds
places that are not entrances, SpeleoLoc asks whether to generate
**Entrances only** or **All places**, which is the quick way to make a
set of entrance markers for a whole karst area. Each label is
attributed to its own cave, so `@cave_title` in the template prints
the right name for every code.

### For places that do not exist yet

You can print labels for places you have not surveyed, carry the strip
underground and attach them as you go.

- On a cave's places list, **Generate cave place QR codes (range)**
  asks for a **From index** / **To index** range and composes the
  codes those places *would* receive.
- On a surface area, **Generate entrance QR codes (range)** does the
  same for cave entrances, for numbering caves you have not recorded
  yet.

Either way the codes are handed straight to the **Generated QR
Codes** screen for printing; nothing is written to your database.
Indices that already belong to a real cave or place are skipped and
the app reports how many, and at most 500 codes are produced in one
go. This needs the hierarchical place-code strategy with the country
and organization codes already set — and, for places, a cave that has
a local index. If one of those is missing the app says which.

## Settings that shape the printed label

> 📷 [QR generation settings](../screenshots/04-places-and-qr-codes.md#settings-qr-generation) — Settings that control how QR labels are rendered and scanned.

Everything below lives under **Settings → QR Code Generation**, except
the grid, which is under **Settings → PDF Output**.

| Setting | What it does |
|---|---|
| **QR output** | **PDF** (grid sheet) or **Images** (one PNG per label). |
| **QR size (px)** | Size of a generated PNG code. In a PDF each code is fitted to its grid cell instead. |
| **QR image padding (px)** | White margin around a generated PNG code. |
| **Label font size** | Used as typed for PNG labels. In the PDF, parts of the template that carry no `#fz` size of their own are drawn at half this value, capped between 6 and 14 pt. |
| **Label font family** | Shown, but currently changes nothing — PDF labels are always set in the app's bundled font so Romanian diacritics print correctly. |
| **QR foreground color** | The colour of the code's modules, on sheets and on images alike. Type a `0xAARRGGBB` value or tap the swatch beside it to **Pick colour** from a palette or colour wheel. |
| **QR background color** | Affects only the single-place QR preview and the image you export from that preview. Batch PDFs and PNGs are always produced on white. |
| **DPI (quality)** | Shown, but currently changes nothing in the output. |
| **Error correction** | **L**, **M** (default), **Q** or **H** — how much of a damaged code can still be read. Applies to PDF, images and preview. |
| **Export images as zip** | Has no effect on the **Generated QR Codes** screen, which always exports images as one ZIP. |
| **Include deep link prefix** | On by default: the code carries `sp://` plus the identifier. Off: the bare identifier. Greyed out while a landing address is set. |
| **Landing address for printed labels** | Empty by default. Set it and the code carries that address plus the identifier instead of `sp://`, so a stranger's camera can open it in a browser. |
| **PDF QR code padding (pt)** | **Horizontal padding** and **Vertical padding** around each code inside its grid cell — this is what decides how big a code is printed. |
| **QR codes per page** (PDF Output) | **Columns** (1–10) × **Rows** (1–20) on an A4 page. 4 × 5 by default. |

QR modules and the three corner markers are always printed as sharp
squares; there is no shape option to choose.

### The label template

The text under each printed code is built from **QR code label
template** at the bottom of the QR Code Generation page. Tapping any
of the variables listed under **Available variables** inserts it at
the cursor.

| Variable | Meaning |
|---|---|
| `@place_title` | Cave place title |
| `@description` | Cave place description |
| `@cave_title` | Cave title |
| `@area_title` | Cave area title |
| `@place_code_identifier` | Place code identifier (PCI) |
| `@qr_res_identifier` | QR code resource identifier (QCRI) |
| `@depth` | Depth in cave, always with a `+` or `-` sign |
| `\n` | Line break |

Formatting prefixes go immediately before the variable they apply to:

- `#fz<number>` — font size, e.g. `#fz14@place_title`.
- `#fc<color>` — font colour as a hex triplet, e.g. `#fcFF0000@depth`.

Example template:

```
#fz14@place_title\n#fz10#fc888888@depth\n#fz9@place_code_identifier
```

A variable that resolves to nothing leaves no stray comma or dash
behind — empty lines and leftover separators are trimmed
automatically.

## Checking a single code before you print a batch

Open a saved cave place and tap the QR button at the far left of the
**QR code resource identifier** row (**View QR code**). The dialog
encodes the same payload a printed label would, at the same error
correction level, with the place title under it and the identifier
below that. The button appears only once the place has been saved and
has a code.

Two buttons at the bottom of that dialog are worth knowing:

- The information button opens **QR Code Info**, which reports the QR
  **Version**, the module grid **Size** (for example 33×33), the
  **Error correction** level in words (Low / Medium / Quartile /
  High) and the exact **Payload** that is encoded — including the
  `sp://` prefix, or the landing address, when one is in use.
  **Copy value** puts that payload on the clipboard. The more modules
  a code has, the larger the label
  must be printed to stay readable by headlamp, so this is the
  cheapest way to judge a label size before committing a batch to
  waterproof paper.
- The download button exports that one code as `qr_<place title>.png`
  — useful for spot-replacing a damaged label without reprinting the
  whole batch. SpeleoLoc first asks whether to
  **Save to Pictures**, showing the exact folder it will use, or to
  **Choose location…**. This single image carries the place's title
  under the code, not the batch label template.

## Assigning a code to a place

A cave place form carries two rows: **Place code identifier** and
**QR code resource identifier**. Each has its own padlock, its own
sparkle **Auto-generate** button, and both open **locked** every time
— so an existing code cannot be changed by accident.

1. Tap the padlock left of the field (**Enable QR edit**) to make it
   editable. The Auto-generate button beside it stays greyed out
   until you do.
2. Type the code, or tap **Auto-generate** to compute one with the
   active [strategy](place-code-identifiers.md).
3. Save.

When the QR code resource identifier mirrors the place code and the
two values are identical, the **Place code identifier** row is hidden
altogether; tap the eye button (**Show place code identifier**) on the
cave-area row just above to bring it back.

The scan button on the **QR code resource identifier** row reads an
existing label into that field rather than navigating anywhere. It
fills the place code as well when the two mirror each other and the
place code is still empty. Afterwards the QR preview opens by itself
so you can check what was read. Three things can interrupt it:

- the same code is already in the field → "The same QR code is
  already present";
- the code belongs to another place → "QR code already used for",
  naming that place, and nothing is filled in;
- the field already holds a *different* code → **Replace QR code?**
  asks "A different QR code is already set for this place. Do you
  want to replace it?" This replaces only the value in the field in
  front of you; no other place is touched.

### Duplicate codes on save

Saving a place whose **place code** is already used by another place
**in the same cave** shows a **Duplicate QR code** dialog reading
'Cave place "…" already uses QR code …. Save with duplicate?' with
**Cancel** (nothing is saved) and **Yes** (the duplicate is kept).
If you edited the **QR code resource identifier** by hand and it
collides with a place in *any* cave, the same dialog appears. In
neither case is the other place changed.

Duplicates across different caves are allowed and are what the
**Choose point / cave** dialog exists for.

## Mounting labels in the cave

- Print on **waterproof label material**, or laminate.
- Use error correction **M** or **Q** so partial smudging stays
  readable. **H** survives more damage but needs more modules, which
  means a physically bigger label.
- Keep **dark modules on white** — the default, and the easiest for a
  camera to recognise under torchlight.
- Attach to clean, dry rock where you can; avoid muddy or flaking
  surfaces.
- Write the **place code** beside the label in permanent marker as a
  fallback. The app accepts it in the manual search even though the
  QR pixels carry the other identifier.
- Before a big print run, define the raster-map points for the places
  you are labelling — a scan that finds no point on any map opens the
  plain place form instead of showing you where you are.

## See also

- [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
- [Cave places](cave-places.md)
- [Deep links (`sp://`)](deep-links.md)
- [Trips — recording your route](trips.md)
- [Navigating underground](../workflows/navigating-underground.md)
- [Settings](settings.md)
