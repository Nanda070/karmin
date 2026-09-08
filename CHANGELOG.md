# Changelog

## Unreleased — Stage 4 harden (polish)

- Fix «Can't reach Neptun» after `0.1.0+8`: the JSON Authenticate probe timed out / reset on iPhone (no HTTP) and aborted before MVC Login. Password is **MVC only**; JSON Authenticate is an optional JWT upgrade after Login2FA. Do not send `X-Requested-With: null` (Dio ArgumentError ≠ network). Build `0.1.0+9`
- Fix password-step HTTP 400: live dummy POST to `…/Account/api/Account/Authenticate` is **empty HTTP 400** (GET is HTML 404) — ELTE does not host that JSON controller. Login that reached Verification is **MVC** `GET+POST /Account/Login` (antiforgery + cookies) then `/Account/Login2FA` Authenticator digits. One JSON probe kept for 202/JWT institutes; empty 400 falls through to MVC (no LCID/header retry). Errors include HTTP status + `empty body` snippet. Build `0.1.0+8`
- Fix password-step HTTP 400 after `0.1.0+6`: first Authenticate is **LCID 1033 + Safari/XHR** (superseded by `+8` — LCID order was not the 400). Build `0.1.0+7`
- Restore Verification after `0.1.0+5`: password+OTP stay on one Authenticate URL; LCID **1038 then 1033** until 202/2FA/JWT (no hardcoded 1038-only); fork-minimal headers first, then one Safari/XHR retry if still not 2FA. Login/OTP errors show `HTTP xxx` + short Neptun text (never the opaque “sign on the website” without status). Student GETs stay on `Account/api` + real JWT. Build `0.1.0+6`
- Fix Authenticator OTP (fork deep compare): ELTE live password+OTP **only** via absolute Authenticate; body matches fork (`token:""` then digits, `LCID:1038`); headers = Content-Type only (+ `devicecookie`); strip Accept/Origin/Referer/XHR/UA/Bearer. No MVC mix on that path. OTP failures show `Neptun rejected this code (HTTP …)` (+ Neptun text); HTML/maintenance not remapped to opaque OTP. Build `0.1.0+5`
- Fix Authenticator OTP after `Account/api` baseUrl: Authenticate always uses absolute fork URL `{institute}/api/Account/Authenticate` via `postUri` (never relative under `…/Account/api/` — that risks `/api/api/…`). Student reads stay on `…/Account/api/`
- Fix live student refresh after Authenticator login: `NeptunClient.baseUrl` → `https://neptun.elte.hu/Account/api/` (fork host); stop calling dead `ujhallgato/api`. Real JWT only for Bearer; portal placeholder never triggers OTP. Soft-fail optional dashboard GETs; map HTML/maintenance clearly
- Fix JSON 2FA pending state: keep `_jsonTwoFactorPending` across unlock / 401 re-login until JWT or `NeptunAuthApi.reset()` (called from `signOut`); do not clear the flag at the start of every `submitPassword`
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
