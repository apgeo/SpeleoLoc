# Trip reports and templates

[← Back to index](../README.md)

SpeleoLoc can generate a **trip report** from a trip's data — a
printable/editable ODT or DOCX document that summarizes the trip,
lists visited places, embeds the trip log and (optionally) an exported
map image.

## How it works

1. You register one or more **trip report templates** (ODT or DOCX
   files containing placeholder variables).
2. For any ended trip, you trigger **Export report**, pick a template
   and an output format.
3. SpeleoLoc fills the placeholders with trip data and writes the
   resulting document to a folder of your choice.

Template formats supported:

- **ODT** (OpenDocument Text) — native LibreOffice / OpenOffice.
- **DOCX** (Word).

The app detects the format from the file extension.

## Managing templates

**Home → ⋮ → Trip report templates**. The list shows every registered
template with size and date. Actions:

- **Add** — pick an `.odt` or `.docx` file from the device. It is
  copied into the app's data directory.
- **Delete** — permanent, with confirmation.

## Authoring a template

Create a regular ODT/DOCX document in your word processor. Wherever
you want data to be injected, use a placeholder variable. The exact
variable syntax matches the project's template engine; see the
in-product help when selecting a template, or inspect any sample
template shipped with the app.

Typical fields you will want to include:

- Trip title, start/end timestamp, duration.
- Cave title, surface area, cave areas traversed.
- Ordered list of trip points (place title, QR, depth, timestamp).
- Free-form trip log.
- An embedded trip map image.
- Team members (typed into the trip log or a dedicated field).

## Generating a report

1. Open a trip (from the cave's **Past trips** list or the active trip
   banner).
2. Pick **Export report** (or similar wording — actual label may vary
   by version).
3. Choose:
   - the **template**,
   - the **output format** (ODT / DOCX — typically matches the
     template's format),
   - the **output folder**.
4. SpeleoLoc writes the document and confirms success.

The generated file is a normal ODT/DOCX you can open, edit, print or
share with any office suite.

## Including a map image

To embed a route image in the report:

1. Open the trip's **map view**.
2. Select the raster map you want in the report.
3. Use **Export map as image** to generate a PNG — or let the template
   engine request it automatically if supported in your version.
4. If needed, reference the image in the template at the correct
   placeholder.

## Troubleshooting

- **Template format unsupported** — ensure the file extension is `.odt`
  or `.docx` and that the file is not password-protected.
- **Placeholders not replaced** — check variable syntax and that you
  selected the correct trip type of report.
- **Images missing** — regenerate the map image and make sure the
  template references the right placeholder key.

## See also

- [Trips](trips.md)
- [Map viewer](map-viewer.md)
