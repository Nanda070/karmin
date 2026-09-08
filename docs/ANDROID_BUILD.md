# Android on Windows (emulator / local APK)

**Application ID:** `online.cheterin.karmin`  
**Display name:** Karmin  
**Testers:** physical **iPhone** ([IOS_SIDELLOAD.md](IOS_SIDELLOAD.md)). There is **no** Android phone in this project. Do not sideload the APK onto a device. Verify Android by building an APK on this machine and, optionally, running the emulator.

---

## Toolchain on this machine (user-level)

| Piece | Path |
|---|---|
| Flutter 3.47.2 | `C:\Users\adnan\sdk\flutter` |
| Microsoft OpenJDK 17 | `C:\Users\adnan\sdk\jdk-17` |
| Android SDK | `C:\Users\adnan\sdk\android` |

User environment (already set): `JAVA_HOME`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`. Flutter: `flutter config --android-sdk` + `--jdk-dir` pointing at those folders.

Open a **new** terminal after first install so PATH picks up `platform-tools` / JDK.

```powershell
flutter doctor
# Android toolchain should be OK. Visual Studio (Windows desktop) is unrelated.
```

Licenses: `flutter doctor --android-licenses` (answer `y`).

---

## Build a debug APK

From the repo root:

```powershell
flutter pub get
flutter build apk --debug
```

Output:

`build\app\outputs\flutter-apk\app-debug.apk`

That is enough to prove the Android tree compiles. `assembleDebug` is the Gradle task Flutter runs.

Live Neptun (same as iOS): `--dart-define=KARMIN_LIVE_AUTH=true`. Default debug is the labeled mock.

---

## Optional: emulator (no phone)

APK build does **not** need an emulator. To run the UI on Windows:

1. Enable **Windows Hypervisor Platform** (and Virtualization in BIOS).  
2. Install the emulator + a system image (large download):

```powershell
sdkmanager --sdk_root=$env:ANDROID_HOME "emulator" "system-images;android-36;google_apis;x86_64"
avdmanager create avd -n karmin_api36 -k "system-images;android-36;google_apis;x86_64" -d pixel_7
emulator -avd karmin_api36
```

3. In another terminal:

```powershell
flutter devices          # should list the emulator
flutter run              # debug mock
# or: flutter run --dart-define=KARMIN_LIVE_AUTH=true
```

If `flutter devices` has no emulator, the AVD is not running or WHPX is off.

---

## What the Android tree includes

- Kotlin `MainActivity` as `FlutterFragmentActivity` (`local_auth`).
- MethodChannel `karmin/secure_flag` → `setSecure` toggles `FLAG_SECURE` (Login / OTP / PIN / Unlock).
- `android:allowBackup="false"` plus backup / data-extraction exclude rules.
- Biometric permissions for the local lock.

Do not commit `android/local.properties` machine paths, keystores, or `android/key.properties`.
