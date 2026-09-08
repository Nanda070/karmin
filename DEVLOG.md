# Karmin — журнал разработки

Неофициальный мобильный клиент ELTE Neptun. Владелец — **Nanda**, компания — **Cheterin Group** ([cheterin.online](https://cheterin.online)). Не связан с ELTE, Neptun или SDA Informatika.

Живой вход на устройстве ещё проверяется. Debug без флага — помеченный mock.

## 8 сентября 2026 г.

### Auth / 2FA (fork 1:1)

- **Deep compare** с [zoligamer/Neptun-Mobile-fork](https://github.com/zoligamer/Neptun-Mobile-fork) `api_coms.dart` `_tryModernLogin` / `submitTwoFactorCode`
- ELTE live: **только** fork Authenticate для пароля и OTP (без MVC mix). Body: `userName`, `password`, `captcha:""`, `captchaIdentifier:""`, `token`, `LCID:1038`. Заголовки Authenticate = только `Content-Type: application/json` (+ `devicecookie`)
- Сохраняем/шлём fork `devicecookie-<base64(UPPER)>` между password и token шагами
- OTP ошибка больше не opaque: `Neptun rejected this code (HTTP 400)` (+ текст Neptun). HTML/maintenance → отдельные исключения, не OTP
- IPA `0.1.0+5`

### API / live data

- **Fix «Neptun rejected this code» после смены baseUrl на Account/api:** Authenticate только absolute `https://neptun.elte.hu/Account/api/Account/Authenticate` (`institute` + `/api/Account/Authenticate`, `dio.postUri` — без merge с student `baseUrl`). Опасный вариант `baseUrl + api/Account/…` дал бы `/api/api/…`. Bearer на Authenticate снимается; student GET остаются на `…/Account/api/`
- **Fix «Can't refresh from Neptun» после успешного Authenticator-логина:** `NeptunClient.baseUrl` сменён с мёртвого `ujhallgato/api` на fork-хост `https://neptun.elte.hu/Account/api/` (как Neptun-Mobile-fork). Календарь / сообщения / предметы идут туда же с реальным JWT
- Placeholder MVC `elte-portal-session` больше не уходит как Bearer и не провоцирует OTP; честный баннер про web-login vs JSON
- Soft-fail опциональных dashboard GET; HTML/maintenance → понятное сообщение
- IPA `0.1.0+4` (superseded by `+5` after fork header/cookie align)

### UI

- Тёмная luxury-тема по умолчанию: чернила, navy, carmine; Fraunces + Plus Jakarta Sans
- Четыре вкладки: Today, календарь, учёба, входящие; настройки с шестерёнки
- Today: следующая пара, чип экзамена, непрочитанные, GPA
- Календарь: неделя / список, фильтры (пара, экзамен, задание, онлайн)
- Светлая тема — cream paper `#F4EFE6`, не Material-белый; в Настройках System / Dark / Light
- Пустые состояния, ошибки и «последний кэш»; Semantics, крупные зоны нажатия
- Язык интерфейса по умолчанию — английский; заготовки HU / RU

### Auth

- Цепочка: дисклеймер → логин → 2FA → PIN → Today
- 2FA на **каждый** новый вход в Neptun; PIN и Face ID открывают только локальный сейф
- Пароль в Keystore / Keychain; JWT только в RAM
- По образцу [zoligamer/Neptun-Mobile-fork](https://github.com/zoligamer/Neptun-Mobile-fork): `POST /Account/api/Account/Authenticate` + тот же URL с `token` (6 цифр). Письмо **не** обязательный шаг
- ELTE live: **без** MVC fallback на password/OTP (раньше mix каналов ломал OTP). Email resend по-прежнему через Login2FA
- Debug — помеченный mock (любой логин и любой 6-значный код)
- Live: `KARMIN_LIVE_AUTH` на устройстве; Chrome режет Neptun из‑за CORS
- Если Keychain или Face ID зависают при старте — выходим из boot, а не крутим вечно
- iOS логин больше не показывает «Can't reach Neptun» из‑за падения Dio на Content-Type; эта строка только timeout / DNS / TLS

### 2FA

- Primary: JSON Authenticate (`/Account/api/…`) + authenticator `token` (как Neptun-Mobile-fork) — **единственный** канал password+OTP на ELTE live
- **Fix «Neptun rejected code» again (fork deep compare):** strip Accept/Origin/Referer/XHR/UA on Authenticate; force `LCID:1038`; resend `devicecookie`; no MVC mix; OTP errors include `HTTP <status>` (+ Neptun text). IPA `0.1.0+5`
- **Fix «Neptun rejected code» (6 causes, earlier):** (1) stale email `_otpPrefix` cleared when session is TOTP; (2) ~~relative Authenticate → MVC~~ superseded by Authenticate-only; (3) empty digits → immediate reject; (4) OTP field length limit always 8; (5) always GET Login2FA before verify POST (email path); (6) `_sessionSupportsTotp` also matches authcode / verificationcode / authenticator in HTML
- **Fix JSON 2FA session state:** `_jsonTwoFactorPending` больше не сбрасывается в начале каждого `submitPassword` (unlock / 401 re-login / failed re-auth не убивают fork `token` path). Флаг = true после JSON 202; false после JWT / `NeptunAuthApi.reset()`. `signOut` вызывает `reset()` (portal cookies + pending + device cookie)
- Authenticator OTP больше не склеивается с email-префиксом `732-`; JSON `token` = только 6 цифр
- Email только по «Send code again» (`GetEmail=true`)
- Пустой HTTP 400 на Authenticate = unavailable, не «неверный пароль»
- Живой ELTE 2FA на устройстве: IPA `0.1.0+5` после fork header/cookie align

### API

- Stage 1–3 в коде: вход, календарь / GPA / кредиты / непрочитанные, предметы, оценки, входящие
- JSON-кэш на устройстве (Isar отложен)
- Запись на экзамен — двойное подтверждение; тело запроса на живом ELTE не проверено
- Входящие только чтение + пометить прочитанным; профиль из `UserInfo`, иначе «Student» и код
- «Can't reach Neptun» — только если нет HTTP-ответа (timeout / DNS / TLS); ответы ELTE — credentials / captcha / OTP / request failed

### iOS

- Проект Xcode, bundle `online.cheterin.karmin`, имя на домашнем экране — Kármin
- Unsigned IPA через GitHub Actions + Sideloadly на Windows (бесплатный Apple ID)
- Сертификат на 7 дней, лимит трёх приложений — ограничение Apple, не баг Karmin
- Основной тест — физический iPhone; IPA на Windows не собирается

### Android

- Gradle собран: debug APK собирается на Windows
- Физического Android-телефона нет; эмулятор / CI, не sideload на чужое устройство

### Документы

- MIT, двуязычный README, дисклеймер и privacy
- Автор и основатель — Nanda; компания — Cheterin Group
- Stage 0–4 polish в коде; Figma light-кадры, локальные уведомления и TestFlight — не в этом дне
