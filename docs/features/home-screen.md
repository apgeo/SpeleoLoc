# Home screen

[← Back to index](../README.md)

The home screen is SpeleoLoc's entry point: it lists all **caves** in
the local database and exposes the most common global actions.

## Top bar

- **Title** — the app name. Tapping it 9 times in a row within a few
  seconds toggles **debug mode**, which reveals additional developer
  options elsewhere in the app (not normally relevant to end users).
  Tapping a few more times turns it back off.
- **Scan QR** icon — opens the [QR scanner](qr-codes.md). Long-press
  (when enabled in settings) opens a manual-input dialog for typing
  the place code by hand if the label is damaged.
- **Add cave** icon — opens the "Add new cave" form.
- **Sync icons** — quick access to manual archive sync and FTP sync
  (when an FTP profile is configured). Tapping a sync icon while a
  sync is in progress jumps to the [FTP progress page](ftp-sync.md).
- **⋮ end-drawer menu** — global and screen-specific items (see below).

A toolbar variant putting the primary actions in a visible bar
(instead of the end drawer) can be enabled in **Settings → General →
Show home toolbar**. The toolbar is shown by default and can be
collapsed via the toolbar toggle in the cave-list header.

## The cave list

Each cave row shows:

- the cave title,
- its **surface area** (if assigned),
- counts of its **cave places** and **raster maps**,
- contextual actions on long-press / swipe (rename, delete, …).

Tapping a cave opens its [places list](cave-places.md).

### Selection mode and bulk delete

Long-pressing a row (or tapping the **Select** toggle in the
list header) enters **selection mode**. Multiple caves can be picked
and then **bulk-deleted** via the action that appears in the header,
with a **double-confirmation** dialog to prevent accidental loss.

## End-drawer menu

Typical items, grouped:

- **Add new cave**
- **Documentation** — opens the global documents browser showing every
  documentation file stored in the app.
- **Manage surface areas** — see [Surface areas](surface-areas.md).
- **CSV import (caves)** / **CSV import (places, multiple caves)** —
  bulk import from CSVs. See [CSV import](csv-import.md).
- **Sync dashboard** — see [Sync dashboard & change log](sync-and-change-log.md).
- **FTP sync** — see [FTP sync](ftp-sync.md).
- **Trip report templates** — manage ODT/DOCX templates used to
  generate [trip reports](trip-reports.md).
- **Settings** — full [Settings](settings.md) tree.
- **About** — version, project info and links.
- **Product tour** — re-trigger the on-screen hints.

## First-launch behaviour

On any of the first 4 launches, if the database is empty, the home
screen offers to populate it with **test data** (a sample cave with
maps, places and documents). Accept to explore the app without risk;
decline to start fresh. See [Getting started](../getting-started.md).
The product tour is deferred until after this dialog so the two don't
fight for the screen.

## See also

- [Caves and cave areas](caves-and-areas.md)
- [Cave places](cave-places.md)
- [Sync dashboard & change log](sync-and-change-log.md)
- [Settings](settings.md)
