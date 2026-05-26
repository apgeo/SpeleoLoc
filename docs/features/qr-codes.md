# QR codes — placing, scanning, printing

[← Back to index](../README.md)

QR codes are the physical bridge between the real cave and the data in
SpeleoLoc. There are two kinds:

1. **Cave-place QR** — encodes a place's **QCRI** (typically equal to
   its **PCI**, or a short hash of it). Scanning it opens the matching
   cave place in the app.
2. **Entrance / web QR** — a URL (`sp://<qcri>` deep link) that opens
   the corresponding cave place directly, including from the phone's
   OS when SpeleoLoc is not already in the foreground. Because it is
   a URL, it can also be opened by anyone **without** SpeleoLoc
   (handled as a web link) for broad public access.

The codes printed on the **label text** beside the QR are based on the
**PCI** (human-readable), while the QR pixels themselves carry the
**QCRI** payload. See
[Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
for what each is and how to choose between them.

## QR code rules

- The PCI is a **string** (digits, hyphens, dots, letters depending on
  strategy). The QCRI is either equal to the PCI or a short hash.
- The PCI must be **unique within a cave** (duplicates trigger a
  warning dialog).
- Duplicates across different caves are allowed but produce a chooser
  dialog when scanned (see [Deep links](deep-links.md)).

## Assigning a place code

1. Open the cave place → **Place code identifier** field.
2. Type the code, or press **Scan** to scan a label and auto-fill, or
   press **Generate** to compute one with the active
   [strategy](place-code-identifiers.md).
3. Save. The **QCRI** is computed automatically.

If the place already has a code assigned, the field is locked. Enable
editing via **⋮ → Enable code edit**.

Assigning a code already in use in the cave shows:
- **Replace code?** — replaces on the existing place, which then
  loses its code.
- **Keep as duplicate** — saves with the duplicate warning accepted.
- **Cancel** — no change.

## Scanning a QR

From the home screen or cave places list, tap the scan icon. The
camera opens. Detected payloads are normalised: surrounding URLs
(`sp://…`, `https://…`) are stripped to leave the bare QCRI. When the
QCRI is resolved:

- If it matches a single cave place → that place opens.
- If it matches places in multiple caves → a chooser dialog opens.
- If it does not match anything → a "not found" message.
- If the value cannot be parsed → an "invalid QR" dialog.

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
- **QR foreground / background color** (via an RGB color picker),
- **Error correction level**: L, M, Q, H,
- **QR module shape** — square modules (default) for sharper print,
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
| `@place_code_identifier` | The PCI (human-readable code) |
| `@qr_code_resource_identifier` | The QCRI (QR payload) |
| `@depth` | Depth in cave, with +/- sign |
| `\n` | Line break |

Formatting prefixes placed before a variable:

- `#fzNN@var` — sets font size NN (e.g. `#fz14@place_title`).
- `#fcRRGGBB@var` — sets font color in hex (e.g.
  `#fcFF0000@depth`).

Example template:

```
#fz14@place_title\n#fz10#fc888888@depth\n#fz9@place_code_identifier
```

## Exporting individual QR images

From the **QR preview dialog** you can export a single label as a PNG
(plus the rendered label text underneath) to a folder of your choice
— useful for spot-replacing a damaged label without re-printing the
whole batch.

## Mounting labels in the cave

Practical recommendations:

- Print on **waterproof label material** or laminate.
- Use a **fine but high-error-correction level** (M or Q) so partial
  smudging stays readable.
- Prefer **dark QR on white** (default) — highest camera recognition
  under torchlight.
- Attach to clean, dry rock when possible; avoid muddy or flaking
  surfaces.
- Write the **PCI** next to the label in permanent marker as a
  fallback (readable even if the QR is damaged).

## See also

- [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
- [Cave places](cave-places.md)
- [Deep links (`sp://`)](deep-links.md)
- [Settings](settings.md) (QR generation & PDF output sub-pages)
