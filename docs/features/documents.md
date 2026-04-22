# Documents

[← Back to index](../README.md)

Documents (also called **documentation files**) are the multimedia
attached to geofeatures. A **geofeature** in SpeleoLoc is any of:

- a **cave place** (most common),
- a **cave** (notes about the whole cave),
- a **cave area** (notes about a zone).

A single file can be linked to more than one geofeature.

## Supported types

| Category | Examples | Created by |
|---|---|---|
| Photo | JPG, PNG from camera or gallery | Camera capture page, file picker |
| Video | MP4, etc. | File picker |
| Audio | M4A / AAC recordings | Built-in recorder, file picker |
| Text | Plain text | Text editor |
| Rich text | Quill document (formatted) | Rich-text editor |
| Image (edited) | Sketches / annotated photos | Built-in image editor |
| Web link | Any URL | "Web link" action |
| Other | Any file | File picker |

## Opening the documents list

From a cave place, cave, or cave area: **Documents** tab or button.

The list supports:

- **View modes**: flat list, list grouped by category, flat grid, grid
  grouped by category, or horizontal grid per category.
- **Sort by**: title, type, size, or date.
- **Search/filter bar** — matches titles and, where relevant, contents.

Tapping a document opens it in the most appropriate viewer or editor;
long-press gives per-document actions (rename, delete, unlink from
geofeature, share, open externally).

## Adding a new document

Press **+** at the top of the document list. Options:

- **Add from file** — pick any file from the device.
- **Take photo** — camera capture with optional editor step.
- **New image (editor)** — blank canvas, draw with the built-in editor.
- **New photo (editor)** — take a photo and open the editor on it.
- **Record audio** — opens the audio recorder (with waveform).
- **New text** — simple plain-text editor.
- **New rich text** — formatted editor (Quill-based).
- **Web link** — paste a URL; stored as a link document.

Newly created documents are immediately linked to the active
geofeature. If a trip is active they are **also** linked to the trip.

## Editing

- **Text / rich text** — opens in the corresponding editor; save via
  the top-right action.
- **Image** — the built-in image editor (crop, draw, annotate, filter).
- **Audio** — the recorder re-opens in edit mode if the document's
  format allows re-recording / trimming.
- **File / video / web link** — metadata only (title, note) is
  editable; the content itself is not edited in-app.

## Category and sorting

The category is derived from the file type (or explicitly set for
links / text). Categories are shown as section headers in the grouped
view modes.

## Global documents browser

Accessible from the home screen **⋮ → Documentation**. Shows every
document in the database across all geofeatures; from there you can
rename, delete or re-link them.

## Storage

All document files are stored under the app's data directory. When you
**export an archive**, documentation files are optionally included
(see [Database export, import and backup](database-export-import.md)).

## See also

- [Cave places](cave-places.md)
- [Trips](trips.md)
- [Database export, import and backup](database-export-import.md)
