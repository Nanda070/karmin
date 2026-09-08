# Architecture

**Owner:** Nanda / Cheterin Group. Unofficial; not affiliated with ELTE or Neptun.

```
[Disclaimer] → [Login] → [Verification / 2FA] → [Set PIN]
[Unlock]     → (JWT in RAM? Today : password from Keystore + 2FA)
                         → Flutter UI (Riverpod, go_router)
                         → StudentRepository (stale-while-revalidate JSON cache)
                         → NeptunClient (dio) → ELTE HTTPS API
```

## Layers

| Layer | Role |
|---|---|
| `lib/app/` | Bootstrap, theme, `KarminPalette` ThemeExtension, ThemeMode, router, shared widgets (including `KarminStatusBanner`) |
| `lib/auth/` | Session, disclaimer, login, OTP, PIN, unlock, lifecycle lock |
| `lib/api/` | Dio client, `NeptunAuthApi`, `NeptunStudentApi`, DTOs, typed exceptions |
| `lib/data/` | JSON cache + `StudentRepository` (Isar deferred) |
| `lib/features/` | Today, Calendar, Study, Inbox, Settings bind `StudentSnapshot` (live or labeled debug) |

## Auth rules (v1)

- One process, one Neptun session. JWT in RAM only.
- Every fresh Neptun authentication requires an interactive OTP (email or authenticator). Stored password never completes login alone. Live ELTE password+OTP is Potlap MVC Login/Login2FA; JSON Authenticate is an optional JWT upgrade after OTP, not a password probe.
- PIN / biometrics open the local vault. They do not replace 2FA.
- 401: drop JWT, replay stored password, then show Verification. Do not retry the original request until OTP succeeds.
- **Resend OTP:** `POST /Account/Login2FA` with the official E-mail code fields (`Phase=RequestEmail` / `Provider=Email`). Fallback: Login then that same send-email POST. Visible error if Neptun still does not dispatch. 30s cooldown. Stay on Verification.
- Base URL hardcoded to ELTE. No university picker.
- Debug / web: `DebugNeptunAuth` + `DebugNeptunStudentApi` (labeled banner) unless `--dart-define=KARMIN_LIVE_AUTH=true`.

## Cache

SharedPreferences JSON key `karmin.cache.student.v1`. 5 minute stale window. Wipe on sign-out. Airplane mode can show last saved week / subjects / inbox once a live (or debug) fetch has succeeded.

Stage 3 extras (subjects, messages, exams, profile) are fetched in the same refresh. If an extra call fails, last cached extras are kept; a hard failure of calendar/dashboard still falls back to the whole snapshot.

Exam signup is a POST with `{ examId }` (unproven on ELTE). 401 still drops JWT and does not retry. Inbox mark-read updates the cached unread count so Today’s chip stays in sync.

See [PLAN.md](PLAN.md) §3–4 and [API.md](API.md).

## Theme

Dark is default (`KarminPalette.dark`: ink `#07080C`). Light is complementary cream (`KarminPalette.light`: paper `#F4EFE6`), not Material white. Widgets read `KarminPalette.of(context)` — do not hardcode `KarminColors` in feature screens. Settings ThemeMode (System / Dark / Light) selects `KarminTheme.light()` / `dark()`.

