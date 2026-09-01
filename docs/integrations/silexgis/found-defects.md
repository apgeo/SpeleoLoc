# Defects found against the SilexGIS sync contract

Written from the app side, for the effort that owns the .NET stack and the specification. Nothing
here is fixed here.

Each entry says what was sent, what came back, and what the contract says should have. Reproduced
against a `node deploy/speleoloc-dev.mjs up` server at `http://127.0.0.1:5205`, contract version 1.

**All three are fixed as of upstream `3435445e` (2026-09-01).** They are kept rather than deleted:
each one changed something in this client, and the entry is why. Every entry now opens with what
the fix settled, and what this side does about it. The reproductions below describe the behaviour of
`31868b10` and earlier.

---

## 1. `name` and `description` are cleared by an upload that does not mention them

**Fixed in `3435445e`.** Both are now applied only when sent, which is what the contract already
promised twice. The other half of that decision is now written down as well: because an absent
member and an explicit `null` arrive as the same value, **this generation cannot clear a field at
all** — `"description": null` leaves the stored description alone, and a device that must empty one
sends a space. This client still sends both on every row, which is now a choice rather than a
workaround; see below.

*Originally: high — silent data loss in the club's registry, on every row a device edits.*

### What the contract says

`01-protocol.md` §8.4:

> **An upload is a partial write.** `name`, `description`, `properties` and the position are what a
> device owns on a row that already exists.

and `06-standalone-rules.md` §2, under what the server guarantees in return:

> **The server never nulls a field it was not sent.** An upload is a partial write. A device may
> send one changed field and leave the rest of the row alone […]

### What happens

A row is created with a name and a description. A second upload renames it, and the `description`
member is **not present in the row object at all**. The rename is applied and the description is
nulled.

```
POST /api/v1/sync/sets/<set>/upload

{ "batchId": "01a05a2c-0a3b-7f2a-a89f-fcc8d9eaeae4", "contractVersion": 1,
  "rows": [ { "id": "01a05a2c-0a3b-7829-a684-c4a6447f7277", "kind": "generic",
              "baseRevision": null, "deleted": false,
              "parentId": "01a05a2a-26f9-7a88-b88d-679256d6acac",
              "name": "Sala Mare",
              "description": "Large chamber, 40 m long. Survey 2019.",
              "featureTypeCode": "cave_place", "isMain": false,
              "geometry": { "type": "Point", "coordinates": [25.56, 45.56] },
              "properties": { "speleolocPci": "AB-0007", "speleolocSchemaVersion": 1 } } ] }

--> 200   rows[0].status = "created", revision "2026-08-31T23:33:50.89016+00:00"
```

Downloading the set here returns `name: "Sala Mare"`,
`description: "Large chamber, 40 m long. Survey 2019."`. Then:

```
POST /api/v1/sync/sets/<set>/upload

{ "batchId": "01a05a2c-0b00-7305-a8bb-b1dcaabae971", "contractVersion": 1,
  "rows": [ { "id": "01a05a2c-0a3b-7829-a684-c4a6447f7277", "kind": "generic",
              "baseRevision": "2026-08-31T23:33:50.89016+00:00", "deleted": false,
              "name": "Sala Mare (resurveyed)" } ] }

--> 200   rows[0].status = "updated", revision "2026-08-31T23:33:51.066845+00:00"
```

Downloading the set now returns `name: "Sala Mare (resurveyed)"` and **`description: null`**.

### It is exactly these two fields

The same probe, run once per field — create a full row, then send an update naming only one field —
gives:

| Update mentions only | Applied | Cleared by omission |
|---|---|---|
| `name` | `name` | `description` |
| `description` | `description` | **`name`** |
| `geometry` | `geometry` | `name`, `description` |
| `properties` | `properties` | `name`, `description` |

`geometry`, `altitude`, `positionQuality` and `properties` behave as documented: omitted, they are
left alone. `name` and `description` do not — and `name` is nulled just as readily as
`description`, so an update that corrects only a description leaves a nameless cave in the registry.

The shape suggests the two text fields are applied unconditionally from the deserialised row, where
an absent JSON member is indistinguishable from an explicit `null`, while the other four are guarded
by a non-null check.

### What this client does, before and after the fix

SpeleoLoc sends `name` and `description` on **every** uploaded row, from its own copy, rather than
only when they changed. Before the fix that sidestepped the data loss without leaning on it; after
it, the reason is the limit the fix made explicit.

The row carries the `baseRevision` the device last read, so the server refuses it outright if
anything moved since. That makes sending them a compare-and-set on the fields the device owns rather
than a blind overwrite — and it is also the only way the device's text reaches the server at all
when a caver empties a field, because an omitted member and a null are indistinguishable and neither
clears anything. A caver who clears a description on the device keeps a stale one on the server
until a generation whose row shape can say "empty this".

---

## 2. Creating any row is refused unless the sync set names a caving group, and nothing says so

**Fixed in `3435445e`.** A new row-level code, `sync.set_unbound`, now names the selection's missing
binding — and only when that is genuinely the cause: the refusal is re-decided against each club the
caller belongs to, and the general `access.create_forbidden` still stands for an account that holds
no create right at all, where choosing a club would change nothing. This client maps the new code to
`surface-to-user` and will offer the caver the clubs their account belongs to.

*Originally: medium — a client author meets it as an undiagnosable refusal on every row.*

### What happens

Signed in as `member@dev.local`, with a sync set created with `"cavingGroupId": null`, every create
is refused, whatever the kind and wherever it is contained:

```
POST /api/v1/sync/sets/<set>/upload
  rows[0] = { "id": …, "kind": "cave", "baseRevision": null, "deleted": false,
              "name": "Probe cave", "caveTypeCode": "cave", "isMain": false }

--> 200
{ "rows": [ { "id": "…", "status": "rejected", "revision": null,
              "code": "access.create_forbidden",
              "detail": "You may not create rows here." } ] }
```

A `surface_area`, which needs no container at all, is refused identically. The same account, the
same rows, and a set whose only difference is `"cavingGroupId": "01a04f07-a93d-7f67-943d-5ab94049409d"`
(Demo Caving Club, which this account is a member of) → `"status": "created"`. It holds for both
`"uploadVisibility": "cavingGroup"` and `"uploadVisibility": "private"`, so it is the binding that
decides and not the visibility.

### What the contract says

Nothing. `01-protocol.md` §2 describes a set as "a named selection of root features, plus the
settings its code generation depends on" and never mentions the group. §8 lists what makes a row
succeed or fail and never mentions it either. `04-errors.md` §6.2 documents the code as

> `access.create_forbidden` — The account may not create a row of this shape in this place.

which reads as a fact about the row's kind and its container — the two things the client chose —
and sends a client author to look at both. The deciding field is on the *set*, which by then was
written and is not part of the failing request.

`sync.caving_group_forbidden` exists for a group the account is not entitled to, and
`sync.caving_group_not_found` for one that does not exist, so the group binding is clearly load
bearing on this route; the case where there is no binding at all is the one with no answer of its
own.

### What would settle it

One sentence in `01-protocol.md` §2 saying that a set with no caving group cannot be uploaded
through by an account that does not otherwise hold a create right, and a line in `04-errors.md`
§6.2 naming the set's binding as the third thing to check. A distinct code would be better than
either — the client could then tell the caver to pick a group instead of showing them
"You may not create rows here."

This is a client-visible constraint on the sync-set editor: a caver who intends to upload has to
choose a caving group, and the app cannot know that from the documents.

---

## 3. `altitude` and `positionQuality` do not survive a round trip, and one of them cannot survive at all

**Fixed in `3435445e`.** An altitude is now kept on every kind that carries a point, mirrored into
the stored point's third ordinate, and `01-protocol.md` §4 now says that a downloaded point may
carry that ordinate and that it is the altitude. `positionQuality` is documented as write-only in
this generation. The fix also names a second fault underneath the first, which this side could not
have seen: comparing two points is a two-dimensional question, so an edit moving nothing but the
altitude produced a point equal to the stored one and was dropped before it reached the database.

This client already sent the altitude on every kind and already read the third ordinate, so it
gained the round trip with no change beyond a comment and a test expectation.

*Originally: medium — a column the device fills is silently unsendable, and an
altitude that is kept is invisible to a client reading the documented fields.*

### What the contract says

`01-protocol.md` §8.4 lists what a row may carry:

> | `geometry`, `altitude`, `positionQuality` | The position, and how it was obtained |

and `02-field-mapping.md` §0 says coordinates are optional on every row, "not only on the ones
that usually have them". Neither says what happens to those two fields afterwards. §4 of the
protocol document, which is the whole of a downloaded row, lists no `altitude` and no
`positionQuality` — and states that the table "is the whole row".

### What happens

Three different behaviours, none of them written down.

| Sent on | `altitude` | `positionQuality` |
|---|---|---|
| `caveEntrance` (and the `cave` that copies it) | kept, and readable **only** as the point's third ordinate | never readable back |
| `cave_place`, `cave_area`, `surface_area` | accepted and discarded | never readable back |

An entrance created with `"geometry": {"type":"Point","coordinates":[25.60,45.60]}` and
`"altitude": 1240.0` comes back from the download as

```json
"geometry": { "type": "Point", "coordinates": [25.6, 45.6, 1240] }
```

The same upload against a `cave_place` — `[25.61, 45.61]` with `"altitude": -137.5` — comes back
two-dimensional, and the ordinary feature route confirms the value was not stored anywhere:
`GET /api/v1/features/{id}` returns the same 2D point and a generic feature record with no altitude
field of any kind. `"positionQuality": "estimated"` is likewise nowhere in either answer.

### Why it matters

**A client reading the documented row loses every altitude.** §4 says the table it gives is the
whole row, so a client that reads `geometry.coordinates[0]` and `[1]` — which is what a GeoJSON
point is — never looks at a third ordinate and drops the entrance altitude on the floor. Nothing in
the documents suggests looking there.

**A cave place's altitude cannot be carried at all in version 1.** SpeleoLoc stores an altitude on
every cave place, entrance or not. There is no field for it on a generic row and no legal place to
put it: `properties` is closed by the `cave_place` schema, and even if it were not,
`02-field-mapping.md` §4 forbids exactly this — "not a latitude, not a longitude, **and not an
altitude**". So the honest statement is that the value does not travel, and a second device syncing
through the server will not have it. This client sends it anyway, because an entrance keeps it and
nothing is lost by trying, and reads a third ordinate where one is offered.

### What would settle it

Say in §4 that a point may carry a third ordinate and what it means, and say in §8.4 which kinds
keep `altitude` and that `positionQuality` is write-only. If a generic kind is meant to keep an
altitude, that is a fix rather than a documentation change — and the version-1 answer for a device
is the same either way until it ships.

---

## 4. A new code and two changed behaviours reached a client with no changelog entry

**Open. Severity: low as a defect, high as a habit — the changelog is the only thing a pinned build
has.**

`3435445e` added `sync.set_unbound`, changed what an upload does with a member it was not sent, and
changed whether an altitude survives on a generic kind. `contract/speleoloc-sync/v1/CHANGELOG.md` is
unchanged: its last entry is still `2026-08-29 — contract version 1`.

That file states its own rule, and this is exactly the case it names:

> - any `sync.*` or `qr.*` code that appeared, changed status, or stopped being sent. **A code is
>   visible to a client even when the version does not move**, and the register of them is
>   `docs/speleoloc-sync/04-errors.md`.

Nothing here needed a version bump and none is being asked for: a build pinned to 1 keeps working,
and all three changes are ones a client either benefits from silently or can ignore. The entry is
what tells that build's author which of those it is, without diffing two repositories.

There is a mechanical consequence too. `manifest.json` covers `CHANGELOG.md` precisely so that a
copy holding an old changelog cannot match on every digest and call itself current — and because the
changelog did not change, the roll-up digest did not either. A copy of the recordings taken before
this commit and one taken after are indistinguishable by the check that exists to distinguish them,
while the server underneath them behaves differently.

### What would settle it

An entry dated 2026-09-01 saying: contract version unchanged at 1; a build pinned to 1 keeps
working; no recorded exchange was re-written; `sync.set_unbound` appeared as a row-level `rejected`
code; an upload no longer writes `name` or `description` it was not sent, and cannot clear either;
an altitude now survives on every kind that carries a point.

---

## Confirmed, not defects

Recorded so the next session does not re-derive them, and so a later change can see what it would be
breaking.

- **A coordinate in a schema-less kind's property document is accepted and echoed back verbatim.**
  `{"latitude": 45.55, "longitude": 25.55}` on a `cave` row is stored unread and comes back on the
  next download. This is `06-standalone-rules.md` rule 11 working exactly as it is written: the rule
  is the client's and there is no server-side backstop. The closure *is* enforced on the two kinds
  that carry a schema — the same keys on a `cave_place` are refused
  `feature.properties_invalid`, `/latitude: All values fail against the false schema`.
- **`baseRevision` is compared on the parsed instant, not on the bytes.** A revision handed back as
  `2026-08-31T23:32:47.596665+00:00` and resent as `2026-08-31T23:32:47.596665Z` is accepted. The
  client still stores and sends the string verbatim — nothing in the contract promises this, and it
  costs nothing to not depend on it.
- **A member may read a row it may not write.** Editing an admin-owned cave answers
  `sync.row_forbidden`, as documented.
- **The withhold rule holds on the seeded data.** A set over all six demo caves downloads 11 rows as
  `member@dev.local`; `Avenul Demo Protejat` and its `Shaft` entrance are absent entirely, with no
  placeholder and nothing marking the gap. The same set as `admin@dev.local` carries them.
- **A child can arrive before its parent on a real page.** In that same download
  `Peștera Demo Izvorului entrance` precedes its cave, so the buffering `01-protocol.md` §3 requires
  is not a theoretical case.
- **`AllowAdministratorRead` is off by default.** `admin@dev.local` reading the member's set by its
  identifier gets `404 sync.set_not_found`.

---

## Questions the documents do not answer

Not defects, and not blocking — but each was decided here on a reading rather than on a statement,
so a later reader can see what was assumed.

**Where a device's identifiers go on a row that is not a `cave_place` or a `surface_area`.**
`02-field-mapping.md` §3 names the `speleoloc*` keys for those two kinds only. A device also holds a
`cave_local_index` on a cave, and a place code and QR reference on an *entrance* — which becomes a
`caveEntrance`, not a `cave_place`. Both of those kinds are schema-less, so the keys are accepted and
round-trip verbatim, and `01-protocol.md` §8.4 describes the property document generally as "where
the device's own identifiers and codes live". This client therefore writes the same keys there.
Nothing locating goes with them, so rule 11 is untouched. If that is wrong, the schema-bearing kinds
are where it will be said.

**Whether a cave may be contained by a `surface_area`.** Nothing says so. It works, and it is the
natural mapping of the device's own `caves.surface_area_uuid` — protection and visibility are
inherited along containment and along nothing else, so a cave under its massif inherits what the
massif carries. This client sends the edge on a create.

**How a downloaded entrance says it is its cave's main one.** It does not: there is no `isMain` on a
downloaded row. What encodes it server-side is that a cave's own map point is a copy of its main
entrance's, and the row does not restate that. Comparing coordinates to work it out would be
deriving a rule from what the server happens to do, so this client does not — it keeps whatever the
device decided locally. Worth a sentence in `01-protocol.md` §4 either way, since a client that
looks for the field will not find it.
