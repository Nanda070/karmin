# Karmin — developer map

> **Один файл для разработчика.** Стек, авторизация, экраны, сборка, флаги. Глубокие разборы — в `docs/` (ссылки внизу). Не связан с ELTE / Neptun.

This is the **single** onboarding document. Other files under `docs/` are deep dives, not a second map.

---

## What / why

**Karmin** is an unofficial ELTE Neptun **mobile** client by **Cheterin Group** / **Nanda**.

| | |
|---|---|
| **Owner, Developer, Founder** | Nanda |
| Discord | `nandak070` |
| Telegram | `nanda070` |
| Mail | `turkapahf@gmail.com` |
| Company | Cheterin Group — [https://cheterin.online](https://cheterin.online) |
| Repo | [https://github.com/Nanda070/karmin](https://github.com/Nanda070/karmin) |

**Not affiliated with ELTE, Neptun, or SDA Informatika.** No official API partnership, no trademark permission, no endorsement. Independent client that signs in with the **student’s own** Neptun code and password. Prefer the official web client when university rules require it. MIT, AS IS.

**Goals (v1):**

- Fast, dark-first, minimal UI (Today, calendar, study, inbox).
- Local **PIN / biometrics** lock (vault), not a Neptun skip.
- No Cheterin backend (no BFF): academic data stays on the phone.
- English UI by default; Hungarian and Russian catalogs exist.

**Non-goals (v1):** own server, public stores, classmate lists, compose mail, scraping HTML of classic Neptun, storing TOTP secrets, university picker.

---

## Stack & why

| Piece | Why |
|---|---|
| **Flutter / Dart** | One codebase; iPhone is the primary test target; Android APK on Windows. |
| **Riverpod** (`flutter_riverpod`) | Session, theme, student snapshot, Dio client as providers. |
| **go_router** | Auth redirects + 4-tab `StatefulShellRoute`. |
| **dio** | HTTPS to ELTE; interceptors attach RAM JWT; map failures to typed exceptions. |
| **flutter_secure_storage** | Neptun code + password + PIN hash in OS Keystore / Keychain. |
| **local_auth** | Face ID / biometrics for the **local** vault (`biometricOnly`, no device-passcode fallback). |
| **shared_preferences** | Disclaimer, ThemeMode, JSON student cache (not secrets). |
| **google_fonts** | Fraunces (display) + Plus Jakarta Sans (UI). |
| **gen-l10n** | `lib/l10n/app_en.arb` source; HU / RU stubs. Default locale is **English**. |
| **crypto** | `sha256(pin \|\| salt)` for PIN. |

**No BFF in v1.** Passwords never leave the device toward Cheterin. JWT (or the MVC session placeholder after portal login) lives in **process RAM only**. Credentials live in Keystore / Keychain.

**Direct Neptun — fork-aligned JSON host:**

`NeptunClient.baseUrl` = `https://neptun.elte.hu/Account/api/`  
(same as [zoligamer/Neptun-Mobile-fork](https://github.com/zoligamer/Neptun-Mobile-fork) institute `https://neptun.elte.hu/Account` + `/api/…`).

The legacy public path `https://neptun.elte.hu/ujhallgato/api/` is a **stub** (GET 404 / empty 400). Karmin no longer uses it for student reads. That empty 400 is **not** “wrong password”.

**What actually logs in (aligned with Neptun-Mobile-fork):**

- Primary (ELTE live): `POST https://neptun.elte.hu/Account/api/Account/Authenticate` only — same URL for password and OTP. Body keys (fork order): `userName`, `password`, `captcha:""`, `captchaIdentifier:""`, `token` (`""` then bare 6 digits), `LCID`. First password POST is **LCID 1033 + Safari/XHR** (the combo that reached Verification before `0.1.0+5`). Fork `LCID:1038` + dart:io-like headers only after a retryable 400 — never 1038-first (`0.1.0+6` did that and ELTE answered HTTP 400). OTP reuses the LCID/headers that reached 2FA. Body is `jsonEncode`d (no Dio charset). See [zoligamer/Neptun-Mobile-fork](https://github.com/zoligamer/Neptun-Mobile-fork) `lib/API/api_coms.dart` `_tryModernLogin` / `submitTwoFactorCode`.
- Headers on Authenticate: first POST is Safari/XHR (Accept, Origin, Referer, `X-Requested-With`) + `Content-Type: application/json` (+ optional fork `Cookie: devicecookie-<base64(UPPER user)>=…`), always strip Bearer. Fork fallback keeps a dart:io User-Agent (never an empty UA). OTP reuses the header profile that worked.
- On `isTwoFactorRequired` → Verification with **Microsoft Authenticator**. Confirm re-POSTs Authenticate with `token=<bare 6 digits>`. **Never** compose email `732-` onto authenticator codes. **No email send on this path.**
- **No MVC fallback** on password/OTP for ELTE live (mixing channels left OTP without a JSON session). Optional mail only via **Send code again** (`EltePortalLogin` `GetEmail=true`).
- Email confirm (only with a prefix): `RequestEmailCode` + `EmailCode` + `CodePrefix`.

**Why fork JSON only:** Neptun-Mobile-fork never does Login2FA for modern institutes; its working 2FA is Authenticate + `token` + device cookie. Do not invent `RequestEmail` / `Provider=Email`.

`LiveNeptunAuth` POSTs Authenticate only via absolute `NeptunClient.authenticateUrl` (`dio.postUri`, 8s timeouts) so the student `baseUrl` (`…/Account/api/`) cannot double `/api/`. Captures fork `devicecookie` from Set-Cookie and resends on the next Authenticate. Password/OTP failures show `HTTP <status>` plus short Neptun text — never collapse HTML/maintenance into the opaque “sign on the website” string. Empty 400 on Authenticate is still not “wrong password”.

User-Agent (student JSON GETs): `Karmin/0.1.0 (Flutter; ELTE student client)`. Authenticate strips it. MVC form posts (email resend only) clear `X-Requested-With` and send Safari-like headers.

---

## Architecture

```
lib/
  app/          KarminApp, theme, ThemeMode, router, shared widgets
  auth/         session, disclaimer, login, OTP, PIN, unlock, Keystore
  api/          NeptunClient (dio), Live/Debug auth, EltePortalLogin, student API, DTOs
  data/         StudentRepository + SharedPreferences JSON cache
  features/     today/, calendar/, study/, inbox/, settings/
  l10n/         app_en.arb (source), app_hu.arb, app_ru.arb
```

`lib/main.dart` → `ProviderScope` → `KarminApp`.

```
Disclaimer → Login (password) → Verification (OTP)
    → Set PIN (first run) → Unlock (PIN / Face ID) → tab shell
```

Warm resume (process alive, token still in RAM): Unlock only.  
Cold start / 401: Unlock if needed, then password replay + interactive OTP. PIN never completes Neptun login.

### Session states (`NeptunAuthStep`)

| Step | Meaning |
|---|---|
| `needsPassword` | Show Login (or replay stored password after Unlock / 401). |
| `needsOtp` | Show `/verify`. User must type the one-time code. |
| `authenticated` | Token in RAM (`NeptunClient.hasJwt`). Tab shell allowed once PIN is set and unlocked. |

PIN / biometrics are a **local vault** (`unlocked`, `hasPin`). They are **not** Neptun 2FA.

`go_router` redirect (`lib/auth/auth_redirect.dart`) also gates: not hydrated → `/boot`; no disclaimer → `/disclaimer`; no credentials → `/login`; has PIN but locked → `/unlock`; OTP pending → `/verify`; authenticated without PIN → `/set-pin`.

### Auth implementation (read, don’t rewrite)

| Type | Role |
|---|---|
| `NeptunAuthApi` | `submitPassword` / `submitOtp` / `resendEmailCode` / `reset` |
| `DebugNeptunAuth` | Any non-empty code+password → `needsOtp`; 6–16 digit OTP → fake JWT `debug-jwt` |
| `LiveNeptunAuth` | Fork Authenticate only (password + OTP); device cookie; `_jsonTwoFactorPending` until JWT / `reset` |
| `EltePortalLogin` | Cookie jar + HTML form scrape + Login2FA (**email resend only** on live ELTE) |
| `AuthController` | Hydrate, login, OTP, resend, PIN, bio, 401, lifecycle lock; `signOut` → `reset()` |

**2FA every fresh Neptun session.** Stored password never finishes login alone.

**JSON pending flag:** set on HTTP 202 / `needsOtp` from fork Authenticate; **not** cleared at the start of `submitPassword` (so unlock / 401 re-login / failed re-auth still POSTs `token` with userName+password). Cleared on JWT or `reset()` / `clear()` (sign-out).

**Resend** = optional Login2FA `GetEmail=true` POST (or Login + GetEmail if the 2FA session died). Hidden when the channel is authenticator. 30s cooldown.

**Current channel: authenticator primary** (fork-aligned). Email is optional when `GetEmail` returns a prefix. Missing email must **not** hard-block login. Do not store authenticator secrets.

**OTP UI:** authenticator → 6 digits, no grey prefix, no “Send code again”. Email → grey **prefix** (`732-`) + tail; Confirm uses `EmailCode` / `CodePrefix` (or composed code on older forms). Failed OTP shows status e.g. `Neptun rejected this code (HTTP 400)`.

**401:** Dio interceptor on **non-**`Account/Authenticate` paths drops the RAM token, calls `onUnauthorized`, and **does not retry** the original request. Controller then replays password and shows OTP. Wait until OTP succeeds.

**Boot hydrate:** `AuthController.hydrateTimeout` defaults to **5 seconds**. Keystore reads and the Face ID probe are each bounded by the remaining budget; hang → fallbacks (`disclaimer=false`, no credentials, no PIN, bio unavailable) and `hydrated: true` so `/boot` cannot stick forever. Biometric **probe** itself times out at 2s; OS prompt at 25s.

PIN: 6 digits, `sha256(utf8(pin) \|\| 16-byte salt)` hex; salt base64 in Keystore. 5 failures → lock (first 30s, then 5 min).

Lifecycle: pause/hidden records a timestamp; resume always `lockLocally()` if a PIN exists.

### Dio (`NeptunClient`)

- Base URL: `https://neptun.elte.hu/Account/api/` (fork institute + `/api/`)
- Connect 15s, receive 30s (JSON Authenticate overrides to 8s).
- `validateStatus`: 2xx only on the default client; auth/MVC use `< 500` and parse bodies.
- **Do not** default `Content-Type: application/json`. Dio 5 GET `/Account/Login` with a null content-type header throws `ArgumentError`; login used to map that crash to “Can't reach Neptun.” JSON POSTs still get `application/json` from Map bodies. `applyEltePortalBrowserHeaders` strips Content-Type on portal GETs.
- **onRequest:** if **real** JWT (`hasRealJwt`), `Authorization: Bearer <token>`. Never send MVC placeholder `elte-portal-session` as Bearer.
- **onError:** HTTP 401 + real JWT + path does not contain `Account/Authenticate` → `clearSession()` + `onUnauthorized`. No retry interceptor.
- `getData` / `postData` require `hasRealJwt`; unwrap `{ data: … }` envelopes. Portal-only session → `NeptunPortalSessionException` (honest empty banner, no OTP storm).
- `lcid`: UI `hu` → 1038; otherwise 1033. Russian UI has **no** Neptun `lcid` — keep 1033. Live password Authenticate tries **1033 + rich headers first**, then fork 1038 only after a retryable 400.

Typed exceptions live in `lib/api/exceptions.dart`. `mapDioException` / `isDioTransportFailure`:

- **Can't reach Neptun** (`NeptunNetworkException`) = **no HTTP response** (timeout, DNS, TLS, connection reset). Never for an `ArgumentError` or any ELTE status.
- HTML / maintenance page → `NeptunMaintenanceException`.
- HTTP from ELTE → credentials (`NeptunAuthException`), captcha, OTP (`NeptunOtpException`), lockout, or **Neptun request failed** (`NeptunApiException`). Empty 400 on JSON Authenticate is still `NeptunUnavailableException` **with HTTP status**, not wrong password and not the opaque website string.

Do not log request bodies.

MVC success sets RAM token to `NeptunClient.portalSessionToken` (`elte-portal-session`) — cookie session, **not** a JSON JWT. Student GETs need a real Authenticate `accessToken`. Portal cookies stay inside `EltePortalLogin`.

---

## Screens & data

| Route | Screen |
|---|---|
| `/boot` | Logo while hydrate runs |
| `/disclaimer` | Unofficial / own-risk |
| `/login` | Neptun code + password; debug banner when `usingDebugAuth` |
| `/verify` | Email OTP (prefix + tail) |
| `/set-pin` | 6-digit PIN + optional bio |
| `/unlock` | PIN pad / Face ID |
| `/today` | Next class, exam chip, unread, GPA |
| `/calendar` | Week / list + filters |
| `/study`, `/study/:id` | Subjects, grades, credits, exam confirm |
| `/inbox`, `/inbox/:id` | Read-only list + thread; mark-read |
| `/settings` | ThemeMode, Face ID, change PIN, sign out. Language + notifications rows are **display-only** |

`KarminApp` hardcodes `locale: Locale('en')`. HU/RU ARBs exist; Settings language is not wired yet (`docs/I18N.md`).

**Demo vs live:** `debugAuthFlagProvider` → `useDebugAuth()`. Debug uses `DebugNeptunAuth` + `DebugNeptunStudentApi` (labeled fixtures: Analysis II, Registrar, etc.). Live uses `LiveNeptunAuth` + `LiveNeptunStudentApi`.

**Cache:** `StudentRepository`, SharedPreferences key `karmin.cache.student.v1`, **5 minute** stale-while-revalidate. Wipe on sign-out. Calendar window is current week Monday → +14 days. If extras (subjects/messages/exams/profile) fail, last cached extras are kept; a hard calendar/dashboard failure falls back to the whole snapshot. Airplane mode can show last saved data + `KarminStatusBanner`.

Student JSON paths (best-effort Óbuda/`neptun-api` names — **unproven** on live ELTE; do not invent others):

| Method | Path |
|---|---|
| Calendar | `GET Calendar/GetCalendarEvents` |
| GPA | `GET Dashboard/GetAverages` |
| Credits | `GET dashboard/creditprogress` |
| Unread | `GET Message/GetUnreadedMessagesCount` |
| Subjects | `GET TakenSubjects/Terms` then `GET TakenSubjects` |
| Grades merge | `GET SubjectCourse/GetSubjectResultsList` (optional) |
| Exams | `GET ExamOverview/GetDashboardExamEntriesInActualTerm` (fallback `GetDashboardExamEntries`) |
| Subject exams | `GET ExamRegistration/GetExamsList` |
| Signup | `POST ExamRegistration/SignUpForExam` `{ examId }` **unproven** |
| Inbox | `GET Message/GetReceivedMessages` |
| Thread | `GET Messages/{id}/Posts` |
| Mark-read | `POST Messages/{id}/Posts/Processed` `{ postIds }` |
| Profile | `GET UserInfo`, `GET MyTrainings` |

### Student JSON after Authenticator login

Fork calendar / messages / subjects all call `{institute}/api/…` with `Authorization: Bearer <accessToken>` where institute is `https://neptun.elte.hu/Account`. Karmin uses the same base. After a successful JSON Authenticate (real JWT), Today / Calendar / Study / Inbox refresh against that host.

**MVC-only login** still cannot drive student JSON (cookie jar ≠ Bearer JWT). Banner: portal-session copy, not vague “Can't refresh.” Debug/mock remains the labeled offline fixture path.

Refresh soft-fails optional dashboard chips (`GetAverages`, credits, unread) so a missing optional path does not wipe a good calendar week.

---

## UI system (so you don’t hardcode)

Widgets must read **`KarminPalette.of(context)`**, not raw `KarminColors`, so Light restyles chrome.

| | Dark (default) | Light |
|---|---|---|
| Page | ink `#07080C` | paper `#F4EFE6` (cream, not Material white) |
| Surface | `#10141C` | `#FFFCF8` |
| Accent | carmine `#9B1B30` / bright `#DB4257` | same carmine |
| Hairline / muted | `#2A3A5C` / `#8B93A7` | `#D4CBBE` / `#6B645A` |

`ThemeModeController` default is **`ThemeMode.dark`**. Settings cycles Dark → Light → System (`karmin.theme.mode` in prefs). `KarminApp` sets `theme: KarminTheme.light()`, `darkTheme: KarminTheme.dark()`, `themeAnimationDuration: Duration.zero`.

**KarminIcons** (`lib/app/widgets/karmin_icons.dart`): Material *rounded* aliases (`home_rounded`, `calendar_month_rounded`, `school_rounded`, `inbox_rounded`, …) — no custom icon font.

Shared chrome: `KarminScaffold`, `KarminBottomNav`, `KarminCard`, `KarminPrimaryButton`, `KarminStatusBanner` / empty states, 8pt spacing, radii 8/12/16, 48pt tap targets. Auth routes wrap `SecureAuthScaffold` (FLAG_SECURE while visible).

---

## Security

- **No JWT on disk.** RAM only; sign-out and 401 clear it.
- **No password / OTP / `Authorization` in logs.**
- Credentials: `karmin.neptun.code`, `karmin.neptun.password` in Keystore/Keychain.
- PIN: hash + salt only (`karmin.pin.hash`, `karmin.pin.salt`).
- Bio preference: `karmin.lock.bio_enabled`.
- Android: `android:allowBackup="false"`; encrypted SharedPreferences for secure storage.
- iOS: Keychain `first_unlock_this_device`, `synchronizable: false`. ATS on (no `NSAllowsArbitraryLoads`). Face ID usage string in Info.plist.
- **FLAG_SECURE** via MethodChannel `karmin/secure_flag` on Login / Verification / PIN / Unlock (no-op on web).
- Free Apple ID sideload: **7-day** cert, **3-app** limit — Apple’s limit, not a Karmin bug.
- Bundle / application id: **`online.cheterin.karmin`**. Display name Kármin (home screen).

Report vulns privately (`turkapahf@gmail.com`). Do not file public issues with secrets.

---

## Build / test

Need Flutter on PATH (this machine: `C:\Users\adnan\sdk\flutter`). SDK constraint `^3.13.2`; Actions uses Flutter **3.47.2**.

```bash
flutter pub get
flutter analyze
flutter test
```

**Windows — Android APK** (no Android phone in this project): see [docs/ANDROID_BUILD.md](docs/ANDROID_BUILD.md).

```powershell
flutter build apk --debug
# build\app\outputs\flutter-apk\app-debug.apk
```

**Windows — Chrome:** UI preview only. Default debug = labeled mock (`kDebugMode`). Chrome CORS blocks live Neptun even with `KARMIN_LIVE_AUTH`.

**iOS cannot compile on Windows.** Paths:

1. GitHub Actions [`.github/workflows/ios.yml`](.github/workflows/ios.yml) (`workflow_dispatch`) → artifact `karmin-ios-unsigned` → `Karmin-unsigned.ipa` (release + `KARMIN_LIVE_AUTH=true`). Install with **Sideloadly** on Windows.
2. Borrowed Mac: Xcode **Personal Team**, bundle `online.cheterin.karmin`.

Details: [docs/IOS_SIDELLOAD.md](docs/IOS_SIDELLOAD.md). Local copy of the IPA may exist at `dist/Karmin-unsigned.ipa` (unsigned; do not commit secrets).

Primary test target: **physical iPhone**. Manual checklist: [docs/SMOKE.md](docs/SMOKE.md).

Tests (under `test/`): auth session + hydrate timeout, redirects, OTP compose/resend, client interceptors, calendar/stage-3 parse, repository cache, theme tokens, smoke. Fixtures are anonymous.

---

## Env / flags

Compile-time `bool.fromEnvironment` in `useDebugAuth()` (`lib/api/neptun_auth.dart`):

| Define | Effect |
|---|---|
| **`KARMIN_LIVE_AUTH=true`** | Force **live** ELTE client (skips debug even in `kDebugMode`). |
| `KARMIN_DEBUG_AUTH=true` | Force debug mock (only if live is not set). |
| *(neither)* | **`kDebugMode` → mock**; **release → live**. |

```powershell
flutter run --dart-define=KARMIN_LIVE_AUTH=true
```

**Debug mock:** Login shows `loginDebugBanner`. Any non-empty Neptun code + password → Verification; any 6–16 **digit** OTP → `debug-jwt` in RAM + demo student snapshot. Resend = password step again.

**Release IPA from Actions is always live.** Do not claim live 2FA, JSON field names, or exam signup are proven without a real account on a **device**.

---

## Links (this file is the map)

| | |
|---|---|
| Repo | https://github.com/Nanda070/karmin |
| Figma | https://www.figma.com/design/Iuxf0sbisHaOwxn6Vkcgdg |
| Site | https://cheterin.online |

Deep dives (do not duplicate into extra root docs):

| Doc | When to open it |
|---|---|
| [docs/PLAN.md](docs/PLAN.md) | Product stages, non-goals, threat-model checklist |
| [docs/API.md](docs/API.md) | Endpoint table, debug vs live, unproven JSON keys |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers, cache, theme contract |
| [docs/SECURITY.md](docs/SECURITY.md) | Keystore keys, 401, FLAG_SECURE |
| [docs/IOS_SIDELLOAD.md](docs/IOS_SIDELLOAD.md) | Actions IPA, Sideloadly, 7-day cert, Mac Personal Team |
| [docs/ANDROID_BUILD.md](docs/ANDROID_BUILD.md) | Windows APK / optional emulator |
| [docs/I18N.md](docs/I18N.md) | ARB + `lcid` |
| [docs/DISCLAIMER.md](docs/DISCLAIMER.md) / [PRIVACY.md](docs/PRIVACY.md) | Legal copy |
| [README.md](README.md) | Public-facing bilingual intro |

© 2026 Nanda / Cheterin Group
