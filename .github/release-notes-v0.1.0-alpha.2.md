This release builds on **v0.1.0-alpha** and introduces major functional improvements centered on **trip workflows**, **navigation UX**, and **document handling**, plus broad technical updates across routing, persistence, and localization.

### 🚩 Major Highlights

- **New Cave Trip system**
  - Start/stop/resume/pause cave trips
  - Active trip state initialization on app startup
  - Trip history and trip details views
  - Trip logs with editable log page
  - Trip points recorded from QR scans
  - Document-to-trip linking and trip-related logging

- **Trip map visualization**
  - Trip route overlay on raster maps
  - Direction arrows, route lines, and numbered progression markers
  - Dedicated trip map/list view toggle

- **Global app menu redesign**
  - New reusable global menu system (`AppBarMenuMixin`)
  - Supports **popup mode** and **drawer mode** (persisted preference)
  - Consistent app-level navigation integration across many screens
  - App version display in menu drawer

- **QR workflows improved**
  - Global QR lookup service and handler
  - Disambiguation UI when multiple QR matches are found
  - New i18n string for multiple-match case
  - Additional QR generation settings behavior improvements (auto-refresh from settings)

---

### 🧭 Navigation & Routes

- Replaced cave route landing from old `CavePage` to **`CavePlacesListPage`**
- Added new routes:
  - `caveTripRoute`
  - `caveTripListRoute`
  - `caveTripLogRoute`
- App startup now initializes:
  - app menu mode preference
  - active trip session state

---

### 🗃️ Database & Data Model Changes

Schema version increased from **3 → 5**.

Added tables:

- `cave_trips`
- `cave_trip_points`
- `documentation_files_to_cave_trips`

Added migration steps:

- Create trip-related tables
- Add `log` column to `cave_trips`

New database/service capabilities include:

- Insert/end/get active trips
- Record trip points
- Fetch trip lists and titles
- Link docs to trips
- Delete trip with related rows
- Append/update trip logs

Archive/export-import updates include support for new trip tables and exclusion of active-trip runtime key from imports.

---

### 📄 Document System Improvements

- New **sound file viewer** overlay (`SoundFileViewer`)
- New **editable viewer wrapper** (`EditableDocumentViewer`) adding contextual edit action where supported
- Registry enhancements to support viewer/editor integration for additional formats
- Text document save now passes content metadata into helper flow
- Trip service can link newly saved documentation directly to active trip context

---

### 🎙️ Audio Recording Enhancements

`SoundRecorderPage` received significant improvements:

- Pause/resume recording support
- Better lifecycle control for player/recorder
- Improved handling of repeated record/stop cycles
- WAV splice/merge logic for partial overwrite workflows
- Safer state transitions and stream subscription management
- Better save behavior while recording and default title fallback

---

### 🗺️ Raster Map & Cave Place UX

- Trip overlay support integrated in raster map editor stack
- Added map/list mode behavior in trip pages
- Cave place list supports:
  - checkbox selection mode
  - select all / invert selection
  - batch delete selected places
  - selected-only QR generation path
- Added trip history quick-access affordances in cave place screen

---

### 🌐 Localization (EN/RO)

Large localization update with many new keys, including:

- trip lifecycle labels and actions
- trip history/log/status labels
- map-view labels
- global menu mode labels
- multi-QR-match messaging
- additional UI action wording consistency

---

### 🧰 Settings & UI Consistency

- Global menu integration added across many app screens (forms, settings, scanner, document pages, viewers, map screens, etc.)
- PDF settings improvements:
  - better variable insertion behavior
  - steppers for rows/columns
  - template focus and cleanup refinements
- QR label template cleanup logic improved to better handle empty variable substitution artifacts

---

### 📦 Tooling / Config

- App version bumped: **`0.1.0+1` → `0.1.0+2`**
- Added dependency: `package_info_plus`
- macOS generated plugin registrant updated accordingly
- `.github/` now ignored in `.gitignore`

---

### ⚠️ Compatibility / Notes

- This remains an **alpha** line release.
- Includes **database migrations** (schema v5), so backup/export is recommended before broad testing on production-like datasets.
- Trip and menu frameworks are now foundational; future releases are expected to extend them further.
