import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu'),
    Locale('ru'),
  ];

  /// App brand name
  ///
  /// In en, this message translates to:
  /// **'Karmin'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get tabStudy;

  /// No description provided for @tabInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get tabInbox;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @todayPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Today — content coming soon'**
  String get todayPlaceholder;

  /// No description provided for @calendarPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Calendar — content coming soon'**
  String get calendarPlaceholder;

  /// No description provided for @studyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Study — content coming soon'**
  String get studyPlaceholder;

  /// No description provided for @inboxPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Inbox — content coming soon'**
  String get inboxPlaceholder;

  /// No description provided for @profilePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get profilePlaceholder;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile details will appear after sign-in'**
  String get profileSubtitle;

  /// No description provided for @settingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Preferences will appear here in a later stage.'**
  String get settingsEmptyHint;

  /// No description provided for @nextClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Next class'**
  String get nextClassLabel;

  /// No description provided for @demoNextClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis II'**
  String get demoNextClassTitle;

  /// No description provided for @demoNextClassMeta.
  ///
  /// In en, this message translates to:
  /// **'D 3-510 · in 12 min'**
  String get demoNextClassMeta;

  /// No description provided for @chipExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get chipExam;

  /// No description provided for @chipMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chipMessages;

  /// No description provided for @chipGpa.
  ///
  /// In en, this message translates to:
  /// **'GPA'**
  String get chipGpa;

  /// No description provided for @demoExamTime.
  ///
  /// In en, this message translates to:
  /// **'Thu 10:00'**
  String get demoExamTime;

  /// No description provided for @demoMessagesNew.
  ///
  /// In en, this message translates to:
  /// **'3 new'**
  String get demoMessagesNew;

  /// No description provided for @demoGpa.
  ///
  /// In en, this message translates to:
  /// **'4.32'**
  String get demoGpa;

  /// No description provided for @calendarWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarWeek;

  /// No description provided for @calendarList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get calendarList;

  /// No description provided for @filterClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get filterClass;

  /// No description provided for @filterExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get filterExam;

  /// No description provided for @filterTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get filterTask;

  /// No description provided for @filterOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get filterOnline;

  /// No description provided for @studySubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get studySubjects;

  /// No description provided for @studyCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get studyCredits;

  /// No description provided for @studyUpcomingExam.
  ///
  /// In en, this message translates to:
  /// **'Upcoming exam'**
  String get studyUpcomingExam;

  /// No description provided for @studySignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get studySignUp;

  /// No description provided for @demoCredits.
  ///
  /// In en, this message translates to:
  /// **'27 / 30'**
  String get demoCredits;

  /// No description provided for @demoSubjectAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis II'**
  String get demoSubjectAnalysis;

  /// No description provided for @demoSubjectProgramming.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get demoSubjectProgramming;

  /// No description provided for @demoSubjectEnglish.
  ///
  /// In en, this message translates to:
  /// **'English practice'**
  String get demoSubjectEnglish;

  /// No description provided for @demoExamLine.
  ///
  /// In en, this message translates to:
  /// **'Discrete math · Thu 10:00'**
  String get demoExamLine;

  /// No description provided for @inboxNewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String inboxNewCount(int count);

  /// No description provided for @demoInboxRegistrar.
  ///
  /// In en, this message translates to:
  /// **'Registrar'**
  String get demoInboxRegistrar;

  /// No description provided for @demoInboxRegistrarSubject.
  ///
  /// In en, this message translates to:
  /// **'Exam period schedule'**
  String get demoInboxRegistrarSubject;

  /// No description provided for @demoInboxNeptun.
  ///
  /// In en, this message translates to:
  /// **'Neptun'**
  String get demoInboxNeptun;

  /// No description provided for @demoInboxNeptunSubject.
  ///
  /// In en, this message translates to:
  /// **'New grade: Analysis II'**
  String get demoInboxNeptunSubject;

  /// No description provided for @demoInboxInstructor.
  ///
  /// In en, this message translates to:
  /// **'Instructor · Kovacs'**
  String get demoInboxInstructor;

  /// No description provided for @demoInboxInstructorSubject.
  ///
  /// In en, this message translates to:
  /// **'Consultation on Thursday'**
  String get demoInboxInstructorSubject;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageValue.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageValue;

  /// No description provided for @settingsFaceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get settingsFaceId;

  /// No description provided for @settingsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsOn;

  /// No description provided for @settingsPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get settingsPin;

  /// No description provided for @settingsChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settingsChange;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsValue.
  ///
  /// In en, this message translates to:
  /// **'Class & exam'**
  String get settingsNotificationsValue;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @demoProfileName.
  ///
  /// In en, this message translates to:
  /// **'Adnan Huseynli'**
  String get demoProfileName;

  /// No description provided for @demoProfileCode.
  ///
  /// In en, this message translates to:
  /// **'ABC123 · IK / ELTE'**
  String get demoProfileCode;

  /// No description provided for @demoProfileProgram.
  ///
  /// In en, this message translates to:
  /// **'Computer Science BSc'**
  String get demoProfileProgram;

  /// No description provided for @demoEventAnalysisTime.
  ///
  /// In en, this message translates to:
  /// **'8:00–10:00'**
  String get demoEventAnalysisTime;

  /// No description provided for @demoEventAnalysisRoom.
  ///
  /// In en, this message translates to:
  /// **'D 3-510'**
  String get demoEventAnalysisRoom;

  /// No description provided for @demoEventProgrammingTime.
  ///
  /// In en, this message translates to:
  /// **'10:15–12:00'**
  String get demoEventProgrammingTime;

  /// No description provided for @demoEventProgrammingTitle.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get demoEventProgrammingTitle;

  /// No description provided for @demoEventProgrammingRoom.
  ///
  /// In en, this message translates to:
  /// **'Lágymányos 2.502'**
  String get demoEventProgrammingRoom;

  /// No description provided for @demoEventExamTime.
  ///
  /// In en, this message translates to:
  /// **'10:00'**
  String get demoEventExamTime;

  /// No description provided for @demoEventExamTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam · Discrete math'**
  String get demoEventExamTitle;

  /// No description provided for @demoEventExamRoom.
  ///
  /// In en, this message translates to:
  /// **'Trefort'**
  String get demoEventExamRoom;

  /// No description provided for @todayQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get todayQuickActions;

  /// No description provided for @todayActionSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get todayActionSchedule;

  /// No description provided for @todayActionSubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get todayActionSubjects;

  /// No description provided for @todayActionInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get todayActionInbox;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get todaySchedule;

  /// No description provided for @disclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Unofficial client'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'Karmin is an unofficial product by Cheterin. It is not affiliated with, endorsed by, or supported by Eötvös Loránd University or the operator of Neptun.\n\nYour Neptun password is stored in this phone’s secure hardware-backed store so you can unlock Karmin with Face ID or a PIN. Every new Neptun session still requires a one-time code from your email or authenticator app. Karmin does not run a server. ELTE and Neptun remain responsible for the data they hold.\n\nYou use Karmin at your own risk. Prefer the official Neptun website when university rules require it.'**
  String get disclaimerBody;

  /// No description provided for @disclaimerUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get disclaimerUnderstand;

  /// No description provided for @disclaimerOfficialNeptun.
  ///
  /// In en, this message translates to:
  /// **'Official Neptun'**
  String get disclaimerOfficialNeptun;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ELTE Neptun'**
  String get loginSubtitle;

  /// No description provided for @loginNeptunCode.
  ///
  /// In en, this message translates to:
  /// **'Neptun code'**
  String get loginNeptunCode;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// No description provided for @loginKeystoreHint.
  ///
  /// In en, this message translates to:
  /// **'First sign-in. Password is stored in Keystore.'**
  String get loginKeystoreHint;

  /// No description provided for @loginDebugBanner.
  ///
  /// In en, this message translates to:
  /// **'Development login — not talking to Neptun. Any non-empty credentials, then any 6-digit code.'**
  String get loginDebugBanner;

  /// No description provided for @loginErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your Neptun code and password.'**
  String get loginErrorEmpty;

  /// No description provided for @loginErrorBadCredentials.
  ///
  /// In en, this message translates to:
  /// **'Neptun rejected these credentials.'**
  String get loginErrorBadCredentials;

  /// No description provided for @loginErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Neptun.'**
  String get loginErrorNetwork;

  /// No description provided for @loginErrorCaptcha.
  ///
  /// In en, this message translates to:
  /// **'Neptun wants a captcha. Sign in once on the website, then retry.'**
  String get loginErrorCaptcha;

  /// No description provided for @loginErrorLockout.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a moment, then sign in again.'**
  String get loginErrorLockout;

  /// No description provided for @loginErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'ELTE student login returned an error. Try again, or sign in on the website.'**
  String get loginErrorUnavailable;

  /// No description provided for @loginOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open Neptun website'**
  String get loginOpenWebsite;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get otpTitle;

  /// No description provided for @otpSubtitleEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the one-time code from your email.'**
  String get otpSubtitleEmail;

  /// No description provided for @otpSubtitleAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'Enter the one-time code from your authenticator app.'**
  String get otpSubtitleAuthenticator;

  /// No description provided for @otpSubtitleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Enter the one-time code from your email or authenticator app.'**
  String get otpSubtitleUnknown;

  /// No description provided for @otpAuthenticatorParked.
  ///
  /// In en, this message translates to:
  /// **'This build uses the email code only; authenticator is temporarily off.'**
  String get otpAuthenticatorParked;

  /// No description provided for @otpPrefixHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code after the dash; the prefix is filled by Neptun.'**
  String get otpPrefixHint;

  /// No description provided for @otpCodeHint.
  ///
  /// In en, this message translates to:
  /// **'One-time code'**
  String get otpCodeHint;

  /// No description provided for @otpConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get otpConfirm;

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Send code again'**
  String get otpResend;

  /// No description provided for @otpResendWait.
  ///
  /// In en, this message translates to:
  /// **'Send again in {seconds}s'**
  String otpResendWait(int seconds);

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code was requested.'**
  String get otpResent;

  /// No description provided for @otpError.
  ///
  /// In en, this message translates to:
  /// **'Neptun rejected this code.'**
  String get otpError;

  /// No description provided for @otpErrorNoMail.
  ///
  /// In en, this message translates to:
  /// **'Neptun did not send an email code. Try Send code again, or tap E-mail code on the website.'**
  String get otpErrorNoMail;

  /// No description provided for @todayEmptyNext.
  ///
  /// In en, this message translates to:
  /// **'No upcoming class'**
  String get todayEmptyNext;

  /// No description provided for @todayEmptySchedule.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the schedule today.'**
  String get todayEmptySchedule;

  /// No description provided for @calendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events to show.'**
  String get calendarEmpty;

  /// No description provided for @dataError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t refresh from Neptun.'**
  String get dataError;

  /// No description provided for @dataCached.
  ///
  /// In en, this message translates to:
  /// **'Showing last saved data.'**
  String get dataCached;

  /// No description provided for @dataRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dataRetry;

  /// No description provided for @dataOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Neptun.'**
  String get dataOffline;

  /// No description provided for @dataMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Neptun is temporarily unavailable (maintenance).'**
  String get dataMaintenance;

  /// No description provided for @dataPortalSession.
  ///
  /// In en, this message translates to:
  /// **'Signed in via web login — live calendar needs Authenticator JSON login. Sign out and try again.'**
  String get dataPortalSession;

  /// No description provided for @dataSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Neptun session expired. Enter a new one-time code.'**
  String get dataSessionExpired;

  /// No description provided for @pinDotsLabel.
  ///
  /// In en, this message translates to:
  /// **'{filled} of {max} digits entered'**
  String pinDotsLabel(int filled, int max);

  /// No description provided for @pinBackspace.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get pinBackspace;

  /// No description provided for @pinDigit.
  ///
  /// In en, this message translates to:
  /// **'Digit {digit}'**
  String pinDigit(String digit);

  /// No description provided for @loginShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// No description provided for @settingsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get settingsBack;

  /// No description provided for @relativeMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {minutes} min'**
  String relativeMinutes(int minutes);

  /// No description provided for @relativeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get relativeNow;

  /// No description provided for @setPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPinTitle;

  /// No description provided for @setPinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get setPinConfirmTitle;

  /// No description provided for @setPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a 6-digit PIN to unlock Karmin on this device.'**
  String get setPinSubtitle;

  /// No description provided for @setPinConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the same PIN again.'**
  String get setPinConfirmSubtitle;

  /// No description provided for @setPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs did not match. Try again.'**
  String get setPinMismatch;

  /// No description provided for @setPinEnableBio.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Face ID / fingerprint'**
  String get setPinEnableBio;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockTitle;

  /// No description provided for @unlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Face ID or 6-digit PIN'**
  String get unlockSubtitle;

  /// No description provided for @unlockSubtitlePinOnly.
  ///
  /// In en, this message translates to:
  /// **'Enter your 6-digit PIN'**
  String get unlockSubtitlePinOnly;

  /// No description provided for @unlockSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get unlockSignOut;

  /// No description provided for @unlockWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get unlockWrongPin;

  /// No description provided for @unlockLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s.'**
  String unlockLocked(int seconds);

  /// No description provided for @unlockUseBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID'**
  String get unlockUseBiometrics;

  /// No description provided for @unlockBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Karmin'**
  String get unlockBiometricReason;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeHint.
  ///
  /// In en, this message translates to:
  /// **'Dark, light, or match the device.'**
  String get settingsThemeHint;

  /// No description provided for @settingsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOff;

  /// No description provided for @settingsFaceIdUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get settingsFaceIdUnavailable;

  /// No description provided for @studyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No subjects for this term yet.'**
  String get studyEmpty;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages.'**
  String get inboxEmpty;

  /// No description provided for @inboxYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get inboxYesterday;

  /// No description provided for @studyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get studyConfirm;

  /// No description provided for @studyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get studyCancel;

  /// No description provided for @studyAlreadySigned.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get studyAlreadySigned;

  /// No description provided for @studySignUpUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign up in official Neptun — ELTE payload not confirmed yet.'**
  String get studySignUpUnavailable;

  /// No description provided for @studySignUpConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up for {exam}?'**
  String studySignUpConfirmTitle(String exam);

  /// No description provided for @studySignUpConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will register you in Neptun for this exam on {date}. You can still cancel.'**
  String studySignUpConfirmBody(String date);

  /// No description provided for @subjectCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get subjectCode;

  /// No description provided for @subjectExams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get subjectExams;

  /// No description provided for @subjectEmptyExams.
  ///
  /// In en, this message translates to:
  /// **'No exams listed for this subject.'**
  String get subjectEmptyExams;

  /// No description provided for @inboxThreadEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts in this thread.'**
  String get inboxThreadEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
