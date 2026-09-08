# Architecture (stub — Stage 0)

```
[Login / Unlock]  →  Flutter UI (Riverpod, go_router)
                         → Repositories → Isar (Stage 2+)
                         → NeptunClient (dio) → ELTE HTTPS API
```

## Layers

| Layer | Role |
|---|---|
| `lib/app/` | Bootstrap, theme, router |
| `lib/auth/` | Secure storage, PIN hash, biometrics (Stage 1: login/unlock) |
| `lib/api/` | Dio client, DTOs, typed exceptions |
| `lib/data/` | Isar collections + repositories (deferred to Stage 2) |
| `lib/features/` | Today, Calendar, Study, Inbox, Settings |

## Rules (v1)

- One process, one Neptun session. JWT in RAM only.
- Base URL hardcoded to ELTE. No university picker.
- On 401: authenticate once and retry (Stage 1 interceptor).
- Cache: stale-while-revalidate; wipe on Sign out.

See [PLAN.md](PLAN.md) §3.
