# Connecting a build to the SilexGIS test instance

[← Back to index](../README.md)

> **For maintainers and testers, not for cavers.** This page is about trying
> a build against a public test server. To set up your own club's server, see
> [Club server (SilexGIS)](../features/silexgis-sync.md).

SilexGIS runs a public test installation at
**https://silexgistest.speotopo.ro**, holding invented demonstration data
only. Point a build at it to try the club server screen end to end without a
registry of your own: signing in, choosing a selection, a sync both ways,
photos, trips, raster maps and the review hold.

## Before you start

- **Never send real data to it.** It is public, and anyone who opens its
  sign-in page holds the administrator account. Use a phone or emulator whose
  caves are invented, or a fresh install.
- **It is wiped every night at 04:30 UTC.** Everything a phone sent is gone
  after that: selections, caves, photos, trips, phone users, and the
  sign-ins too. Expect to sign in again and choose a new selection each day.
- **It is a small shared machine.** No load tests, and no scripts that sync
  in a loop.

## The demonstration accounts

The sign-in page lists these accounts with a fill-in button each, so they
are not secrets.

| Account | Password | Use it for |
|---|---|---|
| `editor@test.local` | `test-login-pass-1` | The phone's ordinary account: download, upload, photos, trips, raster maps |
| `viewer@test.local` | `test-login-pass-1` | A read-only phone: everything comes down, and every upload is refused |
| `admin@test.local` | `test-login-pass-1` | The web interface only: the review queue, the phone users, and marking an account's uploads for review |

Sign the phone in as `editor@test.local` unless you are testing what a
read-only account sees. The administrator account is for the browser, not
for a phone.

## Pointing a build at it

Nothing has to be configured on the server, and any build can connect.

1. Open **Settings → Club server (SilexGIS)** and press **Add a server**.
2. Give it a **Name** such as "SilexGIS test", and enter
   `https://silexgistest.speotopo.ro` as the **Address** — the bare address,
   with nothing after it.
3. Press **Sign in** on the server card, and sign in as
   `editor@test.local` with the password above.
4. Press **Choose** to pick a selection. The account starts each day with
   none, so first sign in to `https://silexgistest.speotopo.ro` in a browser as
   `editor@test.local`, create a selection there, then come back and choose
   it.
5. Run a sync.

The server card shows what the installation offers. On this one all of it is
on: caves and places both ways, photos and documents, people, trips, raster
maps and reviews.

## Trying the review hold

1. In a browser, sign in as `admin@test.local` and, in user administration,
   mark `editor@test.local` as **uploads need review**.
2. Make a change on the phone and sync. The change goes up held, and the
   phone counts it as waiting for a reviewer.
3. Back in the browser as the administrator, accept or reject it on the
   review page.
4. Sync the phone again. An accepted change becomes the server's; a rejected
   one stays on the phone as your draft, under **Needs a decision**.

The nightly wipe clears the mark again, so repeat step 1 each day.

## The automated live tests

The repository's live sync tests are written against the local development
server, its accounts and its seeded caves, and they create and delete
selections freely. Do not point them at this instance; run them against the
development server as their own instructions say.

## See also

- [Club server (SilexGIS)](../features/silexgis-sync.md)
- [Shipping a build with a pre-configured sync profile](seeded-sync-profile.md)
- [Android emulators and automated UI checks](android-emulator-and-ui-testing.md)
- [Working with a local test archive](local-test-archive.md)
