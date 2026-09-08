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

  @override
  String get disclaimerTitle => 'Неофициальный клиент';

  @override
  String get disclaimerBody =>
      'Karmin — неофициальный продукт Cheterin. Он не связан с ELTE и оператором Neptun и не поддерживается ими.\n\nПароль Neptun хранится в защищённом хранилище телефона, чтобы открывать Karmin через Face ID или PIN. Каждый новый сеанс Neptun всё равно требует одноразовый код из почты или приложения-аутентификатора. У Karmin нет своего сервера.\n\nВы используете приложение на свой риск. Если правила университета требуют, пользуйтесь официальным вебом Neptun.';

  @override
  String get disclaimerUnderstand => 'Понятно';

  @override
  String get disclaimerOfficialNeptun => 'Официальный Neptun';

  @override
  String get loginSubtitle => 'ELTE Neptun';

  @override
  String get loginNeptunCode => 'Код Neptun';

  @override
  String get loginPassword => 'Пароль';

  @override
  String get loginSignIn => 'Войти';

  @override
  String get loginKeystoreHint => 'Первый вход. Пароль сохраняется в Keystore.';

  @override
  String get loginDebugBanner =>
      'Режим разработки — без Neptun. Любые непустые данные, затем любой 6-значный код.';

  @override
  String get loginErrorEmpty => 'Введите код Neptun и пароль.';

  @override
  String get loginErrorBadCredentials => 'Neptun отклонил эти данные.';

  @override
  String get loginErrorNetwork => 'Не удаётся связаться с Neptun.';

  @override
  String get loginErrorCaptcha =>
      'Neptun просит captcha. Войдите один раз на сайте и повторите.';

  @override
  String get loginErrorLockout =>
      'Слишком много попыток. Подождите и войдите снова.';

  @override
  String get loginErrorUnavailable =>
      'Не удалось открыть вход ELTE. Повторите или войдите на сайте.';

  @override
  String get loginOpenWebsite => 'Открыть сайт Neptun';

  @override
  String get otpTitle => 'Подтверждение';

  @override
  String get otpSubtitleEmail => 'Введите одноразовый код из письма.';

  @override
  String get otpSubtitleAuthenticator =>
      'Введите одноразовый код из приложения-аутентификатора.';

  @override
  String get otpSubtitleUnknown =>
      'Введите одноразовый код из письма или приложения-аутентификатора.';

  @override
  String get otpCodeHint => 'Одноразовый код';

  @override
  String get otpConfirm => 'Подтвердить';

  @override
  String get otpResend => 'Отправить ещё раз код';

  @override
  String otpResendWait(int seconds) {
    return 'Ещё раз через $seconds с';
  }

  @override
  String get otpResent => 'Новый код запрошен.';

  @override
  String get otpError => 'Neptun отклонил этот код.';

  @override
  String get todayEmptyNext => 'Нет ближайшей пары';

  @override
  String get todayEmptySchedule => 'На сегодня ничего нет.';

  @override
  String get calendarEmpty => 'Нет событий для показа.';

  @override
  String get dataError => 'Не удалось обновить данные Neptun.';

  @override
  String get dataCached => 'Показаны последние сохранённые данные.';

  @override
  String get dataRetry => 'Повторить';

  @override
  String get dataOffline => 'Не удаётся связаться с Neptun.';

  @override
  String pinDotsLabel(int filled, int max) {
    return 'Введено $filled из $max цифр';
  }

  @override
  String get pinBackspace => 'Удалить последнюю цифру';

  @override
  String pinDigit(String digit) {
    return 'Цифра $digit';
  }

  @override
  String get loginShowPassword => 'Показать пароль';

  @override
  String get loginHidePassword => 'Скрыть пароль';

  @override
  String get settingsBack => 'Назад';

  @override
  String relativeMinutes(int minutes) {
    return 'через $minutes мин';
  }

  @override
  String get relativeNow => 'сейчас';

  @override
  String get setPinTitle => 'Задать PIN';

  @override
  String get setPinConfirmTitle => 'Повторите PIN';

  @override
  String get setPinSubtitle =>
      'Выберите 6-значный PIN, чтобы открывать Karmin на этом устройстве.';

  @override
  String get setPinConfirmSubtitle => 'Введите тот же PIN ещё раз.';

  @override
  String get setPinMismatch => 'PIN не совпал. Попробуйте снова.';

  @override
  String get setPinEnableBio => 'Открывать Face ID / отпечатком';

  @override
  String get unlockTitle => 'Разблокировка';

  @override
  String get unlockSubtitle => 'Face ID или 6-значный PIN';

  @override
  String get unlockSubtitlePinOnly => 'Введите 6-значный PIN';

  @override
  String get unlockSignOut => 'Выйти';

  @override
  String get unlockWrongPin => 'Неверный PIN';

  @override
  String unlockLocked(int seconds) {
    return 'Слишком много попыток. Подождите $seconds с.';
  }

  @override
  String get unlockUseBiometrics => 'Face ID';

  @override
  String get unlockBiometricReason => 'Разблокировать Karmin';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsThemeHint => 'Тёмная, светлая или как на устройстве.';

  @override
  String get settingsOff => 'Выкл';

  @override
  String get settingsFaceIdUnavailable => 'Недоступно';

  @override
  String get studyEmpty => 'Пока нет предметов в этом семестре.';

  @override
  String get inboxEmpty => 'Нет сообщений.';

  @override
  String get inboxYesterday => 'Вчера';

  @override
  String get studyConfirm => 'Подтвердить';

  @override
  String get studyCancel => 'Отмена';

  @override
  String get studyAlreadySigned => 'Записан';

  @override
  String get studySignUpUnavailable =>
      'Запись в официальном Neptun — тело запроса ELTE ещё не подтверждено.';

  @override
  String studySignUpConfirmTitle(String exam) {
    return 'Записаться на $exam?';
  }

  @override
  String studySignUpConfirmBody(String date) {
    return 'Это запишет вас в Neptun на экзамен $date. Ещё можно отменить.';
  }

  @override
  String get subjectCode => 'Код';

  @override
  String get subjectExams => 'Экзамены';

  @override
  String get subjectEmptyExams => 'Для этого предмета нет экзаменов.';

  @override
  String get inboxThreadEmpty => 'В этой переписке нет сообщений.';
}
