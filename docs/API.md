# API map (stub — Stage 0)

Base: `https://neptun.elte.hu/ujhallgato/api/`

User-Agent: `Karmin/0.1.0 (Flutter; ELTE student client)`

| Dart method | Stage | Write? | Notes |
|---|---|---|---|
| `authenticate` | 1 | yes | `POST Account/Authenticate` |
| `getCalendarEvents` | 2 | no | |
| Dashboard averages / credits / unread | 2 | no | |
| Subjects, grades, exams, inbox, user info | 3 | mixed | Exam signup is write |

Do not wrap student lists, password change, or calendar export secret URLs in v1.

No personal JSON dumps in this repo. See [PLAN.md](PLAN.md) §10.
