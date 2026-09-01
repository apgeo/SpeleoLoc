# Ruuvi sensor tags

[← Back to index](../README.md)

A Ruuvi tag is a small battery-powered Bluetooth sensor that continuously
broadcasts what it measures — temperature, humidity, air pressure and its
own battery voltage — to anything within radio range. SpeleoLoc can use
one as a marker for a cave place, exactly like an iBeacon, and on top of
that show you its readings: live while you stand next to it, and
afterwards from the measurement log the tag keeps on its own.

Control names on this page are the English ones. The app starts in
Romanian; English is chosen in **Settings → General → App language**.

## What a Ruuvi tag measures

Nothing has to be paired, switched on or connected for the readings to
appear: the tag shouts its values into the air every second or two, and
the phone only has to be close enough to hear it. A connection is made
in one situation only — downloading the tag's stored log.

| Reading | Shown as | What it is |
|---|---|---|
| **Temperature** | `12.34 °C` | air temperature at the tag |
| **Humidity** | `96.5 %` | relative humidity |
| **Pressure** | `1013.2 hPa` | absolute air pressure |
| **Battery** | `2980 mV` | cell voltage; below 2500 mV counts as low |
| **Movement count** | a number | how often the tag has been disturbed; it wraps back to zero after 254 |
| **Acceleration** | `(4, -12, 1010) mG` | the three axes: which way up the tag sits |
| **Signal** | `RSSI: -67 dBm` | how strongly the phone hears the tag now |
| **TX power** | `4 dBm` | how loudly the tag is transmitting |

### Which model you have

The app never asks. It works out the model from which sensors actually
report a value and shows the name it inferred — **RuuviTag**, **RuuviTag
Pro 3in1** or **RuuviTag Pro 2in1**. Readings the model cannot take are
shown as a dash (`—`) rather than as a zero, so a dash under *Pressure*
on a Pro 3-in-1, or under both *Humidity* and *Pressure* on a Pro
2-in-1, is the sensor being absent — not a fault and not a lost packet.

## Attaching a tag to a cave place

A tag has to be assigned to a place before any of the sensor screens can
be reached; there is no free-standing "scan for tags" readout outside
[Beacon Lab](#diagnostics-in-beacon-lab).

1. Open the cave place and save it if it is new — the **BLE beacons**
   section only appears once the place exists.
2. In that section tap **Assign beacon**.
3. The **Nearby beacons** dialog opens and starts listening. Hold the
   phone against the tag you are installing: the list is sorted
   strongest signal first, and anything not heard for 15 seconds drops
   off it, so the tag in your hand climbs to the top and stays there.
4. Each Ruuvi entry shows its model, its MAC address, its signal in dBm
   and its current temperature, humidity, pressure and battery — enough
   to be sure you are picking your tag and not a neighbouring one. Tags
   already registered in this cave are greyed out and marked *already
   assigned*.
5. Tap the tag. The app confirms with **Beacon assigned to this place**.

From then on the tag has two jobs: it identifies the place when you walk
past it, if automatic detection is switched on (see
[BLE beacons](ble-beacons.md)), and it gives that place a live sensor
readout and a history.

> **Android only:** Bluetooth scans return nothing at all while the
> phone's location switch is off, even though no GPS position is ever
> taken. When it is off the app shows a **Turn on location** dialog with
> an **Open Settings** button; enable location there and try again. If
> the Bluetooth or location *permissions* are missing you get
> **Bluetooth/location permissions are required for beacon scanning**
> instead.

## Live sensor data

Two ways in, both for a tag already assigned to a place:

- the cave places list → the **Cave** button on the tool strip →
  **Cave beacons**, then the monitor button on the tag's row, tooltip
  **Live sensor data**;
- the cave place itself → **BLE beacons** section → tap the tag's row.

Until the first advertisement arrives the screen says **Waiting for tag
advertisements… move closer to the tag**. After that it fills in, and
every new advertisement refreshes it:

- a header line with the inferred model and the tag's MAC address, and
  under it **Updated 2s ago** — a counter that keeps ticking up when
  nothing arrives, which is the quickest way to see you have walked out
  of range;
- four large cards: **Temperature**, **Humidity**, **Pressure**,
  **Battery**. The battery card grows an orange warning icon below
  2500 mV;
- a **Motion** panel with **Movement count** and **Acceleration**;
- a **Signal** panel with RSSI, **TX power** and **Packet loss**.

The screen's title bar shows the place the tag is assigned to (or the
model, when you came from the place screen), not the words *Live sensor
data*.

### Using the packet-loss figure

**Packet loss: 12 % (44/50)** means that of the 50 broadcasts the tag
numbered while you watched, 44 reached the phone. The app counts it from
gaps in the tag's own numbering, so it is an estimate of the radio path
between that tag and that phone, at that spot, right now.

This is the practical way to decide where a tag will actually work.
Walk the passage with the live view open and watch RSSI and the loss
figure. If loss is high where you expect the app to recognise the place
automatically, the tag needs a better position — or the trigger
threshold in **Settings → Beacon detection** needs relaxing.

## The tag's own measurement log

A Ruuvi tag records temperature, humidity and pressure by itself while
nobody is there, roughly every five minutes, keeping about ten days
before it overwrites the oldest. SpeleoLoc can pull that log onto the
phone. Open the tag's live view and tap the history icon in the title
bar (**Sensor history**).

### Downloading

1. Stand next to the tag with Bluetooth on.
2. Tap the download icon, **Download from tag**.
3. A progress bar reports the phases: **Searching for the tag…**,
   **Connecting…**, **Downloading… 300 samples** (the count moves in
   steps of a hundred), then **Storing…**.
4. It ends with **History downloaded: 412 new readings**.

Stay beside the tag for the whole transfer — this is the one part of
the feature that needs a real Bluetooth connection, and it only runs
while the screen is open. The app gives up and shows an error if the tag
is not heard within about 30 seconds, if the connection does not
complete within 15 seconds, or if the stream goes quiet for 30 seconds
in the middle. Move closer and start again; nothing is lost.

Downloading again later asks the tag only for what is newer than your
newest stored reading, so the second download after a trip is short, and
repeating one never produces duplicate rows.

### Reading the chart and the list

Readings are drawn as a line chart. The buttons across the top choose
the metric — **°C**, **%RH**, **hPa** — and the row under them limits
the view to **24 h**, **7 d** or **All**; the screen opens on
temperature over the last 24 hours. Tap a point on the line to read its
date, time and exact value. The icon on the right switches between the
chart and a plain **List** of readings, newest first, each row showing
the timestamp and every value stored for it. Times on both are your
phone's local time.

Choosing a metric the tag never logged — pressure on a Pro 3-in-1, for
instance — gives **No values for this metric**. That is the tag's
hardware, not a failed download.

### When everything looks empty

Log timestamps come from the tag's own clock, and SpeleoLoc never sets
that clock. A tag whose clock has never been synchronised stamps its
readings with dates far in the past, so the **24 h** and **7 d** filters
look empty even though the download worked. The screen says so:
**No readings in this range — 2874 stored in total, select "All"**.
Switch to **All** and the readings are there. The measurements
themselves are good; only their dates are wrong, and they will stay
wrong for those rows.

### Export CSV

The save icon writes everything stored for this tag through the system
file picker, as a file named like
`ruuvi_E1A24C90F3B7_2026-09-01T14-05-11.csv`. It has four columns —
`timestamp_utc` (in UTC, not local time), `temperature_c`,
`humidity_pct` and `pressure_hpa` — ready for a spreadsheet. It always
exports the whole stored set, not the range currently on screen, and
confirms with **History exported (2874 rows)**. With nothing stored yet
it declines: **No stored history yet — download from the tag**.

This is the only way to get sensor readings off the phone. See
[Limits worth knowing](#limits-worth-knowing).

### Clear stored history

The bin icon, **Clear stored history**, deletes every reading stored on
this phone for this tag, after asking **Delete all locally stored
history for this tag? The tag itself keeps its last ~10 days.**

**This cannot be undone** and there is no copy anywhere else, so export
the CSV first if the readings matter. What it does not touch is the tag:
its own log is untouched, and a fresh download brings back whatever is
still in it. Clearing is the right move when a tag has been moved to a
different place and the old readings would be misleading.

## What the app records on its own

While automatic beacon detection is running, the app quietly notes the
values every registered Ruuvi tag it passes is broadcasting — at most
once a minute per tag — without you opening anything. Those are stamped
on the tag's registration, wherever it is registered.

The cave places list → **Cave** → **Cave beacons** shows the result: one
row per registered tag in the cave with its place, model, MAC address,
**Last seen** time, battery in mV and last temperature, humidity and
pressure. A tag under 2500 mV gets an orange battery icon with a **Low
battery** tooltip. Running an eye down that list before a trip is how
you find out which tags need new cells before they go silent
underground. The tag's firmware version appears there too (`fw …`) once
you have downloaded its history at least once — that is when the app
reads it.

The movement count is recorded as well, but the only places it is shown
are the live view and Beacon Lab.

Tag titles, photos and descriptions are shared with iBeacons and live
under **Settings → Beacon detection → Tag management**; see
[BLE beacons](ble-beacons.md).

### Diagnostics in Beacon Lab

**Settings → Beacon detection → Beacon Lab**, tab **Raw scan**, then
**Start scanning**, lists the beacon-like devices in range — turn
**Show only beacon-like devices** off to see every device — and decodes
the Ruuvi ones: model, battery, the three readings, acceleration, TX
power, movement counter and advertisement sequence number. It works on
any tag in range, assigned or not, which makes it the tool for checking
a tag straight out of its packet or one you cannot identify.

## What the readings are worth underground

- **Air temperature and humidity at fixed points.** A tag left at an
  entrance, a squeeze and a chamber gives you the profile over ten days
  rather than one instant, and the shape of the temperature curve is
  what shows a passage breathing.
- **Pressure.** Useful mostly as context for the other two, and as a
  record of the weather outside during the period you were away.
- **Has the marker been touched?** A movement count higher than when you
  last looked means the tag has been knocked or handled, which is worth
  knowing before you trust it as a position marker.
- **Where a tag actually reaches.** The live packet-loss figure, walked
  along the passage, is the honest answer.
- **Battery before a trip.** Cheaper to check on the surface.

The app records and draws; it does not interpret. There are no
thresholds, alarms or trends beyond the low-battery flag.

## Limits worth knowing

- **Downloaded history stays on the phone that downloaded it.** It is
  not in export archives, not in a merge import and not in FTP sync, so
  a teammate who imports your archive gets no readings. Send them the
  CSV.
- History belongs to the physical tag, keyed to its MAC address, not to
  the place. It survives unassigning the tag, reassigning it to a
  different place and moving it to another cave — and two places that
  have had the same tag share one pile of readings.
- The app never sets the tag's clock and never changes how often it
  logs. Both stay however Ruuvi's own app left them.
- Downloading needs you next to the tag with the screen open. It cannot
  run in the background or catch up later.
- Packet loss is an estimate from broadcast numbering, not a measured
  link quality.
- The model name is inferred from the sensors that answer, so a tag with
  a failed sensor will be named as a smaller model.

## See also

- [BLE beacons](ble-beacons.md)
- [Cave places](cave-places.md)
- [Navigating underground](../workflows/navigating-underground.md)
- [Settings](settings.md)
- [Database export, import and backup](database-export-import.md)
- [Glossary of terms](../glossary.md)
