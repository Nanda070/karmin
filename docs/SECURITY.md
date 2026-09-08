# Security

Working threat model: [PLAN.md](PLAN.md) §5.

## Keystore keys

| Key | Content |
|---|---|
| `karmin.neptun.code` | Neptun code |
| `karmin.neptun.password` | Password (OS Keystore / Keychain) |
| `karmin.pin.hash` | `sha256(pin \|\| salt)` hex |
| `karmin.pin.salt` | 16 random bytes, base64 |
| `karmin.lock.bio_enabled` | Bio preference |

PIN plaintext is never stored. JWT is never persisted. TOTP secrets and email OTPs are never stored — the user types a fresh code on every Neptun authentication.

## Session

- PIN / Face ID = local app lock.
- Warm resume (JWT still in RAM): Unlock only.
- Cold start or 401: Unlock (if needed) then interactive 2FA. Password may be replayed from Keystore.
- Email OTP resend is **re-authentication** (same password POST). Do not log the password or the OTP. Cooldown 30s to avoid hammering Neptun.

## Platform

- Android: `android:allowBackup="false"`.
- iOS: Keychain `first_unlock_this_device`, `synchronizable: false`. Bundle ID `online.cheterin.karmin`. Face ID usage string in Info.plist (`local_auth`). ATS stays on (Neptun is HTTPS).
- FLAG_SECURE on Login / Verification / PIN / Unlock (best-effort MethodChannel; no-ops on web).
- Free iOS install / 7-day Personal Team: [IOS_SIDELLOAD.md](IOS_SIDELLOAD.md).

## Reporting

If you find a vulnerability in Karmin, contact the maintainer privately (do not file a public issue with secrets). Email TBD.

Do not log `Authorization`, `password`, OTP `token`, or JWTs.

Exam signup (`POST ExamRegistration/SignUpForExam`) is a student-initiated write. The `{ examId }` body is best-effort until captured from a live ELTE session. Show Neptun’s error/notification text; never log the JWT or request bodies.
