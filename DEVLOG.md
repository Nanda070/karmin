# Karmin — журнал разработки

Неофициальный мобильный клиент ELTE Neptun. Владелец — **Nanda**, компания — **Cheterin Group** ([cheterin.online](https://cheterin.online)). Не связан с ELTE, Neptun или SDA Informatika.

Живой вход на устройстве ещё проверяется. Debug без флага — помеченный mock.

## 8 сентября 2026 г.

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
- По образцу [zoligamer/Neptun-Mobile-fork](https://github.com/zoligamer/Neptun-Mobile-fork): сначала `POST /Account/api/Account/Authenticate`, 2FA = тот же URL с `token` (6 цифр из Microsoft Authenticator). Письмо **не** обязательный шаг
- MVC fallback: Login2FA; TOTP primary; опционально `GetEmail=true`; ошибка «письмо не ушло» больше не блокирует вход при authenticator
- Debug — помеченный mock (любой логин и любой 6-значный код)
- Live: `KARMIN_LIVE_AUTH` на устройстве; Chrome режет Neptun из‑за CORS
- Если Keychain или Face ID зависают при старте — выходим из boot, а не крутим вечно
- iOS логин больше не показывает «Can't reach Neptun» из‑за падения Dio на Content-Type; эта строка только timeout / DNS / TLS

### 2FA

- Primary: JSON Authenticate (`/Account/api/…`) + authenticator `token` (как Neptun-Mobile-fork)
- **Fix «Neptun rejected code»:** Authenticator OTP больше не склеивается с email-префиксом `732-`; JSON `token` = только 6 цифр
- MVC fallback после пароля **не** шлёт `GetEmail` сам (fork); письмо только по «Send code again». TOTP игнорирует загрязнённый `RequestEmailCode` phase
- Fallback MVC verify: `RequestTOTP` + `TOTPCode`; email только после явного `GetEmail=true` с `CodePrefix`
- Пустой HTTP 400 на `ujhallgato` больше не считается «неверным паролем»
- Authenticator снова включён (раньше был parked ради отладки email)
- Живой ELTE 2FA на реальном аккаунте проверяется новой IPA после этого фикса

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
