# Changelog

## Unreleased — Stage 2 cached reads (partial)

- Live student reads: calendar, dashboard averages, credit progress, unread count
- Today + Calendar bind to the snapshot (debug fixtures on web; live on mobile / `KARMIN_LIVE_AUTH`)
- JSON stale-while-revalidate cache (Isar deferred)
- Verification: **Send code again** re-POSTs stored Neptun code+password (30s cooldown, snackbar). Neptun email OTP is unreliable; this is the resend mechanism
- 401 interceptor: drop JWT, no retry until OTP
- Study + Inbox lists still demo

## Unreleased — Stage 1 Auth

- Auth gates: Disclaimer → Login → Verification (2FA) → Set PIN → Today
- Returning: Unlock (PIN / biometrics) then 2FA unless a JWT is still in RAM
- Debug/mock login is labeled; live `Account/Authenticate` behind `KARMIN_LIVE_AUTH`
- Settings: Sign out, Face ID toggle, Change PIN, ThemeMode (System / Dark / Light)
- Light theme tokens planned; full visual pass is Stage 4. Dark remains default

- Auth gates: Disclaimer → Login → Verification (2FA) → Set PIN → Today
- Returning: Unlock (PIN / biometrics) then 2FA unless a JWT is still in RAM
- Debug/mock login is labeled; live `Account/Authenticate` behind `KARMIN_LIVE_AUTH`
- Settings: Sign out, Face ID toggle, Change PIN, ThemeMode (System / Dark / Light)
- Light theme tokens planned; full visual pass is Stage 4. Dark remains default

## 0.1.0+1 — Stage 0 foundation

- Dark theme tokens (ink / navy / carmine), Inter, radius 12/16 + shared UI widgets
- `go_router` 4-tab shell: Today | Calendar | Study | Inbox (placeholders)
- Settings push from Today gear; profile placeholder
- l10n EN/HU/RU stubs (default English)
- `NeptunClient` skeleton + typed exceptions (no live auth)
- Secure storage, PIN hash helpers, `local_auth` probe wrappers
- Android `allowBackup=false`; iOS Keychain first-unlock-this-device
- Web platform scaffold for UI preview
- Docs: bilingual README, MIT © Cheterin, PLAN status (Stage 0 done → Stage 1 Auth), disclaimer / privacy / NOTICE
- Owner: Cheterin / cheterin.online — unofficial ELTE Neptun client
