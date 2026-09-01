# Shipping a build with a pre-configured sync profile

Hand-out builds (a caving-congress APK, a club test build) can ship the shared
FTP/SFTP account already configured, so nobody types a host and a password on
a phone underground. The endpoint is baked in at build time through
`--dart-define-from-file` and installed on first start by
`ensureSeededFtpProfile` (`lib/services/sync/ftp/ftp_profile_seed.dart`).

Store builds never use this: `tool/build_store_release.ps1` refuses a define
file that contains any `ftp_seed_*` key.

## Build-settings keys

| key | required | default | notes |
| --- | --- | --- | --- |
| `ftp_seed_host` | yes | — | empty means "no seeded profile"; the switch for the whole feature |
| `ftp_seed_name` | no | the host | display name in *Settings → FTP sync* |
| `ftp_seed_username` | no | empty | |
| `ftp_seed_password` | no | empty | written to the OS keystore |
| `ftp_seed_protocol` | no | `ftp` | `ftp`, `ftps` or `sftp` |
| `ftp_seed_port` | no | protocol default (21/21/22) | |
| `ftp_seed_remote_folder` | no | `/` | |

A define file carrying `ftp_seed_password` is **machine-local** and git-ignored
(`build_settings.congres.json`, `build_settings.*.local.json`) — same treatment
as `android/key.properties`. Recreate it from the table above; the values for a
given hand-out build live with whoever owns that account.

## Behaviour on the device

- The profile is created once, under a fixed UUID, and made the active
  (default) endpoint. Anything the user edits afterwards — password included —
  is never overwritten.
- Seeding is re-checked on every start, so the profile comes back after a
  replace-import (test-data load, restore from backup) has swapped in a
  database without it.
- Deleting the profile keeps it gone until the next replace-import.
- A later build with *different* seed values does not update an install that
  is already seeded; the user has to edit or delete the profile first.

## Security

The password is recoverable from the APK by anyone who has it. Only seed
accounts whose credentials are meant to be shared with everyone receiving the
build.
