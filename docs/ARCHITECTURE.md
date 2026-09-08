# Architecture

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
| `lib/app/` | Bootstrap, theme, ThemeMode, router |
| `lib/auth/` | Session, disclaimer, login, OTP, PIN, unlock, lifecycle lock |
| `lib/api/` | Dio client, `NeptunAuthApi`, `NeptunStudentApi`, DTOs, typed exceptions |
| `lib/data/` | JSON cache + `StudentRepository` (Isar deferred) |
| `lib/features/` | Today, Calendar (live/debug snapshot); Study, Inbox still demo |

## Auth rules (v1)

- One process, one Neptun session. JWT in RAM only.
- Every fresh Neptun authentication requires an interactive OTP (email or authenticator). Stored password never completes login alone.
- PIN / biometrics open the local vault. They do not replace 2FA.
- 401: drop JWT, replay stored password, then show Verification. Do not retry the original request until OTP succeeds.
- **Resend OTP:** re-POST `Account/Authenticate` with stored code+password (no `token`). Neptun email OTP is unreliable; a new login triggers a new challenge / mail. 30s cooldown. Stay on Verification.
- Base URL hardcoded to ELTE. No university picker.
- Debug / web: `DebugNeptunAuth` + `DebugNeptunStudentApi` (labeled banner) unless `--dart-define=KARMIN_LIVE_AUTH=true`.

## Cache

SharedPreferences JSON key `karmin.cache.student.v1`. 5 minute stale window. Wipe on sign-out. Airplane mode can show last saved week once a live (or debug) fetch has succeeded.

See [PLAN.md](PLAN.md) §3–4.
