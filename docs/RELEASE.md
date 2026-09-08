# Release (stub — Stage 0)

**Owner:** Nanda / Cheterin Group. Unofficial; not affiliated with ELTE or Neptun.

- Version: `pubspec` `0.1.0+1` — bump build number every IPA / APK.
- **Primary tester device: iPhone.** iOS bundle ID: `online.cheterin.karmin`. Display name: Kármin.
- Free v1 path (no $99 Apple program): Mac + Xcode Personal Team, **or** GitHub Actions unsigned IPA + Sideloadly / AltStore / SideStore. Step-by-step: [IOS_SIDELLOAD.md](IOS_SIDELLOAD.md). Re-sign every **7 days** on a free Apple ID.
- Windows cannot compile an IPA. Android on this machine: debug APK / optional emulator — [ANDROID_BUILD.md](ANDROID_BUILD.md).
- TestFlight is **optional later** (paid Apple Developer Program). It is not required to test on a physical iPhone. No public App Store / Play Store in v1.
- Signing secrets **not in git**. No auto-update server. Testers install a new build.

Smoke checklist: [SMOKE.md](SMOKE.md) and [PLAN.md](PLAN.md) §13 (Stage 4).
