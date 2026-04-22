# Caves and cave areas

[← Back to index](../README.md)

## Cave

A **cave** is the top-level record in SpeleoLoc. It has:

- **Title** (required, unique in the database),
- optional **surface area** — see [Surface areas](surface-areas.md),
- optional **entrance QR code identifier** — a second, distinct QR at
  the cave entrance that opens the cave's page directly (see
  [QR codes](qr-codes.md)),
- a collection of **cave places**,
- a collection of **cave areas**,
- a collection of **raster maps**,
- a history of **trips**.

### Creating a cave

- **Home → Add cave** (the `+` icon).
- Fill title and, optionally, surface area.
- Save.

### Renaming / deleting a cave

- Long-press or swipe the cave row in the home list for contextual
  actions.
- Deleting a cave removes all of its cave places, raster maps, point
  definitions, and trips (with confirmation).

### Opening a cave

Tapping the cave row opens its **places list**. From there:

- Add cave places (manually, by CSV, or by tapping on a raster map).
- Open the raster maps list and editor.
- Start or view trips.
- Open the cave's documents.
- Generate QR code labels.

## Cave areas (inside a cave)

A **cave area** is a named zone *within a cave*, used to group cave
places. Examples: "Entrance zone", "Main gallery", "Lake room". Cave
areas are:

- optional,
- free-text titled,
- used for filtering in the cave places list and for grouping in
  reports/prints.

### Managing cave areas

- From a cave: **⋮ → Manage cave areas**.
- Add, rename or delete areas. Deleting an area clears the link from
  affected cave places (but does not delete the places).

Cave places can be assigned an area when created or edited, or from a
bulk assignment flow. See [Cave places](cave-places.md).

## Difference between cave area and surface area

- **Surface area** = on the surface, groups caves (geography).
- **Cave area** = underground, groups places inside one cave.

They are independent and can be used together.

## See also

- [Cave places](cave-places.md)
- [Raster maps](raster-maps.md)
- [Surface areas](surface-areas.md)
- [Trips](trips.md)
