# Place codes (PCI) and QR payloads (QCRI)

[← Back to index](../index.md)

Every [cave place](cave-places.md) in SpeleoLoc carries two user-facing
identifiers used by the QR-code system:

| Code | Meaning | Where you see it |
|---|---|---|
| **PCI** — Place Code Identifier | The **human-readable** code printed next to each cave place. Examples: `123`, `RO-CLB-001-002-005`, `LAKE-A12`. | On printed labels (as text), in lists, in reports, on the cave place form. |
| **QCRI** — QR Code Resource Identifier | The **payload encoded inside the QR pixels** (and inside the `sp://` deep link). May be **identical to the PCI**, or a **short hash** of it for shorter/opaque QR codes. | Inside the QR image; in deep links such as `sp://<qcri>`. |

> Heads-up: previous versions of SpeleoLoc used a single **integer**
> field called "QR code identifier". That field has been replaced by
> PCI + QCRI. Older documentation pages that say "QR code identifier"
> refer to what is now the **PCI**.

## Why two codes?

- The **PCI** is for humans — readable, hierarchical, easy to write on
  a marker beside a damaged label, easy to scan visually.
- The **QCRI** is for machines — what the camera reads. You may want
  it shorter (smaller QR), or hashed (so the printed label does not
  betray the cave's internal numbering, or for privacy-sensitive
  caves).

If you don't care about either of those tradeoffs, just set **QCRI
mode = mirror** (the default) and the QCRI equals the PCI.

## Assigning PCIs

There are two ways to fill the PCI of a cave place:

1. **Manually** — type any string in the **Place code identifier**
   field on the cave place form.
2. **Automatically** — generate codes in bulk according to an
   **assignment strategy**.

## Assignment strategies

A strategy is the algorithm SpeleoLoc uses to compute PCIs for a batch
of cave places. The active strategy is chosen globally in
**Settings → Place codes**.

### Global hierarchical (default)

Builds codes of the form

```
<country><organization><general_area><cave_local><place_local>
```

- **Country code** and **Organization code** are short text fields you
  set once in **Settings → Place codes**.
- **General area identifier** is set per [surface area](surface-areas.md).
- **Cave local index** is set per cave.
- **Place local index** is generated per place within a cave.
- Each segment has a configurable **digit width** (zero-padded).
- An optional **segment separator** (`-`, `.`, …) makes the code more
  readable.
- The **main entrance suffix** (e.g. `0`) reserves a specific local
  index for the cave's main entrance so it is always recognisable.

Example output (widths 3/3/3, separator `-`, no country/org):

```
001-002-005   ← cave 002, place 005, in area 001
```

### Per-cave sequential

Numbers places **starting from `start_at`** (default `1`) **inside
each cave**, with a configurable **step** and **zero-pad width**.
Optionally puts the main entrance first.

Example (start 1, step 1, width 3): `001`, `002`, `003`, …

### Per-area sequential

Same idea, but scoped per [cave area](caves-and-areas.md) instead of
per cave. Useful when areas are named, large, and surveyed
independently.

### Choosing a strategy

| If you want… | Strategy |
|---|---|
| Stable, globally unique codes you can share across teams and clubs | **Global hierarchical** |
| Plain `001..N` numbering per cave, no setup | **Per-cave sequential** |
| Plain `001..N` numbering per zone inside the cave | **Per-area sequential** |

You can switch strategies later, but **regenerating** PCIs may
overwrite codes that are already printed on physical labels — see the
warnings in the generation UI.

## QCRI modes

The QCRI is configured separately in **Settings → Place codes → QCRI**.

| Mode | Behaviour |
|---|---|
| **Mirror** (default) | `QCRI = PCI`. Scanning a label is equivalent to typing its PCI. |
| **Hash** | `QCRI = short hash(PCI, salt)`. The QR image encodes the hash, not the PCI. |

For hash mode you choose:

- **Length** — number of characters in the hash (clamped to a safe
  range; longer = lower collision risk, bigger QR).
- **Entrance hash** — whether even the **entrance / main entrance**
  places get a hashed QCRI (typically off, so the entrance code stays
  human-readable).
- **Salt** — an optional secret string. Changing the salt invalidates
  every previously printed hashed label, so set it once before
  generating QCRIs.

> The hash is for **shortness and opacity**, not security. It is not
> a cryptographic protection of the underlying data.

## Generating PCIs and QCRIs

You can trigger generation at three levels of scope:

| From | Scope |
|---|---|
| **Settings → Place codes → Generate** | All places in the database. |
| Cave's **⋮ → Generate place codes** | All places in this cave. |
| Cave place form → **Generate** | This place only. |
| Surface areas list → **Generate codes for area** | All places under that area. |

The dialog shows a preview, and asks how to handle places that
**already have a code**:

- **Skip** — leave existing codes alone (default for already-printed
  labels).
- **Overwrite** — recompute every PCI/QCRI from scratch.
- **Apply choice to all remaining** — shortcut to avoid prompting per
  conflict.

When generation finishes you get a summary: how many codes were
assigned, how many were skipped, and any errors (e.g. the active
strategy needs missing settings like `country_code`).

## Manual PCIs and validation

When typing a PCI by hand:

- Within a cave, **PCIs must be unique** — duplicates show a warning.
- Cross-cave duplicates are tolerated but generate a chooser when
  scanned.
- Some strategies (notably **Global hierarchical** with
  `allow_non_digit = false`) restrict the PCI to digits/separators.
  The form previews whether your manual code is **valid for the
  current strategy**.

The QCRI field is normally read-only and auto-computed when you save.
In hash mode you can regenerate the QCRI without changing the PCI.

## Working with already-printed labels

If you have labels already mounted in the cave:

1. **Don't switch QCRI mode** (mirror ↔ hash) — it invalidates the
   QR-pixel payload on every existing label.
2. When regenerating PCIs, use **Skip existing** unless you are sure
   you can replace the physical labels.
3. For a label that has fallen off / become unreadable, prefer
   re-printing **only that label** rather than the whole batch.

## See also

- [QR codes — placing, scanning, printing](qr-codes.md)
- [Cave places](cave-places.md)
- [Deep links (`sp://`)](deep-links.md)
- [Settings](settings.md)
