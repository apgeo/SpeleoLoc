# Deep links (`sp://`)

[← Back to index](../README.md)

SpeleoLoc registers a custom URI scheme **`sp://`** on the device.
Opening any URI of the form `sp://<number>` navigates directly to the
cave place whose QR code identifier matches `<number>`. This is what
makes the scanner and the entrance QR codes work across apps.

## URI format

```
sp://<place-qr-code-identifier>
```

- `<place-qr-code-identifier>` is a positive integer.
- Anything after optional slashes/query strings is ignored by the
  simple resolver.

Example: `sp://1547` opens the cave place whose QR identifier is
`1547`.

## How deep links are delivered to SpeleoLoc

Three equivalent entry points:

1. **In-app QR scanner** — you scan a QR label encoding an `sp://…`
   URL; the app routes internally.
2. **OS-level scan / link tap** — scanning an `sp://` QR with the
   system camera or tapping such a link in a chat/browser asks the OS
   which app to open with; SpeleoLoc will appear in the chooser.
3. **Manual input** — the long-press-on-scan manual input dialog
   accepts either raw numbers or a full `sp://…` URI.

## Resolution

When SpeleoLoc receives an `sp://<id>` URI:

1. The scheme prefix is stripped and the number parsed.
2. The database is searched for cave places whose
   `place_qr_code_identifier` equals that number.
3. Outcomes:

| Match count | Result |
|---|---|
| 0 | "not found" warning |
| 1 | That cave place opens |
| 2+ across different caves | Prefer the **last opened cave**; otherwise show a chooser |

The "last opened cave" is remembered in the app's settings and used
as a tiebreaker to avoid prompting every time you re-enter a cave
where duplicate identifiers exist.

## Entrance / web QR

At a cave entrance, you can place a QR encoding the **public URL** of
the cave's entrance place. Because it is a URL:

- SpeleoLoc users get the rich in-app experience.
- Non-users opening the same QR with their phone's camera get a
  web-style link (if a public landing page is configured) — useful for
  tourists and other casual visitors.

Future versions may extend `sp://` with additional path components
(`sp://cave/<id>`, `sp://trip/<id>`, …); current behavior treats
anything as a QR identifier lookup.

## Troubleshooting

- **"Invalid QR code"** — the scanned value is not an integer or is
  not a well-formed `sp://` URI.
- **"QR not found"** — the identifier is not in the local database.
  Import the latest archive and retry.
- **Chooser dialog every time** — check for duplicate QR identifiers
  across caves; consider renumbering them.

## See also

- [QR codes](qr-codes.md)
- [Cave places](cave-places.md)
