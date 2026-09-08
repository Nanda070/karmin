# API map

Base: `https://neptun.elte.hu/ujhallgato/api/`

User-Agent: `Karmin/0.1.0 (Flutter; ELTE student client)`

JWT: RAM only, `Authorization: Bearer`. 401 on a non-auth path drops the JWT and does **not** retry until OTP succeeds.

| Dart method | Path | Stage | Write? | Notes |
|---|---|---|---|---|
| `submitPassword` | `POST Account/Authenticate` `{ userName, password, lcid }` | 1 | yes | HTTP 202 + `isTwoFactorRequired` → Verification |
| `submitOtp` | same, plus `token` (one-time code) | 1 | yes | Never silent |
| `resendEmailCode` | **same as `submitPassword`** | 1–2 | yes | Not a dedicated resend endpoint. Re-login so Neptun mails a new OTP (ELTE email delivery is unreliable). No `token` field. |
| `getCalendarEvents` | `GET Calendar/GetCalendarEvents` | 2 | no | Query: `startDate` / `endDate` (`yyyy-MM-ddTHH:mm:ss.000`) plus display flags. Parser is best-effort (`title`/`subjectName`, `startDate`/`start`/`/Date(ms)/`). Live ELTE keys unconfirmed. |
| `getDashboardAverages` | `GET Dashboard/GetAverages` | 2 | no | GPA chip; optional fields |
| `getDashboardCreditProgress` | `GET dashboard/creditprogress` | 2 | no | Cached; Study UI still demo |
| `getUnreadMessageCount` | `GET Message/GetUnreadedMessagesCount` | 2 | no | Today messages chip |
| Subjects, grades, exams, inbox threads, user info | — | 3 | mixed | Exam signup is write |

Do not wrap student lists, password change, or calendar export secret URLs in v1.

**Debug:** `DebugNeptunAuth` + `DebugNeptunStudentApi` (labeled). Same resend = password step again.

No personal JSON dumps in this repo. Fixtures in `test/fixtures/` are anonymous. See [PLAN.md](PLAN.md) §10.
