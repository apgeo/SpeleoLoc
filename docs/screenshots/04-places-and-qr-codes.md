# Cave places and QR codes

[← Screenshot index](README.md) · [← Wiki index](../README.md)

The cave place form, and the generation of printable QR labels.

> The app runs in **Romanian** by default, so the screenshots show Romanian labels. Each entry lists the on-screen wording next to its English equivalent.

**On this page:** [The cave place form: codes and beacon](#cave-place-form-codes-and-beacons) · [Previewing generated QR labels](#qr-labels-pdf-preview) · [QR generation settings](#settings-qr-generation)

---

<a id="cave-place-form-codes-and-beacons"></a>

## The cave place form: codes and beacon

![The cave place form: codes and beacon](../images/cave-place-form-codes-and-beacons.jpg)

*The cave place form, scrolled from Title through BLE beacons to the Raster maps tabs.*

This is the full cave place form for an existing place, captured as one long scroll. The upper block holds Title, Description, the depth field and the Area title (optional) dropdown, with Cave areas and Show place code identifier beside it. The next row is the QR code resource identifier, flanked by View QR code, the QR-edit lock, Auto-generate and Scan. Below it the BLE beacons section offers Assign beacon for pairing a beacon to this place, and the Raster maps section is a tab strip of the cave's maps, each tab showing the map image so the place's position can be checked or set per map. The app bar provides Documents, Pick coordinates on map and Save.

<details><summary>On-screen wording (Romanian → English)</summary>

- p3 — cave place title (app bar)
- P. Ponorul Suspendat — parent cave title (app bar subtitle)
- Documente — Documents (folder icon, app bar)
- Alege coordonatele pe hartă — Pick coordinates on map (globe/search icon, app bar)
- Salvează — Save (floppy icon, app bar)
- Titlu — Title
- Descriere — Description
- Depth '+/-' — depth in cave field (label is untranslated in the app)
- Titlul ariei (opțional) — Area title (optional), set to Niciuna — None
- Zonele peșterii — Cave areas (layers icon)
- Afișează codul locului — Show place code identifier (eye icon)
- Vizualizează cod QR — View QR code (QR icon)
- Activează editarea codului QR — Enable QR edit (padlock icon)
- Identificator resursă cod QR — QR code resource identifier (value 18812520460760047)
- Generează automat — Auto-generate (sparkle icon)
- Scanează — Scan (QR scanner icon)
- Beaconuri BLE — BLE beacons (section header)
- Asociază beacon — Assign beacon
- Hărți: — Raster maps (section header with per-map tabs, e.g. ps_20250107_explorari_plan_fund…)

</details>

**Described in:** [Cave places](../features/cave-places.md) · [Ble beacons](../features/ble-beacons.md)

---

<a id="qr-labels-pdf-preview"></a>

## Previewing generated QR labels

![Previewing generated QR labels](../images/qr-labels-pdf-preview.jpg)

*Preview of the generated QR label sheet before exporting it.*

After generating QR labels for a set of cave places, this screen previews the resulting document — a scrollable, pinch-zoomable sheet of QR codes, each printed with its label text built from the label template (here place title plus cave title, e.g. "C1 baza P. Ponorul Suspendat"). The toolbar above the preview offers Regenerate PDF, QR Generation Settings and PDF Output Settings; returning from either settings page regenerates the preview so layout changes are visible immediately. The Export button at the bottom right writes the finished file out for sharing or printing.

<details><summary>On-screen wording (Romanian → English)</summary>

- App bar title "Coduri QR generate" — "Generated QR Codes"
- Refresh icon: "Regenerare PDF" — "Regenerate PDF"
- QR icon: "Setări generare QR" — "QR Generation Settings"
- PDF icon: "Setări ieșire PDF" — "PDF Output Settings"
- Extended button "Exportă" — "Export" (bottom right)
- Overflow / app menu button, top right
- Paginated preview of QR label cards, each captioned with the rendered label template (place title + cave title)

</details>

**Described in:** [Qr codes](../features/qr-codes.md)

---

<a id="settings-qr-generation"></a>

## QR generation settings

![QR generation settings](../images/settings-qr-generation.jpg)

*Settings that control how QR labels are rendered and scanned.*

This settings page governs everything about generated QR labels: the QR output kind (PDF or Images), then under QR Code generation settings the QR size, image padding, label font size and family, background and foreground colours with swatch pickers, DPI and error correction level, plus switches for Export images as zip and Include deep link prefix. Below that, PDF QR code padding sets horizontal and vertical spacing on the printed sheet, and the QR code label template defines the caption under each code from variables such as @place_title, @cave_title, @place_code_identifier and @depth, with #fz and #fc prefixes for per-variable font size and colour. The final QR scan settings block controls Strip URL to identifier and the URL delimiter characters used when a scanned payload is a web address. Every field saves as it is edited, and this page is reachable both from Settings and from the toolbar of the generated QR preview.

<details><summary>On-screen wording (Romanian → English)</summary>

- "Ieșire QR:" — "QR output:" dropdown, set to PDF (other value: "Imagini" — "Images")
- Section "Setări generare cod QR" — "QR Code generation settings"
- "Dimensiune QR (px)" — "QR size (px)", value 400
- "Spațiu imagine QR (px)" — "QR image padding (px)", value 24
- "Dimensiune font etichetă" — "Label font size", value 22.0
- "Familie font etichetă" — "Label font family", value Helvetica
- "Culoare fond QR (0xAARRGGBB)" — "QR background color (0xAARRGGBB)", FFFFFFFF, with colour swatch
- "Culoare prim-plan QR (0xAARRGGBB)" — "QR foreground color (0xAARRGGBB)", FF000000, with colour swatch
- "DPI (calitate)" — "DPI (quality)", value 300
- "Corecția erorii" — "Error correction" dropdown, set to H
- Switch "Exportă imaginile ca zip" — "Export images as zip" (on)
- Switch "Include prefix deep link" — "Include deep link prefix" (on), with help text about prepending the sp:// prefix
- Section "Spațiere cod QR în PDF (pt)" — "PDF QR code padding (pt)" with "Spațiere orizontală" — "Horizontal padding" 18.0 and "Spațiere verticală" — "Vertical padding" 18.0
- Section "Șablon etichetă cod QR" — "QR code label template", containing "@place_title @cave_title"
- "Variabile disponibile:" — "Available variables:" chips: @place_title (Cave place title), @description (Cave place description), @cave_title (Cave title), @area_title (Cave area title), @place_code_identifier (Place code identifier (PCI)), @qr_res_identifier (QR code resource identifier (QCRI)), @depth (Depth in cave (with +/- sign)), \n (Line break)
- "Prefixe de formatare (înainte de variabilă):" — "Formatting prefixes (before a variable):" with #fz<number> (font size) and #fc<color> (font colour in hex)
- Section "Setări scanare QR" — "QR scan settings"
- Switch "Extrage identificatorul din URL" — "Strip URL to identifier" (on)
- "Caractere delimitatoare URL" — "URL delimiter characters", value "/, ="
- Overflow / app menu button, top right

</details>

**Described in:** [Settings](../features/settings.md) · [Qr codes](../features/qr-codes.md)

---

[← Screenshot index](README.md)
