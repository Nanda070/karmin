// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Karmin';

  @override
  String get tabToday => 'Ma';

  @override
  String get tabCalendar => 'Naptár';

  @override
  String get tabStudy => 'Tanulás';

  @override
  String get tabInbox => 'Bejövő';

  @override
  String get settingsTitle => 'Beállítások';

  @override
  String get todayPlaceholder => 'Ma — hamarosan';

  @override
  String get calendarPlaceholder => 'Naptár — hamarosan';

  @override
  String get studyPlaceholder => 'Tanulás — hamarosan';

  @override
  String get inboxPlaceholder => 'Bejövő — hamarosan';

  @override
  String get profilePlaceholder => 'Hallgató';

  @override
  String get profileSubtitle =>
      'A profiladatok bejelentkezés után jelennek meg';

  @override
  String get settingsEmptyHint =>
      'A beállítások egy későbbi szakaszban jelennek meg.';

  @override
  String get nextClassLabel => 'Következő óra';

  @override
  String get demoNextClassTitle => 'Analízis II';

  @override
  String get demoNextClassMeta => 'D 3-510 · 12 perc múlva';

  @override
  String get chipExam => 'Vizsga';

  @override
  String get chipMessages => 'Üzenetek';

  @override
  String get chipGpa => 'Átlag';

  @override
  String get demoExamTime => 'Cs 10:00';

  @override
  String get demoMessagesNew => '3 új';

  @override
  String get demoGpa => '4.32';

  @override
  String get calendarWeek => 'Hét';

  @override
  String get calendarList => 'Lista';

  @override
  String get filterClass => 'Óra';

  @override
  String get filterExam => 'Vizsga';

  @override
  String get filterTask => 'Feladat';

  @override
  String get filterOnline => 'Online';

  @override
  String get studySubjects => 'Tárgyak';

  @override
  String get studyCredits => 'Kredit';

  @override
  String get studyUpcomingExam => 'Közelgő vizsga';

  @override
  String get studySignUp => 'Jelentkezés';

  @override
  String get demoCredits => '27 / 30';

  @override
  String get demoSubjectAnalysis => 'Analízis II';

  @override
  String get demoSubjectProgramming => 'Programozás';

  @override
  String get demoSubjectEnglish => 'Angol gyakorlat';

  @override
  String get demoExamLine => 'Diszkrét mat. · Cs 10:00';

  @override
  String inboxNewCount(int count) {
    return '$count új';
  }

  @override
  String get demoInboxRegistrar => 'Tanulmányi Osztály';

  @override
  String get demoInboxRegistrarSubject => 'Vizsgaidőszak ütemterve';

  @override
  String get demoInboxNeptun => 'Neptun';

  @override
  String get demoInboxNeptunSubject => 'Új jegy: Analízis II';

  @override
  String get demoInboxInstructor => 'Oktató · Kovács';

  @override
  String get demoInboxInstructorSubject => 'Konzultáció csütörtökön';

  @override
  String get settingsLanguage => 'Nyelv';

  @override
  String get settingsLanguageValue => 'Magyar';

  @override
  String get settingsFaceId => 'Face ID';

  @override
  String get settingsOn => 'Be';

  @override
  String get settingsPin => 'PIN';

  @override
  String get settingsChange => 'Módosítás';

  @override
  String get settingsNotifications => 'Értesítések';

  @override
  String get settingsNotificationsValue => 'Óra és vizsga';

  @override
  String get settingsSignOut => 'Kijelentkezés';

  @override
  String get demoProfileName => 'Adnan Huseynli';

  @override
  String get demoProfileCode => 'ABC123 · IK / ELTE';

  @override
  String get demoProfileProgram => 'Informatika BSc';

  @override
  String get demoEventAnalysisTime => '8:00–10:00';

  @override
  String get demoEventAnalysisRoom => 'D 3-510';

  @override
  String get demoEventProgrammingTime => '10:15–12:00';

  @override
  String get demoEventProgrammingTitle => 'Programozás';

  @override
  String get demoEventProgrammingRoom => 'Lágymányos 2.502';

  @override
  String get demoEventExamTime => '10:00';

  @override
  String get demoEventExamTitle => 'Vizsga · Diszkrét mat.';

  @override
  String get demoEventExamRoom => 'Trefort';

  @override
  String get todayQuickActions => 'Gyors műveletek';

  @override
  String get todayActionSchedule => 'Órarend';

  @override
  String get todayActionSubjects => 'Tárgyak';

  @override
  String get todayActionInbox => 'Bejövő';

  @override
  String get todaySchedule => 'Mai órarend';

  @override
  String get disclaimerTitle => 'Nem hivatalos kliens';

  @override
  String get disclaimerBody =>
      'A Karmin a Cheterin nem hivatalos terméke. Nem áll kapcsolatban az ELTE-vel vagy a Neptun üzemeltetőjével, és azok nem támogatják.\n\nA Neptun-jelszó a telefon biztonságos tárolójában marad, hogy Face ID-val vagy PIN-nel feloldhasd. Minden új Neptun-munkamenethez egyszeri kód kell e-mailből vagy hitelesítő alkalmazásból. A Karmin nem üzemeltet szervert.\n\nSaját felelősségre használod. Ha az egyetem előírja, használd a hivatalos Neptun webes felületet.';

  @override
  String get disclaimerUnderstand => 'Értem';

  @override
  String get disclaimerOfficialNeptun => 'Hivatalos Neptun';

  @override
  String get loginSubtitle => 'ELTE Neptun';

  @override
  String get loginNeptunCode => 'Neptun kód';

  @override
  String get loginPassword => 'Jelszó';

  @override
  String get loginSignIn => 'Bejelentkezés';

  @override
  String get loginKeystoreHint =>
      'Első belépés. A jelszó a Keystore-ban marad.';

  @override
  String get loginDebugBanner =>
      'Fejlesztői belépés — nem a Neptunhoz kapcsolódik. Bármely nem üres adat, majd bármely 6 számjegyű kód.';

  @override
  String get loginErrorEmpty => 'Add meg a Neptun kódot és a jelszót.';

  @override
  String get loginErrorBadCredentials =>
      'A Neptun elutasította ezeket az adatokat.';

  @override
  String get loginErrorNetwork => 'A Neptun nem elérhető.';

  @override
  String get loginErrorCaptcha =>
      'A Neptun captchát kér. Lépj be egyszer a weben, majd próbáld újra.';

  @override
  String get loginErrorLockout =>
      'Túl sok próbálkozás. Várj egy kicsit, majd próbáld újra.';

  @override
  String get loginErrorUnavailable =>
      'A hallgatói belépés hibát adott. Próbáld újra, vagy lépj be a weben.';

  @override
  String get loginOpenWebsite => 'Neptun weboldal megnyitása';

  @override
  String get otpTitle => 'Ellenőrzés';

  @override
  String get otpSubtitleEmail => 'Add meg az e-mailben kapott egyszeri kódot.';

  @override
  String get otpSubtitleAuthenticator =>
      'Add meg a hitelesítő alkalmazás egyszeri kódját.';

  @override
  String get otpSubtitleUnknown =>
      'Add meg az e-mailben vagy a hitelesítő alkalmazásban kapott kódot.';

  @override
  String get otpAuthenticatorParked =>
      'Ez a verzió csak az e-mailes kódot használja; a hitelesítő alkalmazás ideiglenesen ki van kapcsolva.';

  @override
  String get otpPrefixHint =>
      'Add meg a kötőjel utáni kódot; az előtagot a Neptun tölti ki.';

  @override
  String get otpCodeHint => 'Egyszeri kód';

  @override
  String get otpConfirm => 'Megerősítés';

  @override
  String get otpResend => 'Kód küldése újra';

  @override
  String otpResendWait(int seconds) {
    return 'Újra $seconds mp múlva';
  }

  @override
  String get otpResent => 'Új kódot kértünk.';

  @override
  String get otpError => 'A Neptun elutasította ezt a kódot.';

  @override
  String get todayEmptyNext => 'Nincs következő óra';

  @override
  String get todayEmptySchedule => 'Ma nincs semmi a naptárban.';

  @override
  String get calendarEmpty => 'Nincs megjeleníthető esemény.';

  @override
  String get dataError => 'A Neptun most nem frissíthető.';

  @override
  String get dataCached => 'Az utoljára mentett adatok.';

  @override
  String get dataRetry => 'Újra';

  @override
  String get dataOffline => 'A Neptun nem elérhető.';

  @override
  String pinDotsLabel(int filled, int max) {
    return '$filled / $max számjegy megadva';
  }

  @override
  String get pinBackspace => 'Utolsó számjegy törlése';

  @override
  String pinDigit(String digit) {
    return '$digit';
  }

  @override
  String get loginShowPassword => 'Jelszó megjelenítése';

  @override
  String get loginHidePassword => 'Jelszó elrejtése';

  @override
  String get settingsBack => 'Vissza';

  @override
  String relativeMinutes(int minutes) {
    return '$minutes perc múlva';
  }

  @override
  String get relativeNow => 'most';

  @override
  String get setPinTitle => 'PIN beállítása';

  @override
  String get setPinConfirmTitle => 'PIN megerősítése';

  @override
  String get setPinSubtitle =>
      'Válassz egy 6 jegyű PIN-t a Karmin feloldásához.';

  @override
  String get setPinConfirmSubtitle => 'Add meg még egyszer ugyanazt a PIN-t.';

  @override
  String get setPinMismatch => 'A PIN-ek nem egyeznek. Próbáld újra.';

  @override
  String get setPinEnableBio => 'Feloldás Face ID / ujjlenyomattal';

  @override
  String get unlockTitle => 'Feloldás';

  @override
  String get unlockSubtitle => 'Face ID vagy 6 jegyű PIN';

  @override
  String get unlockSubtitlePinOnly => 'Add meg a 6 jegyű PIN-t';

  @override
  String get unlockSignOut => 'Kijelentkezés';

  @override
  String get unlockWrongPin => 'Hibás PIN';

  @override
  String unlockLocked(int seconds) {
    return 'Túl sok próbálkozás. Újra $seconds mp múlva.';
  }

  @override
  String get unlockUseBiometrics => 'Face ID használata';

  @override
  String get unlockBiometricReason => 'Karmin feloldása';

  @override
  String get settingsTheme => 'Téma';

  @override
  String get settingsThemeDark => 'Sötét';

  @override
  String get settingsThemeLight => 'Világos';

  @override
  String get settingsThemeSystem => 'Rendszer';

  @override
  String get settingsThemeHint => 'Sötét, világos, vagy a rendszer szerint.';

  @override
  String get settingsOff => 'Ki';

  @override
  String get settingsFaceIdUnavailable => 'Nem elérhető';

  @override
  String get studyEmpty => 'Ehhez a félévhez még nincsenek tárgyak.';

  @override
  String get inboxEmpty => 'Nincs üzenet.';

  @override
  String get inboxYesterday => 'Tegnap';

  @override
  String get studyConfirm => 'Megerősítés';

  @override
  String get studyCancel => 'Mégse';

  @override
  String get studyAlreadySigned => 'Jelentkezve';

  @override
  String get studySignUpUnavailable =>
      'Jelentkezés a hivatalos Neptunban — az ELTE payload még nincs megerősítve.';

  @override
  String studySignUpConfirmTitle(String exam) {
    return 'Jelentkezés: $exam?';
  }

  @override
  String studySignUpConfirmBody(String date) {
    return 'Ez a Neptunban jelentkeztet a vizsgára ekkor: $date. Még visszavonhatod.';
  }

  @override
  String get subjectCode => 'Kód';

  @override
  String get subjectExams => 'Vizsgák';

  @override
  String get subjectEmptyExams => 'Ehhez a tárgyhoz nincs listázott vizsga.';

  @override
  String get inboxThreadEmpty => 'Nincs bejegyzés ebben a szálban.';
}
