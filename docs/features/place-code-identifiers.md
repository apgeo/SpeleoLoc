# Place codes (PCI) and QR payloads (QCRI)

[← Back to index](../README.md)

Every [cave place](cave-places.md) can carry two codes: a readable
**place code identifier** that you print as text beside the label, and
a **QR code resource identifier** — the payload actually encoded in
the QR pixels. This page explains what each one is, how the app makes
them for you, and what to be careful about once labels are printed and
mounted underground.

## The two codes

| Code | What it is | Where you see it |
|---|---|---|
| **PCI** — place code identifier | The **human-readable** code, e.g. `04-015-001-007-0003`, `001`, `12`. On the cave place form it is the **Place code identifier** field. | Printed as text next to a label, on the cave place form, in reports. |
| **QCRI** — QR code resource identifier | The **payload inside the QR image** (and inside an `sp://` deep link). It is either an exact copy of the place code or a short hash of it. On the form it is the **QR code resource identifier** field. | Inside the QR pixels; in deep links. |

The app uses the short forms PCI and QCRI on several screens — the
settings tab is called **QR code res. ids**, and the button that
refreshes payloads is **Recompute all QCRIs**.

A few older labels survive: the cave places list sorts by **QR code
identifier** and groups by **Has QR code** — both of those read the
place code — and the manual search dialog labels its box **QR code
identifier**, where either code is accepted.

## Why two codes

- The **place code** is for people. It is readable, hierarchical if you
  want it to be, and you can write it on a marker beside a label that
  has fallen off.
- The **QR payload** is for the camera. You may want it shorter, or
  opaque, so that a photographed label does not reveal how your club
  numbers its caves.

If neither of those matters to you, leave the payload mode at **Mirror
PCI** and the two are identical.

> The hash is for shortness and opacity, not security. It is not a
> cryptographic protection of anything.

## Where the settings live

Open **Settings → Place code identifiers**. The page has two tabs:

- **Strategy** — which numbering scheme is active, its rules, and the
  **Generate codes for entire dataset** button.
- **QR code res. ids** — how the QR payload is derived, the hash
  options, and the **Recompute all QCRIs** button.

These are **dataset-wide** settings and they travel with your data:
they are included in archive and FTP sync, so changing the strategy or
the hash salt on one phone changes it for everyone who shares that
dataset. See [Sync and the change log](sync-and-change-log.md).

## How a place gets its code

1. **Type it** in the **Place code identifier** field on the cave place
   form (unlock the field first with the padlock beside it).
2. **Press the ✨ button** (tooltip *Auto-generate*) next to the field.
   It fills the field using the active strategy; nothing is stored
   until you save the place. It stays greyed out while the field is
   locked.
3. **Run a batch** for a whole cave, a whole surface area, or the whole
   dataset — see [Generating codes in bulk](#generating-codes-in-bulk).

Places created through the **Quick add cave place** popup on the raster
map, and places brought in by [CSV import](csv-import.md), get their QR
payload derived automatically from whatever place code they carry, so you do
not have to run a generation pass afterwards. An imported place code
only replaces an existing one when the import is set to overwrite
codes.

## Numbering strategies

The strategy is what the app uses to compute a place code. Pick it in
**Settings → Place code identifiers → Strategy**; the **More info**
link under the dropdown shows a longer description of the selected
one.

### Global hierarchical (default)

Five segments, concatenated in this order:

```
country · organization · surface area · cave index · place index
```

- **Country code** and **Organization code** are **required**. If
  either is blank nothing is generated at all: the run stops at the
  very first place and the summary shows a red banner reading
  *"Generation aborted: country code or organization code is not
  configured."* Set both before you generate.
- The **area** segment is the **General area identifier** of the cave's
  [surface area](surface-areas.md), inserted exactly as it is stored —
  it is never padded.
- The **cave index** is the cave's **Cave local index**. A number the app
  allocates for you is zero-padded to **Cave local index width**; a value
  you typed into that field yourself is used exactly as typed.
- The **place index** is allocated per cave and zero-padded to
  **Cave-place local index width**.
- **Segment separator** (for example `-`) is inserted between *every*
  segment, so a code can never begin with a bare area number.

  ⚠️ **Never make the separator `/` or `=`.** Those are the two
  characters a scan cuts a web address at. Once your labels carry a
  [landing address](qr-codes.md#what-a-printed-label-contains) instead of
  `sp://`, the app keeps only the text after the last `/` or `=` in the
  address it read — so a code assembled with either separator comes back
  as its final segment alone and matches no place. The app **warns** on
  the field the moment you type one (*"A / or = here truncates every
  printed code when it is scanned back."*), and that warning is the whole
  of its protection: the separator is still saved, still used for every
  code generated afterwards, and nothing is ever checked on codes that
  were allocated earlier or typed in by hand. Change it before a print
  run — afterwards it costs a reprint. (In **Hashed** mode the printed
  payload is letters and digits only, so it cannot be affected.)
- **Main entrance suffix** is used verbatim (not padded) as the place
  segment of the cave's main entrance, when that code is still free.
  No other place is given that number.
- **General area identifier width** does *not* size the area segment.
  It is only meant to size the placeholder used when the area is
  missing, and in the current build it has no effect at all — the
  placeholder is always three characters.
- **Allow non-digit segments** has no effect in the current build,
  because nothing you type is checked against the strategy.

Country `04`, organization `015`, area identifier `001`, cave index
width 3, place index width 4, no separator:

```
040150010070003    ← country 04, org 015, area 001, cave 007, place 0003
```

With `-` as the segment separator the same code reads
`04-015-001-007-0003`.

> 📷 [Managing surface areas](../screenshots/01-home-and-caves.md#surface-areas-list) — the surface areas list, where regions that group caves are created and edited.

**Caves with missing data still get codes.** A cave that has not been
assigned to a surface area is not skipped: its places get a code whose
area segment is all zeros (`000`). A cave whose surface area has no
General area identifier gets all nines (`999`). These codes are real,
they are written to the database, and they can end up printed. The
generation summary flags both cases so you can fix the data and
regenerate before printing anything.

**The cave index is allocated once and kept.** Each cave has a **Cave
local index** field on the add/edit-cave screen. Set it yourself, or
leave it empty and let the first generation for that cave pick the
lowest free number and save it to the cave permanently — later
regenerations then produce the same codes. The number only has to be
free *within its area segment*, so two caves in different surface areas
can both be cave `001`. Changing or clearing the field afterwards
changes the codes generated for that cave.

### Per-cave sequential

Plain integers that restart inside each cave. Starting at **Start at**
(default 1), the app moves up by **Step** until it finds a free number,
and zero-pads it to **Zero-pad width** (0 means no padding).
**Main entrance first** reserves the start value for the cave's main
entrance.

Only numeric codes count as "already taken", so a hand-typed code like
`LAKE-A12` does not block a number.

### Per-area sequential

The same idea, but the counter is shared by **every cave in the same
[surface area](surface-areas.md)** — the outdoor region that groups
whole caves — instead of restarting inside each cave. No two places in
one surface area are handed the same number, which suits a karst region
numbered as a single continuous series.

Caves that are **not** assigned to a surface area are **skipped**:
their places are left without codes and counted under *Skipped* in the
generation summary.

### Choosing a strategy

| If you want… | Strategy |
|---|---|
| Stable codes you can share across teams and clubs | **Global hierarchical** |
| Plain `1..N` numbering per cave, no setup | **Per-cave sequential** |
| Plain `1..N` numbering shared by all caves in a surface area | **Per-area sequential** |

You can switch strategies later, but regenerating will offer to
overwrite codes that may already be printed on physical labels — see
[Living with printed labels](#living-with-printed-labels).

### Set the rules before your first batch

⚠️ The boxes on the **Strategy** tab do not take effect until you edit
one of them. Until then the app uses its own built-in values, which are
not always what the boxes show.

This bites the two sequential strategies, because they need no setup at
all: run a batch straight away and codes come out **unpadded** (`1`,
`2`, `3` rather than `001`) and the main entrance **does** take the
start value, even though **Zero-pad width** shows 3 and **Main entrance
first** shows as off.

Editing any single field on the tab saves everything on screen at once,
after which the screen and the generated codes agree. So open the tab
and set the values you want explicitly before your first batch — even
if you only retype the value that is already there. (Global hierarchical
is safe in practice: it refuses to generate until you have typed the
country and organization codes, and typing them saves the rest of the
tab too.)

## The QR payload

On the **QR code res. ids** tab, the **QR code resource identifier
mode** dropdown decides how the payload is derived.

| Mode | Behaviour |
|---|---|
| **Mirror PCI** (default) | The payload is the place code itself. Scanning a label is the same as typing its place code. |
| **Hashed** | The payload is a short hash of the place code. The QR image encodes the hash, not the readable code. |

Under the controls a live example shows what your current settings
produce — *Example: PCI 040150001001 → QCRI …* — and it updates as you
move the length slider or edit the salt, so you can see the result
before generating anything.

### Hash length

Only shown once hashing applies. The slider runs from **4 to 16**
characters, default 8; longer means a lower chance of two places
colliding and a denser QR image.

If a computed hash would clash with another place's, the app quietly
adds one character **for that place only** (up to 16), so a few codes in
your dataset can come out a character or two longer than the rest.

### Hash salt

An optional string mixed into the hash, so that two datasets holding
the same place codes produce different payloads. The box appears only
once hashing is in play, with the on-screen help *"Optional string mixed
into the hash input. Changing this will alter all generated QCRIs —
recompute after saving."*

It is **not a password**: it is stored with your settings and syncs to
every device sharing the dataset. Treat it as a dataset setting. Set it
once, before you print anything — changing it later changes every
payload and every printed label has to be replaced.

### Use hash for entrances

This switch appears **only in Mirror PCI mode**: with the mode set to
*Mirror PCI*, turning it on makes **entrances the only places with a
hashed payload**, while every other place keeps payload = place code. It
applies to any place flagged as a **Cave entrance**, not just the main
entrance. Turning it on also reveals the hash length slider and the
salt box.

In *Hashed* mode there is no such switch — everything, entrances
included, is hashed.

## Generating codes in bulk

### Where you can start a generation

| From | Scope |
|---|---|
| **Settings → Place code identifiers → Strategy → Generate codes for entire dataset** | Every place in the database. |
| Cave places list → the ✨ toolbar button (tooltip *Generate codes*), or **⋮ → Generate codes** on the same screen | Every place in that cave. |
| Edit-cave screen → **⋮ → Generate codes** (only when editing an existing cave) | Every place in that cave. |
| **Manage surface areas** → **⋮ → Show generate icons**, then the ✨ on an area row | Every place in every cave of that surface area. |
| The **Generate codes** button inside the edit-area dialog | The same area-wide scope. |
| Cave place form → the ✨ beside **Place code identifier** | This place only, and only into the field — nothing is stored until you save the place. |

The ✨ button on the **Manage surface areas** rows is hidden until you
tick **Show generate icons** in that screen's **⋮** menu. The QR range
button beside it is always visible.

### What happens during a run

1. A plain confirmation appears first — for example *"Generate place
   codes for the entire dataset?"* — with **Cancel** and **Generate
   codes**. There is no preview list.
2. A **Generating codes…** dialog shows a progress bar, a
   *Processing: 12 / 340 (4%)* counter, an **ETA** line and a **Stop**
   button. **Stop** ends the run; everything written up to that point
   stays written.
3. Places with no code yet are filled in silently. A place whose
   recomputed code is identical to the one it already has is left
   alone.
4. Only when an existing code would actually **change** does the run
   pause and ask.

The question is titled **Overwrite existing value?**, names the field
and shows the old and the new value:

| Button | Effect |
|---|---|
| **Keep** | Leave this one code alone. |
| **Replace** | Take the new code for this place. |
| **Keep all** | Leave every remaining conflict alone, no more questions. |
| **Replace all** | Take the new value for every remaining conflict. |
| **Cancel batch** | Stop the run here. Everything written so far stays written. |

The place code and the QR payload are asked about **separately**, and a
blanket answer applies only to the field it was given for — answering
**Keep all** for place codes still leaves the app free to ask about QR
payloads.

### The generation summary

When the run ends you get a **Generation summary**: caves with codes
generated, places updated, places overwritten (they already had a
code), processing time, and counts of skipped / refused / aborted
places. If you stopped it, *"Batch was cancelled."* appears too.

A red banner appears when the run aborted — most often *"Generation
aborted: country code or organization code is not configured."*

If any cave was missing a surface area, or its area had no identifier,
an expandable section lists those caves by name with how many places
each contributed, and says which placeholder was used
(`000…` or `999…`). Fix the missing data and regenerate **before**
printing those labels.

### "Recompute all QCRIs" is a full regeneration

⚠️ The button at the bottom of the **QR code res. ids** tab is labelled
**Recompute all QCRIs** and its confirmation only mentions QR payloads,
but it runs exactly the same whole-dataset generation as the button on
the Strategy tab. It will also recompute **place codes**, and it will
stop and ask *Overwrite existing value?* for place codes that would
change.

To refresh only the payloads after changing the hash length or salt:
answer **Keep all** the first time it asks about a *Place code
identifier*, and **Replace all** the first time it asks about a *QR
code resource identifier*. If it does ask about place codes at all,
stop and check your strategy settings first: the payloads it goes on to
write are derived from the **new** place codes, not from the ones you
kept, so the readable text and the QR pixels would stop matching.

## Typing codes by hand

Both fields on the cave place form sit behind a padlock (tooltip
*Enable QR edit* / *Disable QR edit*). Unlock a field to type in it, or
to use its ✨ button.

**Nothing you type is checked against the strategy.** Whatever you put
in the **Place code identifier** field is stored exactly as typed; the
digit rules, the segment layout and the **Allow non-digit segments**
switch shape only the codes the app *generates* for you, and the form
shows no validity indicator. Keeping hand-typed codes consistent with
the pattern is up to you.

### Editing a place code does not refresh its QR payload

⚠️ On save, the app derives the payload from the place code **only when
the QR field is empty**. Change a code by hand on a place that already
has a payload and the old payload stays behind — the readable text and
the QR pixels then point at different things.

After a hand edit, press the ✨ next to the **QR code resource
identifier** field (or clear that field before saving) so the two match
again.

### Duplicates

- Within a cave, a duplicate place code raises a **Duplicate QR code**
  dialog — *Cave place "X" already uses QR code Y. Save with
  duplicate?* — and you may accept and keep both.
- In the **Quick add cave place** popup the same duplicate is refused
  outright (*QR code X is already used by "…"*) and you must change it
  before saving.
- Codes are never checked against *other* caves, so cross-cave
  duplicates go through silently. Scanning one then offers a chooser of
  the matching caves.
- The QR payload *is* checked across the whole dataset, but only when
  you edited the QR field yourself, and that check is also a
  save-anyway question rather than a block.

### The place code row can be hidden

When the payload mode is **Mirror PCI** and a place's code and payload
are identical, the form hides the **Place code identifier** row to save
space — you only see the QR row. An eye button on the cave-area row
(tooltip **Show place code identifier**) brings it back when you need
to edit the code.

### Scanning into the QR field

The scan button beside the **QR code resource identifier** field writes
a scanned payload straight into it:

- If another place already uses that payload, you get a warning and
  nothing is written.
- If the field already holds a different value, **Replace QR code?**
  asks first.
- In Mirror PCI mode, when the place code field is still empty, the
  scanned value is copied into it as well.

In developer builds, holding the scan button for about 2.5 seconds opens
**Manual QR code search** instead, for typing a code in when there is no
label to scan. The released app does not have this shortcut; the scan
button only opens the scanner.

## Printing labels before the places exist

You can print labels for caves and places you have not recorded yet.
Nothing is written to the database — you take the printed labels
underground, mount them, and record the places later against the codes
you already printed.

- Cave places list → the QR button tooltipped **Generate cave place QR
  codes (range)** asks for a **From index** / **To index** range and
  produces the codes those places *will* get in this cave.
- **Manage surface areas** → the QR button on an area row
  (**Generate entrance QR codes (range)**) does the same for the main
  entrances of caves numbered in that area.

Both open the **Generated QR Codes** viewer, where you can export a PDF
and print it — see [QR codes](qr-codes.md).

Limits worth knowing:

- At most **500** codes per request.
- Indices that already belong to a recorded cave or place are skipped,
  and you are told how many.
- The reserved main-entrance index is always left out of a cave-place
  range.
- It only works with **Global hierarchical**, and only once the country
  and organization codes are set (*"Set the country and organization
  codes in place-code settings first."*).
- For a cave-place range the cave must already have a cave local index
  (*"This cave has no local index yet — assign one first."*).

## What a scan matches

When you scan a QR code, type a code into the manual search box, or
open an `sp://` [deep link](deep-links.md), the app looks for a place
whose **place code** *or* **QR payload** matches, ignoring upper and
lower case. That has three useful consequences:

- A readable place code still finds its place even after you switch to
  hashed payloads.
- A smudged label can be typed in by hand from the readable text.
- The same code can match places in two different caves, in which case
  a chooser appears (**Choose point / cave**). You can turn that
  chooser off with **Settings → General → Ask which cave on ambiguous
  QR scan**, after which the app silently opens the match from the
  last-opened cave. Deep links are governed by their own switch beside
  it, **Ask which cave on ambiguous deep link**.

## Living with printed labels

1. **Switching from Mirror PCI to Hashed is survivable; switching back
   is not.** A label printed in mirror mode carries the place code, and
   a scan matches place codes too, so it keeps working after you switch
   to hashing. A label printed in hashed mode carries only the hash —
   once you switch back to Mirror PCI and recompute, nothing matches it
   any more and it has to be re-printed.
2. **When regenerating, answer Keep all** at the first *Overwrite
   existing value?* prompt unless you are sure you can replace the
   physical labels. Existing codes are then left untouched while places
   that have no code yet still get one.
3. **Set the hash salt once**, before printing. Changing it later
   changes every hashed payload.
4. For a single label that has fallen off or become unreadable,
   re-print **only that label** rather than the whole batch.
5. **A `/` or an `=` inside your codes cannot be repaired after
   printing.** Labels that carry a landing address and went out with
   such codes are cut short by every scan, and nothing in the app can
   rescue them — correct the
   [segment separator](#global-hierarchical-default) and re-print.

## See also

- [QR codes — placing, scanning, printing](qr-codes.md)
- [Cave places](cave-places.md)
- [Surface areas](surface-areas.md)
- [Deep links](deep-links.md)
- [CSV import of cave places](csv-import.md)
- [Settings](settings.md)
