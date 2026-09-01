# This copy: where it came from and how it is refreshed

Everything else in this directory, and everything under `test_data/silexgis_contract/v1/`, is a
**verbatim copy** of material maintained in the SilexGIS repository. Nothing in those files was
written here and nothing in them may be edited here — an edit would make this copy disagree with the
server it describes while still looking authoritative.

This file is the exception: it is the app side's own, and it exists because a copy nobody refreshes
is worse than no copy.

---

## What was copied, and from where

| Here | Upstream |
|---|---|
| `docs/integrations/silexgis/*.md` (except this file) | `docs/speleoloc-sync/` |
| `test_data/silexgis_contract/v1/` | `contract/speleoloc-sync/v1/` |

Copied at upstream commit `3435445e2be0f0956fa90a8d50465774862f0739`, contract version **1**.

The recorded traffic is the half that matters most: the tests under `test/services/silexgis/`
replay those bytes, so a stale or half-applied refresh silently changes what this application is
asserted to speak.

## Two different questions, answered two different ways

**"Is this copy intact?"** — a test answers it. `test/services/silexgis/contract_manifest_test.dart`
walks `test_data/silexgis_contract/v1/`, checks every file's size and SHA-256 against the
`manifest.json` beside them, and fails on a file the manifest does not list or does not find. A
refresh that copied nine of eleven directories fails there rather than in whichever fixture test
happens to touch the missing bytes first.

**"Is this copy current?"** — no test here can answer it, because currency is a fact about the
upstream repository. `manifest.json` carries a roll-up `digest` over all the recordings for exactly
this purpose: compare the two strings rather than diffing the trees.

```
jq -r .digest test_data/silexgis_contract/v1/manifest.json
jq -r .digest <silexgis>/contract/speleoloc-sync/v1/manifest.json
```

Equal digests mean the recordings are current. They say nothing about the nine documents, which the
manifest does not cover; for those, compare the upstream commit above with upstream's `HEAD`.

## Refreshing

1. Copy both trees over, whole. Never file by file — the manifest's own reason for existing is that
   a partial refresh is otherwise invisible.
2. Update the commit and contract version in the table above.
3. Run `flutter test test/services/silexgis/` — the manifest guard first, then the fixture replays.
4. Read `test_data/silexgis_contract/v1/CHANGELOG.md`. Its entries are written for somebody whose
   build pins a contract version, and the first line of each says whether that build still works.
   If `contractVersion` moved, `SilexgisContract.version` in the client has to move with it, and
   uploads from every build in the field are refused until it does.

A refresh is a contract change and reads as one. Commit it on its own, with the upstream commit in
the message, so the diff in the recordings is not buried under client changes made to accommodate
it.
