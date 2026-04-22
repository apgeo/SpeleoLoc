# Workflow: Documenting a new cave

[← Back to index](../README.md) · [Overview](../overview.md)

This guide walks through the full end-to-end process of setting up a cave
in SpeleoLoc from zero, so that team members can later navigate it and
attach observations. You only need to do most of this **once** per cave;
afterwards you only add incremental data.

## What you will need

- One or more **scanned cave maps** as image files (JPG or PNG). These
  will become [raster maps](../features/raster-maps.md).
- A list of **points of interest** you want to QR-tag (named spots, bends,
  intersections, lakes, narrow squeezes, …).
- A printer (or print shop) to produce the physical QR labels, and
  **waterproof/durable label material** for the cave environment.

## Step 1 — (Optional) Define a surface area

If you organize caves by region, create the surface area first so the
cave can be attached to it:

1. **Home → ⋮ menu → Manage surface areas**.
2. **Add surface area**, give it a title and optional description.

See [Surface areas](../features/surface-areas.md).

## Step 2 — Create the cave

1. From the **Home screen** press **Add cave** (the `+` button).
2. Fill in the cave title and, optionally, the surface area.
3. Save.

You are now on the cave's **places list** (currently empty).
See [Caves and cave areas](../features/caves-and-areas.md).

## Step 3 — Import the raster maps

1. Open the cave's **⋮ menu → Raster maps** (or the raster map icon in
   the toolbar).
2. Press **Add raster map**, pick the image file, choose the **map type**
   (plane view / projected profile / extended profile) and give it a
   title.
3. Repeat for each map you have. You can later delete or replace them.

See [Raster maps](../features/raster-maps.md).

## Step 4 — (Optional) Create cave areas

If the cave is large, it helps to define named zones:

1. **Cave menu → Manage cave areas**.
2. Add areas like "Entrance zone", "Main gallery", "Lower level".

Cave areas make filtering and reporting easier and can be referenced
when creating cave places.
See [Caves and cave areas](../features/caves-and-areas.md).

## Step 5 — Create cave places and their QR codes

There are three ways to create cave places, pick what fits best:

### 5a. One by one, manually

1. On the cave's **places list**, press **Add place**.
2. Enter the title, description, depth, optional GPS, optional QR code
   identifier. If you do not know the QR number yet, leave it blank —
   you can fill it in once the labels are printed and physically mounted.

See [Cave places](../features/cave-places.md).

### 5b. From a CSV list

If you already have a spreadsheet of points:

1. **Home → ⋮ → CSV import** (or from a specific cave's menu for a
   single-cave import).
2. Follow the column-mapping wizard.

See [CSV import](../features/csv-import.md).

### 5c. By tapping on a raster map

When adding places that are best identified visually:

1. Open a raster map in the viewer with tap-mode = **Define new place**.
2. Tap the map where the place is. A quick-add dialog asks for title,
   area and QR code.

See [Map viewer and point editor](../features/map-viewer.md).

## Step 6 — Pin each cave place on each relevant raster map

This is what makes later scans show an actual dot on the map.

1. Open a cave place → **Raster maps** tab (or the map icon).
2. For each raster map, tap the image where the place physically is. An
   orange pin appears and, when saved, becomes green (the stored
   "point definition").
3. If a place appears on several map types (e.g. on both plan view and
   projected profile), repeat for each map.

See [Map viewer and point editor](../features/map-viewer.md).

## Step 7 — Generate and print the QR labels

1. In the cave's places list, open the **⋮ menu → Print QR codes**.
2. Configure the layout (grid columns/rows, label template, colors, DPI)
   in **Settings → PDF Output** and **Settings → QR Generation** first if
   needed.
3. Export as **PDF** (for direct printing) or as **Images** (for external
   layout tools).

Useful template variables when labelling: place title, depth (with sign),
area title, cave title and QR identifier number. See
[QR codes — placing, scanning, printing](../features/qr-codes.md).

## Step 8 — Mount the labels inside the cave

Bring the printed labels with you and physically attach them at each
intended spot. Back on the surface, scanning a freshly mounted label
with the app should now identify the correct place on your maps.

## Step 9 — Attach initial documentation

Before your first real trip it is worth attaching baseline documents to
each place: photos, a short audio description, a sketch, a web link to
prior trip reports, etc.

1. Open a cave place → **Documents** tab.
2. Add as many entries as needed (from file, camera, audio recorder,
   text or rich-text editor, image editor).

See [Documents](../features/documents.md).

## Step 10 — Share the initial data with teammates

Generate an archive and send it to everyone who will go underground:

1. **Settings → Database → Export archive** → choose what to include.
2. Share the resulting zip file by any means (email, cloud, USB).
3. Teammates import it via **Settings → Database → Import / Restore**.

See [Sharing data between teams](sharing-data.md).

---

Next workflow: [Navigating underground](navigating-underground.md).
