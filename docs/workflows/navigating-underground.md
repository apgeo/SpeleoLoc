# Navigating underground

[← Back to index](../README.md)

The trip itself: standing in a passage with a phone, working out which
place you are at, reading what the team already knows about it, and
adding what you find. Everything on this page works with no signal —
the survey maps, the documents and the codes are all on the device.

> Control names below are the English ones. The app starts in Romanian;
> switch with **Settings → General → App language**.

## Before you go down

- **Get the current data onto the phone.** Import the team's latest
  archive, or run a sync, while you still have a network — see
  [Sharing data between teams](sharing-data.md).
- **Grant camera permission on the surface.** The first scan asks for
  it, and the bottom of a pitch is a poor place to find out you had
  refused it once.
- **Switch beacon detection on** if the cave has BLE tags on its places
  — see [Letting a beacon find you](#letting-a-beacon-find-you). It runs
  its own permission requests the first time you enable it.
- **Charge the phone and carry a power bank.** Screen, camera and torch
  together empty a battery quickly, and cold makes it worse.
- **Start the trip before you go in**, or let the entrance label start it
  for you — see [Running a caving trip](running-a-trip.md).

## Two ways to know where you are

1. **Scan the QR label** glued next to the place. This is the reliable
   one: it works in any cave that has been labelled, needs no batteries
   on the wall, and it is what starts and stops trips.
2. **Walk past the place's BLE beacon.** Where a place carries a
   registered tag, the app recognises it by itself and can open the
   place without you touching the phone.

Both end in the same place: the cave place identified, and a trip point
recorded when a trip is running in that cave.

## Scanning a QR label

| Where you are | The button |
|---|---|
| Home screen | **Scan QR**, the first button of the action toolbar — or in the top bar when that toolbar is hidden |
| A cave's places list | **Scan QR**, first button of the toolbar across the top |
| Anywhere, through the ⋮ menu | **Scan** |

1. Tap it. A plain camera view titled **Scan QR** opens.
2. Hold the label in the frame. Detection is automatic and the scanner
   closes itself — there is no shutter button.
3. The **flash** button in the scanner's top bar switches the phone
   torch on, which is usually what makes a muddy or low-contrast label
   readable. Switch it off again once the code is read.

What happens next depends on what was read:

| What was read | What happens |
|---|---|
| A label belonging to one cave place | The map viewer opens on the first map that already holds a point for that place, zoomed onto the pin, and a message confirms **Cave place has been identified** with the place title |
| A place that has no point on any map | The message *No map has a point defined for this cave place*, then the cave place's own page |
| A code that exists in more than one cave | A **Choose point / cave** dialog lists every match with its cave, so you pick the right one |
| A code that is in no cave on this device | *Cave place not found*, quoting the code that was read |
| Anything that cannot be reduced to an identifier | *Invalid QR code (not parsable per rules)* |

A scan started from inside a cave's places list only ever searches that
cave, so the chooser never appears there. Which map you land on follows
your own map order — see
[Map viewer and point editor](../features/map-viewer.md#sorting-the-maps).

Scanning an **entrance** label behaves differently: it offers to start a
trip, to stop the one you are running, or to switch from a trip in
another cave. That is the quickest way to run a trip without touching
menus, and it is described in
[QR codes — placing, scanning, printing](../features/qr-codes.md) and
[Running a caving trip](running-a-trip.md).

While a trip is running in that cave, every ordinary scan silently adds
a trip point and confirms with *Point added to trip*, so the route
builds itself as you go. A **paused** trip records nothing even though
that same message still appears — resume it before you rely on the
route.

### When the label will not scan

Labels get muddy, torn or wet, and a camera will not always focus on
them. Every code can be typed instead:

1. In the cave's places list, tap **Manual QR code search** in the
   toolbar.
2. A search box opens under the toolbar.
3. Type the code into **QR code identifier** and tap **Search place by
   QR code id**.

From there the app does exactly what a successful scan would have done.
The long press that used to open the same box from the home screen is
not in the released app — it survives in development builds only — so
the toolbar button on the cave's places list is the way in, and it is in
any case the handier one when you are working through several codes in a
row.

What you type is matched, ignoring upper and lower case, against both
the QR code identifier and the human-readable place code, so whichever
of the two is still legible on the wall will find the place.

## Letting a beacon find you

A cave place can have a BLE tag registered on it. When beacon detection
is on, walking into range identifies the place with no scan at all —
useful exactly when a label has gone, and in passages where getting the
phone onto the label is awkward.

Turn it on in **Settings → Beacon detection → Detect beacons
automatically**, or with the **Beacon detection** switch at the bottom
of the ⋮ menu, which is the same switch and can be flicked without
leaving the screen you are on. It is off until you turn it on.

Walking into range then gives you:

- a message reading **Place detected** followed by the place title, and
  a short sound unless **Detection sound** is off;
- a trip point, when a trip is running in that place's cave — the same
  point a scan would have recorded, with *Point added to trip* added to
  the message;
- the place opened on the best raster map, exactly as a scan would open
  it, but only when **Open place on detection** is on. It is off by
  default, so that walking past a tag does not yank the screen out from
  under you.

Two settings decide when a tag counts as "here": **Signal trigger
threshold**, which keeps detection to roughly the last few metres, and
**Re-trigger cooldown**, which silences the same beacon for five minutes
after it fires so a rest stop does not fill your trip with repeats.

Some things beacons deliberately do not do:

- **They never start or stop a trip.** Even an entrance tag only
  announces the place; the start/stop questions belong to the QR label,
  because a dialog firing while you walk is worse than useless.
- **They ask nothing when a tag is ambiguous.** If the same tag is
  registered in more than one cave, the app quietly prefers the cave
  your trip is in, then the cave you last had open.
- **They stop when the app is not on screen**, unless **Keep detecting
  in background** is on (Android). With it on, a detection arrives as a
  loud notification instead of a message, and tapping that notification
  opens the cave place.

Ruuvi sensor tags registered on a place trigger detection in exactly the
same way as an iBeacon tag. See [BLE beacons](../features/ble-beacons.md)
for assigning tags to places and checking they are alive, and
[Ruuvi sensors](../features/ruuvi-sensors.md) for the sensor side.

## Reading the survey by headlamp

Once a place is identified you are on the map viewer, looking at a
scanned survey with the pins of that cave on it.

- **Pinch** to zoom, **drag** to pan; the **−**, reset and **+** buttons
  in the bottom-right corner of the image do the same in steps.
- **Tap a pin** to make that place the current one — the map pans onto
  it without changing your zoom. **Press and hold a pin** to read the
  name of the place it belongs to, which saves you in a corner where
  labels overlap.
- The **cave places** strip above the map lists every place in the cave;
  tapping one moves to it, so you can look ahead at where you are going.
- **Open cave place** and **Documents**, in the bar under the map, take
  you from the pin to that place's own page or straight to its photos
  and notes.

A pencil survey photographed under a headlamp is often barely legible on
a phone. The side toolbar's **Image processing** button fixes that:
**Invert colors** for a dark scan, **High contrast** for faint lines,
and **Night red** when you would rather not lose your dark adaptation.
These are display-only — the stored image and the points on it are never
touched. **Full screen** gives the image the whole display, and turning
the phone to landscape does it by itself.

The full list of effects, and how the two work, is in the map viewer
page: [making a faint scan
readable](../features/map-viewer.md#making-a-faint-scan-readable) and
[full screen and
landscape](../features/map-viewer.md#full-screen-and-landscape).

## Adding what you find, on the spot

From a cave place's **Documents** you can record the observation while
you are standing in front of it. The toolbar offers, in order:

| Button | What you get |
|---|---|
| **New text document** | A plain note |
| **New rich text** | A formatted note |
| **Take photo** | The camera, with the picture attached when you keep it |
| **Record audio** | A voice recording — the fastest option with cold hands |
| **Add from file** | Anything already on the phone, several files at once |

Each one is attached to that cave place as soon as it is saved, is
picked up by the next export or sync, and — if a trip is running and not
paused — is linked to that trip as well, so it turns up in the trip
report later. See [Documents](../features/documents.md).

## When you are not sure which place you are at

- If the place carries a **BLE tag** and detection is on, walk up to it
  and let the app tell you.
- If you can read any part of the code, use **Manual QR code search**.
- In the cave's places list, use the **Filter cave places** box: what
  you type is matched against the place name, its place code and the
  name of its cave area.
- On a map, tap the pin nearest to where you think you are, or press and
  hold it to read its name before you commit.
- Failing all of that, note the depth and a description now and sort out
  which place it was on the surface — an unattached photo with a note is
  worth far more than a guess pinned to the wrong place.

## Coming back up

1. **Stop the trip** if you started one, at the entrance or on the
   surface. See [Running a caving trip](running-a-trip.md).
2. **Switch beacon detection off** if you had it on — it scans
   continuously and there is nothing left to find above ground.
3. **Read back what you added** from the cave or from the places you
   visited, while the trip is fresh, and fix titles and descriptions
   then rather than a month later.
4. **Export or sync** so the rest of the team gets what you brought back
   — see [Sharing data between teams](sharing-data.md).

## See also

- [QR codes — placing, scanning, printing](../features/qr-codes.md)
- [BLE beacons](../features/ble-beacons.md)
- [Map viewer and point editor](../features/map-viewer.md)
- [Cave places](../features/cave-places.md)
- [Running a caving trip](running-a-trip.md)
- [Sharing data between teams](sharing-data.md)
