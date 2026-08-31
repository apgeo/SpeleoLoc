# Defects found against the SilexGIS sync contract

Written from the app side, for the effort that owns the .NET stack and the specification. Nothing
here is fixed here.

Each entry says what was sent, what came back, and what the contract says should have. Reproduced
against a `node deploy/speleoloc-dev.mjs up` server at `http://127.0.0.1:5205`, contract version 1,
upstream commit `31868b10`.

---

## 1. `name` and `description` are cleared by an upload that does not mention them

**Severity: high — silent data loss in the club's registry, on every row a device edits.**

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

### What the client does meanwhile, and why it is still worth fixing

SpeleoLoc sends `name` and `description` on **every** uploaded row, from its own copy, rather than
only when they changed. That is not a workaround leaning on the bug: the row carries the
`baseRevision` the device last read, so the server refuses it outright if anything moved since. The
device is doing a compare-and-set on the fields it owns, not a blind overwrite, and it stays correct
after this is fixed. Nothing here is blocked.

It is still worth fixing, for two reasons the client cannot reach.

**A client that believed the documents loses data.** The promise is stated twice, in the protocol
document and again in the standalone rules as something the client "may build on". Sending one
changed field is the obvious reading and it silently empties the club's description — or its name.

**Deliberate clearing has no shape at all in version 1.** An absent member and an explicit `null`
are the same bytes to the server, so whatever rule makes omission safe also makes "the caver cleared
this description" unsendable. If the fix is "apply a text field only when it is non-null", that
consequence is the other half of the same decision and should be written down rather than
discovered.

---

## 2. Creating any row is refused unless the sync set names a caving group, and nothing says so

**Severity: medium — a client author meets it as an undiagnosable refusal on every row.**

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
