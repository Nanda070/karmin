# iOS on a physical iPhone (free)

**Bundle ID:** `online.cheterin.karmin`  
**Display name:** Kármin (home screen) / Karmin (short name)  
**Workspace:** `ios/Runner.xcworkspace` (open this, not the `.xcodeproj`)  
**Paid Apple Developer Program / TestFlight:** not required. Optional later if you pay $99/year.

This Windows machine **cannot** compile an IPA. Apple’s toolchain only runs on macOS. Use **path A** (borrow/own a Mac + free Apple ID) or **path B** (GitHub Actions on `macos-latest` + Sideloadly on Windows).

---

## English

### Prerequisites

| You need | Why |
|---|---|
| Free Apple ID | Signs the app. Same ID you use on the iPhone is simplest. |
| Physical iPhone (iOS 16+ recommended) | Simulator is not a live-Neptun test. |
| USB cable | First install and Trust. |
| This repo on GitHub | Needed for the free Actions build (path B). |

**7-day expiry:** a free “Personal Team” certificate dies after **7 days**. The icon stays; launch fails until you re-sign. This is Apple’s free-account limit, not a Karmin bug.

**3-app limit:** a free Apple ID may only have **three** sideloaded apps at once. Remove unused ones in Settings → General → iPhone Storage, or in Xcode / Sideloadly.

**2FA:** Apple will email or push a 6-digit code. Sideloadly / AltStore may also ask for an [app-specific password](https://appleid.apple.com/) (Apple ID → Sign-In and Security → App-Specific Passwords). Do **not** put Apple ID passwords in git or GitHub Actions secrets for this free path.

**VPN:** try **without** a VPN first. Campus or aggressive VPNs often break Apple’s signing servers and 2FA. If the Apple ID region and the network disagree, 2FA SMS/email can stall.

### Live Neptun vs debug mock

| Build | Neptun |
|---|---|
| `flutter run` **debug** (default) | Labeled **mock** (any non-empty login, any 6-digit OTP). |
| Debug + `--dart-define=KARMIN_LIVE_AUTH=true` | Live `https://neptun.elte.hu/ujhallgato/api/` |
| **Release** (Xcode Run in Release, or the Actions IPA) | Always live. |

Chrome/web stays on the mock (CORS). iPhone does not. Release IPA = real ELTE account + real OTP. Never log password, OTP, or JWT.

### `local_auth` / Face ID / Keychain

- Info.plist has `NSFaceIDUsageDescription`. Face ID unlocks the **local vault**, not Neptun 2FA.
- If Face ID is missing, denied, or flaky on a sideload, the **6-digit PIN** still works.
- `biometricOnly` does **not** fall back to the iPhone passcode (by design).
- Keychain items belong to this bundle ID + the signing Team. Re-signing with the **same** free Apple ID usually keeps the vault. Switching Apple IDs wipes it (log in to Neptun again).
- Free Personal Team does **not** get Push Notifications, Associated Domains, or App Groups. Karmin v1 does not need those.
- Simulator Face ID is fake (`Features → Face ID`). Use a device for the real sheet.

App Transport Security stays **on**. Neptun is HTTPS. Do not set `NSAllowsArbitraryLoads`.

---

### Path A — Mac + free Apple ID (best if you can borrow a Mac)

No $99 program. Xcode **Automatic signing** with your Personal Team.

1. Install **Xcode** from the Mac App Store. Open it once, accept the license, wait until additional components finish.
2. Install Flutter for macOS. In the repo: `flutter pub get`.
3. Open **`ios/Runner.xcworkspace`** in Xcode (never `Runner.xcodeproj` alone).
4. Select the **Runner** target → **Signing & Capabilities**:
   - Team: your Apple ID → **Personal Team** (Add Account… if needed).
   - Bundle Identifier: `online.cheterin.karmin` (already set).
   - Automatically manage signing: **on**.
5. Plug in the iPhone. Unlock it. On the phone: **Trust This Computer**.
6. iOS 16+: **Settings → Privacy & Security → Developer Mode → On**, then restart if asked.
7. In Xcode’s toolbar, pick the iPhone (not a simulator).
8. Product → Run (or the Play button).
   - Live Neptun from debug:  
     `flutter run --dart-define=KARMIN_LIVE_AUTH=true` from Terminal, with the iPhone selected (`flutter devices`).
   - Or run Release from Xcode (live Neptun by default).
9. First launch: Settings → General → VPN & Device Management → trust the developer certificate.

Re-sign before day 8: plug in, Run again (or `flutter run`). Same 7-day clock.

---

### Path B — no Mac: GitHub Actions + Sideloadly (Windows)

This is the free path that **actually produces an IPA** without owning a Mac. You still need an IPA; Actions builds it on `macos-latest`. Sideloadly (Windows) signs it with a free Apple ID and installs over USB.

The workflow file is `.github/workflows/ios.yml`. **GitHub will not run it until that file is on the default branch.** This checkout leaves it in the working tree; push when you are ready (the agent does not commit unless you ask).

1. Push `ios/` + `.github/workflows/ios.yml` to [github.com/Nanda070/karmin](https://github.com/Nanda070/karmin).
2. GitHub → **Actions** → **iOS unsigned IPA** → **Run workflow**. Public repos can use `macos-latest` for free within GitHub’s fairness limits. Expect 10–20 minutes.
3. Download the artifact `karmin-ios-unsigned` (`Karmin-unsigned.ipa`). Artifact retention is **7 days** (same order of magnitude as the signing clock).
4. On Windows, install [Sideloadly](https://sideloadly.io/). Plug in the iPhone. Trust the computer. Enable Developer Mode (iOS 16+).
5. Sideloadly: IPA = the artifact, Apple ID = free ID, start sideload. Use automatic provisioning if the extra options show it. Complete Apple 2FA when prompted.
6. On the iPhone, trust the developer cert (VPN & Device Management), then open **Kármin**.

The IPA is **unsigned**. Sideloadly (or AltStore / SideStore) signs it locally. Do not expect the raw zip to install via Finder.

#### AltStore / SideStore caveats

| Tool | Needs a Mac? | Notes |
|---|---|---|
| **Sideloadly** | No (Windows OK) | Most practical no-Mac install. Third-party; you accept that risk. Still 7-day / 3-app. |
| **AltStore** | AltServer on a PC or Mac | Refresh from the computer (or via AltStore’s own refresh). Same free-account limits. Still needs an IPA. |
| **SideStore** | Computer once (pairing file) | Can refresh on-device with a VPN/pairing helper. More moving parts. Still 7-day signing unless you refresh. Still needs an IPA. |

None of these bypass Apple’s free-account 7-day certificate. They only install the IPA.

---

### Optional paid later (not required)

Apple Developer Program ($99/year) unlocks **TestFlight** and 1-year certificates. Not the v1 testing path. Do not treat TestFlight as the only way onto an iPhone.

---

### What this environment cannot do

- Compile `Runner.app` / IPA on Windows.
- Run Xcode here.
- Install onto your iPhone from this agent.

After you push the workflow, run it on GitHub, or borrow a Mac for path A.

Smoke on device: [SMOKE.md](SMOKE.md). Prefer `KARMIN_LIVE_AUTH=true` or a release IPA.

---

## Русский

**Bundle ID:** `online.cheterin.karmin`  
**Имя на Springboard:** Kármin  
Windows **не умеет** собирать IPA. Нужен Mac (свой/чужой) или GitHub Actions (`macos-latest`).

### Что нужно

Бесплатный Apple ID, физический iPhone, кабель USB. Платный Developer Program **не** обязателен.

**7 дней:** бесплатная подпись Personal Team истекает через неделю — приложение перестаёт открываться, пока не переподпишете.

**Лимит 3 приложения** на бесплатный Apple ID.

**2FA:** код от Apple или [пароль приложения](https://appleid.apple.com/). Пароль Apple ID **не** класть в git и не в секреты Actions на этом бесплатном пути.

**VPN:** сначала без VPN — иначе часто ломается подпись и 2FA.

### Live Neptun

- Debug без флага → помеченный mock.
- Debug с `--dart-define=KARMIN_LIVE_AUTH=true` или **Release** / IPA из Actions → живой `https://neptun.elte.hu/ujhallgato/api/`.
- Нужны реальный Neptun-код, пароль и одноразовый код. Не логировать секреты.

### Face ID (`local_auth`)

Face ID открывает **локальный** сейф, не 2FA Neptun. Если биометрия на sideload капризничает — остаётся PIN. Смена Apple ID сбрасывает Keychain.

ATS включён (только HTTPS). `NSAllowsArbitraryLoads` не ставить.

### Путь A — Mac + бесплатный Apple ID

1. Xcode из App Store, лицензия, компоненты.
2. Открыть **`ios/Runner.xcworkspace`**.
3. Runner → Signing: Team = Personal Team, bundle `online.cheterin.karmin`, Automatically manage signing.
4. Кабель → Trust → **Режим разработчика** (iOS 16+: Настройки → Конфиденциальность и безопасность).
5. Run на iPhone. Для живого API из debug: `flutter run --dart-define=KARMIN_LIVE_AUTH=true`.
6. Доверить сертификат: Настройки → Основные → VPN и управление устройством.
7. На 8-й день — Run / sideload снова.

### Путь B — без Mac: Actions + Sideloadly

1. Запушить `ios/` и `.github/workflows/ios.yml` (пока файлы только в рабочей копии).
2. GitHub → Actions → **iOS unsigned IPA** → Run workflow → скачать `Karmin-unsigned.ipa`.
3. [Sideloadly](https://sideloadly.io/) на Windows: IPA + Apple ID + USB. AltStore / SideStore тоже могут поставить IPA, но им всё равно нужен файл и действуют те же 7 дней / 3 приложения.

TestFlight — только если потом оплатите программу Apple. Для проверки на iPhone это не единственный и не обязательный путь.

### Блокер этой среды

Собрать IPA здесь нельзя. После пуша workflow — собрать на GitHub; либо взять Mac для пути A.
