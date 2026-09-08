# Third-party notices

Karmin (© 2026 Nanda / Cheterin Group) depends on open-source software.

**Owner, Developer, Founder:** Nanda · Discord `nandak070` · Telegram `nanda070` · Mail `turkapahf@gmail.com`  
**Company:** Cheterin Group · [cheterin.online](https://cheterin.online)

## Flutter / Dart SDK

Licenses for the Flutter and Dart SDKs, and for packages pulled in via `pubspec.yaml`, are shown in the app through Flutter’s built-in **`showLicensePage`** (Settings → open-source licenses, once that screen ships).

You can also list licenses from a checkout:

```bash
flutter pub licenses
```

## Main direct dependencies (overview)

| Package | Role | Typical license family |
|---|---|---|
| Flutter / Dart SDK | Runtime, widgets, tooling | BSD-style (see SDK NOTICE) |
| `dio` | HTTPS client for Neptun API | MIT |
| `flutter_riverpod` | State management | MIT |
| `go_router` | Navigation | BSD-3-Clause |
| `flutter_secure_storage` | Keystore / Keychain credentials | BSD-3-Clause |
| `local_auth` | Biometrics | BSD-3-Clause |
| `google_fonts` | Inter typeface loading | Apache-2.0 |
| `crypto` | PIN hashing helpers | BSD-3-Clause |
| `intl` / `flutter_localizations` | i18n | BSD-style |

Exact SPDX text and transitive packages can change with `pub get`. Prefer `showLicensePage` or `flutter pub licenses` over this summary when compliance matters.

## Trademarks

“Neptun”, “ELTE”, and related marks belong to their respective owners. Karmin, Nanda, and Cheterin Group claim **no** affiliation or trademark license from those parties. See [DISCLAIMER.md](../DISCLAIMER.md).
