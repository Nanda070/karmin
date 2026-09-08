# Changelog

## Unreleased — Stage 4 harden (polish)

- Login: “Can't reach Neptun.” only when there is no HTTP response (timeout / DNS / TLS). Dio GET `/Account/Login` must not send JSON `Content-Type` (Dio 5 `ArgumentError`). ELTE HTTP maps to credentials / captcha / OTP / request failed
- Attribution: owner / founder **Nanda**, company **Cheterin Group**; contact Discord `nandak070`, Telegram `nanda070`, mail `turkapahf@gmail.com` (README, LICENSE, legal docs)
- Shared empty / error / last-cached widgets on Today, Calendar, Study, Inbox, Auth (`KarminStatusBanner`, `KarminEmptyState`)
- Accessibility: Semantics on tabs, PIN keypad, OTP, password visibility; 48pt icon tap targets; contrast-aware carmine text
- Full light theme pass: `KarminPalette` — cream paper `#F4EFE6`, not Material white. Settings System / Dark / Light restyles all screens. Dark remains default
- Privacy / Disclaimer wording frozen; `docs/SMOKE.md` manual checklist
- iOS Xcode project repaired (`ios/`, bundle `online.cheterin.karmin`); free sideload guide + GitHub Actions unsigned IPA (`docs/IOS_SIDELLOAD.md`)
- Figma light frames, Android-on-Windows APK, local notifications, paid TestFlight: **not** in this slice

## Unreleased — Stage 3 Study + Inbox

- Study binds live/debug subjects, grades, GPA, credits; subject push page
- Exam signup: confirm sheet + `POST ExamRegistration/SignUpForExam` `{ examId }` (payload unproven on ELTE; debug mock is labeled)
- Inbox live/debug list + thread + mark-read; Today unread chip stays in sync
- Settings profile from `UserInfo` / training, else “Student” + Neptun code
- Empty / error / last-cached + pull-to-refresh on Study and Inbox

## Unreleased — Stage 2 cached reads

- Live student reads: calendar, dashboard averages, credit progress, unread count
- Today + Calendar bind to the snapshot (debug fixtures on web; live on mobile / `KARMIN_LIVE_AUTH`)
- JSON stale-while-revalidate cache (Isar deferred)
- Verification: **Send code again** re-POSTs stored Neptun code+password (30s cooldown, snackbar). Neptun email OTP is unreliable; this is the resend mechanism
- 401 interceptor: drop JWT, no retry until OTP

## Unreleased — Stage 1 Auth

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
- Docs: bilingual README, MIT © Nanda / Cheterin Group, PLAN status (Stage 0 done → Stage 1 Auth), disclaimer / privacy / NOTICE
- Owner: Nanda / Cheterin Group — unofficial ELTE Neptun client
