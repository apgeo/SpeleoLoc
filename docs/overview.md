# Overview

[← Back to index](README.md)

What SpeleoLoc is for, the handful of concepts everything else is built
on, and — just as usefully — what it deliberately does not try to do.

## The problem SpeleoLoc solves

Caves are hard to navigate. GPS does not work underground, and paper maps
are awkward to use in mud, water and tight passages. Teams that explore
the same cave over many years accumulate notes, sketches, photos and
coordinates in scattered formats, making it hard to find which notes
belong to which passage the next time a team goes in.

SpeleoLoc addresses this with a simple idea:

> **Put a physical marker at each point of interest inside the cave, and
> tie everything we know about that spot to that marker.**

Once markers are installed, any team member can later identify a spot
with the app and instantly:

1. See **where they are** on the cave's maps.
2. See **everything previously documented** for that spot (photos, notes,
   depth, sketches…).
3. **Add new observations** (photos, audio recordings, text and rich-text
   notes) that reach every other team once the data is shared.

## How SpeleoLoc knows where you are

There are two kinds of marker, and a cave place can carry both.

**QR labels.** You print a label for a cave place, glue it to the rock,
and scan it underground with **Scan QR**. A label carries the place's
identifier, by default behind SpeleoLoc's own `sp://` prefix, which
nothing but SpeleoLoc resolves. A club that runs its own server can
instead fill in **Settings → QR Code Generation → Landing address for
printed labels**, and then the same square also opens in an ordinary
phone's browser. See [QR codes](features/qr-codes.md).

**Bluetooth (BLE) tags.** You can register an iBeacon tag or a Ruuvi
sensor tag against a cave place. With **Settings → Beacon detection →
Detect beacons automatically** switched on, simply walking past a
registered tag identifies the place: the app shows *Place detected*, adds
a trip point if a trip is running in that cave, and — if you turned on
**Open place on detection** — opens the place outright, with no scan and
no hands. See [BLE beacons](features/ble-beacons.md).

Ruuvi tags do double duty: the same broadcasts that identify a place also
carry temperature, humidity, air pressure and battery level, which the
app shows live and can download from the tag as a stored measurement
history. See [Ruuvi sensor tags](features/ruuvi-sensors.md).

Above ground, cave places that have coordinates are drawn on the **Cave
map**, a geographic map that works offline from cached tiles or from
`.mbtiles` files you import. See [The cave map](features/surface-map.md).

## Core model

SpeleoLoc organises data into a small number of concepts:

```
Surface area (geographic region)
└── Cave
    ├── Cave area (a named zone inside the cave, optional)
    │   └── Cave place ← the point of interest
    │       ├── Documents (photos, audio, text, rich text, links, ...)
    │       ├── A QR label, and/or one or more BLE tags
    │       ├── Coordinates → its pin on the geographic cave map
    │       └── Point definition(s) on raster map(s)
    ├── Raster maps (plane view, projected profile, extended profile, ...)
    └── Trips (a caving session, with a route through cave places)
```

Two things sit outside that tree and apply to everything: the **users**
list, which stamps who made each change, and the **change log**, the
running record of every edit that sync uses to merge one device's work
into another's.

See the [glossary](glossary.md) for precise definitions of each term.

## The three big things you do with SpeleoLoc

1. **You prepare the cave** (once, and then incrementally):
   - Add the cave to the app.
   - Import one or more scanned maps as **raster maps**.
   - Create **cave places** for each point of interest, print their QR
     labels, and mount the labels physically inside the cave.
   - Where it is worth the batteries, register a **BLE tag** on a place
     as well, so it announces itself without a scan.
   - Pin each cave place to its position on each relevant raster map,
     and give the entrances their coordinates so they appear on the
     geographic cave map.
   - See [Documenting a new cave](workflows/documenting-a-new-cave.md).

2. **You use it underground**:
   - Scan a QR label — or walk past a registered tag — to know where you
     are and read what is already there.
   - Record new observations (photos, audio recordings, notes) attached
     to that place.
   - Optionally run a **trip** that logs your path from point to point
     and saves the sequence as a route on the map.
   - See [Navigating underground](workflows/navigating-underground.md)
     and [Running a caving trip](workflows/running-a-trip.md).

3. **You share and report after the trip**:
   - Merge your work with a teammate's by swapping a sync archive by
     hand, or let the app do it over your team's **FTP/SFTP** server.
   - Export the whole database plus documents as a single archive for
     another team, or hand out coordinates as GPX/KML.
   - Generate a printable trip report from an ODT or DOCX template.
   - See [Sharing data](workflows/sharing-data.md) and
     [Trip reports](features/trip-reports.md).

## What SpeleoLoc does **not** do (yet)

- **It does not follow you between markers.** There is no inertial or
  dead-reckoning tracking underground. SpeleoLoc knows where you are
  because you scanned a QR label or passed a BLE tag you registered; in a
  passage with neither, it cannot tell you where you are.
- **It does not run a cloud service for you.** Sync goes through an
  archive file you swap by hand, through an FTP/SFTP server your team
  provides and controls, or against a **Club server (SilexGIS)** your
  club runs — never a service SpeleoLoc operates on your behalf.
  See [FTP / SFTP sync](features/ftp-sync.md).
- **It does not survey or draw.** SpeleoLoc consumes existing maps
  (bitmap images); it does not produce them, and it has no 3D model of
  the cave.
- **It publishes nothing on the web itself.** A label printed with the
  default `sp://` prefix does nothing on a phone without SpeleoLoc, and
  any public page a label does open is one your club hosts, not one
  SpeleoLoc provides.

SpeleoLoc is in **alpha** — some screens are still moving. Where a page
in this wiki knows a feature is partial, it says so.

## See also

- [Getting started](getting-started.md) — installation and first launch
- [Glossary](glossary.md) — precise meaning of every term above
- [Documenting a new cave](workflows/documenting-a-new-cave.md)
- [Navigating underground](workflows/navigating-underground.md)
- [Home screen](features/home-screen.md)
- [Screenshot gallery](screenshots/README.md)
