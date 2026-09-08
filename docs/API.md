# API map

**Owner:** Nanda / Cheterin Group. Unofficial; not affiliated with ELTE or Neptun.

Base (student reads): `https://neptun.elte.hu/Account/api/` (fork institute `…/Account` + `/api/`). JSON Authenticate is still probed at absolute `https://neptun.elte.hu/Account/api/Account/Authenticate` (`postUri`). **Live ELTE does not serve that controller** (dummy POST → empty HTTP 400, GET → HTML 404). Password login that reaches Verification is Potlap MVC `GET+POST /Account/Login` then `/Account/Login2FA`. Legacy `ujhallgato/api` unused. Optional email resend still uses MVC Login2FA.

Authenticate JSON probe headers: `Content-Type: application/json` (no charset) + dart:io User-Agent (+ fork `devicecookie` when present); strip `Authorization`. MVC Login uses Safari-like headers + antiforgery. Student GETs keep User-Agent `Karmin/0.1.0` + `X-Requested-With`.

JWT: RAM only. **Real** Authenticate `accessToken` → `Authorization: Bearer` on student GETs only. MVC placeholder `elte-portal-session` is **not** sent as Bearer and blocks student GETs with an honest portal-session error. 401 on a non-auth path drops a real JWT and does **not** retry until OTP succeeds. HTML/maintenance bodies → `NeptunMaintenanceException` (with HTTP status). Login/OTP reject → `HTTP <status>` + short Neptun text or `empty body` (never the opaque “sign on the website” string without status).

| Dart method | Path | Stage | Write? | Notes |
|---|---|---|---|---|
| `submitPassword` | One JSON probe `POST /Account/api/Account/Authenticate` `{ userName, password, captcha:"", captchaIdentifier:"", token:"", LCID }`; on empty 400 / HTML 404 → **MVC** `GET+POST /Account/Login` | 1 | yes | JSON 202/JWT stays on Authenticate. ELTE live uses MVC (antiforgery). Generic 400 is **not** invalid credentials. |
| `submitOtp` | JSON `token=<bare 6 digits>` if JSON 2FA pending; else MVC `POST /Account/Login2FA` `TOTPCode` | 1 | yes | Never compose email prefix on Authenticator. After MVC success, one JSON upgrade attempt for JWT (ignored if still 400). Failures include HTTP status. |
| `reset` | clears JSON 2FA pending + device cookie + portal cookies | — | — | Called from `AuthController.signOut`. |
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
