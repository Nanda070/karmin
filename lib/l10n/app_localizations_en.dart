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
}
