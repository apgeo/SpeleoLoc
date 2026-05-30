# Deep links (`sp://`)

[← Back to index](../index.md)

SpeleoLoc registers a custom URI scheme **`sp://`** on the device.
Opening any URI of the form `sp://<qcri>` navigates directly to the
cave place whose **QCRI** (QR code resource identifier) matches
`<qcri>`. This is what makes the scanner and the entrance QR codes
work across apps.

## URI format

```
sp://<qcri>
```

- `<qcri>` is a short string — typically the place's
  [PCI](place-code-identifiers.md) in **mirror mode**, or a short hash
  of it in **hash mode**.
- Anything after optional slashes/query strings is ignored by the
  simple resolver.

Examples:

- `sp://1547` — opens the cave place whose QCRI is `1547`.
- `sp://RO-CLB-001-002-005` — opens the place with that hierarchical
  QCRI.
- `sp://a1b2c3d4` — opens the place with that 8-character hashed QCRI.

## How deep links are delivered to SpeleoLoc

Three equivalent entry points:

1. **In-app QR scanner** — you scan a QR label encoding an `sp://…`
   URL; the app strips the URL prefix and resolves the QCRI.
2. **OS-level scan / link tap** — scanning an `sp://` QR with the
   system camera or tapping such a link in a chat/browser asks the OS
   which app to open with; SpeleoLoc will appear in the chooser.
3. **Manual input** — the long-press-on-scan manual input dialog
   accepts either a bare QCRI or a full `sp://…` URI.

The scanner also tolerates **other URL wrappers** (e.g. an `https://`
landing page that contains the QCRI as a path component); configurable
URL-stripping delimiters are applied before lookup.

## Resolution

When SpeleoLoc receives a QCRI:

1. The scheme prefix and any URL wrapper are stripped.
2. The database is searched for cave places whose `qr_code_resource_identifier`
   matches.
3. Outcomes:

| Match count | Result |
|---|---|
| 0 | "not found" warning |
| 1 | That cave place opens |
| 2+ across different caves | Prefer the **last opened cave**; otherwise show a chooser |

The "last opened cave" is remembered in the app's settings and used
as a tiebreaker to avoid prompting every time you re-enter a cave
where duplicate QCRIs exist.

## Entrance / web QR

At a cave entrance, you can place a QR encoding the **public URL** of
the cave's entrance place. Because it is a URL:

- SpeleoLoc users get the rich in-app experience.
- Non-users opening the same QR with their phone's camera get a
  web-style link (if a public landing page is configured) — useful for
  tourists and other casual visitors.

Scanning an entrance QR while a trip is active automatically starts
or stops the trip according to the **scan-an-entrance** setting (see
[Trips](trips.md)).

## Troubleshooting

- **"Invalid QR code"** — the scanned value could not be normalised
  into a QCRI (unexpected wrapper, empty payload).
- **"QR not found"** — the QCRI is not in the local database. Import
  the latest archive and retry.
- **Chooser dialog every time** — check for duplicate PCIs across
  caves; consider renumbering them, or switch to hash QCRIs.

## See also

- [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
- [QR codes](qr-codes.md)
- [Cave places](cave-places.md)
