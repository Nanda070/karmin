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
- «Отправить код ещё раз» = тот же `POST /Account/Login2FA` (E-mail code / `Phase=RequestEmail` / `Provider=Email`), не повтор пароля и не GET; пауза 30 с; ошибка, если письмо не ушло
- Если письмо не ушло при логине — всё равно открываем Verification (не оставляем на Login), чтобы можно было нажать Send code again
- Debug — помеченный mock (любой логин и любой 6-значный код)
- Live: `KARMIN_LIVE_AUTH` на устройстве; Chrome режет Neptun из‑за CORS
- Если Keychain или Face ID зависают при старте — выходим из boot, а не крутим вечно
- iOS логин больше не показывает «Can't reach Neptun» из‑за падения Dio на Content-Type; эта строка только timeout / DNS / TLS

### 2FA

- Сначала JSON `Account/Authenticate`; если ELTE не отдаёт `/ujhallgato/api/` — MVC `POST /Account/Login` → **`POST /Account/Login2FA` с E-mail code** (`Phase=RequestEmail` и/или `Provider=Email`) — пароль сам по себе письмо не шлёт
- Пустой HTTP 400 больше не считается «неверным паролем»
- Код из почты: префикс с сервера (`732-`) + хвост, который вводит студент
- Authenticator / TOTP временно отключён — после пароля форсируем email-провайдер, даже если в аккаунте по умолчанию authenticator
- Кнопка E-mail code на Potlap часто `type="button"` + `data-setval` — больше не пропускаем; 302 после пароля/send-email follow’им до HTML с префиксом
- Живой ELTE 2FA на реальном аккаунте ещё не доказан

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
