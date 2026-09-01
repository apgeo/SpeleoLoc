# GPS and coordinates

[← Back to index](../README.md)

How a surface position gets onto a cave place: the GPS recorder and its
running average, typing or pasting coordinates in decimal, DMS or UTM,
and what accuracy to expect standing at an entrance.

## What a position is here

A position always belongs to a **cave place** — the app stores
coordinates nowhere else. It is three numbers:

| Field | Meaning |
| --- | --- |
| **Latitude** | Decimal degrees, north positive (WGS84, the same reference GPS receivers and Google Earth use). |
| **Longitude** | Decimal degrees, east positive. |
| **Altitude** | Metres, optional, exactly as the GPS receiver reported it. |

Any place can carry one, not only entrances, and every place that has
one is drawn on the [cave map](surface-map.md).

The three fields sit on the cave-place form but are hidden until you
tick **Show/Hide GPS coordinates** in the ⋮ menu of the place. The
choice is not remembered between visits — see
[Cave places](cave-places.md).

**Nothing is written to the place until you save it.** The recorder,
the map picker and the typing dialog all do the same thing: they fill
the form fields and leave. While a field's text differs from what is
stored for the place it carries a faint green tint, so an unsaved
position is easy to spot; saving clears the tint.

## The four ways to fill them

| Way | Where it is | What it fills |
| --- | --- | --- |
| **Record GPS point** | The crosshair button at the end of the coordinate row | Latitude, longitude **and** altitude |
| **Pick coordinates on map** | The globe button on the row, and the globe in the app bar — that one works even while the row is hidden | Latitude and longitude only |
| **Enter coordinates** | The keyboard button on the row | Latitude and longitude only |
| **Import places (GPX/KML)** | Home screen menu; creates whole places rather than editing one | Latitude, longitude and the file's elevation |

Picking on the map is described under
[Using the map as a coordinate picker](surface-map.md#using-the-map-as-a-coordinate-picker);
the file exchange under [GPX/KML place transfer](place-transfer.md).

## Recording a point with the GPS recorder

**Record GPS point** opens a screen of its own with two cards and two
buttons. It exists because a single GPS fix at a cave entrance is a poor
measurement, and an average of many is a much better one.

### Live position (running average)

The upper card starts on *Waiting for GPS fix…* and then updates as
readings arrive:

| Line | What it shows |
| --- | --- |
| **Latitude** / **Longitude** | The average of every fix taken since the screen opened, to seven decimals |
| **Altitude** | The average altitude, in metres, over the fixes that reported one |
| **Accuracy** | `±n m` for the **latest single fix** — not for the average |
| **Samples** | How many fixes have gone into the average so far |

Under them a bar and a word rate that latest accuracy figure:

| Reading | Rating |
| --- | --- |
| 5 m or better | Excellent |
| 5–10 m | Good |
| 10–20 m | Fair |
| 20–50 m | Poor |
| worse than 50 m | Very poor |
| no accuracy reported | Unknown |

### Capture, then Use this

1. Stand still with the phone in the open and let **Samples** climb.
   The averaged latitude and longitude stop wandering after a few dozen
   readings; that settling is the point of the screen.
2. Tap **Capture**. The current average is frozen into the lower card,
   *Captured snapshot*, with the sample count it was made from. The
   accuracy stored with a snapshot is the **best single reading seen so
   far**, so treat it as an optimistic figure rather than the error of
   the average.
3. Tap **Use this**. The screen closes and latitude, longitude and
   altitude land in the cave-place form. Save the place.

**Capture** stays greyed out until the first fix arrives, and **Use
this** until something has been captured. The × on the snapshot card
(**Discard captured snapshot**) throws it away so you can capture again.

### The average never restarts while you stay on the screen

The running average accumulates from the moment the recorder opens and
is never reset while it stays open — discarding a snapshot does not
restart it either. Two consequences in the field:

- the first wild fixes, taken while the receiver was still settling,
  stay in the average for as long as you are on the screen;
- if you walk to a second entrance without leaving the recorder, the
  reading becomes a mix of both places.

To get a clean average, leave the recorder and open it again.

### Averaging on the map, too

**Use my location** in the map's placement bar works the same way: it
starts a fresh average and keeps nudging the pin toward it while
readings arrive. Tapping the map or dragging the pin stops the
averaging, as does tapping the button a second time. Nothing on the bar
shows that averaging is still running, so stand still for a few seconds
before you confirm. See [Cave map](surface-map.md#placing-the-point).

## Typing or pasting coordinates

The keyboard button opens **Enter coordinates**, a single box labelled
*Coordinates (decimal, DMS, or UTM)*. Paste a position from a survey
sheet, a message or another app; the format is worked out from the text
itself, whatever the display setting says.

| Format | Example the app accepts |
| --- | --- |
| Decimal degrees | `45.359167, 22.714722` — also `45,359167 22,714722` with commas as decimal marks, and a semicolon or plain space as separator. Latitude first. |
| Degrees, minutes, seconds | `45°21'33.0"N 22°42'53.0"E`. The hemisphere letters are required, and either both lead their numbers or both trail them, so `N45 21.55 E22 42.88` (degrees and decimal minutes) also works, and putting the E half first is fine. |
| UTM | `34T 634605 5023721`. The band letter is required — it is what tells the app which hemisphere you mean — and easting comes before northing. |

The three example lines are printed under the field as a reminder. If
the text cannot be read the dialog says **Unrecognized coordinate
format** and stays open so you can correct it; a position outside
±90° / ±180° is refused the same way. On **OK** the point is converted
to decimal degrees and written into the Latitude and Longitude fields.
The Altitude field is left untouched.

### Typing straight into the fields

The Latitude, Longitude and Altitude fields themselves are plain number
fields: decimal degrees and metres, nothing else. They are read when you
save, and **anything that is not a number is treated as no value** — the
place saves with no position and no warning. A half-typed latitude, or a
DMS string pasted into the field by hand, is silently lost. Use **Enter
coordinates** for anything that is not already decimal, and glance at
the fields after saving if you typed them yourself.

## Coordinate display format

**Settings → Map → Coordinate display format** chooses how positions are
*shown*:

| Option | Looks like |
| --- | --- |
| **Decimal degrees** (default) | `45.359167, 22.714722` |
| **Degrees, minutes, seconds (DMS)** | `45°21'33.0"N 22°42'53.0"E` |
| **UTM** | `34T 634605 5023721`, rounded to whole metres |

The choice is remembered and applies to the cave map's place info card,
the coordinate line in the placement bar, and an extra grey line under
the cave-place form's fields — that line only appears when the format is
DMS or UTM, since with decimal degrees it would repeat the fields.

It is a display setting only. The Latitude and Longitude fields, and
exported GPX and KML files, always hold decimal degrees, and coordinate
entry accepts all three formats whatever you pick here. Positions
outside the UTM belt (below 80° S or above 84° N) fall back to decimal
degrees.

## What to expect at a cave entrance

- **Horizontal.** In the open, a phone that has been standing still long
  enough to reach *Good* or *Excellent* will usually put an entrance
  within a few metres — good enough to walk back to it. Under a cliff,
  in a doline or beneath dense canopy the accuracy figure climbs and the
  average drifts; that is the receiver, not the app. Record the point
  from the most open spot you can stand on, and note the offset in the
  place description if you had to step away from the entrance.
- **Vertical.** Altitude is whatever the receiver reports, and it is
  always the weakest of the three numbers — expect it to disagree with a
  map or an altimeter, often by tens of metres. It is worth recording,
  but do not treat it as a survey elevation.
- **The map never fills altitude.** Placing or moving a point on the
  map writes latitude and longitude and nothing else, so a place
  positioned that way keeps whatever altitude it already had. If you
  need the height, use **Record GPS point** while standing there, or
  type it into the Altitude field.
- **Repeat it.** Recording the same entrance on two visits and comparing
  the two averages tells you more about your real accuracy than any
  number on the screen.

## Location permission

The app asks for location the first time you open the recorder or use
**My location** on the map, and only ever while the app is in use — it
never follows you in the background. Location is also what Android
requires before it will return Bluetooth scan results, so the same
permission serves [BLE beacons](ble-beacons.md).

If it cannot get a position, the recorder replaces both cards with an
explanation:

| Panel | What it means | Its button |
| --- | --- | --- |
| **Location services disabled** | The device's location switch is off | **Open Settings** goes to the system location screen; the recorder starts again when you come back |
| **Location permission denied** | The permission was refused | **Open Settings** goes to the app's own permission page |
| **GPS error** | Anything else the receiver reported | **Retry** |

On the cave map the same two conditions show a short warning at the
bottom of the screen instead — *Location services are off* or *Location
permission denied* — and the app opens the relevant settings page for
you where that can help.

## See also

- [Cave places](cave-places.md)
- [Cave map](surface-map.md)
- [GPX/KML place transfer](place-transfer.md)
- [Settings](settings.md)
- [Documenting a new cave](../workflows/documenting-a-new-cave.md)
