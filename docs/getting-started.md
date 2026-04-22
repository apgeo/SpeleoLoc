# Getting started

[← Back to index](README.md)

## Installation

SpeleoLoc is a Flutter application targeting Android primarily, with builds
available for iOS, Windows, macOS and Linux. Install the build delivered to
you (APK, store listing or desktop build) like any normal app. Permissions
the app will request on first use:

- **Camera** — to scan QR codes and take photos.
- **Microphone** — to record audio notes.
- **Storage / files** — to pick map images, import CSVs, export archives.

If you deny a permission permanently, you can re-enable it from the
operating system's app settings; the app will offer a shortcut.

## First launch

On first launch you see the **Home screen**, which will be empty. Because
the app starts out with no data, on any of the first four starts where the
database is still empty it asks:

> *Populate the database with test data?*

- Answer **Yes** to explore the app with a sample cave, sample cave places,
  sample maps and sample documents already wired together. The app restarts
  once data is loaded.
- Answer **No** to start with a clean slate and create your own data.

You can always reach the same test data or wipe everything from
**Settings → Database** later — see
[Database export, import and backup](features/database-export-import.md).

## The interface at a glance

The top bar of every screen contains:

- a **title** (tap it 9 times in a row to toggle internal debug mode),
- screen-specific action icons,
- a **⋮ menu** (the end drawer) with global actions and
  screen-specific actions.

The home screen specifically has three primary buttons:

- **Scan QR** — opens the camera to scan any SpeleoLoc QR label.
- **Add cave** — creates a new cave entry.
- **Cave list** — the main area of the home screen.

See [Home screen](features/home-screen.md) for the full tour.

A built-in **product tour** (highlighted hints) runs the first time you
open each major screen. You can re-trigger it from the screen menu.

## Typical first-session suggestions

If you are setting up SpeleoLoc for a specific cave for the first time:

1. Follow [Documenting a new cave](workflows/documenting-a-new-cave.md).

If you received a database archive from another team:

1. Import it via **⋮ menu → Settings → Database → Restore / Import**. See
   [Database export, import and backup](features/database-export-import.md).

If you want to explore features before committing real data:

1. Accept the test-data prompt on first launch, or reinitialize the
   database with test data from **Settings → Database**.

## A few conventions used throughout the wiki

- **Cave place** means the named, QR-coded point of interest (not just a
  pin on a map).
- **Raster map** means a bitmap image of a cave map (plan, profile, …),
  imported from an image file; SpeleoLoc does not draw maps itself.
- **Point definition** is the (x, y) pixel coordinate that ties a cave
  place to a specific raster map. The same cave place can have different
  point definitions on different maps.

Full vocabulary in the [Glossary](glossary.md).

Next: [Documenting a new cave](workflows/documenting-a-new-cave.md) or
jump straight to the [Feature reference](README.md#feature-reference-screen-by-screen).
