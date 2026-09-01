# Workflow: Running a caving trip

[← Back to index](../README.md)

A **trip** records one caving session in one cave: when it started, the
places you reached and in what order, a log the app writes for you, and
the documents you made along the way. This page walks the whole thing
through, from the car park to the finished report.

## When a trip is worth starting

Start a trip when you want:

- a **route** drawn on the cave's raster maps, point by point;
- a **timestamped list** of the places you reached;
- an **ODT or DOCX report** generated afterwards;
- the documents you made underground grouped with the session.

If you only want to look up existing data or attach one photo to a
place, you do not need a trip — see
[Navigating underground](navigating-underground.md).

## One trip at a time, for the whole app

SpeleoLoc tracks **one active trip at a time across every cave**, not
one per cave. While a trip is running:

- **Start trip** disappears from every cave's **⋮** menu, including
  other caves';
- another cave's **Past / active trip(s)** screen still shows the
  running trip, even though it belongs to a different cave.

To pick the trip up again from anywhere, open the **⋮** app menu (the
drawer that slides in from the right edge) and scroll to the bottom.
The trip card there carries **View trip**, **Pause** / **Resume trip**
and a red stop button.

## Before you descend

- Import the latest team archive or run a sync, so the cave's places
  and maps are current. See [Sharing data](sharing-data.md).
- Charge the device and bring a power bank.
- If you will rely on beacons, switch automatic detection on before you
  go in — there is a quick toggle in the **⋮** app menu. See
  [BLE beacons](../features/ble-beacons.md).
- If you want a report the same evening, add a template first (see
  [Export a report](#step-6--export-a-report)); the template screen is
  only reachable from the export flow.

## Step 1 — Start the trip

From the cave:

1. Open the cave (Home → tap the cave). You land on its places list.
2. Open the **⋮** menu and choose **Start trip** (green play icon).
   If the item is missing, a trip is already running somewhere — stop
   it first.
3. The **Start a new trip** dialog opens with **Trip title** already
   filled in: the cave name and today's date, for example
   `Grotte de X 2026/04/22`. If a trip in that cave already has exactly
   that title the app appends a counter — ` [2]`, then ` [3]` — so two
   trips on the same day never collide. Replace the title with
   something more useful if you like; clearing the field keeps the
   suggestion.
4. Confirm. The trip starts and the app opens the cave's
   **Past / active trip(s)** screen, where the running trip appears as
   a green card. From now on it also appears as a card at the bottom of
   the **⋮** app menu, on every screen.

The same **Start trip** button sits at the top of the cave's
**Past / active trip(s)** screen.

### Starting by scanning the entrance

You can run the whole thing without opening a menu. Scan the QR code of
a place marked as a cave entrance and, with no trip running, the app
asks *"You scanned a cave entrance. Would you like to start a new
trip?"*, then shows the same title dialog.

If a trip is already running for a **different** cave, the app names
that cave and asks whether to stop its trip; say yes and it then offers
*"Would you like to start a new trip for this cave?"*.

## Step 2 — Underground

There is no "add point" button. Points record themselves:

| What you do | What is recorded |
|---|---|
| Scan the QR code of a place **in this cave** | A trip point, confirmed with *"Point added to trip"* |
| A **BLE beacon** for a place in this cave is detected | The same trip point, hands-free |
| Scan a place in **another** cave | Nothing — the place still opens normally |
| Scan an **entrance** of this cave | The app asks whether you are leaving (see below) |

Beacon detection is the hands-free case: with automatic detection on,
the phone can stay in a pocket and the route fills in as you pass each
beaconed place. On screen you get *"Place detected: …"* followed by
*"Point added to trip"*; in the background the same arrives as a
notification, which adds *"Point added to trip"* only when a point was
recorded.

The same place can be recorded several times — every scan or detection
is its own point, so a there-and-back route shows both passes.

### Documents you make during the trip

Every document you create while the trip is recording — photo, audio
note, text note — is linked to the trip as well as to its place, and
the trip log gains a line for it. No screen lists a trip's documents,
but the link is kept and travels with sync and export. See
[Documents](../features/documents.md).

### Checking progress without leaving what you are doing

Open the **⋮** app menu and look at the bottom card. It shows the trip
title, the cave, how long you have been underground, the total number
of points and the last five with the time each was recorded.

### Pausing

Press **Pause** — on the trip card, on the trip screen's button row, or
on the **Past / active trip(s)** screen — to stop recording during a
surface break or a side passage you do not want on the route. The card
and the summary chip turn orange and read **Trip paused**. **Resume
trip** starts recording again.

Two things to know about pause:

- It is **forgotten if the app restarts**. The trip itself survives the
  app being closed, killed or the phone rebooting, but it comes back
  **recording**. After any restart, check the colour of the trip card:
  green means it is recording again.
- It leaves **no trace in the trip log**, so the finished record does
  not show where the breaks were.

## Step 3 — Stop the trip

1. Press the red **Stop trip** button. It is in the trip screen's
   button row, on the cave's **Past / active trip(s)** screen, and on
   the trip card in the **⋮** app menu.
2. The first two ask *"Stop recording this trip?"* — confirm. **The
   button on the drawer card stops the trip immediately, with no
   confirmation.**

On the way out you can instead scan the entrance QR code: the app asks
*"You scanned a cave entrance. Are you exiting the cave? Stop the
active trip?"*. Answer **Yes** and the trip ends; answer **No** and the
entrance is recorded as an ordinary trip point.

A stopped trip is **not** locked. Its route, log, linked documents and
times are preserved, it joins the cave's trip history, and you can
still rename it, edit its log, export it, delete it or restart it.

## Step 4 — Review the route

Open the trip from the cave's **Past / active trip(s)** screen, or from
the drawer card while it is still running. The screen opens in list
view: a summary card with the cave, **Started**, **Ended**,
**Duration** and **Points**, then every point in visit order with a
numbered badge, the time, and the place's depth on the right where it
is known. Tap a row to open that cave place.

If the cave has at least one raster map, the button row also offers
**Map view**. There the route is drawn as a blue line with direction
arrows and a numbered blue circle at each point, and three more buttons
appear:

- **Play route** — animates the route, revealing the points one at a
  time at roughly one every 0.8 seconds. Press it again (it has turned
  into a red stop) to jump to the finished route.
- **Fit trip** — zooms and pans so the whole route fits on screen.
- **Export map** — saves a picture of the current view into the app's
  documents folder; the confirmation message shows the file path.

If a stretch of the route is missing, you are probably on the wrong
map: points whose place has no pin on the **selected** map are skipped
entirely, both the number and the line to it. Pick another map in the
strip above the image.

On a phone held in landscape the button row shrinks to icons only and
scrolls sideways — long-press an icon to see its name.

## Step 5 — The trip log

The trip log is **written by the app** from the recorded events; it is
not a blank notebook. Open the trip and press **Trip log**. You can
edit the text freely and press the save icon to keep it.

To change the writing style, press the book icon in the log's app bar:

| Style | What it reads like |
|---|---|
| Raw (timestamps + terse messages) | One dated line per event |
| Classic (full sentences) | The default — "Arrived at …" |
| Field journal (elapsed time + sequence) | "First stop …", "Moved on to …" |
| Narrative (paragraphs) | Flowing prose; the best base for a report |

Switching asks **"Regenerate trip log?"** and warns that any manual
edits will be lost — the whole log is rebuilt from the recorded events.
The choice is stored for the app as a whole and is used for future
trips too.

Your typed text also disappears if you press **Restart trip**, which
rebuilds the log. New points added while the trip runs are *appended*
in the Raw, Classic and Field journal styles, so they do not disturb
text you have already written. Narrative is the exception: every new
point rebuilds the whole log, and manual edits go with it.

## Step 6 — Export a report

1. Open the trip and press **Export report**.
2. Pick a template in the **Select a template** dialog. The output
   format is the template's own — an ODT template produces ODT, a DOCX
   template produces DOCX — and each template's format is shown under
   its name. There is no format choice.
   - If you have no templates yet, the app says *"No templates
     available. Add a template first."* and offers **Manage
     templates**. The same button sits under the template list. This is
     the only way to reach the template screen — nothing in Home,
     Settings or the app menu opens it.
   - If the trip log is empty the export is refused with *"No trip log
     to export"*. Open **Trip log** first.
3. Choose where to save the file. The report is the template with the
   trip log text appended — the route map is **not** included; export
   it separately with **Export map**.
4. After saving, the app hands the file to your device's default
   application for that format and it opens.

See [Trip reports](../features/trip-reports.md) for templates in
detail.

## Step 7 — Get it to the team

Trips, their points and their document links are ordinary records: they
travel to teammates through a sync or an exported archive, like
everything else. Report templates are the exception: what travels is
the entry in the template list, never the ODT or DOCX file behind it,
so every device has to add its own copy. See
[Sharing data](sharing-data.md).

## Fixing mistakes afterwards

**Stopped the trip too early, or went back in the same day.** Open the
trip; where the red stop button was there is now a blue **Restart
trip**. Pressing it makes that trip the active trip again, so new scans
and beacon detections keep adding to the same route. Two consequences:
the start time is **reset to the moment you restart**, so **Started**
and **Duration** now count from there rather than from your original
departure; and the log is rebuilt, keeping the earlier points and
gaining a "restarted" line, but losing anything you typed by hand.

**The title is useless.** Open the trip and choose **⋮ → Rename trip**.
This works on running and finished trips alike and touches nothing
else, although the log's opening line keeps quoting the old title until
the log is regenerated.

**The trip was a mistake.** **⋮ → Delete trip** asks *"Delete this trip
and all its points?"*. **This cannot be undone**, and the deletion is
passed on to teammates at the next sync. If the trip being deleted is
the running one, it is stopped first, leaving you with no active trip.
Documents that were linked to it are **not** deleted — they stay on
their cave or cave place and simply lose the connection to the trip.

**The map behind the route needs work.** The trip screen's **⋮** menu
also carries **Filter cave places**, **Sort cave places list**, **Sort
maps** and **Manage maps**, so you can add or fix a map without leaving
the trip. Place pins cannot be moved from here.

## Finding earlier trips

Once a cave has at least one **finished** trip, a **Past / active
trip(s) (N)** button appears in the cave's header block, under the cave
details. It opens the cave's trip screen: the Start / Stop / Pause /
View controls at the top, the running trip if there is one, then the
finished trips with their point counts. Tap any of them to review its
map, point list and log.

Until your first trip in a cave has ended, that button is not there —
reach the running trip through the card in the **⋮** app menu.

## See also

- [Trips](../features/trips.md) — every screen and control in detail
- [Trip reports](../features/trip-reports.md) — templates and the log styles
- [Navigating underground](navigating-underground.md) — the scanning workflow
- [BLE beacons](../features/ble-beacons.md) — hands-free trip points
- [Documents](../features/documents.md) — photos, audio and notes
- [Sharing data](sharing-data.md) — getting the trip to the rest of the team
