# Place Code Identifiers — Specification

[← Back to index](../README.md)

> Status: **Specification, ready for implementation review.** The
> system is in design; there is **no prior production data** to
> preserve, so the design is a clean break — no backward-compatibility
> shims for the old `place_qr_code_identifier` integer column.
>
> All previously open questions are now resolved. A short list of new
> proposals / clarifications raised by this revision is at the bottom
> (§12).

This document specifies a pluggable system for generating and
validating **place code identifiers** (the internal database codes for
cave places) and **QR code resource identifiers** (the payload
actually embedded in the QR pixels / deep link associated with each
cave place).

It replaces the current `cave_places.place_qr_code_identifier` integer
column and the implicit "uniqueness depends on user choice" behaviour.

`cave_places.uuid` remains the internal unique id used for all
foreign-key relations inside the application. Same for `cave_areas.uuid`.
The PCI and QCRI are *user-facing* identifiers, not internal keys.

---

## 1. Terminology

| Term | Meaning |
| --- | --- |
| **Place code identifier** (PCI) | The human-readable code (optionally printed on the physical label next to a cave place). Stored in `cave_places.place_code_identifier` as **TEXT**. Formerly known as the "QR code identifier". |
| **QR code resource identifier** (QCRI) | The payload embedded in the QR pixels / deep link URL. Either equal to the PCI, or a short hash derived from it. Stored in `cave_places.qr_code_resource_identifier` as **TEXT**. |
| **Assignment strategy** | A pluggable algorithm that allocates a PCI for a new cave place (or rebuilds one on regeneration) and validates a manually entered one. Selected globally per dataset. |
| **Strategy rules** | The strategy-specific settings (digit widths, country/org code, separator, hash style, etc.). |
| **General area identifier** | A string code attached to a `surface_areas` row, used as the area segment in Strategy 1. May itself encode a multi-level hierarchy (e.g. `"2048"` or `"20.48"`). |
| **Cave local index** | A per-cave segment unique within `<country><org><general_area_identifier>`. Stored in `caves.cave_local_index`. |
| **Cave-place local index** | The per-place suffix unique within `<country><org><general_area_identifier><cave_local_index>`. Stored only as part of the PCI; not a separate column. |

`Q-T1` ✅ — Term **"place code identifier"** is confirmed.

---

## 2. Goals & non-goals

**Goals**
- Provide a string PCI column on cave places.
- Provide a second field, QCRI, so QR payloads can optionally be
  hashed (privacy / shorter codes / opaque payloads).
- Support **at least three** assignment strategies, chosen per dataset,
  with room to add more without schema changes.
- Make rule parameters (country code, digit widths, hash style) part
  of the strategy configuration stored in `configurations`, and have
  the active strategy + its rules **sync across devices** without
  introducing a new table.
- Generation is exposed via three entry points: app-wide (from
  settings), per-area (from the cave area page), per-cave (from the
  cave details page). All routes share the same engine.
- Generation always (re)computes both PCI **and** QCRI in the same
  pass, asking the user before overwriting any non-empty existing
  value (with *skip all* / *apply to all* shortcuts).
- Keep the generation engine isolated from existing code: callers go
  through a single façade (`PlaceCodeService`) and never import a
  specific strategy.

**Non-goals (for this iteration)**
- Generating QR codes for `surface_places` (out of scope; that table
  is marked "not used").
- Cryptographic security of the hash — QCRI is *obfuscation*, not auth.
- **Backward compatibility with the legacy `place_qr_code_identifier`
  column.** The system is pre-production; the old column is dropped
  outright and no data migration is performed.
- Indexing tuning for the two new columns — added later when query
  patterns are known.

---

## 3. Database changes

All changes go through a new Drift migration. Drift schema is the
source of truth; the legacy SQL in `db/speleo_loc.db.sql` is updated
for parity.

### 3.1 `cave_places`

```diff
- place_qr_code_identifier    INTEGER,
+ place_code_identifier       TEXT(64),
+ qr_code_resource_identifier TEXT(64),
```

- **`place_code_identifier`**: nullable string.
- **`qr_code_resource_identifier`**: nullable string. Stored
  explicitly (not derived on read) so that switching `qcri_mode`
  doesn't invalidate already-printed labels.

No indexes added yet (deferred).

**Uniqueness is enforced at the service layer** *(Q-DB1 — locked in)*,
not in SQL, because the strategy decides the scope (global / per-cave
/ per-area). The `PlaceCodeService` is the single chokepoint through
which PCI/QCRI writes must pass — direct table writes outside it are
disallowed by convention (documented in
[contributing-docs.md](../contributing-docs.md)).

### 3.2 `caves`

```diff
+ cave_local_index             TEXT(32),
```

Nullable. Populated by Strategy 1 when needed.

### 3.3 `surface_areas`

```diff
+ general_area_identifier      TEXT(32),
```

Nullable, **flat string** *(Q-DB2 — locked in)*. If a multi-level
hierarchy is needed, encode it in the string (`"20.48"` or `"20-48"`).

### 3.4 `configurations` — new well-known keys

The `configurations` table is currently marked **not synced**
(local-only). We do not want a new table for strategy settings, so we
add a lightweight per-key sync flag and special-case the place-code
keys to opt into sync. See §3.5 for the schema change.

| Key | Synced? | Value | Purpose |
| --- | --- | --- | --- |
| `place_code_strategy` | yes | `'global_hierarchical'` \| `'per_cave_sequential'` \| `'per_area_sequential'` | Active strategy id. |
| `place_code_strategy_config` | yes | JSON | Strategy-specific rules. One blob keyed by strategy id, so switching strategies doesn't lose the previous config. |
| `qcri_mode` | yes | `'mirror'` \| `'hash'` | Whether QCRI = PCI, or QCRI = hash(PCI). |
| `qcri_hash_config` | yes | JSON | `{ "alg": "sha256_b36", "length": 8 }` — see §5. Note: salt is *not* stored (see §5.2). |

All read/written via the existing
[`SettingsHelper`](../../lib/screens/settings/settings_helper.dart)
JSON helpers (extended for the new sync flag).

Default seed values (set on first launch):
- `place_code_strategy = 'global_hierarchical'`.
- `qcri_mode = 'mirror'`.
- `qcri_hash_config = { "alg": "sha256_b36", "length": 8 }`.
- `place_code_strategy_config['global_hierarchical']` = defaults from
  §4.2 **with empty `country_code` and `organization_code`**.

On first attempt to generate a PCI under Strategy 1, if
`country_code` or `organization_code` is empty, the UI opens the
settings page and prompts the user to fill them in.

### 3.5 Making selected `configurations` keys syncable

To sync the strategy choice and rules without introducing a new
table, add one column:

```diff
CREATE TABLE configurations (
    id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    title       TEXT(255) NOT NULL UNIQUE,
    value       TEXT,
+   is_synced   INTEGER NOT NULL DEFAULT 0,
    created_at  INTEGER,
    updated_at  INTEGER
);
```

- The archive exporter/importer
  ([`archive_table_configs.dart`](../../lib/services/archive/archive_table_configs.dart))
  filters `configurations` rows by `is_synced = 1` on export, and
  upserts them on import (conflict on `title` → last-writer-wins by
  `updated_at`).
- The place-code keys above are seeded with `is_synced = 1`.
- Existing local-only keys (`device_uuid`, `current_user_uuid`,
  `ftp_*`, etc.) keep `is_synced = 0` — no behaviour change for them.
- The `configurations` table itself is currently in
  `archive_table_configs.tableConfigs`; on import we already have the
  insert/upsert plumbing — only the row-filter logic needs updating.

**Conflict resolution on sync**: a synced configuration value is just
last-writer-wins on `updated_at`, same as every other table. If two
devices change the strategy independently between syncs, the later
update wins and the regen tool (§5.4) can fix up codes on the loser
device.

---

## 4. Assignment strategies

### 4.1 Common abstraction

```dart
abstract class PlaceCodeStrategy {
  String get id;                  // stored in configurations
  String get displayNameKey;      // i18n key
  String get shortDescriptionKey; // i18n key, shown inline next to rules
  String get longDescriptionKey;  // i18n key, shown in a modal
  Map<String, dynamic> get defaultConfig;

  /// Validate a user-entered PCI; null = ok, otherwise a localized error.
  Future<String?> validate(
    String pci, {
    required Uuid cavePlaceUuid,
    required Uuid caveUuid,
  });

  /// Generate the next PCI for a place in [caveUuid].
  ///
  /// Returns a [PlaceCodeGenerationResult]:
  ///   - `ok(pci)`       — code generated successfully
  ///   - `skipped(reason)` — this cave/place cannot be generated under
  ///                        the current config (e.g. missing area code
  ///                        in Strategy 1, missing surface area in
  ///                        Strategy 3). Batch loops continue with
  ///                        the next place; UI surfaces the reason.
  Future<PlaceCodeGenerationResult> generate({
    required Uuid caveUuid,
    required Uuid cavePlaceUuid,
    required bool isMainEntrance,
  });

  /// Optional input mask for the edit field.
  String formatInput(String raw) => raw;
}
```

The active instance is resolved by `PlaceCodeStrategyRegistry` keyed
off `configurations.place_code_strategy`. New strategies = one new
file + one list entry; nothing else needs editing.

### 4.2 Strategy 1 — Global hierarchical *(default)*

PCI format (segments concatenated, all digits by default, optional
separator):

```
<country><sep><organization><sep><general_area_identifier><sep><cave_local_index><sep><cave_place_local_index>

Example (no separator):
  country=881  org=028  area=2048  cave_local=078  place_local=0005
  → "88102820480780005"
```

Config (JSON under `place_code_strategy_config['global_hierarchical']`):

```jsonc
{
  "country_code": "881",
  "country_code_width": 3,
  "organization_code": "028",
  "organization_code_width": 3,
  "cave_local_index_width": 3,         // digits for cave_local_index
  "cave_place_local_index_width": 4,   // digits for cave_place_local_index
  "allow_non_digit": false,            // if true, segments may be alphanumeric
  "main_entrance_suffix": "0001",      // reserved for is_main_entrance places when free
  "segment_separator": ""              // user-chosen, e.g. "" or "-" or "."
}
```

> The area segment width is implicitly the **length of
> `surface_areas.general_area_identifier`** for that cave's area; it is
> not configured here. This lets different areas use different widths
> without a dataset-wide setting.

`country_code` and `organization_code` are **dataset-level only,
independent of any other data** *(Q-S1b — locked in)*.

Rules:
- **`cave_local_index`** is the smallest unused
  `cave_local_index_width`-digit string within
  `<country><org><area>`. Defaults: start at `001`, increment, skip
  used ones. Uniqueness scope: per
  `<country><org><general_area_identifier>` group.
- **`cave_place_local_index`** is the smallest unused
  `cave_place_local_index_width`-digit string within
  `<country><org><area><cave_local_index>`. Defaults: start at
  `0001`. Uniqueness scope: per
  `<country><org><general_area_identifier><cave_local_index>` group.
- If `is_main_entrance` is true and `main_entrance_suffix` is free,
  use it for the place suffix.
- **Global uniqueness** of the final PCI is also re-checked at write
  time (defence-in-depth; should be redundant given the per-segment
  rules).
- **Deferred configuration / skip-this-cave behaviour**
  *(Q-S1c — locked in: refuse for those specific caves)*:
  - If `country_code` or `organization_code` is empty: the **batch
    aborts up-front** with an "open settings" prompt (a dataset-wide
    block).
  - If `cave.surface_area_uuid` is null, or the referenced area has
    no `general_area_identifier`: that specific cave (and its places)
    is **skipped**, the reason is recorded, and the batch continues.
    Reasons are surfaced in a per-batch summary dialog.
- **Manual PCI entry** *(Q-S1a — locked in: warning + override)*: the
  entered string must (1) parse into the configured layout — hard
  error if not, (2) match this cave's baseline
  (country+org+area+cave_local_index) — **warning + override**
  allowed, (3) be globally unique — hard error if not.

### 4.3 Strategy 2 — Per-cave sequential

PCI is an integer (rendered as string), unique within a cave, starting
at 1. The PCI is stored as TEXT so a future strategy can return
alphanumerics without a schema change.

Config:
```jsonc
{
  "start_at": 1,
  "step": 1,
  "zero_pad_width": 0,     // 0 = no padding, 4 = "0001"
  "main_entrance_first": true
}
```

- `generate()`: `max(int(place_code_identifier))` within the cave,
  `+ step`. Initial value = `start_at`.
- `validate()`: integer, ≥ `start_at`, unique within the cave.

### 4.4 Strategy 3 — Per-area sequential

Same as Strategy 2 but uniqueness is scoped to the surface area (all
caves that share `surface_area_uuid`).

*(Q-S3 — locked in: refuse for those specific caves)*. If a cave has
no `surface_area_uuid`, **that cave is skipped** in batch generation
with a recorded reason; the batch continues. Single-place generation
shows an inline error and refuses.

### 4.5 Future strategies (design accommodates them)

- Per-organization sequential.
- Country-prefixed only (`<country><sequence>`).
- Custom user-supplied (manual entry only; strategy = "no auto").
- Per-cave strategy override: different caves on the same device
  using different strategies. Would need a new
  `caves.place_code_strategy_override` column; not part of this
  iteration but the registry already supports the lookup.

---

## 5. QR code resource identifier (QCRI)

QCRI is always stored as a plain string in
`cave_places.qr_code_resource_identifier`. Index optimizations are
deferred until query patterns are known.

### 5.1 `qcri_mode = 'mirror'`

`qr_code_resource_identifier = place_code_identifier` on every PCI
write.

### 5.2 `qcri_mode = 'hash'`

On every PCI write, compute *(Q-H1 / Q-H2 — locked in)*:

```
QCRI = base36_lowercase( sha256( salt || utf8(pci) ) ) [: length]
```

- **Algorithm**: `sha256` (from `package:crypto`).
- **Output alphabet**: `[0-9a-z]` — no uppercase. Standard base36
  encoder over the raw hash bytes interpreted as a big integer, then
  truncate to `length` lowercase characters.
- **Default `length`**: `8`. Range exposed in UI: 4–16.
- **Salt**: a **hardcoded** byte string baked into the app code (not
  user-configurable, not synced). Per the user's decision: "16 random
  bytes hardcoded — two datasets / processes generating the same PCI
  should therefore produce the same QCRIs." Cross-dataset
  reproducibility is the goal.
- **Collision handling**: if the generated QCRI already exists for a
  different `cave_places.uuid`, the hasher retries with `length+1`
  (up to a hard cap of 16). The longer QCRI is stored on the new row
  only; previously-stored QCRIs are not touched. A warning is logged.

> ⚠️ **Design tension flagged** — see §12. A hardcoded salt is
> intentional (so multiple datasets agree on QCRIs), but it also
> means the system has no per-dataset rotation. Confirm this is OK.

### 5.3 Lookup

Deep-link / scan lookup matches **either** column:

```dart
// TODO(place-code): Reconsider — once the system stabilizes we should
//  match only on qr_code_resource_identifier to avoid confusion and
//  edge cases where a PCI and someone else's QCRI collide. Kept
//  permissive for now so users can type a known PCI manually.
WHERE place_code_identifier = ? OR qr_code_resource_identifier = ?
```

### 5.4 Generation entry points

PCI generation is exposed at three scopes, all delegating to
`PlaceCodeService.generateForScope(...)`:

| Entry point | UI location | Scope |
| --- | --- | --- |
| **Global** | Settings → Place code identifiers → "Generate codes for entire dataset" | All cave places in the dataset. |
| **Per-area** | Cave area page → "Generate codes" button | All cave places whose cave belongs to that area. |
| **Per-cave** | Cave details page → "Generate codes" button | All cave places in that cave. |

In all three cases the engine **also (re)computes QCRI** in the same
pass, using the current `qcri_mode`.

**Overwrite handling** (per the user's spec):

For each place visited, the engine compares old vs newly-computed
values:

- If the place's `place_code_identifier` is non-null/non-empty **and**
  the new PCI differs → prompt:
  - *Replace* / *Keep* / *Replace all* / *Keep all (skip remaining
    PCIs)* / *Cancel batch*.
- Same prompt logic for `qr_code_resource_identifier`.
- The two prompts are independent — the user might accept "replace
  all PCIs" but reject overwriting QCRIs, etc.
- Empty/null existing values are overwritten silently.
- All decisions are recorded in `change_log` like any other update.

The batch ends with a summary dialog: *N updated, M skipped (with
reasons), K refused (incompatible / not unique)*.

### 5.5 Recompute / rotate

In addition to the generation entry points above, the settings page
has:

- **"Recompute all QCRIs"** — rewrites every QCRI from the current
  PCI under the current `qcri_mode`. No prompts; assumed-safe action
  used after switching mode or changing `length`. Suggested
  automatically (banner) when the user changes `qcri_mode` or
  `length`.
- **"Regenerate all PCIs from strategy"** — same as the global "Generate
  codes" button (alias for discoverability in the Danger Zone).

---

## 6. UI / UX changes

### 6.1 New settings page

**Settings → Place code identifiers**
(`lib/screens/settings/settings_place_codes_page.dart`):

1. **Strategy** — dropdown (Global hierarchical / Per-cave sequential /
   Per-area sequential).
2. **Strategy description** — short text inline next to the rules
   plus a "More info" button opening a modal with the long
   description. Both texts come from
   `strategy.shortDescriptionKey` / `strategy.longDescriptionKey` and
   are hardcoded i18n entries.
3. **Strategy rules** — dynamic form rendered by the selected
   strategy (each strategy supplies its own widget builder).
   Strategy 1 includes `country_code`, `organization_code`,
   `cave_local_index_width`, `cave_place_local_index_width`,
   `main_entrance_suffix`, `segment_separator`, `allow_non_digit`.
4. **QR code resource identifier**
   - Mode: *Mirror PCI* / *Hashed*.
   - When hashed: length slider (4–16), preview "Example PCI
     `123456789` → QCRI `xa7bk3qm`". (No "regenerate salt" button —
     salt is hardcoded.)
   - "Recompute all QCRIs" button.
5. **Bulk generation**
   - "Generate codes for entire dataset" button (calls the engine
     globally; same as the cave-area / cave button but unscoped).
6. **Surface area codes** — shortcut into the surface-area editor for
   filling `general_area_identifier`. Shown only when the chosen
   strategy needs it.

### 6.2 Cave place edit dialog

- Field labelled "Place code identifier" (was "QR code identifier").
- Text input (was numeric). Placeholder = the strategy's expected
  format (e.g. `881028204807800005` for Strategy 1 with the configured
  widths).
- "Auto-generate" button → calls the active strategy.
- "Scan" button: unchanged; scanner now accepts any string.
- Inline validation messages come from `strategy.validate()`.

### 6.3 Cave details page

- Add a "Generate codes" action (per-cave entry point, §5.4).

### 6.4 Cave area page

- Add a "Generate codes" action (per-area entry point, §5.4).

### 6.5 Cave & surface area edit screens

- Surface area edit: new optional **General area identifier** field
  (shown when the strategy needs it).
- Cave edit: editable **Cave local index** (`cave_local_index`),
  shown when the strategy needs it. Editing is gated behind the same
  unlock affordance currently used for the QR code field on
  `CavePlacePage`.

### 6.6 QR label template engine

Template variables:
- `@place_code_identifier` — the PCI string.
- `@qr_res_identifier` — the QCRI (what's encoded in the QR pixels;
  equals PCI in mirror mode).

The legacy `@place_qr_code_identifier` variable is **removed**, not
aliased.

---

## 7. Migration

The migration is a **clean break** (no prior data to preserve)
*(Q-M1 — locked in)*:

1. `ALTER TABLE caves ADD COLUMN cave_local_index TEXT;`
2. `ALTER TABLE surface_areas ADD COLUMN general_area_identifier TEXT;`
3. `ALTER TABLE configurations ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0;`
4. Replace `cave_places.place_qr_code_identifier` (INTEGER) with:
   - `place_code_identifier       TEXT`
   - `qr_code_resource_identifier TEXT`

   Using Drift's `m.alterTable` to rebuild the table. **Old column
   data is dropped, not copied** — this is the "clean break" decision
   locked in via Q-M1. Any rows already in the wild on developer
   devices will lose their old integer QR codes.
5. Seed `configurations` with the defaults listed in §3.4 (rows
   created with `is_synced = 1`).

`surface_places.surface_place_qr_code_identifier` is **left as-is**
for now; that table is marked "not used" in the schema.

> ⚠️ **Contradiction noted in the prior draft** — an earlier revision
> added a "copy old integer values into the new TEXT column" step
> after step 4. That contradicts the locked-in "clean break"
> decision (Q-M1 / Q-BC1) and has been removed. If you do want to
> preserve the integers, we have to re-open Q-M1; flag in §12.

---

## 8. Code organization

The generation engine is **fully separated** from existing
screens/repositories (per the user's request). Existing code only
imports the façade `PlaceCodeService` — never a concrete strategy or
the hasher.

```
lib/services/place_code/
  place_code_strategy.dart            // abstract + result types + registry
  place_code_service.dart             // façade (the only public entry point)
  qcri_hasher.dart                    // hash mode logic
  strategies/
    global_hierarchical_strategy.dart // Strategy 1
    per_cave_sequential_strategy.dart // Strategy 2
    per_area_sequential_strategy.dart // Strategy 3
  batch/
    place_code_batch_runner.dart      // global / per-area / per-cave loops
    place_code_overwrite_policy.dart  // skip-all / apply-all state machine
lib/screens/settings/
  settings_place_codes_page.dart
  widgets/
    strategy_config_form.dart         // dynamic per-strategy form
```

Touchpoints in **existing** code (kept minimal):

- `lib/services/cave_place_repository.dart` — replace any direct
  writes to the old QR column with calls into `PlaceCodeService`.
- `lib/utils/deep_link_handler.dart` — switch the lookup to the
  `place_code_identifier OR qr_code_resource_identifier` query (§5.3).
- `lib/utils/qr_label_template_engine.dart` — swap the template
  variables (§6.6).
- `lib/services/archive/archive_table_configs.dart` — column list
  updates (new `place_code_identifier`, `qr_code_resource_identifier`,
  `cave_local_index`, `general_area_identifier`) and the
  `is_synced`-filtered `configurations` export.
- `lib/screens/caves/cave_details_page.dart` and the cave-area page —
  add the "Generate codes" buttons (thin UI wrappers that call
  `PlaceCodeService.generateForScope(...)`).

`change_log` automatically picks up the new columns via the existing
repository-layer logging — no change needed there.

---

## 9. Testing

- Unit tests per strategy (`test/services/place_code/`):
  - `generate()` produces the expected sequence (with/without
    main-entrance reservation).
  - `validate()` accepts good codes and rejects bad ones.
  - Strategy 1: layout parsing, `cave_local_index` and
    `cave_place_local_index` allocation, skip-this-cave behaviour
    when config or area is incomplete.
  - Strategy 3: skip-this-cave behaviour when `surface_area_uuid` is
    null.
- `qcri_hasher_test.dart`: deterministic output, collision retry,
  alphabet contains only `[0-9a-z]`, cross-dataset reproducibility
  (same PCI → same QCRI on a clean install elsewhere).
- `place_code_batch_runner_test.dart`: overwrite-prompt state machine
  (apply-all / skip-all / cancel), summary report contents.
- Migration test: schema rebuild succeeds on an empty database and on
  a database with arbitrary unrelated data.
- Widget tests for the new settings page (load/save round-trip,
  strategy switch preserves the previous strategy's config blob).
- Deep-link test: lookup by both `place_code_identifier` and
  `qr_code_resource_identifier`.
- Sync round-trip: export → import preserves `place_code_strategy`,
  `place_code_strategy_config`, `qcri_mode`, `qcri_hash_config`
  (because they're `is_synced = 1`), and does **not** export
  local-only keys like `device_uuid`.

---

## 10. Decisions locked in

| Id | Decision |
| --- | --- |
| Q-T1  | Term confirmed: "place code identifier". |
| Q-DB1 | App-level uniqueness; no SQL `UNIQUE` constraint. |
| Q-DB2 | `general_area_identifier` is a flat string. |
| Q-H1  | Hash algorithm = sha256, truncated, base36 lowercase. |
| Q-H2  | Default QCRI length = 8. |
| Q-M1  | No prior data; clean break. Default strategy = `global_hierarchical`. |
| Q-S1a | Strategy 1 manual entry: warning + override on baseline mismatch. |
| Q-S1b | `country_code` / `organization_code` are dataset-level only. |
| Q-S1c | Strategy 1 with incomplete config: refuse / skip for those specific caves; batch continues. |
| Q-S3  | Strategy 3 without surface area: refuse / skip for those specific caves; batch continues. |
| Q-BC1 | No backward-compatibility shim; legacy column dropped. |
| —     | QCRI stored as plain TEXT string; indexing tuning deferred. |
| —     | Strategy choice + rules are synced via a new `configurations.is_synced` flag (no new table). |
| —     | Hash salt is hardcoded in the app (not stored, not rotatable, not synced — same on all devices and datasets). |

---

## 11. Implementation phases (proposed order)

1. **Schema + migration.** Drift table changes,
   `configurations.is_synced` column, seed rows. Archive column-list
   updates. No new UI; the existing cave-place dialog gets a stub
   text field bound to `place_code_identifier`. Existing screens
   compile, tests pass.
2. **`PlaceCodeService` + the three strategies (pure Dart).** Fully
   unit-tested in isolation before being wired anywhere.
3. **QCRI hasher + integration with cave-place writes.** Every PCI
   write through the service also rewrites the QCRI.
4. **Batch runner + overwrite-policy state machine** (§5.4
   semantics). Unit-tested in isolation.
5. **Cave-place edit UI.** Rename field, auto-generate button,
   strategy-driven validation messages, input mask.
6. **Settings page** (strategy picker, per-strategy form, descriptions
   modal, recompute / generate tools).
7. **Surface area / cave UI additions** (`general_area_identifier`,
   `cave_local_index`, "Generate codes" buttons on cave-area and
   cave-details pages).

Each phase ends green-on-tests and is independently shippable.

---

## 12. Validation pass — contradictions, proposals, and questions

This section is the result of re-reading the spec end-to-end against
the latest set of decisions.

### 12.1 Contradictions found and resolved in this revision

1. **Migration step 5 vs Q-M1**. A prior revision had
   *"5. Copy current `cave_places.place_qr_code_identifier` into
   `place_code_identifier`"* immediately after step 4
   *"Old column data is dropped, not copied"*. These cannot both be
   true.
   **Resolution applied**: removed the copy step, kept Q-M1's "clean
   break".
   **`❓ Q-M2`** — Confirm: developer devices that already have
   non-null integer QR codes will lose them on migration. Is that
   acceptable, or do you actually want the integer-to-text copy
   (which means flipping Q-M1)?

2. **Rule wording around `cave_local_index` vs `cave_place_local_index`**.
   The earlier draft mixed the two ("`cave_place_local_index` is the
   next free `cave_width`-digit sequence", starting at `801` in one
   place and `0001` in another). Rewritten in §4.2 with explicit
   uniqueness scopes and a clean separation:
   - `cave_local_index` (width `cave_local_index_width`, default
     `001…`) is unique per `<country><org><area>`.
   - `cave_place_local_index` (width `cave_place_local_index_width`,
     default `0001…`) is unique per the cave's full baseline.

3. **Area width**. Both old drafts had `area_widths: [4]` in the
   config, but the user's new format makes the area width =
   `length(general_area_identifier)`. Two areas can therefore have
   different widths. Removed `area_widths` from the config in §4.2.
   **`Area width is implicit from each area's
   `general_area_identifier` length, no global setting. Variable-width
   areas are OK (they only need to be unambiguous *within their own
   PCIs*, which they are because the cave segment immediately follows
   the area segment and has a fixed width).

4. **Salt: random vs hardcoded.** The previous draft had a "regenerate
   salt" button and a stored salt in `qcri_hash_config`. The new
   spec says "16 random bytes hardcoded … same PCI should produce
   the same QCRI" across datasets. These are incompatible.
   **Resolution applied**: removed the regenerate-salt button and
   the `salt` key from `qcri_hash_config`; salt is now a constant in
   the app code.
   Confirming that salt is a single global constant baked
   into the binary; never rotated, never user-visible. Trade-off:
   anyone with the source code can compute a QCRI from a PCI
   (obfuscation only, not security). The user explicitly said
   "obfuscation, not auth" — so this matches the goal, but please
   double-confirm.

5. **Sync of strategy config without a new table.** The user asked
   that the strategy be sync-able "ideally without making a new
   table". The cleanest fit is to (a) add `is_synced` to
   `configurations` and (b) special-case the four place-code keys.
   This is now §3.5.
   The `is_synced` column approach is OK.

### 12.2 Proposals (new in this revision)

- **`PlaceCodeGenerationResult`** is now a sum type
  (`ok` / `skipped(reason)`) rather than a raw `Future<String>` —
  needed so the batch runner can keep going past skipped caves
  (Strategy 1 missing area, Strategy 3 missing surface area) and
  produce a useful summary.
- **`PlaceCodeOverwritePolicy`** is a small state machine that holds
  the "apply to all PCIs" / "skip all QCRIs" / etc. flags across the
  batch — kept in its own file so the prompt logic is unit-testable
  without UI.
- **Cave details / cave area generation buttons** are thin wrappers
  that just call `PlaceCodeService.generateForScope(scope)`; the
  same engine and the same prompts back the global, per-area, and
  per-cave flows. No code duplication.
- **Variable-width area identifier** as described in 12.1 §3 is
  simpler and more flexible than a global `area_widths` config.

### 12.3 Remaining open questions

| Id | Question | Answer |
| --- | --- | --- |
| Q-M2 | Confirm dev devices lose their old integer QRs on migration (no copy). | answer - yes |
| Q-S1d | Confirm area width is implicit from `general_area_identifier` length (no global width setting). | answer - yes |
| Q-H3 | Confirm hardcoded salt + no rotation matches your goals. | answer - yes |
| Q-SYNC1 | Confirm `configurations.is_synced` column for selective sync (vs a hardcoded key allow-list). | answer - yes |

These do not block Phase 1 (schema + migration) — even Q-M2 only
affects whether step 4 should be split into "rebuild table" + "copy
integer → text", which is a self-contained tweak.
