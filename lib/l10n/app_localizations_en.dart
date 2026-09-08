// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Karmin';

  @override
  String get tabToday => 'Today';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabStudy => 'Study';

  @override
  String get tabInbox => 'Inbox';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get todayPlaceholder => 'Today — content coming soon';

  @override
  String get calendarPlaceholder => 'Calendar — content coming soon';

  @override
  String get studyPlaceholder => 'Study — content coming soon';

  @override
  String get inboxPlaceholder => 'Inbox — content coming soon';

  @override
  String get profilePlaceholder => 'Student';

  @override
  String get profileSubtitle => 'Profile details will appear after sign-in';

  @override
  String get settingsEmptyHint =>
      'Preferences will appear here in a later stage.';

  @override
  String get nextClassLabel => 'Next class';

  @override
  String get demoNextClassTitle => 'Analysis II';

  @override
  String get demoNextClassMeta => 'D 3-510 · in 12 min';

  @override
  String get chipExam => 'Exam';

  @override
  String get chipMessages => 'Messages';

  @override
  String get chipGpa => 'GPA';

  @override
  String get demoExamTime => 'Thu 10:00';

  @override
  String get demoMessagesNew => '3 new';

  @override
  String get demoGpa => '4.32';

  @override
  String get calendarWeek => 'Week';

  @override
  String get calendarList => 'List';

  @override
  String get filterClass => 'Class';

  @override
  String get filterExam => 'Exam';

  @override
  String get filterTask => 'Task';

  @override
  String get filterOnline => 'Online';

  @override
  String get studySubjects => 'Subjects';

  @override
  String get studyCredits => 'Credits';

  @override
  String get studyUpcomingExam => 'Upcoming exam';

  @override
  String get studySignUp => 'Sign up';

  @override
  String get demoCredits => '27 / 30';

  @override
  String get demoSubjectAnalysis => 'Analysis II';

  @override
  String get demoSubjectProgramming => 'Programming';

  @override
  String get demoSubjectEnglish => 'English practice';

  @override
  String get demoExamLine => 'Discrete math · Thu 10:00';

  @override
  String inboxNewCount(int count) {
    return '$count new';
  }

  @override
  String get demoInboxRegistrar => 'Registrar';

  @override
  String get demoInboxRegistrarSubject => 'Exam period schedule';

  @override
  String get demoInboxNeptun => 'Neptun';

  @override
  String get demoInboxNeptunSubject => 'New grade: Analysis II';

  @override
  String get demoInboxInstructor => 'Instructor · Kovacs';

  @override
  String get demoInboxInstructorSubject => 'Consultation on Thursday';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageValue => 'English';

  @override
  String get settingsFaceId => 'Face ID';

  @override
  String get settingsOn => 'On';

  @override
  String get settingsPin => 'PIN';

  @override
  String get settingsChange => 'Change';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsValue => 'Class & exam';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get demoProfileName => 'Adnan Huseynli';

  @override
  String get demoProfileCode => 'ABC123 · IK / ELTE';

  @override
  String get demoProfileProgram => 'Computer Science BSc';

  @override
  String get demoEventAnalysisTime => '8:00–10:00';

  @override
  String get demoEventAnalysisRoom => 'D 3-510';

  @override
  String get demoEventProgrammingTime => '10:15–12:00';

  @override
  String get demoEventProgrammingTitle => 'Programming';

  @override
  String get demoEventProgrammingRoom => 'Lágymányos 2.502';

  @override
  String get demoEventExamTime => '10:00';

  @override
  String get demoEventExamTitle => 'Exam · Discrete math';

  @override
  String get demoEventExamRoom => 'Trefort';

  @override
  String get todayQuickActions => 'Quick actions';

  @override
  String get todayActionSchedule => 'Schedule';

  @override
  String get todayActionSubjects => 'Subjects';

  @override
  String get todayActionInbox => 'Inbox';

  @override
  String get todaySchedule => 'Today\'s schedule';

  @override
  String get disclaimerTitle => 'Unofficial client';

  @override
  String get disclaimerBody =>
      'Karmin is an unofficial product by Cheterin. It is not affiliated with, endorsed by, or supported by Eötvös Loránd University or the operator of Neptun.\n\nYour Neptun password is stored in this phone’s secure hardware-backed store so you can unlock Karmin with Face ID or a PIN. Every new Neptun session still requires a one-time code from your email or authenticator app. Karmin does not run a server. ELTE and Neptun remain responsible for the data they hold.\n\nYou use Karmin at your own risk. Prefer the official Neptun website when university rules require it.';

  @override
  String get disclaimerUnderstand => 'I understand';

  @override
  String get disclaimerOfficialNeptun => 'Official Neptun';

  @override
  String get loginSubtitle => 'ELTE Neptun';

  @override
  String get loginNeptunCode => 'Neptun code';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginKeystoreHint =>
      'First sign-in. Password is stored in Keystore.';

  @override
  String get loginDebugBanner =>
      'Development login — not talking to Neptun. Any non-empty credentials, then any 6-digit code.';

  @override
  String get loginErrorEmpty => 'Enter your Neptun code and password.';

  @override
  String get loginErrorBadCredentials => 'Neptun rejected these credentials.';

  @override
  String get loginErrorNetwork => 'Can\'t reach Neptun.';

  @override
  String get loginErrorCaptcha =>
      'Neptun wants a captcha. Sign in once on the website, then retry.';

  @override
  String get loginOpenWebsite => 'Open Neptun website';

  @override
  String get otpTitle => 'Verification';

  @override
  String get otpSubtitleEmail => 'Enter the one-time code from your email.';

  @override
  String get otpSubtitleAuthenticator =>
      'Enter the one-time code from your authenticator app.';

  @override
  String get otpSubtitleUnknown =>
      'Enter the one-time code from your email or authenticator app.';

  @override
  String get otpCodeHint => 'One-time code';

  @override
  String get otpConfirm => 'Confirm';

  @override
  String get otpResend => 'Send code again';

  @override
  String otpResendWait(int seconds) {
    return 'Send again in ${seconds}s';
  }

  @override
  String get otpResent => 'A new code was requested.';

  @override
  String get otpError => 'Neptun rejected this code.';

  @override
  String get todayEmptyNext => 'No upcoming class';

  @override
  String get todayEmptySchedule => 'Nothing on the schedule today.';

  @override
  String get calendarEmpty => 'No events to show.';

  @override
  String get dataError => 'Can\'t refresh from Neptun.';

  @override
  String get dataCached => 'Showing last saved data.';

  @override
  String relativeMinutes(int minutes) {
    return 'in $minutes min';
  }

  @override
  String get relativeNow => 'now';

  @override
  String get setPinTitle => 'Set PIN';

  @override
  String get setPinConfirmTitle => 'Confirm PIN';

  @override
  String get setPinSubtitle =>
      'Choose a 6-digit PIN to unlock Karmin on this device.';

  @override
  String get setPinConfirmSubtitle => 'Enter the same PIN again.';

  @override
  String get setPinMismatch => 'PINs did not match. Try again.';

  @override
  String get setPinEnableBio => 'Unlock with Face ID / fingerprint';

  @override
  String get unlockTitle => 'Unlock';

  @override
  String get unlockSubtitle => 'Face ID or 6-digit PIN';

  @override
  String get unlockSubtitlePinOnly => 'Enter your 6-digit PIN';

  @override
  String get unlockSignOut => 'Sign out';

  @override
  String get unlockWrongPin => 'Wrong PIN';

  @override
  String unlockLocked(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s.';
  }

  @override
  String get unlockUseBiometrics => 'Use Face ID';

  @override
  String get unlockBiometricReason => 'Unlock Karmin';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeHint => 'Light look comes in a later polish pass.';

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsFaceIdUnavailable => 'Unavailable';

  @override
  String get studyEmpty => 'No subjects for this term yet.';

  @override
  String get inboxEmpty => 'No messages.';

  @override
  String get inboxYesterday => 'Yesterday';

  @override
  String get studyConfirm => 'Confirm';

  @override
  String get studyCancel => 'Cancel';

  @override
  String get studyAlreadySigned => 'Registered';

  @override
  String get studySignUpUnavailable =>
      'Sign up in official Neptun — ELTE payload not confirmed yet.';

  @override
  String studySignUpConfirmTitle(String exam) {
    return 'Sign up for $exam?';
  }

  @override
  String studySignUpConfirmBody(String date) {
    return 'This will register you in Neptun for this exam on $date. You can still cancel.';
  }

  @override
  String get subjectCode => 'Code';

  @override
  String get subjectExams => 'Exams';

  @override
  String get subjectEmptyExams => 'No exams listed for this subject.';

  @override
  String get inboxThreadEmpty => 'No posts in this thread.';
}
