# Karmin — full implementation plan

**Product:** unofficial mobile client for ELTE Neptun  
**Owner:** [Cheterin](https://cheterin.online) / cheterin.online  
**Brand:** Karmin  
**Repo:** `C:\Users\adnan\Documents\Coding\karmin`  
**Figma:** https://www.figma.com/design/Iuxf0sbisHaOwxn6Vkcgdg  
**Default UI language:** English (Hungarian and Russian in-app; EN is source)  
**This document is not legal advice.** Legal sections are a working checklist for counsel or ELTE/IT, not a clearance to ship.

Last updated: 2026-09-08

---

## Status (current reality)

| Item | Status |
|---|---|
| **Stage 0 — Foundation** | **Done** |
| **Stage 1 — Auth** | **Done in code** — live `Authenticate` + debug mock; not claimed proven on a real ELTE account |
| **Stage 2 — Cached reads** | **Done in code** — calendar/dashboard/unread + OTP resend-via-relogin. Isar deferred (JSON cache). Local notifications still deferred. Live ELTE JSON unproven. |
| **Stage 3 — Study + Inbox** | **Done in code** — subjects/grades/GPA/credits, inbox list + thread + mark-read, Settings from `UserInfo`, exam signup confirm + `SignUpForExam`. Live payloads best-effort / unproven. |
| **Stage 4 — Harden** | **In progress in code** — shared empty/error/cached banners, a11y labels, full light theme pass. Figma light frames pending (file is View-only). Android Gradle / notifications / TestFlight APK not in this slice. |
| **UI visual system** | **Done** — Figma + Flutter widgets are the source of truth (not a future polish pass). Light tokens now applied in Flutter. |
| Web platform (`web/`) | Added alongside iOS/Android (dev/preview; v1 ship target remains mobile) |
| Platforms | **iOS testing is primary** (physical iPhone). Bundle ID `online.cheterin.karmin`. Full `ios/` Xcode tree + unsigned IPA workflow. **Android is emulator/CI on Windows** (Gradle tree is a separate track). Web is UI preview only. |
| Live Neptun auth | Implemented (`LiveNeptunAuth`) + labeled debug/mock. CORS blocks live from Chrome/web. Do not claim ELTE 2FA works until proven on a **device** with a real account. |
| Light theme | **Shipped in Flutter** — Settings System / Dark / Light restyles all 7 screens + shell via `KarminPalette`. Cream paper `#F4EFE6`, not Material white. Figma light frames still pending. |
| **Next** | Prove Stage 1–3 on a real iPhone (`KARMIN_LIVE_AUTH` / release IPA). Free install: [IOS_SIDELLOAD.md](IOS_SIDELLOAD.md). Android Gradle remains emulator/CI on Windows. |

Stage 0 exit criteria met: English Today matching the locked dark visual contract, gear → Settings, l10n EN/HU/RU, `NeptunClient` skeleton, secure storage + PIN helpers, doc stubs, MIT license under Cheterin. Luxury UI redesign shipped in Figma (7 screens + Components) and Flutter (`flutter analyze` clean; tests pass).

**Locked (2026-09-08):** every fresh Neptun authentication requires an interactive one-time code (email **or** authenticator). Stored password never completes login alone. Dark remains default; light is a complementary Karmin cream theme (Stage 4 Flutter pass shipped; Figma light frames pending).

---

## 1. Product definition

Karmin is a Flutter app by **Cheterin** for ELTE students. It signs into the official Neptun student API (`https://neptun.elte.hu/ujhallgato/api/`) with the student’s own Neptun code and password, then shows Today, calendar, grades, exams, and inbox in a dark, minimal UI.

It is **not** an ELTE product, **not** a SDA Informatika product, and **not** a replacement for the legal relationship between the student and the university. Cheterin has **no** trademark permission or endorsement from ELTE, Neptun, or SDA.

### 1.1 Goals

- One first login (password **and** 2FA), then Face ID / 6-digit PIN as a **local** lock.
- Every new Neptun JWT requires a fresh OTP. PIN/biometrics never skip Neptun 2FA.
- Today and calendar feel instant (local cache, then refresh).
- Exam signup with an explicit double confirm.
- UI follows the locked Figma + Flutter visual system (Karmin, English). Dark is default; light is planned.

### 1.2 Non-goals (v1 and “never” unless the product contract changes)

| Out | Why |
|---|---|
| Own backend / BFF | Extra attack surface; passwords would leave the phone |
| Python / Playwright in the app | Survey autofill is banned; Playwright cannot run on-device |
| Thesis, Erasmus, dorm, student-card claims | Out of product |
| MeetStreet, finances, compose mail | Out of v1 |
| Request-form wizard | v1.1 at earliest |
| Public Play Store / App Store | Policy and ToS risk |
| Home-screen widgets, Watch | Explicitly cut for v1 |
| Classmate lists, avatars of others | PII of third parties; skip endpoints |
| Scraping HTML of the old Neptun | We only use the documented-in-neptun-api JSON API |

Web is UI preview only. **iOS on a physical iPhone is the primary test target** (free Apple ID / Personal Team or GitHub Actions IPA — [IOS_SIDELLOAD.md](IOS_SIDELLOAD.md)). Android on Windows is emulator/CI. TestFlight requires a paid Apple program and is optional later, not the v1 path.

### 1.3 Success criteria for v1

- Real ELTE account: login → **2FA** → PIN → Today. After kill/reopen: Unlock (PIN/bio) → **2FA again** → Today from cache (JWT was RAM-only).
- Warm resume (process alive, JWT still in RAM): Unlock only, never a silent Neptun re-auth.
- Backgrounding the app always shows Unlock, never Today.
- Exam signup either succeeds with Neptun’s message or fails with Neptun’s error text.
- `grep` of log output after a session finds no password, no OTP, no JWT.
- Distribute via free iOS sideload for testers (Personal Team / Sideloadly). Android sideload when that tree is ready. TestFlight only if a paid Apple program is added later. No public stores.

---

## 2. Actors and systems

| Actor | Role |
|---|---|
| Student (user) | Owns the Neptun account. Data controller for data on their device. |
| Karmin app | Runs on the phone. Processes data **only** to show it to that student. |
| ELTE Neptun | Source of truth. JWT issuer. Academic and personal data host. |
| OS (iOS/Android) | Keystore/Keychain, biometrics, local notifications |
| Cheterin | Builds and maintains the client. Does **not** receive passwords in v1 (no server). |
| neptun-api (Python) | Reference of URL paths. Not shipped. Not called at runtime. |

---

## 3. Architecture

```
[Disclaimer]
        │
        ▼
[Login]  Neptun code + password
        │  HTTP 202 + isTwoFactorRequired
        ▼
[2FA / Verification]  email code or authenticator — always interactive
        │  JWT → RAM only
        ▼
[Set PIN]  first run only
        │
        ▼
[Unlock]  Face ID or PIN = local vault, not Neptun 2FA
        │  if no JWT: stored password + 2FA again
        ▼
[Flutter UI  Riverpod  go_router]
        │
        ▼
[Repositories] ── Isar (calendar, grades, inbox, dashboard)
        │
        ▼
[NeptunClient dio]
        │  HTTPS, cert verification ON
        │  Authorization: Bearer <jwt in RAM>
        │  401 → stored password + interactive OTP (never silent)
        ▼
https://neptun.elte.hu/ujhallgato/api/
```

### 3.1 Rules

- One process, one Neptun session.
- Base URL hardcoded to ELTE. No university picker in v1.
- `lcid`: 1033 when UI is English, 1038 when Hungarian. Russian UI does **not** send a RU `lcid` (Neptun has no RU); keep 1033 or 1038.
- Timeouts: 15s connect, 30s read. No infinite retries.
- User-Agent: `Karmin/0.1.0 (Flutter; ELTE student client)` — identifiable, not a fake Chrome. If ELTE blocks unknown UAs, fall back to a documented web-like UA and record it in SECURITY.md.

### 3.2 Suggested `lib/` layout

```
lib/
  app/          bootstrap, theme, router, app.dart, widgets/
  auth/         login, unlock, set_pin, session, lifecycle
  api/          neptun_client.dart, dtos/, exceptions.dart
  data/         isar collections, repositories
  features/
    today/
    calendar/
    study/
    inbox/
    settings/
  l10n/         app_en.arb (source), app_hu.arb, app_ru.arb
  notifications/ scheduling from cached events
```

### 3.3 Stack (locked)

| Need | Package | Notes |
|---|---|---|
| HTTP | `dio` | Interceptor: attach JWT; on 401 drop JWT and prompt OTP — **do not retry** until OTP succeeds |
| State | `flutter_riverpod` | No GetX |
| Routing | `go_router` | Redirect: no session → login; locked → unlock |
| Secrets | `flutter_secure_storage` | iOS Keychain, Android Keystore |
| Biometrics | `local_auth` | biometricOnly first, then PIN UI we own |
| Cache | JSON via SharedPreferences (Stage 2) | Isar planned; codegen blocked / Android tree incomplete — Hive/Isar later |
| i18n | `flutter_localizations` + `intl` + gen-l10n | EN is `template-arb-file` |
| Fonts | `google_fonts` | **Fraunces** (titles) + **Plus Jakarta Sans** (body). Locked. |
| Notifications | `flutter_local_notifications` + `timezone` | Stage 2+ |
| Secure flag | `flutter_windowmanager` or platform channel | FLAG_SECURE on Login + Unlock |
| Icons | `KarminIcons` (Material rounded/outlined) | `lucide_icons` is **not** used — it breaks on this SDK |

Do not add Firebase, Sentry-with-PII, analytics SDKs, or crash reporters that upload request bodies in v1.

---

## 4. Authentication (detail)

**Locked decision:** ELTE Neptun requires a one-time code on **every** fresh authentication — from email **or** an authenticator app. This is not optional, not rare, and not an error stub. Stored `code + password` can complete the password step only. The OTP step is always interactive. We do **not** store a TOTP secret to auto-generate codes (that would skip the user’s 2FA). PIN and biometrics are a **local app lock** for an already-established JWT in RAM.

Session API states (Stage 2 plugs live payloads into the same enum):

| `NeptunAuthStep` | Meaning |
|---|---|
| `needsPassword` | No accepted password step yet (or 401 cleared the JWT) |
| `needsOtp` | Password accepted; waiting for email/authenticator code |
| `authenticated` | JWT in RAM |

### 4.1 First session

1. **Disclaimer** (once). Then Login: Neptun code + password. No “remember password” checkbox — storage is mandatory for later unlock, explained in the disclaimer.
2. `POST Account/Authenticate` `{ userName, password, lcid }`.
3. ELTE answers **HTTP 202** + `isTwoFactorRequired: true` (no `accessToken`). Show **Verification** (2FA). Do not persist credentials yet.
4. User enters the one-time code. Re-POST the same body plus `token: "<otp>"` (same field the official web client uses).
5. Success: `accessToken`, `neptunCode`. JWT → RAM. Credentials → Keystore (`neptun_code`, `neptun_password`).
6. Navigate to **Set PIN** (6 digits, enter twice). Enable Face ID / fingerprint (default on if hardware exists).
7. Land on Today.

### 4.2 Returning session

1. Cold start: if Keystore has credentials and PIN is set → **Unlock**, never Login. JWT is gone (was RAM-only).
2. Biometric prompt immediately. Failure / cancel → PIN pad.
3. On local unlock: if JWT still in RAM (warm process) → Today. **Else** submit stored password **without** showing Login, then **2FA again** (Verification). Password is never enough.
4. Wrong PIN: lockout after 5 tries for 30s, then 5 min (document in UI). Do **not** wipe Keystore on PIN fail (that would brick the user after typos). Offer “Sign out” on Unlock.

### 4.3 Token

- Neptun JWT is session-scoped. Treat as expired on 401.
- Do not persist JWT. Process death ⇒ Unlock (if PIN set) then password-from-Keystore + **interactive OTP**. Never a fully silent re-login.
- Refresh endpoint: use `refresh_token` **only if** ELTE actually returns and accepts it *and* that refresh does not require a new OTP. Until proven on live ELTE, 401 → password step + 2FA.
- 401 interceptor: drop JWT, notify session, do **not** retry the original request until OTP succeeds.

### 4.4 Errors (typed)

| Condition | UX |
|---|---|
| Bad password | “Neptun rejected these credentials.” |
| Network | “Can’t reach Neptun.” Cache still used after unlock if already logged in before. |
| HTTP 202 + captcha | “Neptun wants a captcha. Sign in once on the website, then retry.” Button: open `https://neptun.elte.hu/` |
| HTTP 202 + 2FA | **Happy path**, not an error: Verification screen. Channel hint: email / authenticator / unknown. **Resend = re-POST `Account/Authenticate` with stored code+password** (no OTP `token`). Neptun’s email OTP often never arrives; a fresh login issues a new challenge / mail. There is no verified dedicated “resend OTP” endpoint. Show the control on Verification even when the channel is unknown (authenticator users can ignore it). Cooldown 30s. |
| Bad OTP | “Neptun rejected this code.” Stay on Verification. |
| HTTP 403 on a feature | Hide the tile. Do not crash. |

### 4.5 Keystore keys (names)

```
karmin.neptun.code
karmin.neptun.password
karmin.pin.hash          # never store PIN plaintext; use salted hash (see §5)
karmin.lock.bio_enabled
```

PIN: 6 digits, `sha256(pin + app-specific salt from Keystore random 16 bytes)`. Compare in constant time.

---

## 5. Security

### 5.1 Threat model (STRIDE-lite)

| Threat | Mitigation |
|---|---|
| Stolen phone, unlocked | OS lock is the user’s problem. We still lock Karmin on background. |
| Stolen phone, Karmin unlocked | Background lock + FLAG_SECURE. Short idle. |
| Stolen phone, attacker has PIN | They open the local vault. A new Neptun JWT still needs the user’s 2FA code (unless a JWT is already in RAM). Disclose both in Privacy/Disclaimer. |
| Backup / ADB backup of app data | Android: `android:allowBackup="false"`. iOS: Keychain `first_unlock_this_device`. |
| MITM | Default TLS verify. No `badCertificateCallback`. No user-installed bypass in release. |
| Logcat / Xcode console | Logger redacts `Authorization`, `password`, `token`. Debug builds may log URLs without query secrets. |
| Clipboard malware | Never copy password. PIN fields `obscureText`. |
| Reverse engineering the APK | Assume yes. Secrets are the user’s, not an API key we embed. |
| Malicious Neptun HTML in forms (v1.1) | WebView with JS limited; no intercept of passwords. |
| Prompt injection via inbox (if AI later) | AI is out of product. Inbox is render-only, sanitize HTML if Neptun sends HTML. |

### 5.2 Explicit non-mitigations (accepted)

- No certificate pinning in v1 (ELTE/CDN cert rotation). Revisit if MITM reports appear.
- No root/jailbreak detection in v1.
- No remote kill-switch (no server).

### 5.3 Rate and courtesy

- Do not poll Neptun more than: dashboard 5 min, calendar on open + pull-to-refresh, inbox 2 min while Inbox is visible.
- Exponential backoff on 429/5xx.
- Never parallel-stampede 20 endpoints on Today; **one** composed request sequence (3–5 calls), then cache.

### 5.4 Exam write safety

- Payload must be captured from a live web session (Charles/mitmproxy **on a device you own**, for your account) before enabling the button.
- UI: sheet “Sign up for {exam} on {date}?” → type or hold confirm (double).
- After POST: refresh list; show `notification` / model errors from JSON.

---

## 6. Data map (GDPR / Hungarian InfoAct)

Karmin in v1 has **no servers**. Processing is on-device. If you only use it yourself, you are processing your own student data. **If you give the app to other students**, you still need a privacy notice because the app processes their Neptun data locally. Cheterin is not (in v1) a cloud controller, but **designs** the processing.

### 6.1 Categories we will store locally

| Data | Source | Store | Purpose | Retention |
|---|---|---|---|---|
| Neptun code, password | User | Keystore | Re-auth | Until Sign out |
| PIN hash + salt | User | Keystore | Local app lock (not Neptun 2FA) | Until Sign out |
| TOTP secret / email OTP | — | **Never stored** | User types a fresh code every auth | — |
| JWT | Neptun | RAM only | API calls | Process lifetime |
| Calendar events | API | Isar | Today, calendar, notifications | Overwritten on refresh; wipe on Sign out |
| Grades, subjects, GPA | API | Isar | Study | Same |
| Inbox metadata + body | API | Isar | Inbox | Same |
| Language, bio flag, notif prefs, theme mode | User | SharedPreferences (non-secret) | Settings | Until Sign out or reinstall |
| Notification pending IDs | Local | Plugin storage | Alarms | Recreated from cache |

### 6.2 Data we will **not** collect or persist

- Analytics, advertising IDs
- Other students’ photos or full student lists (`get_subject_course_students` — **do not call**)
- Location (even for “navigate to building” in v1: show room text only)
- Password, OTP, or JWT in Isar, logs, or screenshots
- Authenticator TOTP secret (v1: user types the code every time)

### 6.3 Lawful basis (working assumption, not advice)

- **Own use:** processing necessary for the student to access a service they already use.
- **Distribution to classmates:** still no sale of data. Legal basis typically the student’s use of the app to access **their** Neptun account (contract/legitimate interest of the user). Do **not** claim ELTE appointed Cheterin as processor.
- Do not upload Neptun data to ChatGPT, Crashlytics, or iCloud Keychain sync unless the user opts in (v1: **disable iCloud Keychain sync** for the password item if the plugin allows `synchronizable: false`).

### 6.4 Rights

Because data never leaves the phone in v1:

- Access / portability: user already sees it; Sign out + OS uninstall deletes it.
- Erasure: Sign out + uninstall.
- No marketing, no profiling.

Document this in `docs/PRIVACY.md` and a first-run screen.

### 6.5 Cross-border

Neptun is hosted for a Hungarian university. The phone may be physically abroad; that is the user’s device. We do not add extra transfers.

---

## 7. Legal and policy (checklist)

**Not legal advice. Hungarian/EU counsel or ELTE DPO should review before any wide distribution.**

### 7.1 Affiliation

In-app, README, Privacy, TestFlight notes:

> Karmin is an unofficial product by Cheterin. It is not affiliated with, endorsed by, or supported by Eötvös Loránd University or the operator of Neptun.

Do not use ELTE coat of arms or Neptun wordmark as the **app icon**. “Neptun” may appear in text as the name of the system we connect to (nominative / referential use). Do not title the store listing “Official ELTE Neptun”. Do **not** invent or claim trademark permission from ELTE.

### 7.2 Neptun / SDA / ELTE acceptable use

Typical university and vendor terms prohibit:

- Sharing passwords
- Automated access / “unauthorized clients”
- Overloading the service

Karmin **does** automate API calls the official Angular web already makes. Residual risk: ELTE or SDA may disable the account or IP, or demand the app stop. **Mitigation:** low request rate, identifiable UA, sideload-only, stop-if-asked contact via [cheterin.online](https://cheterin.online).

**Action before any group beta:** read current ELTE IT / Neptun student terms (Neptun login page, ELTE SZMSZ / IT regulations). Record the date and URL in `docs/legal/SOURCES.md`. If terms forbid third-party clients, do not run a public beta.

### 7.3 Reverse engineering

`neptun-api` was built by observing the official web client. Karmin reuses those paths. In many EU contexts, interoperability with a system you are entitled to use is argued under software exceptions — **this is contested** for ToS. Do not publish exploit details. Do not bypass captcha, paywalls, or closed registration windows.

### 7.4 Computer crime

Using **your own** (or the user’s own) credentials against the official HTTPS API is not “hacking” in the usual sense. Using **someone else’s** credentials, brute force, or captcha farms **is**. The app must never offer credential stuffing, shared “family” logins, or stored third-party passwords.

### 7.5 App Store / Play (why v1 stays off-store)

- Google: impersonation, scraping, “unauthorized access to another service”.
- Apple: 5.1 privacy, 5.2 IP, apps that log into third-party services without the provider’s blessing.

v1: **TestFlight internal + sideload**. Revisit stores only with written permission or a clearly personal “me-only” listing (still risky).

### 7.6 Consumer / student distribution in HU

If you install APKs on others’ phones: inform them it is unofficial, data stays on device, they use it at their own risk, and they can use the official web instead. No paid version in v1 (avoids extra consumer-contract duties). If you ever charge, stop and get advice.

### 7.7 Open source

- LICENSE: MIT, copyright **Cheterin** / cheterin.online (2026).
- Third-party notices: `docs/legal/NOTICE.md`; Flutter/Dart licenses also via in-app `showLicensePage`.
- Do **not** publish live API dumps with personal grades.

### 7.8 Academic integrity

No auto-submit of petitions with fake justifications. No silent exam signup without confirm. No survey autofill.

### 7.9 Export / cryptography

PIN hashing and TLS are standard. No custom crypto export issue beyond normal app stores (which we are not using).

### 7.10 Accessibility (EU EAA from 2025 — keep in mind)

v1 should not block TalkBack/VoiceOver: labels on tabs, PIN keypad, Sign in. Contrast: carmine on ink must pass WCAG AA for **text** (test Sign in and Sign out). If carmine fails, darken or enlarge.

### 7.11 First-run legal UX (required before Auth hits the network)

Screen **Disclaimer** (blocking, once):

1. Unofficial; not ELTE; by Cheterin.
2. Password stored in OS Keystore to enable PIN.
3. We do not operate a server; Neptun’s privacy policy still applies to data Neptun holds.
4. Link to in-app Privacy + to official Neptun.
5. “I understand” required.

Settings always keep the same links.

---

## 8. UX and visual (locked)

Figma https://www.figma.com/design/Iuxf0sbisHaOwxn6Vkcgdg plus the Flutter widgets under `lib/app/` are the **source of truth**. The luxury dark redesign is **done**. Later stages bind real Neptun data; they do not reopen palette, type, or chrome.

Brand string: **Karmin** (ASCII, no accent). Owner: Cheterin / cheterin.online.

### 8.1 Design language

| Token | Value |
|---|---|
| Ink | `#07080C` |
| Surface | `#10141C` |
| Navy (fields, chips) | `#152036` |
| Hairline | `#2A3A5C` |
| Steel | `#4A6A8A` |
| Muted | `#8B93A7` |
| Text | `#E8EAED` |
| Carmine | `#9B1B30` |
| Carmine bright | `#DB4257` |
| Titles | Fraunces via `google_fonts` |
| Body / UI | Plus Jakarta Sans via `google_fonts` |
| Radius | 8 / 12 / 16 / pill 18 |
| Spacing | 8pt scale; page inset 20 |

Atmosphere: ink → navy page gradient. Cards (`KarminCard`): hairline borders, quiet surface gradients, optional carmine/steel accent bar. Primary CTA (`KarminPrimaryButton`): carmine gradient.

**Theme (locked):** Dark is default and first-class. Light is complementary Karmin cream (not generic Material white). Settings System / Dark / Light restyles chrome via `KarminPalette` (`lib/app/theme.dart`). Figma still has dark frames only — light frames pending.

| Light token | Value |
|---|---|
| Paper / cream page | `#F4EFE6` |
| Surface | `#FFFCF8` |
| Field wash | `#EDE6DA` |
| Ink text | `#141820` |
| Hairline | `#D4CBBE` |
| Muted | `#6B645A` |
| Carmine / bright | `#9B1B30` / `#DB4257` (same accent) |

**Bottom nav** (`KarminBottomNav`): icon + label, carmine active pill, muted inactive, outline-style icons. Language from community file `QYkMt6nybGd2y1gl9WUK1X` / node `96:1987`.

**Auth chrome (Figma):** centered K mark, icon-led inputs (user / lock / eye), gradient Sign in, quiet microcopy. Language from `sCVzmZRqSouvVDRTO8vIDb` / node `2:2`. Flutter Login / PIN / Disclaimer / **2FA Verification** screens ship in Stage 1. Verification is not yet a Figma frame — it follows the same contract (badge, icon-led code field, channel hint, gradient confirm, **Send code again** = re-login).

**Schedule / event cards:** date chips, accent bars, time / location / person metadata with icons. Language from `BZfoM4pLXPnCYW3Gjkk0gV` / node `4:0`.

**Icons:** `KarminIcons` — Material rounded/outlined. Do not add `lucide_icons` (SDK incompatibility). Do not put rainbow icons on tabs.

### 8.2 Visual contract (Figma)

| Screen | Contents |
|---|---|
| 01 Login | K mark, user/lock/eye fields, gradient Sign in |
| 02 PIN | Lock badge, filled dots, polished keypad |
| 02b Verification (2FA) | Shield/mail badge, icon-led OTP field, email vs authenticator hint, gradient Confirm, resend-if-email. **Auth contract, Figma frame TBD** |
| 03 Today | Hero + chips + quick actions + schedule + icon nav |
| 04 Calendar | Week/list, date chips, class/exam cards with pin/user icons |
| 05 Study | GPA/credits, subject rows, Sign up CTA |
| 06 Inbox | Avatars, unread badges, timestamps |
| 07 Settings | Profile card, leading icons per row, theme control, Sign out |
| Components | Shared icon set |

Flutter **Today / Calendar / Study / Inbox / Settings** follow that contract. Today/Calendar bind Stage 2 reads; Study/Inbox/Settings profile bind Stage 3 reads (debug fixtures on web). Login, PIN, Disclaimer, and Verification shipped in Stage 1.

### 8.3 App structure

- Bottom tabs: Today | Calendar | Study | Inbox
- Settings: gear on Today (and profile card)
- Shared widgets: `KarminScaffold`, `KarminCard`, `KarminPrimaryButton`, `KarminBottomNav`, `KarminIcons`, chips, segmented control, list rows
- i18n: EN default; HU/RU files exist; Settings language overrides OS

Do not invent extra tabs. Do not add a floating compose button.

### 8.4 Remaining UI (not a redesign)

- **Stage 1:** implement Login, Disclaimer, Verification (2FA), Set PIN, Unlock against Figma 01/02 + the 02b contract (behavior + FLAG_SECURE). ThemeMode preference can be stored and exposed in Settings.
- **Stage 4:** empty / error / offline banners (`KarminStatusBanner`, `KarminEmptyState`); TalkBack/VoiceOver labels and carmine contrast (§7.10); **full light theme pass in Flutter** (all 7 screens + shell). **Figma light frames still pending** (KARMIN file is View-only from this agent). Android Gradle + local notifications + TestFlight APK are **not** in this polish slice.
- Web stays a preview scaffold; v1 ship target is mobile.
- No Lucide migration, no extra motion system (nav already animates the active pill).

---

## 9. Features by screen (v1)

Visual chrome for tabs + Settings is built (§8). Login / Unlock / Verification Flutter screens are Stage 1. Copy below is product behavior, not a new layout brief.

### 9.1 Login

Neptun code, password, Sign in, Keystore one-liner. Disclaimer already accepted. Match Figma 01. Success goes to Verification, not Today.

### 9.1b Verification (2FA)

Always shown after a successful password step when there is no JWT. Icon-led one-time code, hint for email vs authenticator vs unknown, gradient Confirm. **Send code again** re-submits stored Neptun code+password (in-memory login attempt or Keystore) so Neptun issues a new email OTP — it does not call a separate resend endpoint. Visible for every channel (the bug is email; TOTP users can ignore it). 30s cooldown; stay on Verification after HTTP 202 / `needsOtp`; clear the OTP field and snackbar. Not a Figma frame yet — same chrome as 01/02.

### 9.2 Unlock

Karmin wordmark, 6 PIN dots, keypad, Face ID. Sign out link. Match Figma 02. This opens the local vault only. If JWT is missing, Unlock is followed by Verification.

### 9.3 Today

Next class, exam chip, unread, GPA. Avatar + gear.

### 9.4 Calendar

Week | List. Day strip. Filters: Class, Exam, Task, Online. Event rows.

### 9.5 Study

GPA, credits, subjects, upcoming exam + Sign up.

### 9.6 Subject (push)

From event or subject row. Code, credits, grade, exams. No separate tab.

### 9.7 Inbox

List + thread. Read-only. Unread dots.

### 9.8 Settings

Profile (name, code, training if API gives it), Language, **Theme (System / Dark / Light)**, Face ID, Change PIN, Notifications (class & exam), Privacy, Disclaimer, Sign out. Theme control and the light look are both shipped (Stage 4 Flutter pass). Figma light frames still pending.

### 9.9 Notifications

Local only: N minutes before class/exam (default 15 min class, 24 h exam). No inbox polling in background (no server; OS background fetch optional later, off in v1 to save battery and ToS heat).

---

## 10. API methods to wrap (thin Dart)

Map 1:1 from `neptun-api` (`NeptunAPI`). Confirm live ELTE JSON once.

| Dart | Stage | Write? |
|---|---|---|
| `authenticate` (password) | 1 | yes (login) |
| `authenticate` (OTP `token`) | 1 | yes (2FA) |
| `getCalendarEvents` | 2 | no |
| `getDashboardAverages` / `getTermAverages` | 2 | no |
| `getDashboardCreditProgress` | 2 | no |
| `getUnreadMessageCount` | 2 | no |
| `getTakenSubjects` + terms | 3 | no |
| `getAllGrades` | 3 | no |
| `getExamsList` | 3 | no |
| `signUpForExam` / `unsubscribeFromExam` | 3 | **yes** |
| `getReceivedMessages` / `getMessagePosts` | 3 | no |
| `getUserInfo` (safe fields only) | 3 | no |

**Do not wrap** in v1: `raw_post` generic, password change, TOTP delete, `get_calendar_export_links` (secret URLs), student lists, avatars of others, `call_method` style meta.

DTOs: explicit fields we render. Unknown JSON keys ignored. Calendar **must** include start/end/title/type — if ELTE payload differs from Óbuda, log keys in debug and adapt.

---

## 11. Implementation stages

### Stage 0 — Foundation — **DONE**

Completed:

- Luxury dark visual system in Figma **and** Flutter (source of truth; see §8)
- Theme tokens: ink / surface / hairline / carmine; Fraunces + Plus Jakarta Sans; radius 8/12/16
- Shared widgets: `KarminScaffold`, `KarminCard` (gradients + accent bars), `KarminPrimaryButton`, `KarminBottomNav` (icon + carmine pill), `KarminIcons`, chips, segmented control, list rows
- Figma screens 01–07 + Components icon set rebuilt to the community-ref language
- Flutter Today / Calendar / Study / Inbox / Settings match that contract with demo data
- `go_router` + 4-tab shell
- l10n EN/HU/RU stubs, default EN
- `NeptunClient` empty + exceptions
- Secure storage + PIN hash helpers + `local_auth` probe
- `android:allowBackup="false"`; iOS Keychain accessibility
- LICENSE (MIT, Cheterin), PLAN, PRIVACY, DISCLAIMER, legal NOTICE
- Web platform scaffold for UI preview
- `.gitignore` secrets / keystores
- `flutter analyze` clean; tests pass

**Exit (met):** `flutter run` shows English Today in the locked dark UI, gear opens Settings.

### Stage 1 — Auth (5–7 days) — **DONE IN CODE / GATE: live ELTE unproven**

- Session layer with explicit `needsPassword` / `needsOtp` / `authenticated`.
- Login, Disclaimer, **Verification (2FA)**, Set PIN, Unlock, lifecycle lock, Sign out — Figma 01/02 + 02b contract, existing shared widgets.
- Live `POST Account/Authenticate` (password, then OTP in `token`) plus a **labeled debug/mock path** (any non-empty credentials → require any 6-digit OTP). Do not claim production Neptun auth works until an on-device ELTE login succeeds. Web preview uses the debug path (CORS + no Keystore/biometrics).
- 401 interceptor: drop JWT, then stored password + **interactive OTP** — never silent; **do not retry** the original request until OTP succeeds.
- FLAG_SECURE on Login / Verification / PIN / Unlock.
- Captcha error path.
- ThemeMode preference + Settings control (dark default). Light visuals are not done.

**Exit:** real ELTE account, login → 2FA → PIN → Today; kill app → Unlock → 2FA → Today placeholder (empty data OK). Warm resume: Unlock only. No secrets in logcat. **Not yet proven in this repo.**

**Debug / no-network (honest):** `kDebugMode` uses `DebugNeptunAuth` unless `--dart-define=KARMIN_LIVE_AUTH=true`. Mock: non-empty code+password → `needsOtp` (channel unknown); any 6-digit OTP → fake JWT in RAM. Login shows a development banner. Release builds always use the live client. Web/Chrome stays on the debug path (CORS).

### Stage 2 — Cached reads (8–10 days) — **DONE IN CODE / GATE: live ELTE JSON unproven**

Shipped:

- Authenticated `NeptunClient` GET helper + 401 interceptor (drop JWT, no retry).
- Live reads: `Calendar/GetCalendarEvents`, `Dashboard/GetAverages`, `dashboard/creditprogress`, `Message/GetUnreadedMessagesCount`.
- Today + Calendar bind to that snapshot when the call succeeds; graceful empty / “last saved” on failure.
- **OTP resend = re-login** (re-POST Authenticate with stored password). Debug mock also re-issues `needsOtp`.
- Stale-while-revalidate JSON cache (`SharedPreferences`, 5 min). **Isar deferred** — codegen + incomplete Android tree. Hive/Isar still the planned durable store.
- Local notifications from cache: **not shipped** (platform setup; keep cache ready). Stage 4/notifications.

**Exit (not met):** airplane mode after one **live** fetch still shows the week — needs a real device + ELTE JSON confirmation.

**Debug vs live:** same `KARMIN_LIVE_AUTH` / `kDebugMode` switch as auth. Debug student API returns the former demo week (Analysis II, etc.). Live student API is used on mobile / release / `KARMIN_LIVE_AUTH=true`.

### Stage 3 — Study, exams, inbox, settings (8–10 days) — **DONE IN CODE / GATE: live ELTE unproven**

Shipped in this pass:

- Study: taken subjects + best-effort grades (current term; **no** N+1 `GetSubjectDetails`), GPA/credits from Stage 2 dashboard, subject push page, pull-to-refresh, empty/error/last-cached.
- Exam card + double-confirm sheet. Live `POST ExamRegistration/SignUpForExam` `{ examId }` — **payload shape unproven**; UI shows Neptun’s text or a disabled “use official Neptun” hint when there is no `examId`. Debug mock is labeled, not a fake live signup.
- Inbox list + thread + mark-read; unread count stays in sync with Today’s chip. Real timestamps (PLAN does not lock 04:04).
- Settings profile from `UserInfo` / `MyTrainings`; else “Student” + Neptun code from auth. Debug keeps the previous demo-quality name.

**Still demo / unproven:** live ELTE JSON field names; exam POST body; get-all-grades via per-subject details (skipped to avoid a request stampede). Unsubscribe-from-exam is not in the UI.

**Exit (not met):** sign up or fail with Neptun’s text on a dummy/real exam **you intend to take** — needs a device + real account.

**Debug vs live:** same switch as Stage 1–2. Chrome/web stays on labeled `DebugNeptunStudentApi` (CORS).

### Stage 4 — Harden + closed beta (4–6 days) — **POLISH IN CODE; BETA NOT SHIPPED**

Shipped in this pass:

- Shared empty / error / last-cached banners (`KarminStatusBanner`, `KarminEmptyState`, `KarminInlineError`) on Today, Calendar, Study, Inbox, Auth.
- Accessibility: 48pt tap targets on icon buttons, Semantics on tabs / PIN keypad / OTP / password toggle, live-region errors, carmine contrast via `accentText` (bright on dark, carmine on cream).
- **Light theme pass in Flutter:** `KarminPalette` ThemeExtension; Settings System / Dark / Light restyles all 7 screens + shell + cards + primary button. Cream paper, not Material white. Dark remains default.
- Privacy / Disclaimer wording frozen (still not legal advice). Manual smoke checklist in `docs/SMOKE.md`.

**Not in this slice:**

- Figma light frames (file access is View-only; still pending).
- Local notifications (`flutter_local_notifications`) — still deferred; cache is ready.
- Completing the Android Gradle tree / `MainActivity` FLAG_SECURE channel / sideload APK / TestFlight.
- Live ELTE proof (same gate as Stages 1–3).

**Exit (not met):** invite-only APK + TestFlight after Android tree + live smoke on a real account.

### After v1 (not scheduled)

Request forms (native top ELTE templates), surveys WebView, message reply, finances.

---

## 12. Documentation to write (deliverables)

All live under `docs/` unless noted. Stage 0 stubs exist; freeze text in Stage 4.

| File | Audience | Contents |
|---|---|---|
| `README.md` | Devs / testers | Bilingual EN/RU; unofficial banner; Cheterin ownership; how to run |
| `docs/PLAN.md` | This file | Source of product truth |
| `docs/ARCHITECTURE.md` | Devs | Layers, interceptor, cache invalidation |
| `docs/SECURITY.md` | Devs | Threat model, keystore keys, how to report a vuln |
| `docs/PRIVACY.md` | Users | GDPR-style notice: what, why, retention, no server, Neptun’s role |
| `docs/DISCLAIMER.md` | Users | Unofficial, own risk, exam signup is the student’s act |
| `docs/legal/SOURCES.md` | Team | Dates + URLs of ELTE/Neptun terms actually read |
| `docs/legal/NOTICE.md` | Everyone | Third-party / Flutter dependency notices |
| `docs/API.md` | Devs | Dart method ↔ path ↔ sample fields (no personal dumps) |
| `docs/I18N.md` | Devs | EN source; lcid mapping |
| `docs/IOS_SIDELLOAD.md` | Testers | Free iPhone install (Personal Team / GHA IPA / Sideloadly); 7-day expiry |
| `docs/RELEASE.md` | Team | Sideload, optional TestFlight later, versioning `0.1.0+1` |
| `CHANGELOG.md` | Testers | Human changes |
| `LICENSE` | Everyone | MIT © Cheterin / cheterin.online |
| In-app screens | Users | Disclaimer, Privacy, open-source licenses page (`showLicensePage`) |

Figma + `lib/app/theme.dart` / `lib/app/widgets/` are the UI spec. Tokens live in §8; do not reopen them in later stages.

### 12.1 In-app copy (English source)

- Disclaimer title: “Unofficial client”
- Privacy short: “Karmin stores your Neptun password in the secure hardware-backed store of this phone so you can unlock with Face ID or PIN. Karmin does not run a server. ELTE and Neptun remain responsible for the data they hold.”

Translate HU/RU only after EN is frozen.

---

## 13. Testing

| Layer | What |
|---|---|
| Unit | PIN hash, DTO parse with fixtures **stripped of PII** (anonymized JSON in `test/fixtures/`) |
| Widget | Login validation, Unlock keypad, exam confirm sheet |
| Integration (device) | Stage 1–3 checklist against **your** ELTE account |
| Never | CI that logs into Neptun with a shared robot password |

Manual smoke (Stage 4):

1. Disclaimer → Login → 2FA → PIN → Today  
2. Kill → biometric → 2FA → Today from cache  
2b. Background (JWT still in RAM) → Unlock only → Today  
3. Airplane → Calendar still populated  
4. Wrong password once → error, no captcha spiral  
5. Sign out → Keystore empty, Login shown  
6. Exam confirm cancel does not POST  

---

## 14. Release and ops

- Version: `pubspec` `0.1.0+1`; bump build number every IPA / APK.
- **iOS is the primary tester path** (bundle `online.cheterin.karmin`). Free Personal Team or unsigned GHA IPA — [IOS_SIDELLOAD.md](IOS_SIDELLOAD.md). Re-sign every 7 days on a free Apple ID.
- Android on Windows is emulator / CI. Signing: personal keystore **not in git**. `android/key.properties` gitignored.
- Distribution: invite-only sideload. TestFlight only if a paid Apple program is added later. Track testers in a private note, not in the repo.
- Support: GitHub issues and [cheterin.online](https://cheterin.online). No in-app chat.
- Incident: if ELTE complains or accounts lock — yank the build, document in CHANGELOG, pause Stage 3 writes.
- No auto-update server. Testers install a new IPA / APK.

---

## 15. Risks register

| ID | Risk | Likelihood | Impact | Treatment |
|---|---|---|---|---|
| L1 | ToS forbids clients | M | High | Closed beta; stop-if-asked |
| L2 | Store rejection / impersonation | H if we try | Med | Don’t ship stores in v1 |
| S1 | Captcha after retries | M | Med | Web fallback |
| S4 | 2FA every login / 401 | H | Med | Dedicated Verification screen; never store TOTP secret |
| S2 | Exam POST shape wrong | M | High | Capture live payload first |
| S3 | ELTE JSON ≠ Óbuda | M | Med | Optional DTO fields; live fixture |
| P1 | Classmate PII | L if we skip lists | High | Never call student-list endpoints |
| O1 | Neptun outage | M | Med | Cache + banner |
| O2 | Keystore lost on uninstall | — | — | Expected; user logs in again |

---

## 16. Open questions (do not block Stage 1)

1. Exact ELTE JSON for `GetCalendarEvents` (start/end field names).  
2. Whether ELTE `Authenticate` returns refresh tokens.  
3. **Closed:** every ELTE login requires an interactive OTP (email or authenticator). Do not store a TOTP secret to skip it. Channel detection (email vs app) is best-effort from the 202 payload; default hint is “email or authenticator”.  
4. Display name from API vs “Student” + code.  
5. Notification exact times (15 min / 24 h) — confirm in Settings later.

License decided: **MIT** under Cheterin.

---

## 17. Immediate next actions

1. **Stage 1–3 live on iPhone** (`KARMIN_LIVE_AUTH=true` or release IPA): confirm calendar/study/inbox JSON keys; prove 2FA + resend-via-relogin; capture `SignUpForExam` body. Free install: [IOS_SIDELLOAD.md](IOS_SIDELLOAD.md). Push `.github/workflows/ios.yml` so Actions can build an unsigned IPA (this Windows checkout cannot).  
2. Fill `docs/legal/SOURCES.md` after personally opening ELTE Neptun terms.  
3. Figma light frames (when write access exists). Android remains emulator/CI on Windows until that tree is ready.  
4. If ELTE or SDA asks to stop distribution — stop, note in CHANGELOG, contact via cheterin.online.

---

## 18. References (code, not legal)

- Local reference client: `C:\Users\adnan\Documents\Coding\neptun-api` (`NeptunAPI`, `docs/request_forms.md` for later)  
- ELTE API base: `https://neptun.elte.hu/ujhallgato/api/`  
- Figma: https://www.figma.com/design/Iuxf0sbisHaOwxn6Vkcgdg  
- Owner: https://cheterin.online  
