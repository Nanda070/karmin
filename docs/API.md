# API map

**Owner:** Nanda / Cheterin Group. Unofficial; not affiliated with ELTE or Neptun.

Base: `https://neptun.elte.hu/ujhallgato/api/` (SDA JSON student web). **ELTE's public host does not serve that path** (GET 404 / POST empty 400). Live login therefore tries fork JSON `POST https://neptun.elte.hu/Account/api/Account/Authenticate` first, then relative `ujhallgato`, then MVC `POST /Account/Login` → `/Account/Login2FA`.

User-Agent: `Karmin/0.1.0 (Flutter; ELTE student client)` plus `X-Requested-With: XMLHttpRequest` on JSON auth (not Safari MVC headers).

JWT: RAM only, `Authorization: Bearer`. 401 on a non-auth path drops the JWT and does **not** retry until OTP succeeds.

| Dart method | Path | Stage | Write? | Notes |
|---|---|---|---|---|
| `submitPassword` | JSON `POST /Account/api/Account/Authenticate` `{ userName, password, captcha, captchaIdentifier, token:"", LCID }` then MVC `POST /Account/Login` | 1 | yes | HTTP 202 / `isTwoFactorRequired` → authenticator Verification; sets JSON 2FA pending (kept across re-login until JWT / MVC / `reset`). **No** auto `GetEmail` on password. Empty 400 is **not** invalid credentials. |
| `submitOtp` | same Authenticate URL with `token=<bare 6 digits>` (or MVC `RequestTOTP`+`TOTPCode`) | 1 | yes | Prefer JSON while pending or no portal session. Never compose email prefix onto authenticator codes. Never silent. |
| `reset` | clears JSON 2FA pending + portal cookies | — | — | Called from `AuthController.signOut`. |
| `resendEmailCode` | **`POST /Account/Login2FA` + `GetEmail=true`** (or Login + GetEmail) | 1–2 | yes | Optional email path only. Visible error if no prefix. |
| `getCalendarEvents` | `GET Calendar/GetCalendarEvents` | 2 | no | Query: `startDate` / `endDate` plus display flags. Parser best-effort. Live ELTE keys unconfirmed. |
| `getDashboardAverages` | `GET Dashboard/GetAverages` | 2 | no | GPA chip; optional fields |
| `getDashboardCreditProgress` | `GET dashboard/creditprogress` | 2 | no | Study credits card |
| `getUnreadMessageCount` | `GET Message/GetUnreadedMessagesCount` | 2 | no | Today + Inbox chip (kept in sync after mark-read) |
| `getTakenSubjects` | `GET TakenSubjects/Terms` then `GET TakenSubjects` | 3 | no | Current/open term only. Grades from list + optional `GET SubjectCourse/GetSubjectResultsList`. **Not** N+1 `GetSubjectDetails`. |
| `getExamOffers` | `GET ExamOverview/GetDashboardExamEntriesInActualTerm` (fallback `GetDashboardExamEntries`) | 3 | no | Upcoming exam CTA |
| `getExamsForSubject` | `GET ExamRegistration/GetExamsList` | 3 | no | Subject page; `subjectId` + `termId` |
| `signUpForExam` | `POST ExamRegistration/SignUpForExam` `{ examId }` | 3 | **yes** | Payload **unproven** on live ELTE. Confirm sheet required. Show Neptun `notification` / error text. |
| `getReceivedMessages` | `GET Message/GetReceivedMessages` | 3 | no | `firstRow` / `lastRow` / `filterType` |
| `getMessagePosts` | `GET Messages/{id}/Posts` | 3 | no | Thread body; HTML stripped for display |
| `markMessageRead` | `POST Messages/{id}/Posts/Processed` `{ postIds }` | 3 | yes | After opening a thread |
| `getUserInfo` | `GET UserInfo` | 3 | no | Display name / code if present |
| `getTrainingLabel` | `GET MyTrainings` | 3 | no | Settings subtitle; else “Student” + auth code |

Do not wrap student lists, password change, or calendar export secret URLs in v1. Unsubscribe-from-exam is not in the UI.

**Debug:** `DebugNeptunAuth` + `DebugNeptunStudentApi` (labeled). Same resend = password step again. Study/Inbox fixtures match the old demo quality (Analysis II, Registrar, etc.).

No personal JSON dumps in this repo. Fixtures in `test/fixtures/` are anonymous. See [PLAN.md](PLAN.md) §10.

Live ELTE JSON keys for subjects, messages, exams, and the signup body are **best-effort** (Óbuda/`neptun-api` names). Do not claim they are proven without a real account.
