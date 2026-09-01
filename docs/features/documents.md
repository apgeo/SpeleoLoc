# Documents

[← Back to index](../README.md)

Documents (the app calls them **documentation files**) are the photos,
recordings, notes and files you attach to a cave or to a cave place.
Every documents list in the app is the same screen, so what you learn on
one cave place works everywhere else.

## What a document can be attached to

- a **cave place** — the most common case: a photo of a junction, a
  voice note at a squeeze, a sketch of a passage detail;
- a **cave** — material about the whole cave, such as a survey PDF or
  an access description.

The stored data also allows documents on a **cave area**, but no screen
in the app offers that. Documents attached to a cave area — for example
ones arriving in a teammate's archive — can only be seen in the global
**Documentation files** browser described below.

## Opening a documents list

The action is normally a **folder icon** in the title bar, with the
tooltip **Documents**.

| Where you are | What the folder icon shows |
|---|---|
| A cave place | Documents of that place. The icon appears only once the place has been saved. |
| A cave's places list | Documents of the **cave itself**, not of any individual place. |
| The cave edit form | Documents of that cave. The icon appears only when you are editing an existing cave, not while creating a new one. |
| The raster-map place-point editor | Documents of the place currently selected on the map (a document icon in the editor's action bar). |

The title bar of the documents screen shows the place or cave name, with
the cave name underneath as a reminder of where you are.

## The documents list

> 📷 [The documents browser, list view](../screenshots/05-documents.md#documents-list) — The document library in list view, with view-mode selector, sort and search.

A pinned header at the top of the list carries three controls that stay
in place while you scroll.

- **View modes** — five icon buttons with the tooltips **List**,
  **List by category**, **Grid**, **Grid by category** and
  **Horizontal grid**. In **Horizontal grid** an extra **Rows** control
  appears below them, letting you set 1, 2 or 3 rows per category strip.
- **Sort by** (the sort icon to the right of the view buttons) —
  **Title**, **Type**, **File size** or **Date**. Picking the field you
  are already sorted by reverses the order; the arrow beside a field
  shows the current direction.
- **Search documents...** — matches the document title, its file name
  and its description. It does not search inside the files themselves.

In list mode each row shows a thumbnail, the title, and the category and
file size underneath. In the grid modes you get a large thumbnail with
the title below it.

Thumbnails are informative rather than generic: text documents show the
first few lines of their content, photos show the picture, and PDFs,
audio, video and office files show a coloured type icon with a small
badge giving the file extension. A photo whose file has gone missing
shows a broken-image icon.

### Categories

The category comes from the file type. In the two "by category" layouts
and in **Horizontal grid**, each category present becomes a heading
carrying the number of documents in it; tap a heading to collapse or
expand that section.

> 📷 [List grouped by category](../screenshots/05-documents.md#documents-list-by-category) — The all-documents browser in list-by-category view, showing audio recordings and photos.

| Heading | What lands there |
|---|---|
| **Photos** | JPG, PNG, GIF, BMP, WEBP, HEIC |
| **Videos** | MP4, MOV, AVI, MKV, WEBM |
| **Audio** | MP3, WAV, OGG, M4A, FLAC |
| **Text documents** | Plain text and Markdown, **rich-text documents**, PDF, and Word / OpenDocument files |
| **Web links** | Nothing you can create in the app — see below |
| **Other** | Any file type the app does not recognise |

Two groupings surprise people: a rich-text note and a survey PDF both
count as **Text documents**, and a spreadsheet or an archive lands in
**Other**. **Web links** can appear as a heading, but nothing in the app
creates a web-link document — such rows only arrive from imported or
synchronised data.

## Adding documents

By default a row of five icon buttons sits directly under the title bar.
Left to right:

| Button | What it does |
|---|---|
| **New text document** | A plain-text editor with a title field. |
| **New rich text** | A formatted editor with a styling toolbar (bold, italic, lists, headings). |
| **Take photo** | Opens the device camera. |
| **Record audio** | The audio recorder, with a live waveform. |
| **Add from file** | Pick one or several files from the device at once. |

The toolbar can be turned off with **⋮ menu → Hide action toolbar**.
With it hidden, a **+** button and a paperclip button appear in the
title bar instead and offer exactly the same five actions. The choice is
remembered and applies to every documents list in the app.

New documents are attached to the cave or place whose list you opened.

### Taking a photo

**Take photo** opens the camera straight away. Once you have a shot,
three buttons appear under the preview:

1. **Retake** — opens the camera again.
2. **Edit in editor** — sends the picture to the image editor (crop and
   rotate, drawing tools, filters, text overlays) and saves the result.
3. **Save** — stores the photo as it is.

Backing out of the camera closes the whole screen without adding
anything. The page underneath the camera also offers **Pick from
gallery**, which attaches a picture you took earlier with another app.

A photo saved directly gets an automatic title such as
`Photo 2026-09-01T14:32:05`; one saved through the image editor is named
`image_` plus a timestamp. There is no chance to type your own title,
and photos cannot be renamed afterwards.

### Recording audio

The recorder writes uncompressed **WAV**, which is considerably larger
than an MP3 or M4A of the same length — a long recording underground
will take real space in your archive.

Press the microphone button to start, the pause button to pause and
resume, and the stop button to finish. Fill in **Title** before saving;
if you leave it empty the recording is named `rec_` plus the date and
time. Save with the save icon in the title bar.

The first time you record, the phone asks for microphone permission. If
you have previously refused it for good, SpeleoLoc shows a
**Permission required** dialog with an **Open Settings** button that
jumps straight to the app's permission page.

### Adding several files at once

**Add from file** takes a multiple selection, not just one file. Pick as
many as you like; a progress box counts them off as they are copied in,
and it cannot be cancelled or dismissed while it runs.

Each file keeps its own name, minus the extension, as the document
title — there is no opportunity to name them individually, so use the
editors when a proper title matters.

Files whose contents exactly match a document already attached to this
cave or place are silently skipped, so re-adding the same folder does
not create duplicates. If everything you picked was already there, the
confirmation reads "Imported: 0".

## Opening a document

What a tap does depends on the type.

| Type | What opens |
|---|---|
| **Photo** | The full-screen gallery. |
| **Text, rich text, audio** | Their **editor**, when you are in a cave or place documents list. |
| **PDF** | The built-in PDF reader — scroll through the pages, pinch to zoom. |
| **Video, spreadsheets, archives, anything unrecognised** | A placeholder page showing the file extension and a **Save** button. There is no player or preview. |

The **Save** button on that placeholder writes a copy of the file into
the device's temporary folder and tells you the path. It is the only way
to get a single document back out of the app; for anything more, use the
archive export.

**Long-press** a document for up to two choices: **Open** (the read-only
viewer) and, for text, rich-text, photo and audio documents, **Edit**
(the matching editor). Videos and unrecognised file types have neither,
so long-pressing them simply opens them.

That distinction matters most for audio: tapping an audio note in a cave
or place list opens the **recorder**, not a player. To just listen,
long-press it and choose **Open** — playback starts by itself once the
waveform is ready, a play/pause button sits underneath, you can tap or
drag the waveform to seek, and the player closes itself when the
recording ends.

### The photo gallery

Tapping any photo opens it full-screen on a black background. Swipe left
and right to move through all the other photos in the list without going
back, pinch to zoom and drag to pan. The header shows the photo's title
and its position, such as "3 / 17".

The gallery follows whatever filter and sort order the list is currently
using, so searching first is a quick way to page through only the photos
you care about. It is view-only — to change a photo, go back, long-press
it and choose **Edit**.

> 📷 [Grid view](../screenshots/05-documents.md#documents-grid) — The same documents browser in flat grid view, showing photo thumbnails.

## Editing

| Type | What you can change |
|---|---|
| **Text** | Title and content, in the text editor. |
| **Rich text** | Title and formatted content, in the rich-text editor. |
| **Audio** | Title, and the recording itself (see below). |
| **Photo** | The picture, in the image editor. The title stays as it was. |
| **PDF, video, office documents, anything else** | Nothing — these cannot be changed in the app at all, not even their title. |

A document's **description** cannot be edited anywhere in the app; it
only ever arrives with imported or synchronised data, where it still
counts for the search box.

Saving an edit **overwrites the stored file in place**. The previous
version of a photo, a note or a recording is not kept anywhere.

If you press back with unsaved changes in the text or rich-text editor,
a dialog offers **Save**, **Discard** and **Cancel**, so a mis-tap will
not lose a note you typed underground. Both editors refuse to save
without a title, and the plain-text editor also refuses to save an empty
document. If a new text document's contents exactly match one already
stored in the app, a short warning says so — it is only a notice, the
document is still saved.

### Re-recording audio

Opening an audio document in the recorder does not start from scratch.
Play the existing recording, drag the waveform to the point you want,
then press record: everything from that point on is replaced by the new
take, and everything before it is kept. There is no trim function, and
saving overwrites the original file.

## What you cannot do

There is no rename, delete, unlink, share or open-in-another-app action
for documents anywhere in SpeleoLoc. Once a file is attached it stays
attached, and the only way to change its title is to re-save it in the
text, rich-text or audio editor. Plan titles accordingly — especially
for photos and imported files, which cannot be renamed at all.

## Documents and trips

If a trip is running and not paused, documents you **create in the app**
— text notes, rich text, photos, sketches and recordings — are also
linked to the running trip and appear in its log alongside the places
you visit.

Files brought in with **Add from file** or with the bulk cave-document
import are attached to the cave or place only. They are never added to
the trip, even when one is running. See [Trips](trips.md).

## The all-documents browser

Open it from the home screen **⋮ menu → Documents**, from the
**Documents** icon on the home toolbar (which itself is switched on in
**Settings → General → Show home toolbar**), or from the **Documents**
entry in the ⋮ menu on other screens. The page is titled
**Documentation files** and lists every document stored in the app,
whichever cave or place it belongs to.

It is a browse-only view. You can search, sort, switch layouts, open
documents, and edit the content of text, rich-text, photo and audio
documents — but you cannot add new documents there, and you cannot
change which cave or place a document belongs to.

Because there is no cave or place in context, tapping a text, rich-text
or audio document here opens the **viewer** first, with a small pencil
button in the corner for switching to the editor. One oddity: a
rich-text document has no viewer of its own, so it shows the same
placeholder page as an unrecognised file — use the pencil button to
read it properly.

## Bulk import: a folder of documents per cave

If you already keep your cave photos and surveys in folders — one folder
per cave — you can attach the lot in one pass.

1. On the home screen choose **⋮ menu → Import cave documents**, or the
   folder-upload icon on the home toolbar.
2. Pick the parent folder — the one that *contains* the per-cave
   subfolders.
3. SpeleoLoc lists each subfolder with how many files it holds and tries
   to work out which cave it belongs to: first by an exact match of the
   folder name against a cave title, then by a leading
   `<area code>-<cave code>` token such as `2046-18 P. Fisurii`. A
   coloured chip on each row shows the result — **by title**, **by
   code**, **manual** or **not matched**.
4. Correct anything it got wrong: each row has a dropdown listing the
   caves in scope, plus **— skip —** to leave that folder out. Rows
   showing 0 files cannot be selected.
5. Press **Import**. A summary reports how many files were imported, how
   many caves were updated, how many were skipped as duplicates and how
   many failed.

Only files sitting *directly* in each subfolder are imported — deeper
subfolders are ignored — and hidden files are skipped. Running the same
import twice is safe: files whose contents already match a document on
that cave are skipped rather than duplicated.

The caves offered are the ones currently in scope on the home screen: if
you are in selection mode, the checked caves; otherwise every cave the
filter has left visible. Narrow the home list first if you want to
import into just a few caves.

### If every folder reports "0 files"

On Android it is common for the importer to list your subfolders
correctly but show "0 files" in all of them. That is Android hiding
other apps' files, not an empty folder. When every row scans as empty,
an orange banner explains this and offers **Allow all-files access**,
which takes you to the system permission page, and **Rescan** to try
again once you have granted it. Grant the access, come back, rescan, and
the counts should appear.

## Photo size and image compression

**Settings → Image compression** decides whether photos are shrunk as
they come into the app. It is **off by default**, so photos are stored
at full size until you turn it on.

With **Enable image compression** switched on you choose a
**Compression profile**:

| Profile | Longest side | Quality |
|---|---|---|
| Low reduction | 3840 px | 92% |
| Medium reduction | 1920 px | 80% |
| High reduction | 1280 px | 65% |
| Very high reduction | 800 px | 45% |
| Manual | your own value | your own value |

Compression applies to photos taken with the camera, photos added with
**Add from file**, and photos brought in by the bulk cave-document
import. Only images larger than the limit are actually shrunk, and the
stored copy is re-saved as JPEG. It does not touch videos, PDFs, audio
or sketches saved from the image editor, and it never alters the
original file on your device — only the copy the app keeps.

## Where the files live

Adding a document always makes a **copy**. Your original files stay
exactly where they were; nothing is moved, deleted or modified.

The copies go into a private folder inside the app's own storage, and
each one is renamed with a timestamp in front of the original file
name, so two files that share a name can never collide.

That folder belongs to the app, so **uninstalling SpeleoLoc deletes
every document with it**. Export an archive before uninstalling, or
before wiping app data. When you export an archive, documentation files
are optionally included; see
[Database export, import and backup](database-export-import.md).

## See also

- [Cave places](cave-places.md)
- [Caves and areas](caves-and-areas.md)
- [Trips](trips.md)
- [Home screen](home-screen.md)
- [Settings](settings.md)
- [Database export, import and backup](database-export-import.md)
