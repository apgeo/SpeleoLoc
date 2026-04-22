# Trips

[← Back to index](../README.md)

A **trip** records a single caving session inside one cave: its
timestamps, an ordered list of **trip points** (visited cave places),
a free-form log, and any documents produced while the trip was active.

Trips are optional — you can use SpeleoLoc purely for navigation and
documentation without ever starting one. But trips are the basis for
the [trip reports](trip-reports.md).

## Lifecycle

```
  Start → (Pause ↔ Resume)* → Stop
```

- **Start** creates the trip with a `started_at` timestamp, makes it
  the single **active trip** for this device, and begins recording
  events.
- **Pause** freezes recording; scans do not add points; the log still
  records a "paused" entry.
- **Resume** re-enables recording, logs a "resumed" entry.
- **Stop** sets `ended_at`, clears the active-trip pointer, marks the
  trip read-only.

Only **one trip** can be active at a time on a device.

## Starting a trip

From a cave's places list: **⋮ → Start trip**. Give it a title
(suggested: date + descriptor). The active-trip banner appears on
this screen and on every cave place inside the cave.

## Trip points

While active:

- **Every QR scan** adds a trip point (cave place + current
  timestamp). The log records a `QR scanned "<place title>"` entry.
- You can also **manually select a place** as a trip point from the
  trip's map view.

Trip points are ordered by scan time. A cave place can be scanned
multiple times within one trip — each scan produces a distinct trip
point.

## The trip log

A free-form text editor with automatic timestamps. Reach it from:

- **Cave → View trip → Log**, or
- directly from the trip page's **Log** tab.

Use it for narrative notes: weather, team composition, observations
not tied to a specific place, conclusions.

## Linking documents to a trip

Any document created while a trip is active is auto-linked to that
trip in addition to its geofeature. You can manually link/unlink
existing documents from the trip view.

## The trip map

The trip page has a **map view** showing the route for a selected
raster map:

- **Numbered pins** at each trip point (in scan order).
- **Polyline** connecting successive points.
- **Playback** — animate the route from first to last point.
- **Export as image** — generate a PNG of the current map view with
  the route, used when generating a report.

## Viewing past trips

From a cave's places list, the **Past trips** button opens the list of
ended trips, with per-trip actions:

- **Open** — view its map, list, log.
- **Export report** — see [Trip reports](trip-reports.md).
- **Delete**.

## Stopping a trip

**View trip → ⋮ → Stop trip** (or the long-press action on the banner).
Confirm. The trip becomes read-only but its data is preserved and
included in archive exports.

## Deleting a trip

**View trip → ⋮ → Delete trip**. Permanently removes the trip, its
points and log. Documents linked to the trip remain in the database
but lose the trip link.

## See also

- [Trip reports](trip-reports.md)
- [Map viewer](map-viewer.md)
- [Documents](documents.md)
