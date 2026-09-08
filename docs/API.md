# API map

Base: `https://neptun.elte.hu/ujhallgato/api/`

User-Agent: `Karmin/0.1.0 (Flutter; ELTE student client)`

JWT: RAM only, `Authorization: Bearer`. 401 on a non-auth path drops the JWT and does **not** retry until OTP succeeds.

| Dart method | Path | Stage | Write? | Notes |
|---|---|---|---|---|
| `submitPassword` | `POST Account/Authenticate` `{ userName, password, lcid }` | 1 | yes | HTTP 202 + `isTwoFactorRequired` → Verification |
| `submitOtp` | same, plus `token` (one-time code) | 1 | yes | Never silent |
| `resendEmailCode` | **same as `submitPassword`** | 1–2 | yes | Not a dedicated resend endpoint. Re-login so Neptun mails a new OTP. No `token` field. |
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
