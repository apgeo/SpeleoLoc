# Trips

[← Back to index](../README.md)

A **trip** records one caving session in one cave: when it started and
ended, an ordered list of **trip points** (the places you reached), a
generated **trip log**, and the documents you made while it was
running.

Trips are optional — you can use SpeleoLoc purely for navigation and
documentation without ever starting one. But a trip is what a
[trip report](trip-reports.md) is generated from.

## Lifecycle

```
  Start → (Pause ↔ Resume)* → Stop → (Restart → … → Stop)*
```

- **Start** creates the trip, stamps its start time, and makes it the
  one **active trip** on this device.
- **Pause** stops recording without ending the trip.
- **Resume** starts recording again.
- **Stop trip** stamps the end time and leaves no active trip, so
  nothing more is recorded.
- **Restart trip** takes a finished trip and makes it the active one
  again.

Only **one trip** can be active at a time on a device, across all
caves. While a trip is running in cave A you cannot start one in cave
B — you have to stop the first.

A stopped trip is **not** locked. You can still rename it, edit its
log, export a report, delete it, or restart it.

## Starting a trip

There are three ways:

- From a cave's places list: **⋮ → Start trip**. This item only
  appears when no trip is running, in this or any other cave. After
  you confirm, the app opens the cave's **Past / active trip(s)**
  screen.
- From the cave's **Past / active trip(s)** screen: the green
  **Start trip** button.
- By scanning the QR code of a place marked as a cave entrance: the
  app asks *"You scanned a cave entrance. Would you like to start a
  new trip?"*.

All three open the **Start a new trip** dialog, with the **Trip
title** already filled in: the cave name followed by today's date,
for example `Grotte de X 2026/04/22`. If a trip in that cave already
carries exactly that title, the app appends a counter — ` [2]`,
` [3]` and so on — so two trips on the same day never collide. Edit
the title before confirming if you want something more descriptive;
clearing the field keeps the suggestion.

## Trip points

While the trip is running, points are recorded for you. There is no
button that adds one by hand.

- **Scanning a QR code** of a place that belongs to the trip's cave
  adds a trip point (place + current time) and confirms with *"Point
  added to trip"*. Scanning a place in a **different** cave records
  nothing — the place still opens as usual.
- **A detected BLE beacon** adds a trip point under the same
  same-cave rule, with no scanning at all: the toast reads
  *"Place detected: "<place>" · Point added to trip"*, and when the
  app is in the background the notification says whether a point was
  recorded. This is the hands-free way to build a route — see
  [BLE beacons](ble-beacons.md).
- **Entrance places behave differently when scanned.** If the trip
  running is for that same cave, the app asks *"You scanned a cave
  entrance. Are you exiting the cave? Stop the active trip?"*. Answer
  **Yes** and the trip stops; answer **No** and the entrance is
  recorded as an ordinary trip point instead. If the running trip
  belongs to another cave, the app names that cave, offers to stop its
  trip, and then offers to start one here.

Points are ordered by the time they were recorded. The same place can
be recorded several times in one trip — each scan or detection is a
separate point.

> Caution: while the trip is **paused** the confirmation message still
> appears, but no point is stored.

## The trip screen

Open a trip from the trip card in the **⋮** end-drawer menu, or by
tapping it on the cave's **Past / active trip(s)** screen. The screen
has a row of action buttons at the top and opens in list view. On a
phone held in landscape the buttons shrink to icons only — long-press
one to see its name — and the row scrolls sideways when the buttons do
not all fit.

### Summary card and point list

The card at the top shows the cave, **Started**, **Ended** (once the
trip is finished), **Duration** and **Points**, plus a green
**Active trip** or orange **Trip paused** chip while the trip is live.

Below it, every point is listed in visit order with a numbered badge
matching the number on the map, the time it was recorded, and the
place's depth in the cave on the right when that is known. Tap a row
to open that cave place. Before the first point the list reads
*"No points recorded yet"*.

### Map view

If the cave has at least one raster map, the button row also offers
**Map view** (and **List view** to come back). In map view three more
buttons appear: **Play route**, **Fit trip** and **Export map**.

The route is drawn on the map currently selected in the maps strip
above the image:

- a **numbered blue circle** at each point, in visit order, with a
  direction arrow on each connecting line;
- points whose place has no pin on the **selected** map are skipped —
  both the number and the line segment — so switch maps if part of the
  route seems missing;
- when the same place was visited several times, its numbers fan out
  in a ring around the pin instead of hiding one another.

**Play route** reveals the points one at a time, roughly 0.8 s each;
press it again (it turns into a red stop) to jump to the full route.
**Fit trip** zooms and pans so the whole route fits on screen.
**Export map** saves a PNG of the current map view into the app's
documents folder and shows the full path in the confirmation message.

The map here is read-only: tapping a place in the places strip only
highlights it and centres the map on it. It never records a point, and
you cannot move place pins from this screen.

### The ⋮ menu

| Item | What it does |
|---|---|
| **Filter cave places** | Filters the strip of places above the map. |
| **Sort cave places list** | Changes the order of that strip. |
| **Sort maps** | Reorders the raster-map thumbnails. |
| **Manage maps** | Opens the cave's [raster maps](raster-maps.md) screen, so you can add or fix a map without leaving the trip. |
| **Rename trip** | See below. |
| **Delete trip** | See below. |

## Following a running trip from anywhere

While a trip is running, a card sits at the bottom of the **⋮**
end-drawer menu on every screen that has one — green while recording,
orange while paused. It shows the trip title, the cave, how long you
have been underground, the total number of points, and the last five
points with the time each was recorded. Tapping the card opens the
trip.

Three buttons sit at the bottom of the card:

- **View trip** — opens the trip screen.
- **Pause** / **Resume trip** — toggles recording.
- **Stop trip** (red) — stops the trip **immediately, without the
  usual confirmation**. Treat this one with care.

This card is the quickest way back to a running trip, and the only way
to reach a cave's first trip before it has ever been stopped.

## Pausing and resuming

**Pause** stops recording: QR scans and beacon detections no longer
add points, and documents you create are no longer linked to the trip.
**Resume trip** switches recording back on. Pause and resume are on
the trip screen, on the cave's **Past / active trip(s)** screen, and on
the trip card in the ⋮ menu.

Two things are worth knowing before you rely on it:

- **A pause leaves no trace in the trip log.** Nothing in the finished
  record shows where the breaks were.
- **A pause is forgotten if the app is closed.** The active trip
  itself survives the app being closed, killed, or the phone
  rebooting, but the paused state does not — the trip comes back
  recording. After a restart, check the colour of the trip card in the
  ⋮ menu: green means it is recording again.

## The trip log

The trip log is written **by the app**, not by you. It turns the
recorded events — trip started, each point reached, each document
added, restarted, ended — into text. Open it with the **Trip log**
button on the trip screen.

### Log styles

The book icon in the log screen's top bar picks the **log generation
method**. The choice is remembered app-wide and applies to every trip
from then on; the default is **Classic**.

| Style | A point looks like |
|---|---|
| **Raw (timestamps + terse messages)** | `[2026/04/22 10:14:03] Point: "Sala Mare"` |
| **Classic (full sentences)** — default | `[2026/04/22 10:14:03] Arrived at "Sala Mare".` |
| **Field journal (elapsed time + sequence)** | `[10:14 · +1h12min] Moved on to "Sala Mare".` |
| **Narrative (paragraphs)** | prose paragraphs grouping consecutive moves, e.g. *"After 1 h 12 min, the team reached Sala Mare"* |

Picking a different style asks **Regenerate trip log?** and warns that
*"Any manual edits will be lost."* — the whole log is rebuilt from the
recorded events.

### Editing the log

You can type in the log and press the save icon, and that is where
narrative notes belong: weather, team composition, observations not
tied to one place, conclusions. But the app owns this text, so treat
your notes as fragile:

- **Restarting** the trip or **changing the log style** rebuilds the
  whole log from the recorded events; your typed text is gone.
- In the **Raw**, **Classic** and **Field journal** styles a new event
  is only appended to the end, so earlier edits survive it. In the
  **Narrative** style every new point or document rewrites the whole
  log.

Add such notes at the end of the trip, and keep a copy elsewhere if
they matter.

A trip with an empty log cannot be exported as a report: **Export
report** answers *"No trip log to export"*.

## Documents created during a trip

Documents you make with the app's own editors — camera capture, image
and sketch editor, text and rich-text notes, sound recordings — are
linked to the running trip automatically, in addition to the cave or
cave place they belong to, and a line about each appears in the trip
log.

Documents added by attaching an existing file in the document form, or
by bulk import, are not linked, and nothing is linked while the trip is
paused. There is no way to link or unlink a document by hand, and the
trip screens do not list the linked documents — see
[Documents](documents.md) for browsing them.

## Past and active trips

Once a cave has at least one **finished** trip, a
**Past / active trip(s) (N)** button appears under the cave header on
its places list. It opens a screen with:

- a button row: **Start trip** when nothing is running, otherwise
  **Stop trip**, **Pause** / **Resume trip** and **View trip**;
- a highlighted card for the trip that is currently running, if any;
- the cave's finished trips, newest first, with the start date and
  time and the number of points. Tap one to open it.

The buttons and the card act on whichever trip is running, even when
that trip belongs to a **different** cave — which is also why the
**Start trip** button disappears while any trip is active. When the
cave has no finished trips yet and nothing is running, the list reads
*"No past trips"*.

**Export report** and **Delete trip** are not here; they live on the
trip screen itself.

## Renaming a trip

Open the trip and choose **⋮ → Rename trip**, edit the title and
confirm. This works whether the trip is running or finished, and it
changes nothing else — although the log's opening line keeps quoting
the old title until the log is regenerated.

## Stopping a trip

Press the red **Stop trip** button: on the trip screen, on the cave's
**Past / active trip(s)** screen, or on the trip card in the ⋮ menu.
The first two ask *"Stop recording this trip?"*; the card's button
stops immediately, with no confirmation. Scanning the QR code of an
entrance in the trip's own cave also offers to stop it.

Stopping records the end time and clears the active trip. All the
trip's data is kept.

## Restarting a finished trip

When you open a trip that has already ended, the **Stop trip** button
is replaced by a blue **Restart trip** button. Pressing it makes that
trip the active trip again, so new scans and beacon detections keep
adding to the same route instead of starting a fresh trip. Use it when
you stopped a trip by mistake, or when you go back underground the
same day and want one continuous record.

Two consequences:

- Restarting **resets the trip's start time to the moment you
  restart**, so the **Started** time and **Duration** on the trip
  screen now count from the restart, not from your original descent.
- The log is rebuilt at the same time. It keeps the earlier points and
  gains a "restarted" entry between the two runs, but anything you had
  typed into it by hand is lost.

## Deleting a trip

**⋮ → Delete trip** on the trip screen asks *"Delete this trip and all
its points?"*. If the trip is the one currently running it is stopped
first, so you are left with no active trip.

**This is irreversible.** The trip, its points and its log are gone,
and the deletion is passed on to your teammates at the next sync.
Documents that were linked to the trip are **not** deleted — they stay
attached to their cave or cave place and simply lose the trip link.

## Where trip data goes

Trips, their points and their logs live in the database like
everything else, so they are included in archive exports and travel
over [FTP sync](ftp-sync.md) to the rest of the team. Exported report
files and exported map images are ordinary files on the device and are
not synced.

## See also

- [Running a trip](../workflows/running-a-trip.md)
- [Trip reports and templates](trip-reports.md)
- [QR codes](qr-codes.md)
- [BLE beacons](ble-beacons.md)
- [Map viewer](map-viewer.md)
- [Documents](documents.md)
