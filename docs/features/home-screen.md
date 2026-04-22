# Home screen

[← Back to index](../README.md)

The home screen is SpeleoLoc's entry point: it lists all **caves** in
the local database and exposes the most common global actions.

## Top bar

- **Title** — the app name. Tapping it 9 times in a row within a few
  seconds toggles **debug mode**, which reveals additional developer
  options elsewhere in the app (not normally relevant to end users).
- **Scan QR** icon — opens the [QR scanner](qr-codes.md). Long-press
  (when enabled in settings) opens a manual-input dialog for typing the
  QR identifier by hand if the label is damaged.
- **Add cave** icon — opens the "Add new cave" form.
- **⋮ end-drawer menu** — global and screen-specific items (see below).

A toolbar variant putting the primary actions in a visible bar (instead
of the end drawer) can be enabled in **Settings → General → Show home
toolbar**.

## The cave list

Each cave row shows:

- the cave title,
- its **surface area** (if assigned),
- counts of its **cave places** and **raster maps**,
- contextual actions on long-press / swipe (rename, delete, …).

Tapping a cave opens its [places list](cave-places.md).

## End-drawer menu

Typical items:

- **Add new cave**
- **Documentation** — opens the global [Documentation files](#) browser
  showing every documentation file stored in the app.
- **Manage surface areas** — see [Surface areas](surface-areas.md).
- **CSV import (caves)** — bulk import of multiple caves from a CSV.
  See [CSV import](csv-import.md).
- **Settings** — full [Settings](settings.md) tree.
- **Trip report templates** — manage ODT/DOCX templates used to
  generate [trip reports](trip-reports.md).
- **Product tour** — re-trigger the on-screen hints.

## First-launch behaviour

On any of the first 4 launches, if the database is empty, the home
screen offers to populate it with **test data** (a sample cave with
maps, places and documents). Accept to explore the app without risk;
decline to start fresh. See [Getting started](../getting-started.md).

## See also

- [Caves and cave areas](caves-and-areas.md)
- [Cave places](cave-places.md)
- [Settings](settings.md)
