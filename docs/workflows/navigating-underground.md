# Workflow: Navigating underground with QR codes

[← Back to index](../README.md) · [Overview](../overview.md)

This is the core in-cave workflow. Once a cave has been prepared (see
[Documenting a new cave](documenting-a-new-cave.md)), teams underground
use SpeleoLoc primarily to **scan QR labels** in order to locate
themselves and to read or add observations.

## The 30-second version

1. Open the app underground.
2. Press **Scan QR** on the home screen.
3. Aim at the QR label on the wall.
4. The matching **cave place** page opens — you can now:
   - see the place on each raster map,
   - read its description and existing documents,
   - add new photos/audio/notes,
   - and (if a trip is active) log that you passed there.

## Before you descend — optional checklist

- Make sure the device has the latest data archive imported (see
  [Sharing data](sharing-data.md)).
- Fully charge the device; bring a power bank. Underground trips drain
  batteries quickly (screen + camera + torch).
- (Optional) Start a **trip** *on the surface* so the entry scan is
  logged. See [Running a caving trip](running-a-trip.md).

## Scanning a QR label

From any screen that shows the QR-scan icon (notably **Home** and a
cave's **places list**):

1. Tap the scan icon. The camera view opens.
2. Hold the camera steady on the label. Detection is automatic.
3. On detection the scanner closes and one of several things happens:

| Situation | Result |
|---|---|
| The code is a known cave place's QR | The matching cave place opens |
| The code is a cave's entrance QR | The cave's places list opens |
| The code matches places in *several* caves | A disambiguation dialog lets you pick |
| The code is not in the database | A "not found" message is shown |
| The code is not a parseable integer | An "invalid QR" dialog is shown |

If the label came off or is unreadable, you can **long-press** the scan
icon on the home screen to enter the code manually.

## What you see after a successful scan

The **cave place page** has tabs:

- **Details** — title, description, depth, coordinates, QR code, entrance
  flags.
- **Raster maps** — the cave's maps with a pin on the current place.
- **Documents** — all attached photos, audio, text, links, etc.

You can freely switch between tabs. Swipe or tap the raster maps tab to
see the place on a plane view, projected profile, etc. The point is
highlighted with a pulse animation so it is easy to find.

See [Cave places](../features/cave-places.md) and
[Map viewer](../features/map-viewer.md).

## Adding observations on the spot

Tap the **Documents** tab, then the **+** button:

- **Take photo** — opens the camera capture page.
- **Record audio** — microphone recording with waveform preview.
- **New text** / **New rich text** — quick note, possibly formatted.
- **New image (editor)** — draw on top of a blank canvas or a photo.
- **Add from file** — pick anything from the device.
- **Web link** — paste a URL.

All new documents are attached to this cave place immediately and will
be included in the next data export.

See [Documents](../features/documents.md).

## If the label is ambiguous

When the same QR identifier exists in multiple caves (it should not, but
legacy imports can produce this), a chooser dialog lists every matching
cave + place. Pick the correct one.

## If you are not sure which place you are at

You can also find a place **without scanning**:

- From a cave's places list, use **Filter** (title or QR substring).
- From a raster map viewer, tap a visible pin to open that place.
- From a cave place, use **Search place by QR identifier** to jump
  around.

## When you come back to the surface

- Stop the trip if you started one (see [Running a trip](running-a-trip.md)).
- Review the newly added documents from the cave or cave-place pages.
- Back home, run a **database export** so other teams can benefit from
  what you added — see [Sharing data](sharing-data.md).

---

Next: [Running a caving trip](running-a-trip.md).
