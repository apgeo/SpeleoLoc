# Workflow: Running a caving trip

[← Back to index](../README.md) · [Overview](../overview.md)

A **trip** is SpeleoLoc's way of recording a single caving session
inside one cave: when it started, what places were visited in what
order, free-form log entries, and any documents produced during the
trip. At the end, a trip can be turned into a printable report.

## When to use a trip

Start a trip when you want:

- a **route** drawn on the raster maps from scan to scan,
- a **timestamped list** of everything you observed,
- to later generate an **ODT/DOCX trip report** from it,
- to keep trip-specific documents grouped together.

If you only want to look at existing data or attach a single photo to a
place, you do not need a trip.

## One active trip at a time

SpeleoLoc tracks **one active trip per device**. The active trip's state
(running/paused) is shown at the top of the cave's places list with
convenient Pause/Resume/Stop controls.

## Start a trip

1. Open the cave you will explore (Home → tap the cave).
2. In the cave's **⋮ menu**, choose **Start trip** (green play icon).
3. Give the trip a title (e.g. `2026-04-22 recon`).
4. The trip starts and the active-trip banner appears.

Alternatively you can start it from the scanner flow if the setting is
enabled.

## During the trip

Every **QR scan** while the trip is active automatically adds a trip
point (cave place + timestamp) to the route. You do not need to press
anything else to log positions.

Other things you can do while a trip is active:

- **Pause** the trip — no new points recorded until resume. Useful for
  rests or side-branches you do not want on the route.
- **Resume** the trip.
- **Open the trip log** (free-form text editor, auto-timestamped
  entries): **cave menu → View trip → Log**.
- **Link a document to the trip** — any document you create while the
  trip is active is also associated with it.
- **View the trip's map/list** at any time (**View trip**) to see the
  route drawn on the raster maps, with numbered trip points and route
  line, plus an **animated playback** of the route.

See [Trips](../features/trips.md) for the details of each of these.

## End the trip

1. **Cave menu → View trip → Stop** (or long-press the trip banner).
2. Confirm.

The trip is now read-only. Its route, log, linked documents and metadata
are preserved.

## After the trip

- **Review** the trip's map and list — numbered points, route, log
  entries.
- **Generate a trip report**:
  1. Ensure you have a template registered (**Home → ⋮ → Trip report
     templates**). See [Trip reports](../features/trip-reports.md).
  2. From the trip, choose **Export report**, pick a template, and
     choose an output format (ODT or DOCX).
  3. The generated document is saved to a folder of your choice.
- **Export an archive** so the team gets the new route and documents.
  See [Sharing data](sharing-data.md).

## Multiple trips in the same cave

Each cave has a **Past trips** list in its places list header (button
near the filter). This shows all ended trips for the cave and lets you
open any of them to view its map, list and log afterwards.

See [Trips](../features/trips.md) and
[Trip reports](../features/trip-reports.md).

---

Next: [Sharing data between teams](sharing-data.md).
