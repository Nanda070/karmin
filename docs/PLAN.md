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
| Web platform (`web/`) | Added alongside iOS/Android (dev/preview; v1 ship target remains mobile) |
| UI polish | **Done** — premium dark theme (ink / navy / carmine), shared widgets (`KarminScaffold`, cards, list rows, chips, segmented control, bottom nav) |
| Platforms | Android, iOS, web scaffold |
| Live Neptun auth | **Not started** |
| **Next** | **Stage 1 — Auth** |

Stage 0 exit criteria met: English Today placeholder, dark theme, gear → Settings, l10n EN/HU/RU, `NeptunClient` skeleton, secure storage + PIN helpers, doc stubs, MIT license under Cheterin.

---

## 1. Product definition

Karmin is a Flutter app by **Cheterin** for ELTE students. It signs into the official Neptun student API (`https://neptun.elte.hu/ujhallgato/api/`) with the student’s own Neptun code and password, then shows Today, calendar, grades, exams, and inbox in a dark, minimal UI.

It is **not** an ELTE product, **not** a SDA Informatika product, and **not** a replacement for the legal relationship between the student and the university. Cheterin has **no** trademark permission or endorsement from ELTE, Neptun, or SDA.

### 1.1 Goals

- One first login, then Face ID / 6-digit PIN.
- Today and calendar feel instant (local cache, then refresh).
- Exam signup with an explicit double confirm.
- UI matches the Figma file (Karmin, English).

### 1.2 Non-goals (v1 and “never” unless the product contract changes)

| Out | Why |
|---|---|
| Own backend / BFF | Extra attack surface; passwords would leave the phone |
| Python / Playwright in the app | Survey autofill is banned; Playwright cannot run on-device |
| Thesis, Erasmus, dorm, student-card claims | Out of product |
| MeetStreet, finances, compose mail | Out of v1 |
| Request-form wizard | v1.1 at earliest |
| Public Play Store / App Store | Policy and ToS risk |
| Light theme, widgets, Watch | Explicitly cut for v1 |
| Classmate lists, avatars of others | PII of third parties; skip endpoints |
| Scraping HTML of the old Neptun | We only use the documented-in-neptun-api JSON API |

Web is available for development and UI preview; production distribution for v1 remains TestFlight internal + Android sideload.

### 1.3 Success criteria for v1

- Real ELTE account: login → PIN → Today shows next class from cache after kill/reopen.
- Backgrounding the app always shows Unlock, never Today.
- Exam signup either succeeds with Neptun’s message or fails with Neptun’s error text.
- `grep` of log output after a session finds no password, no JWT.
- Distribute only via TestFlight internal + Android sideload / invite.

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
[Login / Unlock]
        │  Face ID or PIN
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
| HTTP | `dio` | Interceptor: attach JWT; on 401 authenticate once and retry |
| State | `flutter_riverpod` | No GetX |
| Routing | `go_router` | Redirect: no session → login; locked → unlock |
| Secrets | `flutter_secure_storage` | iOS Keychain, Android Keystore |
| Biometrics | `local_auth` | biometricOnly first, then PIN UI we own |
| Cache | `isar` + `isar_flutter_libs` | Stage 2; Hive only if Isar codegen blocks |
| i18n | `flutter_localizations` + `intl` + gen-l10n | EN is `template-arb-file` |
| Fonts | `google_fonts` (Inter) | Theme locked in Stage 0 |
| Notifications | `flutter_local_notifications` + `timezone` | Stage 2+ |
| Secure flag | `flutter_windowmanager` or platform channel | FLAG_SECURE on Login + Unlock |
| Icons | custom / Lucide subset as SVG | No Material rainbow icons on tabs |

Do not add Firebase, Sentry-with-PII, analytics SDKs, or crash reporters that upload request bodies in v1.

---

## 4. Authentication (detail)

### 4.1 First session

1. User enters Neptun code + password. No “remember password” checkbox — storage is mandatory for PIN unlock, explained in the disclaimer.
2. `POST Account/Authenticate` `{ userName, password, lcid }`.
3. Success: `accessToken`, `neptunCode`. JWT → RAM. Credentials → Keystore (`neptun_code`, `neptun_password`).
4. Navigate to **Set PIN** (6 digits, enter twice). Enable Face ID / fingerprint (default on if hardware exists).
5. Land on Today.

### 4.2 Returning session

1. Cold start: if Keystore has credentials and PIN is set → **Unlock**, never Login.
2. Biometric prompt immediately. Failure / cancel → PIN pad.
3. On success: if JWT still in RAM (warm process) use it; else authenticate with stored password **without** showing Login.
4. Wrong PIN: lockout after 5 tries for 30s, then 5 min (document in UI). Do **not** wipe Keystore on PIN fail (that would brick the user after typos). Offer “Sign out” on Unlock.

### 4.3 Token

- Neptun JWT is session-scoped. Treat as expired on 401.
- Do not persist JWT. Process death ⇒ silent re-login.
- Refresh endpoint: use `refresh_token` **only if** ELTE actually returns and accepts it. Until proven on live ELTE, 401 → full Authenticate.

### 4.4 Errors (typed)

| Condition | UX |
|---|---|
| Bad password | “Neptun rejected these credentials.” |
| Network | “Can’t reach Neptun.” Cache still used after unlock if already logged in before. |
| HTTP 202 + captcha | “Neptun wants a captcha. Sign in once on the website, then retry.” Button: open `https://neptun.elte.hu/` |
| 2FA required | If ELTE enables it: TOTP field or stored TOTP secret (opt-in, Keystore). Not in first Auth slice unless live test shows 202. |
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
| Stolen phone, attacker has PIN | They get Neptun. Same as stealing the password. Disclose this in Privacy/Disclaimer. |
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
| PIN hash + salt | User | Keystore | App lock | Until Sign out |
| JWT | Neptun | RAM only | API calls | Process lifetime |
| Calendar events | API | Isar | Today, calendar, notifications | Overwritten on refresh; wipe on Sign out |
| Grades, subjects, GPA | API | Isar | Study | Same |
| Inbox metadata + body | API | Isar | Inbox | Same |
| Language, bio flag, notif prefs | User | SharedPreferences (non-secret) | Settings | Until Sign out or reinstall |
| Notification pending IDs | Local | Plugin storage | Alarms | Recreated from cache |

### 6.2 Data we will **not** collect or persist

- Analytics, advertising IDs
- Other students’ photos or full student lists (`get_subject_course_students` — **do not call**)
- Location (even for “navigate to building” in v1: show room text only)
- Password in Isar, logs, or screenshots

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

## 8. UX and visual

- Figma is source: https://www.figma.com/design/Iuxf0sbisHaOwxn6Vkcgdg
- Brand string: **Karmin** (ASCII, no accent)
- Owner brand: Cheterin / cheterin.online
- Dark only. Background: ink → navy (login: ink → navy → carmine)
- Bottom tabs: Today | Calendar | Study | Inbox
- Settings: gear on Today (and Profile card)
- Shared widgets under `lib/app/widgets/` (Stage 0 polish done)
- i18n: EN default; HU/RU files exist; Settings language overrides OS

Do not invent extra tabs. Do not add a floating compose button.

---

## 9. Features by screen (v1)

### 9.1 Login

Neptun code, password, Sign in, Keystore one-liner. Disclaimer already accepted.

### 9.2 Unlock

Karmin wordmark, 6 PIN dots, keypad, Face ID. Sign out link.

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

Profile (name, code, training if API gives it), Language, Face ID, Change PIN, Notifications (class & exam), Privacy, Disclaimer, Sign out.

### 9.9 Notifications

Local only: N minutes before class/exam (default 15 min class, 24 h exam). No inbox polling in background (no server; OS background fetch optional later, off in v1 to save battery and ToS heat).

---

## 10. API methods to wrap (thin Dart)

Map 1:1 from `neptun-api` (`NeptunAPI`). Confirm live ELTE JSON once.

| Dart | Stage | Write? |
|---|---|---|
| `authenticate` | 1 | yes (login) |
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

- Theme from Figma (colors, radius 12/16, Inter) + premium shared widgets
- `go_router` + 4-tab shell (placeholder pages)
- l10n EN/HU/RU stubs, default EN
- `NeptunClient` empty + exceptions
- Secure storage + PIN hash helpers + `local_auth` probe
- `android:allowBackup="false"`; iOS Keychain accessibility
- LICENSE (MIT, Cheterin), PLAN, PRIVACY, DISCLAIMER, legal NOTICE
- Web platform scaffold for UI preview
- `.gitignore` secrets / keystores

**Exit (met):** `flutter run` shows English Today placeholder, dark theme, gear opens Settings.

### Stage 1 — Auth (5–7 days) — **NEXT / GATE**

- Live `Authenticate` against ELTE.
- Login, Disclaimer, Set PIN, Unlock, lifecycle lock, Sign out.
- 401 interceptor.
- FLAG_SECURE on those routes.
- Captcha error path.

**Exit:** real ELTE account, kill app, Face ID → Today placeholder (empty data OK). No secrets in logcat.

### Stage 2 — Cached reads (8–10 days)

- Isar collections.
- Calendar + dashboard repos, stale-while-revalidate.
- Today + Calendar week/list + filters.
- Local notifications from cache.

**Exit:** airplane mode after one fetch still shows the week.

### Stage 3 — Study, exams, inbox, settings (8–10 days)

- Grades/subjects/subject page.
- Exam signup confirm + live payload verification.
- Inbox + thread.
- Settings filled from `getUserInfo` / training if available; else “Student” + neptun code from auth.

**Exit:** sign up or fail with Neptun’s text on a dummy/real exam **you intend to take**.

### Stage 4 — Harden + closed beta (4–6 days)

- Empty/error/offline banners.
- Accessibility pass on Login, Unlock, tabs.
- Internal TestFlight + APK.
- Privacy/Disclaimer finalized.
- Live smoke script (manual checklist).

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
| `docs/RELEASE.md` | Team | Sideload, TestFlight, versioning `0.1.0+1` |
| `CHANGELOG.md` | Testers | Human changes |
| `LICENSE` | Everyone | MIT © Cheterin / cheterin.online |
| In-app screens | Users | Disclaimer, Privacy, open-source licenses page (`showLicensePage`) |

Figma remains UI spec; do not duplicate pixel specs in Markdown except tokens.

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

1. Disclaimer → Login → PIN → Today  
2. Kill → biometric → Today from cache  
3. Airplane → Calendar still populated  
4. Wrong password once → error, no captcha spiral  
5. Sign out → Keystore empty, Login shown  
6. Exam confirm cancel does not POST  

---

## 14. Release and ops

- Version: `pubspec` `0.1.0+1`; bump build number every APK.
- Signing: personal keystore **not in git**. `android/key.properties` gitignored.
- Distribution: invite-only. Track testers in a private note, not in the repo.
- Support: GitHub issues and [cheterin.online](https://cheterin.online). No in-app chat.
- Incident: if ELTE complains or accounts lock — yank the APK, document in CHANGELOG, pause Stage 3 writes.
- No auto-update server. Testers install a new APK.

---

## 15. Risks register

| ID | Risk | Likelihood | Impact | Treatment |
|---|---|---|---|---|
| L1 | ToS forbids clients | M | High | Closed beta; stop-if-asked |
| L2 | Store rejection / impersonation | H if we try | Med | Don’t ship stores in v1 |
| S1 | Captcha after retries | M | Med | Web fallback |
| S2 | Exam POST shape wrong | M | High | Capture live payload first |
| S3 | ELTE JSON ≠ Óbuda | M | Med | Optional DTO fields; live fixture |
| P1 | Classmate PII | L if we skip lists | High | Never call student-list endpoints |
| O1 | Neptun outage | M | Med | Cache + banner |
| O2 | Keystore lost on uninstall | — | — | Expected; user logs in again |

---

## 16. Open questions (do not block Stage 1)

1. Exact ELTE JSON for `GetCalendarEvents` (start/end field names).  
2. Whether ELTE `Authenticate` returns refresh tokens.  
3. Whether 2FA is ever on for ELTE student web.  
4. Display name from API vs “Student” + code.  
5. Notification exact times (15 min / 24 h) — confirm in Settings later.

License decided: **MIT** under Cheterin.

---

## 17. Immediate next actions

1. **Stage 1 Auth** against a live ELTE login (Disclaimer → Login → PIN → Unlock → lifecycle lock).  
2. Fill `docs/legal/SOURCES.md` after personally opening ELTE Neptun terms.  
3. Keep Figma as the visual contract; English + Karmin + gear → Settings.  
4. If ELTE or SDA asks to stop distribution — stop, note in CHANGELOG, contact via cheterin.online.

---

## 18. References (code, not legal)

- Local reference client: `C:\Users\adnan\Documents\Coding\neptun-api` (`NeptunAPI`, `docs/request_forms.md` for later)  
- ELTE API base: `https://neptun.elte.hu/ujhallgato/api/`  
- Figma: https://www.figma.com/design/Iuxf0sbisHaOwxn6Vkcgdg  
- Owner: https://cheterin.online  
