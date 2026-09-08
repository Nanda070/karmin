# iOS on a physical iPhone (free)

**Owner:** Nanda / Cheterin Group. Unofficial; not affiliated with ELTE or Neptun.  
**Bundle ID:** `online.cheterin.karmin`  
**Display name:** Kármin (home screen) / Karmin (short name)  
**Paid Apple Developer Program / TestFlight:** not required.

This Windows machine **cannot** compile an IPA. Apple’s toolchain only runs on macOS. The **primary** path is GitHub Actions (`macos-latest`) + **Sideloadly on Windows**. Borrowing a Mac + Xcode is optional.

Unsigned IPA from Actions (after a successful run):  
`C:\Users\adnan\Documents\Coding\karmin\dist\Karmin-unsigned.ipa`

---

## English

### Prerequisites

| You need | Why |
|---|---|
| Free Apple ID | Sideloadly signs the app. Same ID you use on the iPhone is simplest. |
| Physical iPhone (iOS 16+ recommended) | Simulator is not a live-Neptun test. |
| USB cable | First install and Trust. |
| [Sideloadly](https://sideloadly.io/) on Windows | Resigns the unsigned IPA and installs over USB. |
| This repo on GitHub | Actions builds the IPA on a Mac runner. |

**7-day expiry:** a free Apple ID certificate dies after **7 days**. The icon stays; launch fails until you re-sign with Sideloadly. This is Apple’s free-account limit, not a Karmin bug.

**3-app limit:** a free Apple ID may only have **three** sideloaded apps at once. Remove unused ones in Settings → General → iPhone Storage, or in Sideloadly.

**Developer Mode (iOS 16+):** Settings → Privacy & Security → Developer Mode → On, then restart if asked. Without this, the sideloaded app will not launch.

**Trust the certificate:** after install, Settings → General → VPN & Device Management → trust the developer cert for your Apple ID. Until you do, Kármin will not open.

**2FA:** Apple will email or push a 6-digit code. Sideloadly may also ask for an [app-specific password](https://appleid.apple.com/) (Apple ID → Sign-In and Security → App-Specific Passwords). Do **not** put Apple ID passwords in git or GitHub Actions secrets.

**VPN:** try **without** a VPN first. Campus or aggressive VPNs often break Apple’s signing servers and 2FA.

### Live Neptun vs debug mock

| Build | Neptun |
|---|---|
| `flutter run` **debug** (default) | Labeled **mock** (any non-empty login, any 6-digit OTP). |
| Debug + `--dart-define=KARMIN_LIVE_AUTH=true` | Live `https://neptun.elte.hu/Account/api/` |
| **Release** (the Actions IPA) | Always live. |

Chrome/web stays on the mock (CORS). iPhone does not. Release IPA = real ELTE account + real OTP. Never log password, OTP, or JWT.

### `local_auth` / Face ID / Keychain

- Info.plist has `NSFaceIDUsageDescription`. Face ID unlocks the **local vault**, not Neptun 2FA.
- If Face ID is missing, denied, or flaky on a sideload, the **6-digit PIN** still works.
- `biometricOnly` does **not** fall back to the iPhone passcode (by design).
- Keychain items belong to this bundle ID + the signing Team. Re-signing with the **same** free Apple ID usually keeps the vault. Switching Apple IDs wipes it (log in to Neptun again).
- Free Personal Team does **not** get Push Notifications, Associated Domains, or App Groups. Karmin v1 does not need those.

App Transport Security stays **on**. Neptun is HTTPS. Do not set `NSAllowsArbitraryLoads`.

---

### Primary — Windows: GitHub Actions + Sideloadly

The workflow is `.github/workflows/ios.yml` (**iOS unsigned IPA**). It produces artifact `karmin-ios-unsigned` → `Karmin-unsigned.ipa`. The IPA is **unsigned**; Sideloadly signs it with your Apple ID. The raw zip will not install via Finder.

#### Sideloadly — 5 steps

1. **Get the IPA.** GitHub → **Actions** → **iOS unsigned IPA** → **Run workflow** (10–20 minutes). Download artifact `karmin-ios-unsigned`, or use `C:\Users\adnan\Documents\Coding\karmin\dist\Karmin-unsigned.ipa` if it was already copied there.
2. **Install Sideloadly** from [sideloadly.io](https://sideloadly.io/). Plug in the iPhone with a USB cable. Unlock the phone → **Trust This Computer**.
3. **Developer Mode.** iOS 16+: Settings → Privacy & Security → Developer Mode → On (restart if asked).
4. **Sideload.** IPA = `Karmin-unsigned.ipa`. Apple ID = your free ID. Start the sideload. Complete Apple 2FA (or an app-specific password) when prompted. Use automatic provisioning if Sideloadly shows that option.
5. **Trust the cert, then open Kármin.** Settings → General → VPN & Device Management → trust this Apple ID. Then tap **Kármin**. Re-sideload before day 8 (same 7-day clock). Remember the **3-app** free-account limit.

Public repos can use `macos-latest` within GitHub’s fairness limits. Artifact retention is **7 days** (same order of magnitude as the signing clock).

#### AltStore / SideStore caveats

| Tool | Needs a Mac? | Notes |
|---|---|---|
| **Sideloadly** | No (Windows OK) | Primary no-Mac install. Third-party; you accept that risk. Still 7-day / 3-app. |
| **AltStore** | AltServer on a PC or Mac | Refresh from the computer. Same free-account limits. Still needs an IPA. |
| **SideStore** | Computer once (pairing file) | Can refresh on-device with a VPN/pairing helper. More moving parts. Still 7-day unless you refresh. Still needs an IPA. |

None of these bypass Apple’s free-account 7-day certificate. They only install the IPA.

---

### Optional — Mac + free Apple ID (Xcode)

No $99 program. Use this only if you have a Mac. On this repo, Xcode “eternal loading” is often the **Karmin boot screen** waiting on Keychain/Face ID, or Xcode using a Windows-generated Flutter config. Prefer Sideloadly unless you need a debug `flutter run`.

**Workspace:** `ios/Runner.xcworkspace` (open this, not the `.xcodeproj`).

1. Install **Xcode** from the Mac App Store. Open it once, accept the license, wait until additional components finish.
2. Install Flutter for macOS. In the repo: `flutter pub get` **before** opening Xcode (regenerates `ios/Flutter/Generated.xcconfig`; a Windows checkout has the wrong `FLUTTER_ROOT`).
3. Open **`ios/Runner.xcworkspace`** in Xcode.
4. Select the **Runner** target → **Signing & Capabilities**:
   - Team: your Apple ID → **Personal Team** (Add Account… if needed).
   - Bundle Identifier: `online.cheterin.karmin` (already set).
   - Automatically manage signing: **on**.
5. Plug in the iPhone. Unlock it. **Trust This Computer**. iOS 16+: Developer Mode on.
6. In Xcode’s toolbar, pick the iPhone (not a simulator). Product → Run.
   - Live Neptun from debug: `flutter run --dart-define=KARMIN_LIVE_AUTH=true` with the iPhone selected.
   - Or run Release from Xcode (live Neptun by default).
7. First launch: Settings → General → VPN & Device Management → trust the developer certificate.

Re-sign before day 8: plug in, Run again (or `flutter run`). Same 7-day / 3-app limits as Sideloadly.

---

### Optional paid later (not required)

Apple Developer Program ($99/year) unlocks **TestFlight** and 1-year certificates. Not the v1 testing path.

---

### What this environment cannot do

- Compile `Runner.app` / IPA on Windows.
- Run Xcode here.
- Install onto your iPhone from this agent (you install with Sideloadly).

Smoke on device: [SMOKE.md](SMOKE.md). Prefer a release IPA.

---

## Русский

**Bundle ID:** `online.cheterin.karmin`  
**Имя на Springboard:** Kármin  
Windows **не умеет** собирать IPA. Основной путь: GitHub Actions (`macos-latest`) + **Sideloadly на Windows**. Mac + Xcode — по желанию.

Готовый файл после успешного прогона:  
`C:\Users\adnan\Documents\Coding\karmin\dist\Karmin-unsigned.ipa`

### Что нужно

Бесплатный Apple ID, физический iPhone, кабель USB, [Sideloadly](https://sideloadly.io/). Платный Developer Program **не** обязателен.

**7 дней:** бесплатная подпись истекает через неделю — приложение перестаёт открываться, пока не переподпишете в Sideloadly.

**Лимит 3 приложения** на бесплатный Apple ID.

**Режим разработчика** (iOS 16+): Настройки → Конфиденциальность и безопасность → Режим разработчика.

**Доверие сертификату:** Настройки → Основные → VPN и управление устройством.

**2FA:** код от Apple или [пароль приложения](https://appleid.apple.com/). Пароль Apple ID **не** класть в git и не в секреты Actions.

**VPN:** сначала без VPN — иначе часто ломается подпись и 2FA.

### Live Neptun

- Debug без флага → помеченный mock.
- **Release** / IPA из Actions → живой `https://neptun.elte.hu/Account/api/`.
- Нужны реальный Neptun-код, пароль и одноразовый код. Не логировать секреты.

### Face ID (`local_auth`)

Face ID открывает **локальный** сейф, не 2FA Neptun. Если биометрия на sideload капризничает — остаётся PIN. Смена Apple ID сбрасывает Keychain.

ATS включён (только HTTPS). `NSAllowsArbitraryLoads` не ставить.

### Основной путь — Windows: Actions + Sideloadly (5 шагов)

1. GitHub → Actions → **iOS unsigned IPA** → Run workflow → скачать `Karmin-unsigned.ipa` (или взять файл из `dist\`).
2. Установить Sideloadly, подключить iPhone по USB, Trust This Computer.
3. Включить **Режим разработчика**.
4. Sideloadly: IPA + Apple ID, пройти 2FA, начать установку.
5. Доверить сертификат (VPN и управление устройством), открыть **Kármin**. На 8-й день — Sideloadly снова. Лимит **3 приложения**.

### По желанию — Mac + Xcode

Сначала `flutter pub get` на маке, затем `ios/Runner.xcworkspace`, Personal Team, Developer Mode, Run. «Вечная загрузка» часто бывает экраном boot в приложении (Keychain / Face ID), а не самим Xcode.

TestFlight — только если потом оплатите программу Apple.
