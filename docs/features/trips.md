# Trips

[← Back to index](../README.md)

A **trip** records one caving session in one cave: when it started and
ended, who took part, an ordered list of **trip points** (the places you
reached), a generated **trip log**, and the documents and pictures that
go with it.

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

A stopped trip is **not** locked. You can still rename it, add, move or
remove its points, correct its start and end times, fill in its
participants, edit its log, export a report, delete it, or restart it.

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

While the trip is running, points are recorded for you:

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

Points do not have to come from scans. You can add, move and remove them
yourself, during the trip or long after it — see
[Correcting the points](#correcting-the-points) — and build them from
the photos and videos you took underground — see
[Points from pictures](#points-from-pictures).

## The trip screen

Open a trip from the trip card in the **⋮** end-drawer menu, or by
tapping it on the cave's **Past / active trip(s)** screen. The screen
has a row of action buttons at the top and opens in list view. On a
phone held in landscape the buttons shrink to icons only — long-press
one to see its name — and the row scrolls sideways when the buttons do
not all fit.

| Button | What it does |
|---|---|
| **Stop trip** / **Pause** / **Resume trip** | Shown while this trip is the active one. See [Pausing and resuming](#pausing-and-resuming) and [Stopping a trip](#stopping-a-trip). |
| **Restart trip** | Shown instead once the trip has ended. See [Restarting a finished trip](#restarting-a-finished-trip). |
| **Add point** | Records a point at a place and time you choose. See [Correcting the points](#correcting-the-points). |
| **Pictures** | Opens **Points from pictures**. See [Points from pictures](#points-from-pictures). |
| **Trip log** | Opens the log. See [The trip log](#the-trip-log). |
| **Export report** | See [Trip reports](trip-reports.md). |
| **Map view** / **List view** | Only when the cave has at least one raster map. See [Map view](#map-view). |

### Summary card and point list

The card at the top shows the cave, **Started**, **Ended** (once the
trip is finished), **Duration** and **Points**, plus a green
**Active trip** or orange **Trip paused** chip while the trip is live.
Under the times it shows the trip's **Participants** and the start of
its details, or an **Add participants and details** button while there
are none; tap either to edit them — see
[Participants and details](#participants-and-details).

When points were changed and the log was left as it was, a card under
the summary says **The trip log is out of date** — see
[When the points change](#when-the-points-change).

Below it, every point is listed in visit order with a numbered badge
matching the number on the map, the time it was recorded, and the
place's depth in the cave on the right when that is known. Tap a row
to open that cave place. Before the first point the list reads
*"No points recorded yet"*.

Two more controls sit at the right of a row:

- a **picture icon with a count**, on points that have pictures bound to
  them (see [Points from pictures](#points-from-pictures)). Tap it for
  **Pictures at this point**, a sheet of those pictures; tap one to open
  it. The sheet is for looking only — the same files are attached to the
  cave place and appear among its documents too;
- a **⋮** button (**Point actions**) with **Change time** and **Delete
  point**.

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
| **Points from pictures** | The same screen as the **Pictures** button. See [Points from pictures](#points-from-pictures). |
| **Participants and details** | See [Participants and details](#participants-and-details). |
| **Start and end times** | See [Correcting the start and end times](#correcting-the-start-and-end-times). |
| **Rename trip** | See below. |
| **Delete trip** | See below. |

## Correcting the points

A missed scan, a label that would not read, a trip written up the
evening after: every point can be added, moved or removed by hand, on a
running trip or on one that ended long ago.

- **Add point** in the button row asks you to **Choose a place** from the
  trip's cave (with a **Search** box), then for the **Point time** —
  a **Date** and a **Time**. The time starts at the moment of asking on a
  running trip, and at the trip's end on a finished one. The point is
  recorded exactly as a scan at that moment would have been, and it is
  recorded even while the trip is paused.
- **⋮ → Change time** on a point's row moves it to another moment. The
  list re-orders itself by time, and the numbers on the map follow.
- **⋮ → Delete point** asks *"Remove the point "…" from this trip?"*.
  The pictures bound to that point stay on the cave place.

A time before the trip started or after it ended is allowed, but the
time dialog says so in orange while you choose it — *"This time is
before the trip started (…)."* — so that you commit to it knowingly. The
same place cannot be recorded twice at exactly the same moment: the app
refuses with *"This place is already recorded at that time"*.

Every one of these changes alters what the log should say. What happens
to the log then is decided by a setting — see
[When the points change](#when-the-points-change).

## Correcting the start and end times

**⋮ → Start and end times** shows **Started** and, for a finished trip,
**Ended**; tap either to pick a new date and time. It exists mainly for
trips entered after the fact, whose recorded times are the moment you
typed them in rather than the moment you went underground, and for
putting back the original start after a **Restart trip**.

- A running trip offers only its start — *"The trip is still running;
  its end is set when you stop it."*
- An end before the start is refused: *"The end is before the start."*,
  and **OK** stays greyed out.
- If recorded points would fall outside the new times, the dialog counts
  them — *"N recorded point(s) would fall outside these times. They are
  kept as they are."* Nothing is moved or deleted for you.

Saving shows **Trip times saved**. The log is treated as for a change to
the points.

## Participants and details

**⋮ → Participants and details**, or a tap on the participants line of
the summary card, opens a page with two fields:

- **Participants** — names separated by commas, typed in one go. Each
  name appears as a chip under the field, showing how the text was
  understood; the × on a chip takes that name out again. The button at
  the end of the field (**Add a participant**) asks for a single
  **Name** instead. A name given twice is kept once.
- **Details** — free text for anything else worth keeping about the
  trip: its aim, the weather, the equipment, what was found.

Press **Save** to keep them (*"Trip details saved"*). Both travel to the
team with the trip. They are not written into the trip log, so they do
not reach an exported report on their own — copy them into the log or
the report template if you want them there.

## Points from pictures

Most cavers come out with a camera roll, not a tidy list of scans. The
**Points from pictures** screen — the **Pictures** button, or
**⋮ → Points from pictures** — turns the photos and videos on the device
into trip points at the moments they were taken, and can attach the
pictures themselves to the places and points they belong to.

The screen is a worksheet: nothing is written until you press the
**Add N** button at the bottom, so you can work through a few hundred
pictures and correct them first.

### Which pictures are listed

The date range at the top starts as the trip's own days, from the day it
started to the day it ended (today, for a running trip). Tap it to
choose other days; the refresh button (**Reload**) reads the list again.
Pictures are listed by when they were taken, which for pictures copied
over from a waterproof camera or a teammate's phone is the camera's own
capture time, not the day the file arrived — so set the camera's clock
before the trip.

Where the pictures come from depends on what the phone lets the app see.
A line under the date range says which case you are in:

| Line | Meaning | Buttons |
|---|---|---|
| *Listing the photos and videos on this device.* | Full access to the photo library. | **Pick files instead** |
| *Only the pictures you allowed access to are listed.* | You gave access to selected photos only. | **Choose more photos**, **Pick files instead** |
| *No access to the photo library, so only files you pick are listed. …* | No library access: you choose files one batch at a time. | **Add files**, **Allow access to all photos** |
| *Listing the files you picked.* | You chose files although the library was available. | **Add files**, **Use the photo library** |

For picked files the time comes from the file itself and can be less
exact. A clock icon beside a picture's time means the camera recorded
no capture time and the file's own date was used instead — which may be
when it was copied rather than when it was taken.

### Reading the QR labels in the pictures

If you photographed the QR labels at the places you passed, the app
reads them for you. Once the list is on screen it goes through the
photos of the selected days one by one — *"Looking for QR codes on the
selected days: 12/80 (5 found)"* — and fills in the place wherever it
finds the label of a place in the trip's cave, marked with a small green
QR icon. **Stop** ends the search early; whatever it found so far stays.
Videos are not searched.

The search never overwrites a place you have already chosen yourself.
What it read is remembered on this device, so opening the screen again
on the same pictures is quick; the match against places is made afresh
each time, so a place whose code changed is still found correctly. Some
devices cannot read codes from saved pictures at all; the screen then
says *"This device cannot read QR codes from saved pictures — choose the
places yourself."*

### Choosing places and times by hand

Tap a picture's row (or **⋮ → Choose the place**) to pick its place. The
row's **⋮** also offers **Change time**, which moves the point that
picture will create without touching the picture, and **Clear**, which
removes the place. A row can be ticked only once it has a place, and it
is ticked as soon as it gets one; untick the ones you do not want.

### Adding the points

**Also store the pictures**, on by default, attaches each ticked picture
to its cave place and binds it to the track point it creates, so it
appears behind that point's picture icon on the trip screen. Your
[image compression](settings.md#image-compression) settings apply. With
it off, only the points are added.

Press **Add N**. If any ticked picture is at an entrance of the cave,
an **Entrance pictures** dialog comes first, because a picture at an
entrance records going in or coming out and may contradict what the
trip already holds. It can offer to:

- remove the entrance points already on the trip, each one ticked
  separately;
- **Move the trip start** to an entrance picture's time;
- **Move the trip end** likewise, on a finished trip.

Two or more entrance pictures read as "went in at the first, came out at
the last"; a single one moves whichever end of the trip it is nearer to.
**Everything in this dialog starts switched off** — press **OK**
untouched and the points are simply added.

The points are then added, with a progress line, and the screen closes
with a summary such as *"7 point(s) added · 2 already recorded · 7
picture(s) stored"*. A picture whose place is already recorded at that
exact moment adds no second point, but is still bound to the existing
one. While points are being added the screen cannot be left.

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
- **Regenerating** after the points were changed does the same — see
  below.
- In the **Raw**, **Classic** and **Field journal** styles a new event
  is only appended to the end, so earlier edits survive it. In the
  **Narrative** style every new point or document rewrites the whole
  log.

Add such notes at the end of the trip, and keep a copy elsewhere if
they matter.

A trip with an empty log cannot be exported as a report: **Export
report** answers *"No trip log to export"*.

### When the points change

Adding, moving or deleting a point, correcting the trip's times or
adding points from pictures all change what the log ought to say. What
happens to the log then is set in **Settings → Trip log → Regenerate the
log when points change**, which is **off** by default. The log page says
which way it is set, with a gear button that opens the setting.

- **Off** — the log stays as you wrote it, and the trip is marked as
  having an out-of-date log. Nothing you typed is lost.
- **On** — the log is rewritten from the points in the current log
  style. If it still reads exactly as the points would produce it, that
  happens silently. If it holds anything else — text you typed, or
  changes it had fallen behind — the app asks first, in a dialog headed
  **Regenerating would replace text in the log**: **Regenerate**, **Keep
  as written** (which marks it out of date instead), or **Cancel**, which
  abandons the change to the points as well.

While a log is out of date, both the trip screen and the log page show
a card: **The trip log is out of date** — *"Points have changed since …
and the log was not regenerated, so it no longer matches them."* It
offers:

- **Regenerate** — asks **Regenerate the trip log?**, warns that
  anything typed by hand is replaced, then rewrites the log from the
  points;
- **Keep as written** — accepts the log as it is and removes the card;
  the text is not touched;
- **Trip log settings** — opens the setting above.

Live scans and beacon detections are not edits: they keep adding to the
log as described above, whichever way the setting is.

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

Pictures stored through [Points from pictures](#points-from-pictures)
are bound differently: each one to the **track point** it created, as
well as to its cave place. Those are the ones the picture icon on a
point's row shows.

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
  **⋮ → Start and end times** puts the original start back.
- The log is rebuilt at the same time. It keeps the earlier points and
  gains a "restarted" entry between the two runs, but anything you had
  typed into it by hand is lost.

## Deleting a trip

**⋮ → Delete trip** on the trip screen asks *"Delete this trip and all
its points?"*. If the trip is the one currently running it is stopped
first, so you are left with no active trip.

**This is irreversible.** The trip, its points and its log are gone,
and the deletion is passed on to your teammates at the next sync.
Documents that were linked to the trip, and pictures bound to its
points, are **not** deleted — they stay attached to their cave or cave
place and simply lose the trip link.

## Where trip data goes

Trips, their points, their participants and details, their logs and the
links between pictures and points live in the database like everything
else, so they are included in archive exports and travel over
[FTP sync](ftp-sync.md) to the rest of the team. Exported report files
and exported map images are ordinary files on the device and are not
synced. Neither is what **Points from pictures** read from your
pictures' QR labels: that refers to pictures on this device only.

## See also

- [Running a trip](../workflows/running-a-trip.md)
- [Trip reports and templates](trip-reports.md)
- [QR codes](qr-codes.md)
- [BLE beacons](ble-beacons.md)
- [Map viewer](map-viewer.md)
- [Documents](documents.md)
