# Trip reports and templates

[← Back to index](../README.md)

SpeleoLoc turns a trip into an ODT or DOCX document by taking a
template you supply and appending the trip's log text to the end of it.
Everything useful in the report therefore comes from two things: the
template you wrote, and the trip log.

## What a report actually is

The exported file is an exact copy of your template with the trip log
added as plain paragraphs at the very end. That is the whole of it:

- There are **no placeholders or variables**. SpeleoLoc does not scan
  the template for anything and does not substitute values into it.
- There is **no automatic place list, no trip metadata block and no
  map image**. Cave name, depths, place-code identifiers and QR
  identifiers never reach the document by themselves.
- The **output format always matches the template** — an ODT template
  produces an ODT, a DOCX template produces a DOCX. You are not asked
  to choose a format.

Anything else you want in the report you either put into the template
as fixed text, type into the trip log before exporting, or add by hand
in your word processor after the file is generated.

The report is a normal office document. Nothing links it back to the
template or to SpeleoLoc, so you can edit, print and share it freely.

## The trip log

The report is built from the trip log, so the log is where the work
happens. Open it from a trip's toolbar: **Trip log**.

### What SpeleoLoc records for you

The log is written for you automatically as the trip runs. It covers:

- the trip **starting**, with the trip title,
- every **stop** in order — a place you scanned or picked — together
  with any note attached to that stop (the **Raw** style leaves the
  notes out),
- every **document** you create or link while the trip is active,
  by title,
- a **restart**, if you restart an ended trip,
- the trip **ending**.

**Pauses and resumes are not written to the log.** Pausing simply
stops new stops and documents from being recorded until you resume; it
leaves no trace in the text and no gap you can point at afterwards.

Only a document's *title* appears in the log. Its content stays with
the document itself.

The log sentences are written in whatever language the app was set to
at the moment each line was generated, so a log built on a
Romanian-language app contains Romanian text. Changing **Settings →
General → App language** afterwards does not rewrite text that is
already in the log — only a regeneration (a style switch, or a trip
restart) rewrites it in the language then in use.

### Editing the log by hand

The trip log page is a plain monospace text editor. Type whatever you
like into it — team members, weather, equipment, conclusions.

Two things will catch you out:

1. **Nothing is saved until you tap the save icon** in the top bar.
   Saving shows **Trip log saved** and closes the page. Leaving any
   other way — back button, a swipe — discards what you typed without
   asking. Always save before exporting, because the export reads the
   saved log and not what is on screen.
2. **Some actions rebuild the log from scratch** and throw your text
   away. Restarting a trip does it, switching the log style does it,
   and — with the **Narrative** style only — so does every new event
   while the trip is still running.

With **Raw**, **Classic** or **Field journal**, a new event is added
as one more line after whatever is already in the log, so your own
text survives. **Narrative** has to rebuild the whole thing to keep
the paragraphs reading properly. If you want to annotate the log of a
trip that is still running, use one of the other three styles, or wait
until you have stopped the trip.

### Log styles

Four styles are available, and they change how the whole log reads.

| Style | What it produces | Line prefix |
|---|---|---|
| **Raw (timestamps + terse messages)** | Terse one-liners: `Trip started: "Sunday survey"`, `Point: "Entrance"`, `Document added: "Sump photo"`. | `[yyyy/MM/dd HH:mm:ss]` |
| **Classic (full sentences)** *(default)* | One full sentence per event: `The trip "Sunday survey" has begun.`, `Arrived at "Entrance".`, with any stop note in brackets after it. | `[yyyy/MM/dd HH:mm:ss]` |
| **Field journal (elapsed time + sequence)** | Sentences aware of their position in the trip: `First stop: "Entrance".`, then `Moved on to "Gallery".`, each stamped with the time elapsed since the start. | `[HH:mm · +Δ]` |
| **Narrative (paragraphs)** | Prose. An opening sentence with the trip title, date and start time; consecutive stops chained into one sentence carrying the gap between each (`After 15 min, the team reached "Entrance", then continued to "Gallery" (5 min later)`); a sentence for every stop note and every document; and a closing sentence with the finish time and total duration. | none |

**Narrative** is the one that reads well when appended to a report.

### Switching the style

1. Open a trip and tap **Trip log**.
2. Tap the open-book icon in the top bar (**Change log generation
   method**) and pick a style. A tick marks the one in use.
3. A **Regenerate trip log?** dialog warns you: *"The trip log will be
   regenerated from the recorded events using the selected method. Any
   manual edits will be lost."* Tap **Regenerate** to go ahead.
4. The log is rewritten in the new style and saved immediately.

The style is a **single setting for this device**, not a per-user or
per-trip one — changing it changes it for everyone who uses the
device, and it also applies to the next trip you run. You only need to
set it once.

> **Tip**: **Narrative** gives the most report-ready prose, so choose
> it *before* you write anything into the log by hand. Do not switch
> styles back and forth around a log you have already annotated —
> each switch discards your text. Export first, then edit the finished
> document in your word processor.

## Templates

A template is an ordinary ODT or DOCX document — your club's
letterhead, a title page, headings, a fixed "Participants" or
"Equipment" section, whatever you want above the log. It needs no
special markup of any kind, because SpeleoLoc only appends text to the
end of it. Leave the end of the document empty: that is where the log
lands.

No sample template ships with the app.

### Reaching the template screen

Open a trip, tap **Export report**, then **Manage templates** in the
template dialog. **This is the only way in** — there is no entry for
templates from the Home screen or from Settings.

The first time you do this you will have no templates at all, so
instead of a picker you get **No templates available. Add a template
first.** with a **Manage templates** button next to **Cancel**. That
button is the intended route.

The screen is titled **Document Templates**. Each row shows the
template's name, its format and its file size, for example
`ODT · 42.7 KB`. An empty list reads *"No templates defined. Tap + to
add an ODF or DOCX template."*

### Adding a template

1. On **Document Templates**, tap the **+** button.
2. Pick an `.odt` or `.docx` file from the device. Anything else is
   refused with **Unsupported format. Please select an ODT or DOCX
   file.**
3. An **Add Template** dialog opens with a **Template name** field,
   pre-filled with the file's name without its extension. This name is
   what you will see in the template list and when picking a template
   for a report, so make it recognisable.
4. Tap **OK**. The confirmation is **Template added**.

The file is copied into SpeleoLoc's own storage, so you can move or
delete the original afterwards without breaking anything.

If you clear the name field and tap **OK**, nothing is added and no
message is shown — it simply looks as though the dialog closed.

### Deleting a template

Tap the red delete icon on the row and confirm **Delete template
"<name>"?** with **Yes**. This removes both the entry and SpeleoLoc's
stored copy of the document; it cannot be undone from inside the app.
Your original file, wherever you picked it from, is untouched, and
reports you already exported are unaffected.

### Templates do not travel between devices

This is the one thing to know before relying on templates in a club.

A template has two parts: an entry in the database and the actual
`.odt`/`.docx` file inside the app. **Syncing and database export
carry the entry but not the file.** On a second phone the template
therefore appears in the list looking perfectly normal, and the export
then fails with a raw error message containing **Template file not
found**.

If your club shares one report template, every device has to add the
file for itself — there is no way to distribute it through sync or an
archive. The same applies after restoring a backup onto a fresh
install.

## Exporting a report

**Export report** is on the trip's toolbar and works for **any trip,
running or ended** — you do not have to stop the trip first.

1. Open the trip: from the cave's places list tap **Past / active
   trip(s)**, then tap the trip (or **View trip** for the active one).
2. Tap **Export report**. If the trip's log is empty you get **No trip
   log to export** and nothing else happens.
3. **Select a template** appears. Tap the template you want. The
   dialog also carries a **Manage templates** button if you need to
   add one first.
4. Your device's save dialog opens, titled **Export report**, with the
   file name already filled in as `trip_report_<trip title>.odt` (or
   `.docx`); spaces and punctuation in the trip title become
   underscores. Change the name or the destination if you want, then
   confirm.
5. SpeleoLoc writes the document, shows **Report exported
   successfully**, and then hands the file to whatever app on your
   device opens ODT or DOCX files.

If nothing opens at step 5 the report was still written — your device
simply has no app registered for that format.

## The trip map image

SpeleoLoc **cannot** put a map image into a report. The map is a
separate export that you insert by hand afterwards.

The trip's map view has its own **Export map** button, which appears
only while you are in map view and only when the cave has at least one
raster map. It saves a PNG of the map exactly as shown — route line,
direction arrows and numbered stops included — into the app's own
documents folder, named `trip_map_<trip title>_<timestamp>.png`, and
shows the full path in a **Trip map exported** message. There is no
save dialog and no folder choice.

To get that picture into your report: export the map, export the
report, then open the report in your word processor and insert the
PNG where you want it.

## Troubleshooting

| Message or symptom | What it means |
|---|---|
| **No trip log to export** | The trip's log is empty, and the report is built entirely from the log. Open **Trip log**, put something in it, save, then export again. |
| An error containing **Template file not found** | The template is listed but its document is missing on this device. Normal on a second device or after restoring a backup: add the file again here. |
| **Unsupported format. Please select an ODT or DOCX file.** | The picked file is not `.odt` or `.docx`. Save it again from your word processor in one of those two formats. |
| The report is just the template with text pasted at the end | That is exactly what it is. There is no substitution step. Rearrange things in your word processor after exporting. |
| Text you typed into the log has vanished | The log was regenerated — by a trip restart, by a style switch, or by a new event while the **Narrative** style was active. |
| Nothing happened after the export succeeded | The file was written; your device has no app that handles ODT or DOCX. |

## See also

- [Trips](trips.md)
- [Documents](documents.md)
- [Map viewer](map-viewer.md)
- [Running a trip](../workflows/running-a-trip.md)
- [Sync and the change log](sync-and-change-log.md)
- [Database export and import](database-export-import.md)
