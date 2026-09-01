# Home screen

[← Back to index](../README.md)

The home screen — titled **Speleo Loc** — is the app's entry point. It lists
every cave stored on the device and gathers the actions that apply to caves
as a whole: scanning, adding, importing, mapping, syncing and printing QR
sheets.

> 📷 [The home screen and its cave list](../screenshots/01-home-and-caves.md#home-cave-list) — The home screen lists every cave with its place and raster-map counts.

## The top bar

The top bar holds the app title on the left and the **⋮** button on the
right. What sits between them depends on the action toolbar:

- while the action toolbar is shown — the default — the top bar carries
  nothing else;
- while the toolbar is hidden, three icons move up into the top bar:
  **Scan QR**, **Add new cave** and **FTP / SFTP sync**.

Tapping **⋮** opens the app menu, described further down this page.
Repeatedly tapping the title switches the hidden **debug mode** on and off —
also described below.

## The action toolbar

A row of icon buttons sits directly under the title bar. It is shown by
default and holds, from left to right:

| Button | What it does |
| --- | --- |
| **Scan QR** | Opens the camera scanner. See [QR codes](qr-codes.md). |
| **Add new cave** | Opens the new-cave form. See [Caves and cave areas](caves-and-areas.md). |
| **Documents** | Opens the browser holding every document in the app. See [Documents](documents.md). |
| **Cave map** | Opens the [cave map](surface-map.md) on the caves currently in scope. |
| **Manage surface areas** | Opens the list of [surface areas](surface-areas.md). |
| **Import caves - CSV** | Bulk-creates caves from a CSV file. See [CSV import](csv-import.md). |
| **Import cave documents** | Attaches a folder of files to several caves at once. |
| **Settings** | Opens [Settings](settings.md). |
| **Man. sync** | Opens the [sync dashboard](sync-and-change-log.md). |
| **FTP / SFTP sync** | Starts a sync at once and opens the [progress page](ftp-sync.md). |

The buttons are icons only; hold one down to see its name.

**FTP / SFTP sync** is the one button with no confirmation step: it starts a
sync with your default server profile the moment you tap it, then opens the
progress page. If no default profile is set, or no password is stored for
it, the run fails immediately and the progress page shows the error. If a
sync is already under way, tapping simply takes you to it.

Importing cave *places* from a CSV is not offered here — open the cave and
use **Import places from CSV** in its places list.

### Hiding and showing the toolbar

The **Hide action toolbar** button at the right-hand end of the cave-list
header folds the toolbar away; the same button then reads **Show action
toolbar** and brings it back. The switch in **Settings → General → Show
home toolbar** ("Display scan/add/docs/settings buttons in a toolbar on the
home page") controls exactly the same thing, so the two always agree once
you have used either of them. On a brand-new install the toolbar is shown
even though that switch still reads off; turning it on and off again puts
the display in step with the switch.

Hiding the toolbar does not move its actions into the ⋮ menu — the menu is
the same either way. Only **Scan QR**, **Add new cave** and **FTP / SFTP
sync** reappear, in the top bar.

### Scan QR and typing a code by hand

Tapping **Scan QR** opens the scanner; a recognised code jumps straight to
the place it belongs to. To type a code in by hand — when a label is too
damaged or too dirty to scan — open the cave's places list and use its
**Manual QR code search** button, which shows a **QR code identifier** box
with a **Search place by QR code id** button. (In developer builds, holding
the scan button down for about two and a half seconds opens the same search
from the home screen; that shortcut is not in the released app.)

## The cave list

Each row shows the cave title, the name of its surface area underneath (when
it has one), and two counters: a pin icon with the number of
[cave places](cave-places.md) and a map icon with the number of
[raster maps](raster-maps.md). Tapping a row opens that cave's places list.

The list keeps itself up to date: caves added, changed or removed by an
import, a sync or another screen appear immediately, so there is no
pull-to-refresh to look for.

Cave rows have no long-press or swipe actions. To rename a cave, open it and
use **⋮ → Edit cave**; to delete caves, use selection mode as described
below.

### Filtering and sorting

The cave-list header carries the label **Caves:** with a count, then the
buttons **Selection mode**, **Sort by**, **Show filter**, **Generate QR
codes for caves** and the toolbar toggle.

- **Show filter** opens a box above the list. What you type is matched
  against both the cave title and its surface-area name, so an area name is
  a quick way to narrow the list to one region. While a filter is active
  the count changes from, say, "(45)" to "(5 /45)". Closing the box clears
  the filter.
- **Sort by** offers **Last modified** (the default, newest first),
  **Title**, **Surface area** and **Number of cave places**, each ascending
  or descending, with an optional second field. Sorting by Title or by
  Surface area also groups the rows under headings. Your choice is
  remembered for next time.

The same header behaves the same way on the other lists in the app — see
[Filtering, sorting and selecting in lists](lists-filter-sort-select.md).

### Selection mode

Tapping the checklist icon (**Selection mode**) puts a checkbox on every
row; tapping it again leaves selection mode and clears the ticks. While
selection mode is on, tapping a row ticks or unticks it instead of opening
the cave, and three more buttons appear in the header:

- **Select all** — ticks every cave *currently visible after the filter*,
  not the whole database;
- **Invert selection** — flips the ticks on the visible caves;
- **Delete selected** — see below.

> 📷 [Selection mode on the cave list](../screenshots/01-home-and-caves.md#home-cave-list-selection-mode) — The home cave list in selection mode, with two caves checked.

### Deleting caves

Deleting a cave takes all of its places, raster maps and trips with it, and
it cannot be undone. Documents are not deleted: they stay in the app, but
lose their link to the cave. The app therefore asks three times:

1. "Delete the selected N item(s)?"
2. "Permanently delete N cave(s) and all their data? This cannot be undone."
3. "Confirm again: delete N cave(s) with all their places, maps, and
   records?"

The buttons on the third dialog are deliberately swapped — **Delete** on the
left, **Cancel** on the right — so read it before tapping.

**Delete selected** only appears while **Settings → General → Allow bulk
deletion of caves** is on. It is on by default; turning it off removes the
only way of deleting a cave from this screen.

### Actions that follow the selection or the filter

Four actions work on a set of caves rather than on all of them: **Cave
map**, **Import cave documents**, **Export places (GPX/KML)** and **Generate
QR codes for caves**. They all use the same rule, without saying so on
screen:

- with selection mode on, they use only the ticked caves;
- otherwise they use every cave still visible after the current filter.

So typing a few letters into the filter box, or ticking three caves, is the
way to limit a map view, an export or a QR sheet to just those caves. If the
scope comes out empty, **Import cave documents**, **Generate QR codes for
caves** and **Export places (GPX/KML)** stop with a short message — for
example "No caves to import documents to." — rather than doing nothing.
**Cave map** is the exception: an empty scope is treated as no scope at all,
and the map opens on every cave.

### Generate QR codes for caves

The QR button in the cave-list header collects the places of every cave in
scope and opens the printable QR sheet for them, which is the quickest way
to produce entrance labels for a whole area in one go.

1. Narrow the list with the filter, or tick the caves you want.
2. Tap **Generate QR codes for caves**.
3. If any of those caves holds places that are not entrances, the app asks
   **Generate QR codes**: choose **Entrances only** or **All places**.
4. The QR sheet opens, ready to print or export. See
   [QR codes](qr-codes.md).

If there is nothing to work with you get "No caves to generate QR codes for"
or "No cave places to generate QR codes for".

## The ⋮ app menu

The **⋮** button opens a drawer from the right-hand edge. Its top part is
specific to the home screen; everything below the divider is the same on
every screen in the app.

> 📷 [The global menu (end drawer)](../screenshots/01-home-and-caves.md#home-global-menu) — The global end drawer opened from the home screen's overflow button.

### Home entries

- **Add new cave** — opens the new-cave form.
- **Documents** — opens the browser holding every document in the app.
- **Manage surface areas** — see [Surface areas](surface-areas.md).
- **Import caves - CSV** — see [CSV import](csv-import.md).
- **Import cave documents** — you pick a folder, and each of its subfolders
  is matched to one of the caves in scope; the files inside are imported as
  that cave's documents. It is meant for photos and notes organised on a
  computer as one folder per cave.
- **Cave map** — the [cave map](surface-map.md), framed on the caves in
  scope.
- **Export places (GPX/KML)** — writes the places of the caves in scope to a
  GPX or KML file for Garmin, Locus, QGIS or Google Earth. Only places that
  have coordinates are written; if none do, you get "No places with
  coordinates to export".
- **Import places (GPX/KML)** — reads such a file back in; you pick the file
  first, then choose which cave the waypoints belong to.

These two menu entries are the only way to reach GPX/KML transfer — there
are no toolbar buttons for it. See
[GPX/KML place transfer](place-transfer.md).

### Shared navigation and cards

Below the divider the drawer shows a row of navigation icons — **Caves**,
**Man. sync** (the [sync dashboard](sync-and-change-log.md)), **Documents**,
**Settings** and **Scan** — followed by:

- a **Beacon detection** switch. It is not a link but the same master
  switch as the one in Settings, so you can silence or re-enable automatic
  detection without leaving the screen you are on; turning it on asks for
  the same permissions. See [BLE beacons](ble-beacons.md).
- an **FTP sync** card pinned near the bottom. With no server profile it
  reads "Configure FTP to enable sync" and takes you to the FTP settings.
  With a profile it shows **Sync now** and the profile name, and starts the
  sync when you tap it; while a run is in progress it becomes a progress bar
  with the current phase and a pause button; afterwards it shows the result
  — green when complete, red when failed, orange when cancelled — with a
  button to start another run. Tapping the card during or after a run opens
  the full [progress page](ftp-sync.md).
- a card for the **running trip**, when there is one: green while
  recording, orange while paused. It gives the trip title, the cave, how
  long the trip has run, how many points it holds and the last five scanned
  places with their times, plus buttons to view the trip, pause or resume
  it, and stop it. This is the fastest way to pause a trip mid-cave. See
  [Trips](trips.md).

At the very bottom sit a **Help tour** (?) button, an **About** (i) button
and the installed version, printed as something like "v0.2.1+328" — quote
that when reporting a problem. The About dialog itself only links to the
SpeoSilex site and to the project's page on GitHub.

The menu normally opens as this drawer. If it ever opens as a compact popup
list instead, the button at the bottom of that list turns it back into the
drawer for good, on every screen.

## The first-run offer of test data

In a developer build, on any of the first four app starts and only when the
build carries a test-data source, if there are no caves yet the app asks
**Load test data?** — "The database is empty. Would you like to populate it
with sample caves and places for testing?" The released app never asks.

Accepting is destructive and cannot be undone: it replaces the whole local
database and every stored file with the contents of a ready-made test
archive, then restarts the app. When the app finds raster maps or documents
already on the device, the dialog adds the warning "Warning: existing raster
maps and/or documents will be permanently deleted and replaced by the test
data." Choose **No** to carry on with an empty database.

If you accept, the archive is fetched — downloaded, when the installed build
points at a web address — behind a "Downloading test data archive..."
dialog, imported, and the app restarts on the sample data. Builds that carry
no test archive do not put the question up at all — nothing appears and
nothing changes.

See [Getting started](../getting-started.md), and
[Database export and import](database-export-import.md) if you want to save
what you already have first.

## Guided tours

The first time you open a screen that has a tour, its hints appear on their
own, each step with a **Next** button, a **Skip** button and a **Disable
auto tours** button. Each screen remembers that you have seen its tour. On
the home screen the tour waits for the "Load test data?" question to be
answered before it starts, so the two do not fight for the screen.

**Disable auto tours** stops the automatic hints everywhere and confirms
with "Automatic tours were disabled. You can still start Help tour manually
from the menu." The **Help tour** button at the bottom of the ⋮ menu
replays the hints for whichever screen you are on, whether or not automatic
tours are off.

## Debug mode

Tapping the app title nine times, with no more than about three seconds
between taps, switches on **debug mode** and shows a confirmation message.
Switching it back off takes twenty taps. Debug mode is not remembered — it
is off again after the next app start.

While it is on, Settings gains a **Debug Info** section (database path, data
directory, configuration table) and the app records more detailed logs. In a
developer build **Settings → Database** also gains an **Open SQL command
runner** button; the released app does not have it at all. None of it is
needed for normal caving use; the SQL runner in particular writes directly
to the database and can damage your data.

## See also

- [Caves and cave areas](caves-and-areas.md)
- [Filtering, sorting and selecting in lists](lists-filter-sort-select.md)
- [Cave places](cave-places.md)
- [Sync dashboard & change log](sync-and-change-log.md)
- [FTP sync](ftp-sync.md)
- [Settings](settings.md)
