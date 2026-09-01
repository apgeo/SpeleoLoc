# BLE beacons

[← Back to index](../README.md)

A BLE beacon is a small battery-powered Bluetooth tag mounted at a point
of interest. SpeleoLoc can recognise the tags you registered and tell you
which cave place you are standing at without you touching the phone.

## What a beacon adds over a QR label

A [QR label](qr-codes.md) is cheap, needs no battery and lasts as long as
the glue does — but you have to get the phone out, find the label with
the camera and hold it steady. A beacon works the other way round: the
tag shouts its identity a couple of times a second, and the phone in your
chest pocket hears it as you walk past.

| | QR label | BLE beacon |
|---|---|---|
| How it is read | Camera, aimed at the label | Radio, hands-free |
| Costs | Paper and glue | A tag and a battery to replace |
| Precision | Exact — you are at that label | Approximate — the app fires once the signal is strong enough, typically within a few metres |
| Can start or stop a trip | Yes, at an entrance | No, never — it only records points |
| Works with the phone stowed | No | Yes, and on Android even with the screen off |

The two are not alternatives: a place can carry both, and most caves are
best served by labelling everything and putting beacons only where you
want hands-free confirmation — junctions, the top of a pitch, an
entrance series.

Be realistic about what detection means. The app does not measure a
distance or a direction; it reports any registered tag whose signal
crossed the threshold. Rock, water and your own body all attenuate
2.4 GHz radio heavily, so the practical range in a passage is a few
metres and varies with how the tag is mounted. Detection is off by
default, and QR scanning remains the exact method.

## Supported tags

Two families are recognised.

**iBeacon-style tags.** Any tag that broadcasts a standard iBeacon frame,
including the HoneyComm BP1003 family (HCBB01, HCBB07, HCBB16, HCBB22,
HCBB62, H8), whose factory proximity identifier is
`FDA50693-A4E2-4FB1-AFCF-C6EB07647825`. Such a tag is identified by three
values: its proximity identifier plus a **major** and a **minor** number.
SpeleoLoc keeps nothing else about it — only when it was last heard, no
battery reading and no sensor values — even though the Beacon Lab can
decode the extra figures a HoneyComm tag broadcasts alongside its
identity.

**Ruuvi sensor tags.** RuuviTag and RuuviTag Pro (2-in-1 and 3-in-1). A
Ruuvi tag is identified by the MAC address inside its broadcast, and it
also transmits temperature, humidity, air pressure, battery voltage and
motion. SpeleoLoc harvests those readings from the broadcasts while
detection runs and offers a live readout and a downloadable measurement
history — see [Ruuvi sensor tags](ruuvi-sensors.md).

On Android the phone hears every iBeacon in range regardless of its
proximity identifier. On iPhone the operating system only reports tags
whose proximity identifier the app already knows: the factory identifier
above works out of the box, any other one has to be added first in the
Beacon Lab (below), otherwise the tag will never appear in the
**Nearby beacons** picker.

## Assigning a tag to a cave place

A tag means nothing until it is tied to a cave place. Do this in the
cave, standing at the point you are equipping.

1. Mount the tag. Open the cave, open the cave place, and scroll the form
   to the **BLE beacons** section. It only appears once the place has
   been saved at least once.
2. Tap **Assign beacon**. On Android the app asks for the Bluetooth and
   location permissions the first time, and if the phone's location
   switch is off it shows **Turn on location** with a shortcut to the
   system setting — Android delivers no Bluetooth scan results while that
   switch is off, even though SpeleoLoc takes no position.
3. The **Nearby beacons** dialog opens and keeps scanning, showing
   "Searching for beacons… hold the phone next to the tag" until
   something is heard. Entries are sorted strongest signal first, so
   holding the phone against the tag you just mounted normally puts it at
   the top. A tag that goes unheard for 15 seconds drops off the list, so
   a stale reading cannot outrank the one in your hand.
4. Tap the tag. The registration is written immediately and the app
   confirms "Beacon assigned to this place".

> 📷 [The cave place form: codes and beacon](../screenshots/04-places-and-qr-codes.md#cave-place-form-codes-and-beacons) — the cave place form, scrolled from Title through BLE beacons to the Raster maps tabs.

Two things about that dialog are worth knowing. Tags already registered
anywhere in **this** cave are shown with a green tick and the note
"already assigned", and cannot be tapped — the same physical tag cannot
be assigned twice in one cave. And a Ruuvi row shows its live readings
(temperature, humidity, pressure, battery) next to the signal strength,
which is a quick way to confirm you are looking at the right tag.

The assignment is **not** part of the form's save button. It takes effect
the moment you tap the tag, and leaving the form without saving does not
undo it.

### Removing an assignment

The unlink button (**Unassign beacon**) at the right of a beacon row asks
"Remove beacon … from this place?" and, on **Yes**, frees the tag.
Nothing else is deleted — the cave place, its documents and its trip
points are untouched — and the tag can be assigned somewhere else
straight away. The same button exists on the **Cave beacons** list.

## Switching detection on

Detection is a per-device preference. It is off by default and nothing is
scanned until you turn it on.

1. Open **Settings → Beacon detection**.
2. Turn on **Detect beacons automatically**. The app requests the
   Bluetooth and location permissions if it does not have them; if you
   refuse, it warns "Bluetooth/location permissions are required for
   beacon scanning" and the switch stays off.
3. If scanning cannot be started — most often because Bluetooth itself is
   off — you get "Detection could not start — check Bluetooth is on".
   Turn Bluetooth on and the app re-arms on its own.

Once enabled, detection starts again by itself every time you open the
app, without asking anything.

### The quick switch in the drawer

The end-drawer menu (the overflow button in the app bar) carries a
**Beacon detection** switch at the bottom of its navigation block. It is
the same switch as the one in Settings and the two always agree, so you
can silence detection while you work at one spot, or re-arm it, without
leaving the screen you are on.

### Options

The sliders and switches below the master switch are greyed out until
**Detect beacons automatically** is on, and **Background scan interval**
also needs **Keep detecting in background**. **Tag management** and
**Beacon Lab** stay reachable either way.

| Control | What it does | Default |
|---|---|---|
| **Detect beacons automatically** | Master switch. While the app is open, passing near a registered beacon identifies the place and records a trip point. | Off |
| **Signal trigger threshold** | Slider from −100 to −40 dBm. A tag only counts once its signal is stronger than this. A value closer to zero means you have to be nearer. | −75 dBm |
| **Re-trigger cooldown** | Slider from 1 to 30 minutes. After a detection, that same tag stays quiet for this long, so working at one point does not fire repeatedly. | 5 min |
| **Open place on detection** | Navigates to the detected place, exactly as a QR scan does. Off means you only get the message and the trip point. | Off |
| **Detection sound** | Plays an audible alert on detection: a short in-app sound with the app on screen, the notification sound when detecting in the background. | On |
| **Keep detecting in background** | Android only — keeps scanning with the screen off or another app in front. See below. | Off |
| **Background scan interval** | Slider from 5 to 60 seconds: how often a short scan burst starts while detecting in the background. Longer saves battery. | 30 s |
| **Tag management** | Opens the tag library — titles, photos and places for every registered tag. | — |
| **Beacon Lab** | Opens the diagnostics screen. | — |

## What happens when you walk past a tag

A registered tag triggers a detection when its signal is stronger than
the **Signal trigger threshold** and it has been heard **twice within
five seconds**. That second sighting is what keeps a single stray
reflection from firing a false detection. Tags you never registered are
ignored completely.

On a detection, with the app on screen:

- a message reads `Place detected: "<place title>"`;
- a short alert sound plays, unless **Detection sound** is off;
- if a trip is running **in that same cave**, a trip point is recorded
  and the message gains "· Point added to trip" — see
  [Trips](trips.md);
- if **Open place on detection** is on, the app opens the place on the
  most relevant raster map of that cave, falling back to the plain place
  form when the place is not pinned on any map;
- that tag then stays quiet for the **re-trigger cooldown**.

### What detection deliberately does not do

**It never starts or stops a trip.** Scanning the QR label at an entrance
can prompt you to start or stop one; a beacon detection cannot, because a
dialog appearing while you walk past a tag would be worse than useless.
Even with a tag on the entrance, start and stop the trip yourself — on
the surface, before you go in.

**It never asks which cave you meant.** A tag can only be registered once
per cave, but the same physical tag may be registered in two different
caves — after it was moved to a new site, for instance. In that case the
app chooses quietly: the cave of the trip you are running wins, then the
cave you opened most recently, then the first match. **Settings → General
→ Ask which cave on ambiguous QR scan** has no effect on beacon
detections.

## Detecting in the background (Android)

**Keep detecting in background** lets scanning continue with the screen
off or another app in front — which is the point of beacons in the first
place, since the phone can stay in a chest pocket.

Turning it on asks for notification permission (without it the option
refuses to enable, warning "Notification permission is required for
background alerts") and for permission to run unrestricted in the
background. While it is active a permanent notification reads
**SpeleoLoc beacon detection — Scanning for cave beacons…**.

Because it has to survive hours underground, background scanning is
duty-cycled: one short burst about every **Background scan interval**
seconds, rather than continuous listening. That is the trade-off to
understand — a long interval saves a lot of battery, but a tag you walk
briskly past between two bursts is simply never heard. Within a burst a
single strong sighting is enough to trigger, since two bursts can be a
minute apart.

A background detection behaves differently from an on-screen one:

- instead of a message it raises a system notification titled
  `Place detected: <place title>`, with vibration and a sound played at
  **alarm** volume, so you hear it with the media volume down;
- tapping the notification opens that cave place, even if the app had
  been closed in the meantime;
- **Open place on detection** does not apply — nothing opens until you
  tap;
- **Detection sound** off makes the notification silent, but it still
  appears and the trip point is still recorded.

This is an Android feature. On iPhone, and on Android with the option
off, scanning stops when the app leaves the screen and resumes when you
come back to it.

## Keeping track of the tags themselves

### Cave beacons — one cave's tags

The **Cave** button at the end of a cave places list's tool strip opens a
small menu with a **Cave beacons** entry, listing every tag registered
anywhere in that cave. Each row shows:

| Part of the row | Meaning |
|---|---|
| Title | The cave place the tag is mounted at. |
| Identity line | For a Ruuvi tag, the model and MAC address (and firmware version if known); for an iBeacon, its major/minor and proximity identifier. |
| **Last seen** | When this phone last heard the tag, or "never". |
| Readings | Battery in mV plus the last temperature, humidity and pressure the tag reported — Ruuvi tags only. |
| Orange battery icon | **Low battery**: the tag last reported under 2500 mV. Ruuvi tags only. |

That makes it the natural pre-expedition check: open it after your last
trip and you can see which tags have gone quiet and which need new cells.
Tapping a row opens the cave place; a Ruuvi row also has a button
straight to its live readings, and every row has the unlink button.

Readings only refresh when a phone actually hears the tag, so **Last
seen** stays where it was until someone carries a phone past the tag with
detection on.

### Tag management — every tag you own

**Settings → Beacon detection → Tag management** lists every registered
tag across all caves, sorted by cave and then by place. Each row carries
the tag's photo, the name you gave it (or its model, or its identity if
you gave it neither), the cave and place it belongs to, and when it was
last seen. With nothing registered yet it says "No tags registered yet".

Opening a tag gives you an editor with:

- a photo of the physical tag — the camera, gallery and delete buttons
  under the image are **Take photo**, **Choose from gallery** and
  **Remove photo**. The photo is saved as soon as you take it;
- a **Title** and a **Description**, saved with the save button in the
  app bar, which confirms "Tag saved" and returns to the list;
- the tag's identity, when it was last seen and its last battery reading;
- **Open cave place**, a shortcut to the place it is assigned to.

The point of all this is recognising hardware in the field. Beacons look
identical to one another, so a photo of the tag actually on the rock, and
a title like "junction, left wall, 2 m up", is what tells you which tag
you are looking at when one stops answering.

The title and description travel to other devices with your data. **The
photo does not** — it stays on the phone that took it, and is not
included in sync or in archive exports.

## When a tag is not detected

Work through this before assuming the hardware is dead.

1. **Is Bluetooth on?** Enabling detection with it off warns "Detection
   could not start — check Bluetooth is on".
2. **On Android, is the phone's location switch on?** Bluetooth scan
   results are only delivered while it is, even though SpeleoLoc takes no
   position. With it off, scanning silently finds nothing at all — which
   looks exactly like broken hardware. The pickers and the Ruuvi screens
   warn you about this with the **Turn on location** dialog; automatic
   detection does not, so check it yourself.
3. **Is detection actually on?** Check the **Beacon detection** switch in
   the drawer.
4. **Is the tag still in cooldown?** After a detection it stays quiet for
   the re-trigger cooldown, five minutes by default.
5. **Are you close enough?** Lower the **Signal trigger threshold**
   (further from zero, for example −85 dBm) to trigger at greater
   distance, at the price of more false positives from neighbouring
   points.
6. **Is the app on screen?** Unless **Keep detecting in background** is
   on, scanning stops when the app is not.
7. **On iPhone**, if the tag never even reached the **Nearby beacons**
   picker, add its proximity identifier in the Beacon Lab and assign it
   again — the picker only sees listed identifiers. A tag that is already
   assigned is detected whatever its identifier.

### Beacon Lab

**Settings → Beacon detection → Beacon Lab** is the hardware
troubleshooting screen. It has nothing to do with your caves — it just
shows what the radio hears, in raw form, and it is the tool to reach for
when a tag refuses to be seen. A red dot beside **Captured log lines** at
the top tells you a capture is running, and the number next to it counts
what has been gathered so far.

The **iBeacon** tab lists everything the phone ranges, strongest signal
first, after you press **Start scanning**. Each entry gives the tag's
major/minor and proximity identifier, an estimated distance in metres,
how many packets have arrived, how long ago the last one was, and the
weakest and strongest signal seen. Walking the passage with this open is
a practical way to check a mounting position and to find where a tag
stops being heard.

Above the list sits the proximity-identifier list as chips, with
**Add proximity UUID** to type another one — needed if your tags were
reprogrammed away from the factory identifier. On Android the app notes
that it scans all iBeacons anyway and the list is only required on iOS;
on iPhone this list is also what the **Nearby beacons** picker is allowed
to see. At least one identifier is always kept.

The **Raw scan** tab goes a level lower, listing any nearby Bluetooth
device with its signal, and decoding what it can out of the broadcast —
battery, MAC, temperature and humidity for HoneyComm tags, the full
sensor set for Ruuvi. **Show only beacon-like devices** is on by default;
turn it off to see every device around you. Tap a row to expand the
decoded detail.

Two buttons in the app bar apply to both tabs: **Export capture log**
writes everything captured to a file you choose (offered as
`beacon_lab_<timestamp>.jsonl`) so it can be sent on for analysis, and
**Clear captured data** empties the lists and the log. The export is
machine-readable material for someone diagnosing a tag; the app never
reads it back.

## What travels to other devices

Which tag is mounted at which place is shared data. Register a tag once
and every teammate who imports your archive or syncs with you gets that
registration, so their phones start detecting it too — see
[Sync dashboard and change history](sync-and-change-log.md).

The health figures each phone collects — last seen, battery, and for
Ruuvi tags the last temperature, humidity and pressure — travel along
with the registration, but they never raise a sync conflict, because two
devices legitimately saw the same tag at different moments.

Two things stay local: tag photos, and any Ruuvi measurement history you
downloaded off a tag.

## See also

- [Cave places](cave-places.md)
- [Ruuvi sensor tags](ruuvi-sensors.md)
- [QR codes — placing, scanning, printing](qr-codes.md)
- [Trips — recording your route](trips.md)
- [Navigating underground](../workflows/navigating-underground.md)
- [Settings](settings.md)
