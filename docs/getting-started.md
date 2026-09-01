# Getting started

[← Back to index](README.md)

How to install SpeleoLoc, what it asks for the first few times you start
it, and the handful of things worth setting up before you take the phone
underground.

## Installing the app

SpeleoLoc is built for Android first; builds also exist for iOS, Windows,
macOS and Linux. The app is in alpha, so you will normally be handed a
file — an Android APK, or a desktop build — rather than find it in a
store. Install it like any other app.

Nothing else is needed to get going. SpeleoLoc keeps all of its data on
the device and the underground features work with no network at all. A
connection only matters for downloading the sample data described below,
for FTP/SFTP sync, and for online map tiles on the cave map.

## The app speaks Romanian out of the box

SpeleoLoc ships with **Romanian** as its default language. This wiki uses
the English labels, so if you want the two to match, switch the app to
English first:

1. Open **Settings** — the gear icon in the **⋮** menu, or the
   **Settings** button in the home screen's action toolbar.
2. Open **General**.
3. Tap the dropdown next to **App language** and choose `en`.

The dropdown lists the two languages the app ships with by their codes,
`ro` and `en`. Screens drawn after the change come up in the new
language, and the choice is remembered the next time you start the app.

## First launch

The first thing you see is the home screen, titled **Speleo Loc**. Its
cave list is empty, because the app starts with no data of its own.

### The offer to load test data

While the cave list is empty, a developer or test build of SpeleoLoc
offers to fill it with a worked example:

> **Load test data?**
> The database is empty. Would you like to populate it with sample caves
> and places for testing?

- **Yes** fetches the sample archive, replaces everything currently
  stored on the device with it, and restarts the app. You end up with
  sample caves, cave places, raster maps with their point definitions and
  documents, all already wired together — a good way to see what the
  screens are meant to look like before you type anything real.
- **No** leaves the database empty so you can start entering your own
  data.

A few things are worth knowing before you answer:

- The release build handed out for normal caving never makes this offer:
  the sample-data tooling is left out of it, so a fresh install simply
  starts with an empty cave list and you enter your own first cave.
- The offer appears only while there are no caves **and** only during the
  first four starts of the app. After that it stops asking.
- **Yes is destructive.** If the device already holds raster maps or
  documents — from a half-finished import, say — the dialog adds a
  warning that they will be permanently deleted and replaced, and they
  will be. There is no undo.
- Loading the archive needs an internet connection. If your build carries
  no test data, you are not asked at all: no dialog appears and no message
  is shown.

You can wipe the database back to empty at any time with **Reinitialize
database** in **Settings → Database**. Reloading the sample data from
**Settings → Data Export / Import** is possible only in a developer or
test build; the released app has no **Test Data** section. See
[Database export, import and backup](features/database-export-import.md).

## What the app asks permission for

SpeleoLoc asks for nothing at install time. Each permission is requested
at the moment you first use the feature that needs it, so a caver who
never records audio is never asked about the microphone.

| Permission | Asked when | What it is for |
| --- | --- | --- |
| **Camera** | the first scan or photo | scanning QR labels, taking pictures |
| **Microphone** | the first audio recording | audio note documents |
| **Storage** | you choose **Save to Pictures** when exporting a single QR image, and only on Android 9 or older | writing the PNG into the shared Pictures folder |
| **Location** | you open **Record GPS point**, or tap **My location** on the cave map | GPS coordinates for entrances and surface places |
| **Bluetooth** (scanning and connecting) plus **Location** | you switch on beacon detection, or open a picker that scans for nearby tags | finding BLE beacons and Ruuvi tags |
| **Notifications** | you switch on **Keep detecting in background** | the alert raised when a beacon is detected with the app out of sight |
| **Unrestricted battery usage** | the same moment | letting a scan keep running for hours |

Bulk document import and the exports — the archive, the sync archive and
the database copy — ask for no permission at all: the system folder and
**save as** dialogs you go through carry their own access to the place you
pick. The folder you choose for an import is readable in full, whether or
not its files are photos. **Choose location…** likewise asks for nothing,
and on Android 10 and newer neither does **Save to Pictures**.

### If you refuse one

Refusing a permission disables the feature that asked for it, and
nothing else. Refuse location, for example, and **Record GPS point**
opens onto a *Location permission denied* panel with an **Open Settings**
button; every other screen carries on as before.

If you refuse permanently, the operating system stops showing the request
altogether. The app notices this and offers a shortcut instead — either a
*Permission required* dialog with **Open Settings**, or the system
settings page opened directly — so a permission you shut the door on is
always recoverable.

### On Android, beacon scans also need the location switch on

Android ties Bluetooth scan *results* to the device's location switch.
SpeleoLoc never reads your position in order to find a beacon, but with
that switch off a scan silently returns nothing. When that happens the
app explains it rather than appearing to hang:

> **Turn on location**
> On Android, Bluetooth beacon scans only return results while the device
> location (GPS) switch is on — even though no GPS position is taken.
> Enable location, then try assigning the beacon again.

Tap **Open Settings**, turn location on, and try again. See
[BLE beacons](features/ble-beacons.md).

## Finding your way around

### The top bar

Every screen carries a top bar: the screen's title on the left, any
icons for actions specific to that screen, and the **⋮** button at the
right-hand end.

### The app menu (⋮)

**⋮** opens the app menu. By default it slides in from the right as a
drawer; a compact popup form also exists, and the icon at the foot of the
popup switches back to the drawer. The app remembers which of the two you
last used.

In either form the menu holds the actions of the screen you are on, then
five navigation icons that work from anywhere — **Caves**, **Man. sync**,
**Documents**, **Settings** and **Scan** — and **Help tour**. The drawer
form adds a quick switch for automatic beacon detection, a sync card with
the last FTP/SFTP result and a button to sync now, a card for the trip in
progress when there is one, and **About** with the version number at the
bottom.

### The home screen

Under the title, the home screen shows an action toolbar: a row of icon
buttons for **Scan QR**, **Add new cave**, **Documents**, **Cave map**,
**Manage surface areas**, **Import caves - CSV**, **Import cave
documents**, **Settings**, **Man. sync** and **FTP / SFTP sync**. They
are icons only — hold one down to see its name. **Hide action toolbar**
in the cave-list header folds the row away, and the same preference lives
in **Settings → General → Show home toolbar**. The rest of the screen is
the cave list. See [Home screen](features/home-screen.md) for the full
tour.

### Help tours

The first time you open one of the main screens, a guided tour dims the
screen and highlights its controls one at a time. **Skip** ends the
current tour; **Disable auto tours** stops every tour from starting on
its own, leaving them available on demand. You can replay a screen's tour
at any time from **⋮ → Help tour**, and
**Settings → General → Reset help tours** makes them all behave as though
you had never seen them.

## Before you take it underground

1. **Say who you are.** In **Settings → Users**, add a user, then tap
   **Select** on your row so it shows the **Current** chip. From then on
   every change you make is stamped with that identity in the change
   history — useful after a trip, when someone asks who moved a point.
   See [Users](features/users.md).
2. **Get data onto the device.** Either build it yourself, following
   [Documenting a new cave](workflows/documenting-a-new-cave.md), or take
   an archive from another team: **Settings → Data Export / Import →
   Import Archive**, choosing **Replace all data** or **Merge with
   existing data**. See
   [Database export, import and backup](features/database-export-import.md).
3. **Check the maps are actually on the phone.** Raster maps travel
   inside the archive, but offline surface tiles do not — see
   [Using offline MBTiles layers](workflows/mbtiles-layers.md).
4. **Try a scan above ground**, so the camera permission and the QR
   labels are known to work before you are standing in the dark. See
   [QR codes](features/qr-codes.md).

## Debug mode

Tapping the title on the home screen nine times in quick succession —
leave more than three seconds between taps and the count restarts — turns
on the app's hidden debug mode, confirmed by a *Debug mode activated*
message. Twenty taps turn it off again, and it is off anyway after the
next restart.

While it is on, a **Debug Info** section appears in Settings, showing the
database path, the data directory and the configuration table, and the app
records far more detail in its log. In a developer or test build,
**Settings → Database** also gains an **Open SQL command runner** button;
the released app never shows it, whatever debug mode is set to. The SQL
runner writes straight to your data with no confirmation and no undo —
leave it alone unless someone is walking you through a repair.

## A few conventions used throughout the wiki

- **Cave place** means the named, QR-coded point of interest, not just a
  pin on a map.
- **Raster map** means a bitmap image of a cave map (plan, profile, …)
  imported from an image file; SpeleoLoc does not draw maps itself.
- **Point definition** is the pixel position that ties a cave place to a
  specific raster map. The same cave place can have a different point
  definition on each map it appears on.

Full vocabulary in the [Glossary](glossary.md).

## See also

- [Overview](overview.md) — what the app is for and the ideas behind it
- [Home screen](features/home-screen.md) — the screen you start on
- [Settings](features/settings.md) — everything under the gear icon
- [Users](features/users.md) — choosing the current caver identity
- [Database export, import and backup](features/database-export-import.md)
- [Documenting a new cave](workflows/documenting-a-new-cave.md) — the
  first real job to try
