# Documenting a new cave

[← Back to index](../README.md)

Everything it takes to turn a fresh survey into a cave your team can
navigate underground: the cave record, its maps and places, the printed
QR labels, and the first archive you hand around. Most of this is done
once per cave — afterwards you only add to it.

## What you will need

- One or more **scanned survey drawings** as pictures in your phone's
  photo library — the picker offers pictures and nothing else, so a PDF
  has to be saved as an image first. They become the cave's
  [raster maps](../features/raster-maps.md).
- A list of the **points you want to label** — chambers, junctions,
  squeezes, sumps, rigging points.
- A printer (or a print shop) and **waterproof, durable label
  material**. Plain paper does not survive a cave.
- *(Optional)* **BLE tags** for the points you want recognised
  hands-free. SpeleoLoc reads two families: iBeacon-type tags of the
  HoneyComm BP1003 family — as shipped they broadcast the factory
  proximity UUID `FDA50693-A4E2-4FB1-AFCF-C6EB07647825` — and Ruuvi
  tags, which also report temperature and humidity, plus pressure on
  the models that carry that sensor. Budget one tag per point, and plan
  to register every tag on site, standing next to it (step 10).

The app starts in Romanian. Every label quoted below is the English
wording, which you pick in **Settings → General → App language**.

Two decisions are far cheaper to make before the cave exists than
after: the numbering scheme (step 1) and the surface area the cave
belongs to (step 2). Both feed the codes that end up printed on the
labels, and changing them later means reissuing codes and reprinting.

## Step 1 — Choose how places will be numbered

Open **Settings → Place code identifiers** and, on the **Strategy**
tab, pick one:

| Strategy | Code shape | What it needs first |
|---|---|---|
| **Global hierarchical** | country + organization + area + cave + place segments | **Country code** and **Organization code** on this page — nothing is generated without them. A cave with no surface area gets an all-zero area segment, and a surface area with no **General area identifier** an all-nine one |
| **Per-cave sequential** | a counter unique inside each cave | **Start at**, **Step**, **Zero-pad width** |
| **Per-area sequential** | a counter unique across a surface area | the same three, and a surface area on every cave |

Tap **More info** to read the full rules of the selected strategy.
Under the hierarchical strategy, the **Segment separator** you type is
checked as you type: a `/` or an `=` in it truncates every code printed
afterwards when it is scanned back, and the field says so.

The **QR code res. ids** tab decides what the printed square actually
carries: **Mirror PCI** prints the place code itself, **Hashed** prints
a short hash of it, so a found label gives nothing away.

You are only setting rules here — codes are handed out in step 8. See
[Place codes (PCI) and QR payloads (QCRI)](../features/place-code-identifiers.md).

## Step 2 — Create the surface area (optional)

Worth doing if you group caves by region, and required if you chose the
per-area scheme, which skips every cave that has no surface area.

1. **Home → ⋮ → Manage surface areas**.
2. Press **Add surface area**.
3. Fill in **Enter surface area title**, the **General area identifier**
   (the area segment of hierarchical codes) and an optional
   **Description**.
4. **Save**.

See [Surface areas](../features/surface-areas.md).

## Step 3 — Create the cave

Two routes. Use the map one when you are standing at the entrance.

### From the home screen

1. Tap **Add new cave** — the **+** in the top bar, or the same entry
   in the **⋮** menu.
2. Fill in **Cave title**, an optional **Description**, the surface area
   under **Area title (optional)**, and **Cave local index** if you use
   hierarchical codes.
3. Tap **Add**.

Unless you turned off **Settings → General → Auto-add entrance when
creating cave**, the new cave already contains one place, named
**Entrance** and flagged as both **Cave entrance** and **Main cave
entrance**.

### From the surface map, standing at the entrance

1. Open **Cave map** from the home screen.
2. Press **Add point**, then **New cave** ("Create a cave with an
   entrance at this point").
3. Set the point: tap the map, long-press it, or press **Use my
   location**, which starts an averaged GPS capture — the pin follows
   the running mean as fixes arrive. Press it again to stop averaging.
4. Press **Confirm**, then give the **Cave title** and the **Entrance
   name**, and tap **Add**.

> 📷 [Placing the point for a new cave](../screenshots/02-cave-map.md#cave-map-new-cave-placement) — Placing the entrance point for a new cave on the surface map.

The first entrance of a cave automatically becomes its main entrance. A
cave made this way has coordinates straight away but no surface area,
so open it and use **Edit cave** to set one before you generate codes.
The **Cave local index** is allocated for you the first time codes are
generated, if you have not typed one yourself.

See [Caves and cave areas](../features/caves-and-areas.md) and
[Surface map](../features/surface-map.md).

## Step 4 — Add the survey drawings

1. Open the cave and press **View raster maps** in its toolbar.
2. Press **Add raster map**.
3. Give it a **Title**, press **Select image** and pick the file, then
   choose the **Map type**: *plane view*, *projected profile*,
   *extended profile* or *Other*.
4. **Save**, and repeat for every drawing.

Two titles of the same type cannot repeat inside one cave. If you pick
an image that another map already uses, the app names that map and asks
whether to **Save anyway**. **Reorder maps** lets you drag the list into
the order you want to page through underground.

See [Raster maps](../features/raster-maps.md).

## Step 5 — Divide the cave into areas (optional)

1. In the cave's toolbar, press **Cave areas**.
2. Press **Add cave area**, type the name in **Enter area title**, then
   **Save**.

Each place can carry one area ("Entrance series", "Main gallery",
"Lower level"). Areas are what you later filter and sort the places
list by, and the area name can be printed on the labels.

## Step 6 — Create the cave places

Four ways in; mix them freely.

### One at a time

1. Press **Add place** in the cave's toolbar.
2. Fill in **Title**, **Description**, **Depth '+/-'** (relative to the
   entrance; a value beyond ±1800 asks for confirmation and beyond
   ±5000 is refused), and the area under **Area title (optional)**.
3. Add **Place code identifier** and **QR code resource identifier**
   now, or leave them for step 8.
4. Use the **⋮ → Show/Hide GPS coordinates** entry to reveal
   **Latitude**, **Longitude** and **Altitude** if the place has a known
   position.
5. Switch on **Cave entrance** and **Main cave entrance** where they
   apply, then save with the save icon in the top bar.

If you name a place exactly *Entrance* and have not flagged it, saving
asks whether to mark it as a cave entrance; if it is an entrance and the
cave has no main entrance yet, it then asks whether to make it the main
one. See [Cave places](../features/cave-places.md).

### From a CSV list

1. Press **Import places from CSV** in the cave's toolbar.
2. **Select CSV File**. The file must have a header row.
3. Map the columns: **Cave place name** is required and **QR code** is
   optional. **Data rows found** and **Data preview** show what will be
   read.
4. Press **Start import**. Matching entries already in the database are
   listed before anything is written, and QR conflicts let you choose
   **Skip QR updates** or **Overwrite QR codes**. A summary reports how
   many cave places were created and how many QR codes were updated.

See [CSV import](../features/csv-import.md).

### By tapping on the survey drawing

1. Press **Place positions on map** in the cave's toolbar.
2. Press **Quick add cave place**. The icon turns green and the app
   tells you to tap the map.
3. Tap the drawing where the place is. A dialog asks for **Cave place
   title**, **Depth '+/-'**, **Cave area** and **Place code
   identifier** — the last with a **Scan** button if the label already
   exists.
4. **Save**. The place is created *and* its point on that map is
   already defined, so step 7 is done for this map.

### From a GPX or KML file

**Home → ⋮ → Import places (GPX/KML)**, pick the file, then choose the
cave it belongs to. Every waypoint becomes a place with coordinates;
duplicates are skipped and the counts are reported. See
[Exporting and importing places](../features/place-transfer.md).

## Step 7 — Pin every place on every map

A pinned place is what makes a later scan show a dot on the survey.

1. Press **Place positions on map** in the cave's toolbar.
2. Pick the place in the navigation bar, then tap the drawing where it
   is. The new point is a blue dot with an orange centre labelled
   **new**; if the place was already pinned here, the old position stays
   visible as a blue outline labelled **old**. Places already pinned on
   this map are red dots carrying their titles.
3. Press **Define place on map** (the save icon) to store the point.
   That also closes the editor, so use it for the last place of a
   session rather than for each one.
4. To pin many places in one go, simply move to the next place. The
   first time you do it with an unsaved point the app asks *"Save the
   current point automatically when switching to another place or
   map?"* — answer **Yes** and it keeps saving for the rest of the
   session.
5. **Next place without location** jumps straight to the next place
   with no point on *this* drawing, and its tooltip counts how many
   remain.

Other controls worth knowing: **Toggle legend** explains the colours
(**Current**, **New**, **Original**, **Existing**); **Reset point to
initial position** undoes an unsaved move; **Remove point definition**
deletes the pin for this place on this map, after a confirmation; the
tap-mode button switches between **Tap mode: Define new point** and
**Tap mode: Select existing place**.

Repeat for each drawing a place appears on — a station usually needs a
point on both the plane view and the profile. See
[Map viewer and point editor](../features/map-viewer.md).

## Step 8 — Give every place its code

The printed square encodes the place's QR code resource identifier, or
its place code if no QCRI was computed. A place with neither still gets
a label, but the square carries nothing to look up — so assign codes
before printing.

- **One place**: press **Auto-generate** beside **Place code
  identifier** (and beside **QR code resource identifier**) on the cave
  place page.
- **A whole cave**: press **Generate codes** in the cave's toolbar and
  confirm *"Generate place codes for every place in this cave?"*.
- **A whole surface area**: open **Manage surface areas**, edit the
  area, and press **Generate codes** there.
- **Everything**: **Settings → Place code identifiers → Generate codes
  for entire dataset**.

Places that already hold a value stop the batch with **Overwrite
existing value?**, showing the old and the new code and offering
**Replace**, **Keep**, **Replace all**, **Keep all** or **Cancel
batch**. When it finishes you get a summary of how many were updated,
skipped, refused or aborted. If you later change the QCRI mode, use
**Recompute all QCRIs** so the labels you are about to print agree with
the database.

## Step 9 — Print the QR labels

1. Set the output first. **Settings → QR Code Generation** holds
   **QR output:** (**PDF** or **Images**), the **QR size (px)**,
   colours, **DPI (quality)** and **Error correction**;
   **Settings → PDF Output** holds **QR codes per page**
   (**Columns**, **Rows**).
2. Write the text that prints under each square in **QR code label
   template**, further down that same **QR Code Generation** page, using
   the variables it lists: `@place_title`, `@description`,
   `@cave_title`, `@area_title`, `@place_code_identifier`,
   `@qr_res_identifier`, `@depth` and `\n` for a line break. Prefix a
   variable with `#fz` for a font size or `#fc` for a colour.
3. Decide what the square itself points at. Left empty, **Landing
   address for printed labels** prints an `sp://` square that only
   SpeleoLoc opens; set it to your club server's landing address and the
   square also opens on a stranger's phone while still resolving in the
   app.
4. In the cave's places list press **Print QR codes**. With selection
   mode on and places ticked, only those are printed; otherwise the
   whole cave is.
5. On the **Generated QR Codes** screen, **Regenerate PDF** re-renders
   after a settings change, and **Export** saves the result — one PDF,
   or, in *Images* mode, a zip of PNGs while **Export images as zip**
   is on.

Labels for places that do not exist yet: **Generate cave place QR codes
(range)** in the cave's toolbar composes codes for a range of place
indices (**From index** to **To index**, up to 500 at a time) without
writing anything to the database, so you can print a strip of blank-slate
labels and attach the codes to real places afterwards. It needs the
hierarchical strategy, the country and organization codes, and a cave
local index on the cave.

See [QR codes — placing, scanning, printing](../features/qr-codes.md).

## Step 10 — The trip that mounts the labels

Underground, glue or bolt each label at its point. If you are also
installing BLE tags, register them on the same trip — the app finds a
tag by listening for it, so you have to be next to it:

1. Open the cave place the tag belongs to.
2. In the **BLE beacons** section, press **Assign beacon**.
3. **Nearby beacons** lists what it hears, strongest signal first, with
   the tags already registered in this cave greyed out. Hold the phone
   against the tag you are installing and pick the top entry.
4. The place confirms *"Beacon assigned to this place"*.

On Android the device location switch must be on, or a Bluetooth scan
returns nothing at all; the app explains this before it opens the
picker. See [BLE beacons](../features/ble-beacons.md) and
[Ruuvi sensors](../features/ruuvi-sensors.md).

While you are there, scan each freshly mounted label once. A label that
opens the right place has been printed, coded and mounted correctly; a
label that opens nothing is much easier to fix on this trip than on the
next one.

## Step 11 — Attach the first documents

Baseline documentation makes the cave useful to someone who has never
been in it.

- **Per place**: open a cave place, press **Documents**, then use
  **New text document**, **New rich text**, **Take photo**, **Record
  audio** or **Add from file**.
- **In bulk**: **Home → ⋮ → Import cave documents**, then **Select
  directory**. Each subdirectory is matched to a cave by name, or by a
  leading `<area code>-<cave code>` token, or by hand; its files are
  attached to that cave. Files already present are skipped, and the
  summary counts imported, skipped and failed.

See [Documents](../features/documents.md).

## Step 12 — Hand the cave to the team

- Everyday sharing: **Settings → Man. sync → Archive sync → Export sync
  archive**, and let the others import it on the same screen. Newest
  edit wins, and deletions travel too.
- A whole new dataset, media included: **Settings → Data Export /
  Import**, tick **Include documentation files** and **Include raster
  map images**, then **Export Archive**. The receiving device uses
  **Import Archive** and picks **Merge with existing data** or
  **Replace all data** — replacing wipes what is already on that phone.
- Hands-off: point everyone at the same folder with
  [FTP sync](../features/ftp-sync.md) and let the app push and pull the
  archives.

The two archive kinds are not interchangeable; read
[Sharing data between teams](sharing-data.md) before the first exchange.

## Check your work

- The entrance shows on the surface map, labelled with the cave title,
  once it has coordinates.
- Every place you meant to label has a code, and the code is on the
  printed square.
- On each drawing, the **Next place without location** button has gone
  grey and reads *All cave places already have a location defined* —
  the count it shows is for the drawing you are looking at, so check
  each one.
- A scan of a mounted label opens the right cave place.

> 📷 [Decluttered entrance labels](../screenshots/02-cave-map.md#cave-map-decluttered-labels) — The surface map on OpenTopoMap, entrance waymarks labelled with their cave titles.

## See also

- [Navigating underground](navigating-underground.md)
- [Sharing data between teams](sharing-data.md)
- [Cave places](../features/cave-places.md)
- [Raster maps](../features/raster-maps.md)
- [QR codes — placing, scanning, printing](../features/qr-codes.md)
- [Place codes (PCI) and QR payloads (QCRI)](../features/place-code-identifiers.md)
