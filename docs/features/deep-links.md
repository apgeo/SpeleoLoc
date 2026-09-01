# Deep links (`sp://`)

[← Back to index](../README.md)

A deep link is a short address of the form `sp://<identifier>` that opens
one cave place directly. It is what a printed QR label carries unless
you have SpeleoLoc print a web address instead (see [Labels that carry
the prefix](#labels-that-carry-the-prefix)), and what your phone's
camera hands to SpeleoLoc when you point it at that label.

## Where deep links work

On **Android**, SpeleoLoc registers the `sp://` scheme with the system:
tapping such a link in a message, a browser or a notes app, or scanning
it with the phone's own camera app, offers SpeleoLoc as the app to open
it with.

On **iOS the scheme is not registered**, so `sp://` links do nothing
there — no app claims them. Everything else on this page still works on
iOS through the app's own scanner and manual input; only the hand-off
from the operating system is missing.

## What the link looks like

```
sp://<identifier>
```

The identifier is a place's **QCRI** (the payload inside the QR pixels)
or its **PCI** (the human-readable place code) — both are matched, so a
link built from either one works. See
[Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md).

Examples:

- `sp://1547` — opens the place whose code or QR payload is `1547`.
- `sp://RO-CLB-001-002-005` — a hierarchical place code.
- `sp://a1b2c3d4` — an 8-character hashed QR payload.

Two rules matter in practice:

- **Everything after `sp://` is taken exactly as written**; only spaces
  around it are trimmed. A trailing slash, an extra path segment or a
  `?query=…` becomes part of the value being searched for, so
  `sp://1547/` will *not* find the place that `sp://1547` opens.
- **Upper and lower case do not matter.** `sp://AB12CD34` and
  `sp://ab12cd34` open the same place.

## How a link reaches SpeleoLoc

There are three ways in, and they behave slightly differently.

| Route | What happens |
|---|---|
| **In-app scanner** — the scan button on the home screen or in a cave's places list | The camera reads the label, the app strips the prefix and looks the value up. This is the reliable route underground. |
| **System camera or a tapped link** (Android only) | The OS asks which app to open the link with. SpeleoLoc jumps to the place when it is **already running**, in the foreground or in the background. A link that has to start SpeleoLoc from cold opens it on the home screen without navigating — once the app is up, tap the link again. |
| **Manual input** | In a cave's places list, tap **Manual QR code search** in the toolbar. Type either the bare identifier or a whole `sp://…` value into **QR code identifier** and press **Search place by QR code id**. (Developer builds can also reach the same search by holding the scan button for about two and a half seconds.) |

Manual input is the answer to a label that is muddy, cracked or behind a
squeeze — read the printed code with your eyes and type it in. Because
it always runs from inside a cave's places list, the search is limited to
that cave, so it can never be ambiguous. (In a developer build, the same
long-press on a cave place's own QR field does something different: it
fills that place's identifier in, rather than searching for a place.)

## What SpeleoLoc does with the value

1. **The `sp://` prefix is removed.** URL wrappers are unwrapped only
   for codes read by the in-app scanner or typed in by hand: an
   `http://` or `https://` payload is cut back to the text after the
   last delimiter character — which is how a label printed
   with your club's landing address still opens the place in the app.
   That behaviour is
   **Settings → QR Code Generation → Strip URL to identifier**, with
   **URL delimiter characters** `/` and `=` by default. A link handed
   over by the operating system skips this step entirely — what follows
   `sp://` is used as written.
2. **Every cave place whose QR payload or place code equals that value
   is matched**, ignoring upper/lower case. Because the place code is
   matched too, a link built from a place code still works even when
   your QR payloads are hashed.
3. **The result depends on how many places matched.**

| Matches | Result |
|---|---|
| 0 | The warning *Cave place not found* appears with the value that was searched for. |
| 1 | The place opens **on a map** — the first raster map, in your map sort order, that has a point defined for it. If no map has a point for that place you get *No map has a point defined for this cave place* and the plain cave place page instead. Either way a *Cave place has been identified* confirmation appears. |
| 2 or more | A **Choose point / cave** dialog lists each match with its cave underneath. See below. |

When a [trip](trips.md) is running in the cave the matched place belongs
to, opening a place that is **not** an entrance also records it as a trip
point and confirms with *Point added to trip*. An entrance place asks
about the trip instead — see [Scanning an entrance](#scanning-an-entrance).

### When more than one cave uses the same code

Nothing stops the same code from being used in two different caves: a
code you type is only checked against the other places in the same cave,
and even there a duplicate is a question you can answer *yes* to. By
default SpeleoLoc asks which one you meant, with
the **Choose point / cave** dialog. Its **Open Settings** button goes
straight to the two switches that govern this:

| Switch (**Settings → General**) | Default | Off means |
|---|---|---|
| **Ask which cave on ambiguous QR scan** | On | A camera scan or a typed code silently opens the match from the last cave you opened. |
| **Ask which cave on ambiguous deep link** | On | An `sp://` link silently opens the match from the last cave you opened. |

"The last cave you opened" is the last cave whose places list you
visited. If none of the matches belongs to that cave, the first match is
opened. Both switches are independent, so you can keep the question for
one route and suppress it for the other.

## Scanning an entrance

Scanning or opening an **entrance** place never starts or stops a trip
on its own — it always asks first.

- **No trip running** — **Start trip**: *"You scanned a cave entrance.
  Would you like to start a new trip?"* Answer **Yes** and a **Start a
  new trip** dialog appears with a suggested **Trip title** you can
  edit.
- **A trip running in this cave** — **Stop trip**: *"You scanned a cave
  entrance. Are you exiting the cave? Stop the active trip?"* Answer
  **No** and the scan is recorded as a trip point instead, so you can
  pass the entrance without ending the trip.
- **A trip running in a different cave** — SpeleoLoc names that cave and
  asks whether to stop its trip; if you agree, it then offers to start a
  trip here.

See [Trips](trips.md) for what a trip records.

## Labels that carry the prefix

Every QR label SpeleoLoc prints normally encodes `sp://<identifier>`
rather than the bare identifier. That prefix is what makes the label
mean something outside the app: a phone's system camera recognises it as
a link and offers to open SpeleoLoc.

Turn **Settings → QR Code Generation → Include deep link prefix** off
and labels carry only the identifier — still perfectly readable by the
in-app scanner, and a slightly simpler QR image, but inert to the system
camera. Decide before printing a batch: labels already printed keep
whatever they were printed with, and the scanner accepts both forms
either way.

A landing address takes precedence over that switch. While one is set,
every label carries that address instead of `sp://`, and **Include deep
link prefix** is greyed out — a square carries one prefix or the other,
never both.

SpeleoLoc still has **no built-in public web page for a place** — the
page a visitor lands on is one your club hosts. What SpeleoLoc does now
is compose the address for you, so you no longer build it by hand
outside the app. Fill in **Settings → QR Code Generation → Landing
address for printed labels** with your club server's landing address and
every printed label carries that address with the identifier on the end
(`https://speo.example.org/q/k3f9x2`). A visitor without the app scans
it with the phone's own camera and gets your club's page; because the
identifier sits at the very end, **Strip URL to identifier** still
recovers it when a caver scans the same label with SpeleoLoc. See
[QR codes](qr-codes.md) for the setting itself.

One thing to check before printing labels as web addresses: an
identifier holding a `/` or an `=` does not survive the trip back. The
scanner keeps only what follows the last one, so the rest of the code is
thrown away and the place is not found — from a label that printed
perfectly well. SpeleoLoc warns you about the one field that would break
every future code at once: type either character into **Settings → Place
code identifiers → Segment separator**, under the hierarchical strategy,
and a warning appears under the field. It is only a warning — the value
is still saved, and nothing checks a code you type into a place
yourself. Hashed QR payloads never contain either character.

## Troubleshooting

- **"Cave place not found: …"** — the value matches neither the QR
  payload nor the place code of any place on this device. Sync or import
  the latest data and try again; check for a stray trailing slash if you
  typed or built the link by hand. On a label printed with a landing
  address, check as well that the code itself holds no `/` or `=` — the
  scanner would have cut it short there.
- **"Invalid QR code"** — nothing was left to search for once the prefix
  was stripped. From the scanner or manual input this reads
  *Invalid QR code (not parsable per rules)* together with the value that
  was read; from a link it appears as a dialog titled **Deep Link**. A
  link that is nothing but `sp://` is discarded without any message at
  all. Note that a value which is present but unknown is not "invalid" —
  that gives *Cave place not found* instead.
- **The chooser dialog appears every time** — press **Open Settings** in
  it and turn off *Ask which cave on ambiguous deep link* (or *…on
  ambiguous QR scan*) to have SpeleoLoc pick the last cave you opened.
  The lasting fix is to remove the duplicate place codes across caves;
  switching to hashed QR payloads does not help, because the place code
  is matched too.
- **A tapped link only opened the home screen** — SpeleoLoc was not
  running yet. Tap the link a second time now that it is.
- **Nothing at all happens on an iPhone** — expected: the `sp://` scheme
  is not registered on iOS. Use the in-app scanner or manual input.

## See also

- [QR codes — placing, scanning, printing](qr-codes.md)
- [Place codes (PCI) and QR payloads (QCRI)](place-code-identifiers.md)
- [Cave places](cave-places.md)
- [Trips](trips.md)
- [Settings](settings.md)
- [Navigating underground](../workflows/navigating-underground.md)
