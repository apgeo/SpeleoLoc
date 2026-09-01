# SpeleoLoc — User Wiki

Welcome to the user documentation for **SpeleoLoc**, a mobile application for
cavers that helps with:

- **Underground positioning** — knowing where you are on a cave map by scanning
  QR labels physically placed at points of interest, or by detecting a BLE
  beacon mounted there.
- **Cave documentation** — attaching photos, audio, text notes, sketches and
  other files to those points of interest.
- **Surface positioning** — plotting every cave entrance you know about on a
  geographic map that works offline.
- **Trip logging and reporting** — recording a caving trip's path and events,
  and generating a trip report afterwards.
- **Data sharing** between teams through exportable archives or FTP/SFTP sync.

Start with the [Overview](overview.md) if you are new; jump into the
[feature reference](features/) if you are looking up a specific function; open
the [screenshot gallery](screenshots/README.md) if you would rather see the app
than read about it.

> 🇷🇴 **Această documentație este disponibilă și în română:**
> [documentația în limba română](ro/README.md).

---

## Table of contents

### Start here

1. [Overview — what SpeleoLoc does and why](overview.md)
2. [Getting started — first launch](getting-started.md)
3. [Glossary of terms](glossary.md)
4. [Screenshot gallery — the app, screen by screen](screenshots/README.md)

### Workflows (task-oriented)

- [Documenting a new cave](workflows/documenting-a-new-cave.md)
- [Navigating underground](workflows/navigating-underground.md)
- [Running a caving trip](workflows/running-a-trip.md)
- [Sharing data between teams](workflows/sharing-data.md)
- [Using offline MBTiles layers](workflows/mbtiles-layers.md)

### Feature reference (screen by screen)

**Organising your data**

- [Home screen](features/home-screen.md)
- [Caves and cave areas](features/caves-and-areas.md)
- [Cave places](features/cave-places.md)
- [Surface areas](features/surface-areas.md)
- [Filtering, sorting and selection](features/lists-filter-sort-select.md)

**Finding your way**

- [The cave map](features/surface-map.md)
- [Raster maps](features/raster-maps.md)
- [Map viewer and point editor](features/map-viewer.md)
- [GPS and coordinates](features/gps-and-coordinates.md)

**Identifying places**

- [Place codes (PCI) and QR payloads (QCRI)](features/place-code-identifiers.md)
- [QR codes — placing, scanning, printing](features/qr-codes.md)
- [BLE beacons](features/ble-beacons.md)
- [Ruuvi sensor tags](features/ruuvi-sensors.md)
- [Deep links (`sp://`)](features/deep-links.md)

**Recording what you find**

- [Documents (photos, audio, text, rich text, links)](features/documents.md)
- [Trips — recording your route](features/trips.md)
- [Trip reports and templates](features/trip-reports.md)

**Moving data around**

- [Sync dashboard & change history](features/sync-and-change-log.md)
- [FTP / SFTP sync](features/ftp-sync.md)
- [Club server sync (SilexGIS)](features/silexgis-sync.md)
- [Database export, import and backup](features/database-export-import.md)
- [CSV import](features/csv-import.md)
- [GPX/KML place transfer](features/place-transfer.md)

**Configuration**

- [Settings](features/settings.md)
- [Users](features/users.md)

### Meta

- [Contributing to this wiki](contributing-docs.md)
- [Working with a local test archive](workflows/local-test-archive.md)

---

## A note on the screenshots

SpeleoLoc's default language is **Romanian**, and the app was photographed as it
ships — so the screenshots show Romanian labels while these pages use the
English ones. English is selected in **Settings → General → App language**.
Every entry in the [screenshot gallery](screenshots/README.md) spells out the
on-screen Romanian wording next to its English equivalent.

## Status

SpeleoLoc is in **alpha**. Some features are partially implemented or subject to
change; where that is the case, the page says so. See the project
[README](../README.md) for release state.

This wiki is a work in progress and is not always level with the app — see
[Contributing to this wiki](contributing-docs.md) for the conventions it
follows.
