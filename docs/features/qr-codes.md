# QR codes — placing, scanning, printing

[← Back to index](../README.md)

QR codes are the physical bridge between the real cave and the data in
SpeleoLoc. There are two kinds:

1. **Cave-place QR** — a numeric identifier (e.g. `1547`) that, when
   scanned, opens the matching cave place in the app.
2. **Entrance / web QR** — a URL (`sp://<id>` deep link) that opens the
   corresponding cave place directly, including from the phone's OS
   when SpeleoLoc is not already in the foreground. Because it is a
   URL, it can also be opened by anyone **without** SpeleoLoc (handled
   as a web link) for broad public access.

## QR code identifier rules

- Any **positive integer** is valid.
- Must be **unique within a cave** (duplicates trigger a warning
  dialog).
- Duplicates across different caves are allowed but produce a chooser
  dialog when scanned (see [Deep links](deep-links.md)).

## Assigning a QR to a cave place

1. Open the cave place → **QR code identifier** field.
2. Type the number, or press **Scan** to scan a label and auto-fill.
3. Save.

If the place already has a QR assigned, the field is locked. Enable
editing via **⋮ → Enable QR edit**.

Assigning a code already in use in the cave shows:
- **Replace QR code?** — replaces on the existing place, which then
  loses its QR.
- **Keep as duplicate** — saves with the duplicate warning accepted.
- **Cancel** — no change.

## Scanning a QR

From the home screen or cave places list, tap the scan icon. The
camera opens. When a QR is detected:

- If it matches a single cave place → that place opens.
- If it matches places in multiple caves → a chooser dialog opens.
- If it does not match anything → a "not found" message.
- If it is not a parseable integer / valid `sp://` URL → an
  "invalid QR" dialog.

Long-press the scan icon on the home screen (if enabled in
**Settings → General**) to type the identifier manually.

## Generating QR code labels (PDF / images)

1. Open a cave's **places list → ⋮ → Print QR codes**.
2. A preview dialog opens showing the layout.
3. Choose output format:
   - **PDF** — a multi-page, grid-layout printable file.
   - **Images** — one PNG per label, zipped, for further layout work.
4. Save to a folder of your choice.

### Layout and appearance — defaults & customization

Defaults are defined in the app but can be customized under
**Settings → QR generation** and **Settings → PDF output**:

- **QR size** (pixels), **image padding**, **DPI**,
- **QR foreground / background color** (ARGB hex),
- **Error correction level**: L, M, Q, H,
- **Label font** and **label font size**,
- **PDF grid**: columns × rows per page,
- **PDF QR padding** (horizontal / vertical).

### Label template

The text under each QR is built from a **label template** you configure
in **Settings → QR generation → Label template**. Available variables:

| Variable | Meaning |
|---|---|
| `@place_title` | Cave place title |
| `@description` | Cave place description |
| `@cave_title` | Parent cave title |
| `@area_title` | Cave area title |
| `@place_qr_code_identifier` | QR number |
| `@depth` | Depth in cave, with +/- sign |
| `\n` | Line break |

Formatting prefixes placed before a variable:

- `#fzNN@var` — sets font size NN (e.g. `#fz14@place_title`).
- `#fcRRGGBB@var` — sets font color in hex (e.g.
  `#fcFF0000@depth`).

Example template:

```
#fz14@place_title\n#fz10#fc888888@depth
```

## Mounting labels in the cave

Practical recommendations:

- Print on **waterproof label material** or laminate.
- Use a **fine but high-error-correction level** (M or Q) so partial
  smudging stays readable.
- Prefer **dark QR on white** (default) — highest camera recognition
  under torchlight.
- Attach to clean, dry rock when possible; avoid muddy or flaking
  surfaces.
- Write the QR number next to the label in permanent marker as a
  fallback (readable even if the QR is damaged).

## See also

- [Cave places](cave-places.md)
- [Deep links (`sp://`)](deep-links.md)
- [Settings](settings.md) (QR generation & PDF output sub-pages)
