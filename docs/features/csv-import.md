# CSV import

[← Back to index](../README.md)

When you already have your data in spreadsheets, SpeleoLoc can bulk
import it via CSV files. Two flavors:

- **Caves CSV** — import multiple caves at once (possibly with their
  surface areas and descriptions).
- **Cave places CSV** — import places, either into a single target
  cave or with a cave-name column that creates/links caves on the fly.

Both importers follow the same pattern: pick the file → map columns to
fields → preview → confirm.

## File format

- Plain UTF-8 CSV.
- First row must contain **column headers**. Header names are free —
  you map them to fields in the next step.
- Standard CSV quoting rules apply (values with commas or newlines
  must be quoted).

## Importing caves

**Home → ⋮ → CSV import (caves)**.

Required column:

- **Cave name**.

Optional columns:

- **Surface area** — created if missing.
- **Cave area** — created within the cave if missing (only relevant
  when combined with places).
- **Description** — free-form.

After mapping, a preview shows how many data rows were found. Existing
caves (match on title) are skipped by default; the count is shown at
the end.

## Importing cave places

Two modes:

### Single-cave mode

Triggered from inside a specific cave's menu: **⋮ → Import places
from CSV**. All rows are imported into that cave.

Required column:

- **Cave place name**.

Optional columns:

- **QR code** (integer).
- **Cave area**.
- **Description**.

### Multiple-cave mode

Triggered from **Home → ⋮ → CSV import (places, multiple caves)**.
Each row goes into the cave named in its row.

Additional required column:

- **Cave name**.

If a cave does not exist, it is created on the fly.

## Conflict handling

Before writing anything, the importer flags conflicts and asks how to
proceed:

- **Existing entries** — rows whose cave/place combination already
  exists. Counted and previewed; continue to import the new rows and
  keep the existing ones untouched.
- **QR code conflicts** — a row wants to assign a QR that is already
  used by another place. Choose:
  - **Skip QR updates** — keep the existing QR assignments; no
    changes to the colliding places.
  - **Overwrite QR codes** — move the QR to the imported place; the
    previous owner is cleared.

## Summary report

At the end, the importer shows counts for:

- Caves created.
- Surface areas created.
- Cave areas created.
- Cave places created.
- QR codes updated.
- Caves skipped (duplicates).

## Tips

- Keep a small **trial file** (3–5 rows) to verify your column mapping
  before committing a full import.
- Include a `depth` column for consistency with other reports.
- After import, run a quick visual check in the cave's places list and
  on the raster maps.

## See also

- [Caves and cave areas](caves-and-areas.md)
- [Cave places](cave-places.md)
