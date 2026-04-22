# Overview

[← Back to index](README.md)

## The problem SpeleoLoc solves

Caves are hard to navigate. GPS does not work underground, and paper maps
are awkward to use in mud, water and tight passages. Teams that explore the
same cave over many years accumulate notes, sketches, photos and coordinates
in scattered formats, making it hard to find which notes belong to which
passage the next time a team goes in.

SpeleoLoc addresses this with a simple idea:

> **Put a physical QR-code label at each point of interest inside the cave,
> and tie everything we know about that spot to the QR code.**

Once labels are installed, any team member can later scan a label with the
app to instantly:

1. See **where they are** on existing cave maps.
2. See **everything previously documented** for that spot (photos, notes,
   depth, sketches…).
3. **Add new observations** (pictures, audio notes, measurements) that are
   then available to every other team once data is synced.

There is also a second kind of QR code placed at the **cave entrance** which
acts as a web link and can be opened by anyone with a normal phone, not just
SpeleoLoc users.

## Core model

SpeleoLoc organizes data into a small number of concepts:

```
Surface area (geographic region)
└── Cave
    ├── Cave area (a named zone inside the cave, optional)
    │   └── Cave place ← the QR-coded point of interest
    │       ├── Documents (photos, audio, text, rich text, web links, ...)
    │       └── Point definition(s) on raster map(s)
    ├── Raster maps (plan view, projected profile, extended profile, ...)
    └── Trips (a caving session, with a route through cave places)
```

See the [glossary](glossary.md) for precise definitions of each term.

## The three big things you do with SpeleoLoc

1. **You prepare the cave** (once, and then incrementally):
   - Add the cave to the app.
   - Import one or more scanned maps as **raster maps**.
   - Create **cave places** for each point of interest, print their QR
     labels, and mount the labels physically inside the cave.
   - Pin each cave place to its position on each relevant raster map.
   - See [Documenting a new cave](workflows/documenting-a-new-cave.md).

2. **You use it underground**:
   - Scan a QR label to know where you are and read what is already there.
   - Record new observations (photos, audio, sketches) attached to that
     place.
   - Optionally run a **trip** that logs your path from scan to scan and
     saves the sequence as a route on the map.
   - See [Navigating underground](workflows/navigating-underground.md) and
     [Running a caving trip](workflows/running-a-trip.md).

3. **You share and report after the trip**:
   - Export the database + documents as a single archive for other teams.
   - Generate a printable trip report from an ODT/DOCX template.
   - See [Sharing data](workflows/sharing-data.md) and
     [Trip reports](features/trip-reports.md).

## What SpeleoLoc does **not** do (yet)

- It does not provide inertial or sensor-based underground tracking —
  positioning relies on physically scanning QR labels you have placed.
- There is no central server. Synchronization is file-based (send a zip
  archive by any means; see [Sharing data](workflows/sharing-data.md)).
- Cave surveying/3D drawing is not part of the app — SpeleoLoc consumes
  existing maps (bitmap images), it does not produce them.

Next: [Getting started](getting-started.md).
