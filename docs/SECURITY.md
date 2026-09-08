# Security (stub — Stage 0)

Not a full audit. Working threat model: [PLAN.md](PLAN.md) §5.

## Keystore keys

| Key | Content |
|---|---|
| `karmin.neptun.code` | Neptun code |
| `karmin.neptun.password` | Password (OS Keystore / Keychain) |
| `karmin.pin.hash` | `sha256(pin \|\| salt)` hex |
| `karmin.pin.salt` | 16 random bytes, base64 |
| `karmin.lock.bio_enabled` | Bio preference |

PIN plaintext is never stored. JWT is never persisted.

## Platform

- Android: `android:allowBackup="false"`.
- iOS: Keychain `first_unlock_this_device`, `synchronizable: false`.

## Reporting

If you find a vulnerability in Karmin, contact the maintainer privately (do not file a public issue with secrets). Email TBD.

Do not log `Authorization`, `password`, or tokens.
