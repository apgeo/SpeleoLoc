# SpeleoLoc

SpeleoLoc is an application that helps cavers to navigate underground and to document cave systems using QR codes and BLE beacons to identify places in caves.

## Project goals

One of the main goals of SpeleoLoc is underground positioning, designed to help exploration teams navigate more easily through complex cave systems and to help during all exploration phases. Another key goal is to simplify cave documentation and automate the information flow, both during exploration and in later analysis.

The system is based on placing QR code labels at points of interest inside caves, in both already known areas and newly explored sections. QR codes are scanned in the app and linked to corresponding points on existing maps, creating a practical form of underground "geolocation".

Each mapped point can store additional information, including text and media. After data synchronization between mobile devices, other teams can later identify their exact position on system maps, review existing information, and add new observations.

Another component of the system is placing QR codes at the entrance of explored caves. The payload in these QR codes is a weblink that can be scanned both with SpeleoLoc but could optionally be linked with a website in order to open on any mobile device online for broader access to relevant information.

## Features

- **Caves and places** — caves, cave areas, surface areas and the points of interest inside a
  cave, with entrances, depth, GPS positions and place codes; lists with filtering, sorting,
  grouping and batch selection.
- **Underground positioning** — QR labels (generated and printed as PDF sheets, also readable by a
  phone without the app through a web link) and BLE beacons detected automatically, in the
  background on Android too. Ruuvi sensor tags with live readings and history download.
- **Raster maps** — cave maps with the places defined on them, a full-screen viewer, image filters
  and the trip route drawn on top.
- **3D survey models** — Therion `.lox` and Survex `.3d` surveys in a 3D viewer, with cave places
  mapped to survey stations.
- **Surface map** — every cave entrance on a geographic map with online base maps, an offline tile
  cache and MBTiles layers; GPS with averaged fixes, distance and bearing measuring, UTM and DMS
  coordinates, GPX/KML export and import.
- **Documents** — photos, videos, audio recordings, text and rich-text notes, sketches and files
  attached to caves, places and trips; bulk import and an image gallery.
- **Trips** — start, pause and stop a trip, record points from QR scans and beacons, add and edit
  points afterwards or build them from the photos taken underground; participants, a trip log,
  and reports exported from ODT/DOCX templates.
- **Sharing data** — export and import of archives (replace or merge), FTP/SFTP sync with pinned
  SFTP host keys, two-way sync with a club's SilexGIS server, a change log with the caver who made
  each change, and CSV import of caves and places.
- **Users** — each change is stamped with the caver who made it; the app asks who is using it on
  first start.
- English and Romanian interface, help tours on the main screens; Android first, with iOS and
  desktop builds.

## Current status
The application is under development, in an alpha stage - some of the functionality is not tested
extensively. Download the [latest release](https://github.com/apgeo/SpeleoLoc/releases/latest);
what each release brought is listed in [What's new](docs/whats-new.md).

## Building it

Developer setup — Flutter, the Linux desktop target and the optional Android SDK, with the exact
commands and the traps — is in [DEVELOPMENT.md](DEVELOPMENT.md).

## Docs
Check the [user documentation](docs/README.md) (English and Romanian), also published at
<https://speotopo.ro/speleoloc/docs/> (might not be always up to date).

## Future development
- In cave sync between devices via bluetooth