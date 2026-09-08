// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Karmin';

  @override
  String get tabToday => 'Сегодня';

  @override
  String get tabCalendar => 'Календарь';

  @override
  String get tabStudy => 'Учёба';

  @override
  String get tabInbox => 'Входящие';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get todayPlaceholder => 'Сегодня — скоро';

  @override
  String get calendarPlaceholder => 'Календарь — скоро';

  @override
  String get studyPlaceholder => 'Учёба — скоро';

  @override
  String get inboxPlaceholder => 'Входящие — скоро';

  @override
  String get profilePlaceholder => 'Студент';

  @override
  String get profileSubtitle => 'Данные профиля появятся после входа';

  @override
  String get settingsEmptyHint => 'Настройки появятся на следующем этапе.';

  @override
  String get nextClassLabel => 'Следующая пара';

  @override
  String get demoNextClassTitle => 'Анализ II';

  @override
  String get demoNextClassMeta => 'D 3-510 · через 12 мин';

  @override
  String get chipExam => 'Экзамен';

  @override
  String get chipMessages => 'Сообщения';

  @override
  String get chipGpa => 'Средний';

  @override
  String get demoExamTime => 'Чт 10:00';

  @override
  String get demoMessagesNew => '3 новых';

  @override
  String get demoGpa => '4.32';

  @override
  String get calendarWeek => 'Неделя';

  @override
  String get calendarList => 'Список';

  @override
  String get filterClass => 'Пара';

  @override
  String get filterExam => 'Экзамен';

  @override
  String get filterTask => 'Задание';

  @override
  String get filterOnline => 'Онлайн';

  @override
  String get studySubjects => 'Предметы';

  @override
  String get studyCredits => 'Кредиты';

  @override
  String get studyUpcomingExam => 'Ближайший экзамен';

  @override
  String get studySignUp => 'Записаться';

  @override
  String get demoCredits => '27 / 30';

  @override
  String get demoSubjectAnalysis => 'Анализ II';

  @override
  String get demoSubjectProgramming => 'Программирование';

  @override
  String get demoSubjectEnglish => 'Практика английского';

  @override
  String get demoExamLine => 'Дискретная мат. · Чт 10:00';

  @override
  String inboxNewCount(int count) {
    return '$count новых';
  }

  @override
  String get demoInboxRegistrar => 'Учебный отдел';

  @override
  String get demoInboxRegistrarSubject => 'Расписание сессии';

  @override
  String get demoInboxNeptun => 'Neptun';

  @override
  String get demoInboxNeptunSubject => 'Новая оценка: Анализ II';

  @override
  String get demoInboxInstructor => 'Преподаватель · Kovacs';

  @override
  String get demoInboxInstructorSubject => 'Консультация в четверг';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageValue => 'Русский';

  @override
  String get settingsFaceId => 'Face ID';

  @override
  String get settingsOn => 'Вкл';

  @override
  String get settingsPin => 'PIN';

  @override
  String get settingsChange => 'Изменить';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotificationsValue => 'Пары и экзамены';

  @override
  String get settingsSignOut => 'Выйти';

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
  String get demoEventProgrammingTitle => 'Программирование';

  @override
  String get demoEventProgrammingRoom => 'Lágymányos 2.502';

  @override
  String get demoEventExamTime => '10:00';

  @override
  String get demoEventExamTitle => 'Экзамен · Дискретная мат.';

  @override
  String get demoEventExamRoom => 'Trefort';

  @override
  String get todayQuickActions => 'Быстрые действия';

  @override
  String get todayActionSchedule => 'Расписание';

  @override
  String get todayActionSubjects => 'Предметы';

  @override
  String get todayActionInbox => 'Входящие';

  @override
  String get todaySchedule => 'Расписание на сегодня';
}
