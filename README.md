# Karmin

**Unofficial ELTE Neptun mobile client** — built by **Nanda** / **Cheterin Group**.

Dark, minimal Flutter app for students who want Today, calendar, grades, exams, and inbox without living in the Neptun web UI. English UI by default.

> **Not affiliated with ELTE, Neptun, or SDA Informatika.**  
> Karmin is an independent Cheterin Group project. It is not endorsed, sponsored, or supported by Eötvös Loránd University or the operators of Neptun. Use at your own risk. Prefer the official web client when university rules require it.

**Owner, Developer, Founder:** Nanda  
- Discord: `nandak070`  
- Telegram: `nanda070`  
- Mail: `turkapahf@gmail.com`  

**Company:** Cheterin Group  
- Site: [https://cheterin.online](https://cheterin.online)

© 2026 Nanda / Cheterin Group · [cheterin.online](https://cheterin.online)

---

## English

### What it is

Karmin signs into the official ELTE Neptun student API with **your** Neptun code, password, and a **one-time code** (email or authenticator — required on every fresh login). Credentials stay on-device (OS Keystore / Keychain) so Face ID or a 6-digit PIN can unlock the **local** vault. PIN does not skip Neptun 2FA. There is **no Cheterin Group backend** in v1 — academic data stays on the phone.

### Features (v1 scope)

| Area | Plan |
|---|---|
| Auth | Disclaimer, login, **2FA**, set PIN, biometric unlock, lifecycle lock |
| Today | Next class, exam chip, unread, GPA |
| Calendar | Week / list, filters (class, exam, task, online) |
| Study | Subjects, grades, credits, exam signup with double confirm |
| Inbox | Read-only messages and threads |
| Settings | Language, Face ID, PIN, notifications, privacy / disclaimer |

**Status:** Stages 0–4 polish are implemented in code (auth, cached reads, Study/Inbox, light theme + empty/error widgets). Debug builds use a labeled mock (any non-empty credentials, then any 6-digit code) plus demo-quality Study/Inbox fixtures. Live ELTE: `flutter run --dart-define=KARMIN_LIVE_AUTH=true` on a **device** (Chrome CORS will block the API). Do not claim live 2FA, JSON field names, or exam signup are proven without a real account. Light theme is cream paper (`#F4EFE6`), not generic white; Dark remains default.

Screenshots will land here once a live device pass exists. Until then, see the [Figma file](https://www.figma.com/design/Iuxf0sbisHaOwxn6Vkcgdg).

### Stack

- Flutter / Dart
- `dio`, `flutter_riverpod`, `go_router`
- `flutter_secure_storage`, `local_auth`
- `google_fonts` (Fraunces + Plus Jakarta Sans), gen-l10n (EN / HU / RU)
- Local cache: SharedPreferences JSON (Stage 2). Isar planned if codegen is viable.

### Getting started

```bash
# Flutter SDK on PATH, e.g. C:\Users\adnan\sdk\flutter\bin
flutter pub get
flutter run
```

**iOS on a physical iPhone is the primary test target.** Android on this Windows machine is emulator / CI only. Web is UI preview (Chrome CORS blocks live Neptun). You cannot compile an IPA on Windows — see [docs/IOS_SIDELLOAD.md](docs/IOS_SIDELLOAD.md) (free Apple ID + Xcode Personal Team, or GitHub Actions unsigned IPA + Sideloadly). Bundle ID: `online.cheterin.karmin`.

Live ELTE on a device: `flutter run --dart-define=KARMIN_LIVE_AUTH=true` (or install the release IPA from Actions). Debug without that flag stays on the labeled mock.

### Docs

**Developers:** start with [DEV.md](DEV.md) (single map — stack, auth, build).

| Doc | Purpose |
|---|---|
| [DEV.md](DEV.md) | Developer onboarding (the map) |
| [docs/PLAN.md](docs/PLAN.md) | Full product & stage plan |
| [docs/IOS_SIDELLOAD.md](docs/IOS_SIDELLOAD.md) | Free iPhone install (no $99 account) |
| [docs/ANDROID_BUILD.md](docs/ANDROID_BUILD.md) | Windows APK + optional emulator (no Android phone) |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers and cache |
| [docs/SECURITY.md](docs/SECURITY.md) | Threat model, keystore |
| [docs/PRIVACY.md](docs/PRIVACY.md) | On-device processing |
| [docs/DISCLAIMER.md](docs/DISCLAIMER.md) | Unofficial / own risk |
| [docs/legal/NOTICE.md](docs/legal/NOTICE.md) | Third-party notices |
| [docs/legal/SOURCES.md](docs/legal/SOURCES.md) | Terms URLs (fill before beta) |

### License & legal

- Software: [MIT](LICENSE) — Copyright © 2026 Nanda / Cheterin Group — provided **AS IS**
- Product disclaimer: [docs/DISCLAIMER.md](docs/DISCLAIMER.md)
- Privacy: [docs/PRIVACY.md](docs/PRIVACY.md)
- ELTE API base: `https://neptun.elte.hu/Account/api/` (fork-aligned; not `ujhallgato`)

If ELTE or SDA asks that distribution stop, we stop and record it in the changelog.

### Contact

- **Owner, Developer, Founder:** Nanda
  - Discord: `nandak070`
  - Telegram: `nanda070`
  - Mail: `turkapahf@gmail.com`
- **Company:** Cheterin Group — [https://cheterin.online](https://cheterin.online)
- Issues: use this repository’s issue tracker

---

## Русский

### Что это

**Karmin** — неофициальный мобильный клиент ELTE Neptun от **Nanda** / [Cheterin Group](https://cheterin.online). Тёмный минималистичный Flutter-клиент: Today, календарь, оценки, экзамены и входящие. Язык интерфейса по умолчанию — английский (есть заготовки HU/RU).

> **Не связан с ELTE, Neptun или SDA Informatika.**  
> Karmin — независимый проект Cheterin Group. Университет и операторы Neptun его не поддерживают и не одобряют. Используйте на свой риск. При сомнениях пользуйтесь официальным веб-клиентом.

**Владелец, разработчик, основатель:** Nanda  
- Discord: `nandak070`  
- Telegram: `nanda070`  
- Почта: `turkapahf@gmail.com`  

**Компания:** Cheterin Group  
- Сайт: [https://cheterin.online](https://cheterin.online)

© 2026 Nanda / Cheterin Group · [cheterin.online](https://cheterin.online)

### Возможности (объём v1)

| Область | План |
|---|---|
| Вход | Дисклеймер, логин, **2FA**, PIN, Face ID, блокировка при уходе в фон |
| Today | Следующая пара, экзамен, непрочитанные, GPA |
| Календарь | Неделя / список, фильтры |
| Учёба | Предметы, оценки, запись на экзамен с двойным подтверждением |
| Входящие | Только чтение |
| Настройки | Язык, биометрия, PIN, уведомления, privacy / disclaimer |

**Статус:** Stages 0–3 есть в коде (вход, Today/календарь, учёба/входящие, подтверждение записи на экзамен). Debug — помеченный mock. Живой ELTE 2FA / JSON / запись на экзамен не считаем доказанными без реального аккаунта. Светлая тема — Stage 4; по умолчанию тёмная.

Скриншоты появятся после живого прогона на устройстве. Макеты: [Figma](https://www.figma.com/design/Iuxf0sbisHaOwxn6Vkcgdg).

### Стек

Flutter / Dart · `dio` · Riverpod · go_router · secure storage · local_auth · Fraunces + Plus Jakarta Sans · gen-l10n · JSON-кэш (Isar позже).

### Запуск

```bash
flutter pub get
flutter run
```

**Основной тест — iPhone**, не Android. На Windows IPA не собирается. Бесплатная установка: [docs/IOS_SIDELLOAD.md](docs/IOS_SIDELLOAD.md) (`online.cheterin.karmin`). Android здесь — эмулятор / CI. Live Neptun: `--dart-define=KARMIN_LIVE_AUTH=true` или release IPA.

**Разработчикам:** сначала [DEV.md](DEV.md) (один файл — стек, вход, сборка).

### Лицензия и правовые тексты

- Код: [MIT](LICENSE) — © 2026 Nanda / Cheterin Group — **как есть**
- Дисклеймер: [docs/DISCLAIMER.md](docs/DISCLAIMER.md)
- Конфиденциальность: [docs/PRIVACY.md](docs/PRIVACY.md)
- Сторонние пакеты: [docs/legal/NOTICE.md](docs/legal/NOTICE.md)

Проект **не** имеет разрешения на товарные знаки ELTE / Neptun. Название Neptun используется только как ссылка на систему, к которой подключается клиент.

### Контакты

- **Владелец, разработчик, основатель:** Nanda
  - Discord: `nandak070`
  - Telegram: `nanda070`
  - Почта: `turkapahf@gmail.com`
- **Компания:** Cheterin Group — [https://cheterin.online](https://cheterin.online)
- Вопросы: issues в этом репозитории
