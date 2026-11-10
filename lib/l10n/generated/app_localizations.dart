import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('es'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @mainNavigation.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get mainNavigation;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Theme, stats, reminders, sleep data and app info.'**
  String get settingsSupport;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @sleepReminder.
  ///
  /// In en, this message translates to:
  /// **'Sleep reminder'**
  String get sleepReminder;

  /// No description provided for @sleepReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get sleepReminderOff;

  /// No description provided for @sleepReminderEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String sleepReminderEveryDay(String time);

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notificationsOff;

  /// No description provided for @notificationsOffSupport.
  ///
  /// In en, this message translates to:
  /// **'Allow Sleepy3 to send the notification.'**
  String get notificationsOffSupport;

  /// No description provided for @notificationsPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to get the sleep reminder.'**
  String get notificationsPermissionNeeded;

  /// No description provided for @sleepReminderScheduleFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t set the sleep reminder. Try again.'**
  String get sleepReminderScheduleFailed;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @sleepReminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to record your sleep'**
  String get sleepReminderNotificationTitle;

  /// No description provided for @sleepReminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Open Sleepy3 and tap Sleep when you turn off the lights.'**
  String get sleepReminderNotificationBody;

  /// No description provided for @sleepReminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Sleep reminder'**
  String get sleepReminderChannelName;

  /// No description provided for @sleepReminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'A nightly reminder to record your sleep.'**
  String get sleepReminderChannelDescription;

  /// No description provided for @sleepingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleeping'**
  String get sleepingNotificationTitle;

  /// No description provided for @sleepingNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Goal {goal} · until {time}'**
  String sleepingNotificationBody(String goal, String time);

  /// No description provided for @sleepingNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Sleep status'**
  String get sleepingNotificationChannelName;

  /// No description provided for @sleepingNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'A quiet timer while a sleep session is active.'**
  String get sleepingNotificationChannelDescription;

  /// No description provided for @sleepingNotificationOngoing.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get sleepingNotificationOngoing;

  /// No description provided for @sleepStatusNotification.
  ///
  /// In en, this message translates to:
  /// **'Sleep in progress'**
  String get sleepStatusNotification;

  /// No description provided for @sleepStatusNotificationSupport.
  ///
  /// In en, this message translates to:
  /// **'Shows a live timer while you sleep.'**
  String get sleepStatusNotificationSupport;

  /// No description provided for @sleepStatusNotificationOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get sleepStatusNotificationOff;

  /// No description provided for @sleepStatusNotificationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to show your sleep status.'**
  String get sleepStatusNotificationPermissionNeeded;

  /// No description provided for @sleepData.
  ///
  /// In en, this message translates to:
  /// **'Sleep data'**
  String get sleepData;

  /// No description provided for @googleHealth.
  ///
  /// In en, this message translates to:
  /// **'Google Health'**
  String get googleHealth;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get timeFormat;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @timeFormat12.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get timeFormat12;

  /// No description provided for @timeFormat24.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get timeFormat24;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @privacyLocal.
  ///
  /// In en, this message translates to:
  /// **'On-device only.'**
  String get privacyLocal;

  /// No description provided for @privacyHealth.
  ///
  /// In en, this message translates to:
  /// **'Stored in Health Connect. Google Health can read it.'**
  String get privacyHealth;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @importSupport.
  ///
  /// In en, this message translates to:
  /// **'Download from Google Health to the local copy.'**
  String get importSupport;

  /// No description provided for @sleepDataSourceDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep data source'**
  String get sleepDataSourceDialogTitle;

  /// No description provided for @sourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get sourceLocal;

  /// No description provided for @sourceHealth.
  ///
  /// In en, this message translates to:
  /// **'Google Health'**
  String get sourceHealth;

  /// No description provided for @copyLocalSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy local sessions?'**
  String get copyLocalSessionsTitle;

  /// No description provided for @localSessionsNotInHealth.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 local session is not in Google Health yet.} other{{count} local sessions are not in Google Health yet.}}'**
  String localSessionsNotInHealth(int count);

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @syncRecentSupport.
  ///
  /// In en, this message translates to:
  /// **'Send the most recent one.'**
  String get syncRecentSupport;

  /// No description provided for @addAllSupport.
  ///
  /// In en, this message translates to:
  /// **'Send every local session.'**
  String get addAllSupport;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectedPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Connected · 1 pending} other{Connected · {count} pending}}'**
  String connectedPending(int count);

  /// No description provided for @connectedLastSync.
  ///
  /// In en, this message translates to:
  /// **'Connected · Last sync {time}'**
  String connectedLastSync(String time);

  /// No description provided for @permissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get permissionNeeded;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequired;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking.'**
  String get checking;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connectSupport.
  ///
  /// In en, this message translates to:
  /// **'Allow Sleepy3 to read and write sleep.'**
  String get connectSupport;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @installSupport.
  ///
  /// In en, this message translates to:
  /// **'Get or update Health Connect.'**
  String get installSupport;

  /// No description provided for @syncSupport.
  ///
  /// In en, this message translates to:
  /// **'Send the most recent local session.'**
  String get syncSupport;

  /// No description provided for @addSupport.
  ///
  /// In en, this message translates to:
  /// **'Send local sessions that aren\'t in Google Health.'**
  String get addSupport;

  /// No description provided for @healthPermissionReadWrite.
  ///
  /// In en, this message translates to:
  /// **'Google Health needs permission to read and write sleep.'**
  String get healthPermissionReadWrite;

  /// No description provided for @sleepAction.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepAction;

  /// No description provided for @wakeAction.
  ///
  /// In en, this message translates to:
  /// **'Wake'**
  String get wakeAction;

  /// No description provided for @slideToWake.
  ///
  /// In en, this message translates to:
  /// **'Slide to wake'**
  String get slideToWake;

  /// No description provided for @slideToWakeHint.
  ///
  /// In en, this message translates to:
  /// **'Slide the circle to the right, or double tap to confirm.'**
  String get slideToWakeHint;

  /// Replaces the elapsed time during the first minute of an open sleep session.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get wakeSlideJustNow;

  /// Accessible label for the Wake slide during the first minute of an open sleep session.
  ///
  /// In en, this message translates to:
  /// **'You just fell asleep. Slide to wake.'**
  String get wakeSlideJustNowSemantics;

  /// Accessible label for the Wake slide while a sleep session is open.
  ///
  /// In en, this message translates to:
  /// **'Sleeping for {duration}. Slide to wake.'**
  String wakeSlideSemantics(String duration);

  /// No description provided for @savingSession.
  ///
  /// In en, this message translates to:
  /// **'Saving session'**
  String get savingSession;

  /// No description provided for @sessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Session saved'**
  String get sessionSaved;

  /// No description provided for @sessionDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Session discarded'**
  String get sessionDiscarded;

  /// No description provided for @sessionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the session'**
  String get sessionSaveFailed;

  /// No description provided for @dayStatus.
  ///
  /// In en, this message translates to:
  /// **'Day · ready to wake'**
  String get dayStatus;

  /// No description provided for @nightStatus.
  ///
  /// In en, this message translates to:
  /// **'Night · time to rest'**
  String get nightStatus;

  /// No description provided for @dayStatusSpoken.
  ///
  /// In en, this message translates to:
  /// **'Day, ready to wake'**
  String get dayStatusSpoken;

  /// No description provided for @nightStatusSpoken.
  ///
  /// In en, this message translates to:
  /// **'Night, time to rest'**
  String get nightStatusSpoken;

  /// No description provided for @currentTime.
  ///
  /// In en, this message translates to:
  /// **'Current time {time}'**
  String currentTime(String time);

  /// No description provided for @sleepingSince.
  ///
  /// In en, this message translates to:
  /// **'Sleeping since {time}'**
  String sleepingSince(String time);

  /// No description provided for @lastSession.
  ///
  /// In en, this message translates to:
  /// **'Last session: {duration}'**
  String lastSession(String duration);

  /// No description provided for @noActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get noActiveSession;

  /// No description provided for @tapSleepAtNight.
  ///
  /// In en, this message translates to:
  /// **'Tap Sleep when you turn off the lights'**
  String get tapSleepAtNight;

  /// No description provided for @sleepTooShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep too short'**
  String get sleepTooShortTitle;

  /// No description provided for @sleepTooShortBody.
  ///
  /// In en, this message translates to:
  /// **'Sleeps shorter than 10 minutes are not recorded. Are you sure you want to discard this session?'**
  String get sleepTooShortBody;

  /// No description provided for @keepSleeping.
  ///
  /// In en, this message translates to:
  /// **'Keep sleeping'**
  String get keepSleeping;

  /// No description provided for @discardSession.
  ///
  /// In en, this message translates to:
  /// **'Discard session'**
  String get discardSession;

  /// No description provided for @sleepTooLongTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep too long'**
  String get sleepTooLongTitle;

  /// No description provided for @sleepTooLongBody.
  ///
  /// In en, this message translates to:
  /// **'Sleeps longer than 24 hours are not recorded. Edit the start time to keep this session, or discard it.'**
  String get sleepTooLongBody;

  /// No description provided for @editStartTime.
  ///
  /// In en, this message translates to:
  /// **'Edit start time'**
  String get editStartTime;

  /// No description provided for @startTimeNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Start time not saved'**
  String get startTimeNotSaved;

  /// No description provided for @selectSleepDate.
  ///
  /// In en, this message translates to:
  /// **'Select sleep date'**
  String get selectSleepDate;

  /// No description provided for @selectSleepTime.
  ///
  /// In en, this message translates to:
  /// **'Select sleep time'**
  String get selectSleepTime;

  /// No description provided for @selectWakeDate.
  ///
  /// In en, this message translates to:
  /// **'Select wake date'**
  String get selectWakeDate;

  /// No description provided for @selectWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Select wake time'**
  String get selectWakeTime;

  /// No description provided for @last3Days.
  ///
  /// In en, this message translates to:
  /// **'Last 3 days'**
  String get last3Days;

  /// No description provided for @last3DaysAverage.
  ///
  /// In en, this message translates to:
  /// **'Last 3 days · {average} avg'**
  String last3DaysAverage(String average);

  /// No description provided for @last3DaysNoAverage.
  ///
  /// In en, this message translates to:
  /// **'Last 3 days · — avg'**
  String get last3DaysNoAverage;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @noAverageSpoken.
  ///
  /// In en, this message translates to:
  /// **', no average'**
  String get noAverageSpoken;

  /// No description provided for @averageSpoken.
  ///
  /// In en, this message translates to:
  /// **', average {duration}'**
  String averageSpoken(String duration);

  /// No description provided for @noSessionSpoken.
  ///
  /// In en, this message translates to:
  /// **'no session'**
  String get noSessionSpoken;

  /// No description provided for @loadingSleepHistorySemantic.
  ///
  /// In en, this message translates to:
  /// **'Loading sleep history'**
  String get loadingSleepHistorySemantic;

  /// No description provided for @loadingSleepHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading sleep history…'**
  String get loadingSleepHistory;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your sleep history'**
  String get historyLoadError;

  /// No description provided for @historyLoadErrorSupport.
  ///
  /// In en, this message translates to:
  /// **'Your sessions are safe. Try again.'**
  String get historyLoadErrorSupport;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// No description provided for @statsSupport.
  ///
  /// In en, this message translates to:
  /// **'Your sleep, night by night.'**
  String get statsSupport;

  /// No description provided for @statsSupportingSleeping.
  ///
  /// In en, this message translates to:
  /// **'Sleeping since {time} · it will appear when you wake.'**
  String statsSupportingSleeping(String time);

  /// No description provided for @advancedStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced stats'**
  String get advancedStatsTitle;

  /// No description provided for @advancedStatsAction.
  ///
  /// In en, this message translates to:
  /// **'View advanced stats'**
  String get advancedStatsAction;

  /// No description provided for @statsSummary.
  ///
  /// In en, this message translates to:
  /// **'Stats summary'**
  String get statsSummary;

  /// No description provided for @statsSummarySupport.
  ///
  /// In en, this message translates to:
  /// **'Choose the block shown above View advanced stats. Only one at a time.'**
  String get statsSummarySupport;

  /// No description provided for @statsSummaryCurrentBlock.
  ///
  /// In en, this message translates to:
  /// **'Current block: {block}'**
  String statsSummaryCurrentBlock(String block);

  /// No description provided for @statsSummaryKeyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Key metrics'**
  String get statsSummaryKeyMetrics;

  /// No description provided for @statsSummaryKeyData.
  ///
  /// In en, this message translates to:
  /// **'Key data'**
  String get statsSummaryKeyData;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get timeRange;

  /// No description provided for @rangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get rangeMonth;

  /// No description provided for @rangeThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get rangeThreeMonths;

  /// No description provided for @rangeYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get rangeYear;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rangeAll;

  /// No description provided for @averageSleep.
  ///
  /// In en, this message translates to:
  /// **'Average sleep'**
  String get averageSleep;

  /// No description provided for @noNightsInRange.
  ///
  /// In en, this message translates to:
  /// **'No nights in this range'**
  String get noNightsInRange;

  /// No description provided for @summarySupporting.
  ///
  /// In en, this message translates to:
  /// **'Across {nights, plural, =1{1 night} other{{nights} nights}} · {total} total'**
  String summarySupporting(int nights, String total);

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @summarySpoken.
  ///
  /// In en, this message translates to:
  /// **'Average sleep {average}, across {nights, plural, =1{1 night} other{{nights} nights}}, {total} total'**
  String summarySpoken(String average, int nights, String total);

  /// No description provided for @summarySpokenNoNights.
  ///
  /// In en, this message translates to:
  /// **'Average sleep, no nights in this range'**
  String get summarySpokenNoNights;

  /// No description provided for @heroCoverageWindow.
  ///
  /// In en, this message translates to:
  /// **'{recorded} of {window, plural, =1{1 night} other{{window} nights}}'**
  String heroCoverageWindow(int recorded, int window);

  /// No description provided for @heroCoverageAll.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night recorded} other{{count} nights recorded}}'**
  String heroCoverageAll(int count);

  /// No description provided for @heroComparison.
  ///
  /// In en, this message translates to:
  /// **'vs {previous}: {delta}'**
  String heroComparison(String previous, String delta);

  /// No description provided for @previousRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'previous week'**
  String get previousRangeWeek;

  /// No description provided for @previousRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'previous month'**
  String get previousRangeMonth;

  /// No description provided for @previousRangeThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'previous 3 months'**
  String get previousRangeThreeMonths;

  /// No description provided for @previousRangeYear.
  ///
  /// In en, this message translates to:
  /// **'previous year'**
  String get previousRangeYear;

  /// No description provided for @metricGoalHitRate.
  ///
  /// In en, this message translates to:
  /// **'Goal hit rate'**
  String get metricGoalHitRate;

  /// No description provided for @metricGoalHitSupport.
  ///
  /// In en, this message translates to:
  /// **'{met} of {total, plural, =1{1 night} other{{total} nights}}'**
  String metricGoalHitSupport(int met, int total);

  /// No description provided for @metricPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String metricPercent(int percent);

  /// No description provided for @metricScheduleConsistency.
  ///
  /// In en, this message translates to:
  /// **'Schedule consistency'**
  String get metricScheduleConsistency;

  /// No description provided for @metricBedtime.
  ///
  /// In en, this message translates to:
  /// **'bedtime'**
  String get metricBedtime;

  /// No description provided for @metricVariability.
  ///
  /// In en, this message translates to:
  /// **'±{duration}'**
  String metricVariability(String duration);

  /// No description provided for @metricSleepBalance.
  ///
  /// In en, this message translates to:
  /// **'Sleep balance'**
  String get metricSleepBalance;

  /// No description provided for @metricBalanceSurplus.
  ///
  /// In en, this message translates to:
  /// **'surplus · vs {goal} goal'**
  String metricBalanceSurplus(String goal);

  /// No description provided for @metricBalanceDebt.
  ///
  /// In en, this message translates to:
  /// **'debt · vs {goal} goal'**
  String metricBalanceDebt(String goal);

  /// No description provided for @metricBalanceEven.
  ///
  /// In en, this message translates to:
  /// **'even · vs {goal} goal'**
  String metricBalanceEven(String goal);

  /// No description provided for @metricBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get metricBestStreak;

  /// No description provided for @metricBestStreakSupport.
  ///
  /// In en, this message translates to:
  /// **'current {count}'**
  String metricBestStreakSupport(int count);

  /// No description provided for @metricNights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}'**
  String metricNights(int count);

  /// No description provided for @metricNeedsTwoNights.
  ///
  /// In en, this message translates to:
  /// **'Needs 2 nights'**
  String get metricNeedsTwoNights;

  /// No description provided for @durationSignedPositive.
  ///
  /// In en, this message translates to:
  /// **'+{duration}'**
  String durationSignedPositive(String duration);

  /// No description provided for @durationSignedNegative.
  ///
  /// In en, this message translates to:
  /// **'−{duration}'**
  String durationSignedNegative(String duration);

  /// No description provided for @chartSleepDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration'**
  String get chartSleepDurationTitle;

  /// No description provided for @chartSleepDurationSupport.
  ///
  /// In en, this message translates to:
  /// **'{range} · {nights, plural, =1{1 night recorded} other{{nights} nights recorded}} · Goal {goal}'**
  String chartSleepDurationSupport(String range, int nights, String goal);

  /// No description provided for @chartTooltipDate.
  ///
  /// In en, this message translates to:
  /// **'{date} · {duration}'**
  String chartTooltipDate(String date, String duration);

  /// No description provided for @chartTooltipSessions.
  ///
  /// In en, this message translates to:
  /// **'{date} · {duration} · {sessions, plural, =1{1 session} other{{sessions} sessions}}'**
  String chartTooltipSessions(String date, String duration, int sessions);

  /// No description provided for @chartTooltipAverageValue.
  ///
  /// In en, this message translates to:
  /// **'{duration} avg'**
  String chartTooltipAverageValue(String duration);

  /// No description provided for @chartTooltipNights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}'**
  String chartTooltipNights(int count);

  /// No description provided for @chartTooltipNoData.
  ///
  /// In en, this message translates to:
  /// **'{range} · No night recorded'**
  String chartTooltipNoData(String range);

  /// No description provided for @chartDurationSpoken.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration for {range}. Average {average}. Best night {best}. Shortest night {worst}. {short, plural, =0{No nights under the {goal} goal} =1{1 night under the {goal} goal} other{{short} nights under the {goal} goal}}. {missing, plural, =0{No nights without data} =1{1 night with no data} other{{missing} nights with no data}}.'**
  String chartDurationSpoken(
    String range,
    String average,
    String best,
    String worst,
    int short,
    int missing,
    String goal,
  );

  /// No description provided for @chartSleepWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep window'**
  String get chartSleepWindowTitle;

  /// No description provided for @chartSleepWindowSupport.
  ///
  /// In en, this message translates to:
  /// **'Bedtime to wake · {range}'**
  String chartSleepWindowSupport(String range);

  /// No description provided for @chartWindowSpoken.
  ///
  /// In en, this message translates to:
  /// **'Sleep window for {range}. Average bedtime {bedtime} and average wake {wake}. {missing, plural, =0{Every night has data} =1{1 night has no data} other{{missing} nights have no data}}.'**
  String chartWindowSpoken(
    String range,
    String bedtime,
    String wake,
    int missing,
  );

  /// No description provided for @chartWeekdayTitle.
  ///
  /// In en, this message translates to:
  /// **'By weekday'**
  String get chartWeekdayTitle;

  /// No description provided for @chartWeekdaySupport.
  ///
  /// In en, this message translates to:
  /// **'Average by wake day · {range}'**
  String chartWeekdaySupport(String range);

  /// No description provided for @chartWeekdayBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get chartWeekdayBest;

  /// No description provided for @chartWeekdaySpoken.
  ///
  /// In en, this message translates to:
  /// **'Average sleep by weekday for {range}. {best} is the longest average with {average}. {count} of 7 weekdays have data.'**
  String chartWeekdaySpoken(
    String range,
    String best,
    String average,
    int count,
  );

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightBestNight.
  ///
  /// In en, this message translates to:
  /// **'Best night'**
  String get insightBestNight;

  /// No description provided for @insightShortestNight.
  ///
  /// In en, this message translates to:
  /// **'Shortest night'**
  String get insightShortestNight;

  /// No description provided for @insightAverageBedtime.
  ///
  /// In en, this message translates to:
  /// **'Average bedtime'**
  String get insightAverageBedtime;

  /// No description provided for @insightAverageWake.
  ///
  /// In en, this message translates to:
  /// **'Average wake'**
  String get insightAverageWake;

  /// No description provided for @insightBedtimeVariability.
  ///
  /// In en, this message translates to:
  /// **'Bedtime varies by'**
  String get insightBedtimeVariability;

  /// No description provided for @insightDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get insightDistribution;

  /// No description provided for @insightDistributionSpoken.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration distribution. {underSix} nights under 6 hours, {sixToSeven} from 6 to 7 hours, {sevenToEight} from 7 to 8 hours, {eightToNine} from 8 to 9 hours and {ninePlus} of 9 hours or more.'**
  String insightDistributionSpoken(
    int underSix,
    int sixToSeven,
    int sevenToEight,
    int eightToNine,
    int ninePlus,
  );

  /// No description provided for @sleepBandUnderSix.
  ///
  /// In en, this message translates to:
  /// **'Under 6h'**
  String get sleepBandUnderSix;

  /// No description provided for @sleepBandSixToSeven.
  ///
  /// In en, this message translates to:
  /// **'6–7h'**
  String get sleepBandSixToSeven;

  /// No description provided for @sleepBandSevenToEight.
  ///
  /// In en, this message translates to:
  /// **'7–8h'**
  String get sleepBandSevenToEight;

  /// No description provided for @sleepBandEightToNine.
  ///
  /// In en, this message translates to:
  /// **'8–9h'**
  String get sleepBandEightToNine;

  /// No description provided for @sleepBandNinePlus.
  ///
  /// In en, this message translates to:
  /// **'9h+'**
  String get sleepBandNinePlus;

  /// No description provided for @noSleepHistoryHealth.
  ///
  /// In en, this message translates to:
  /// **'No sleep history in Google Health'**
  String get noSleepHistoryHealth;

  /// No description provided for @noSleepHistory.
  ///
  /// In en, this message translates to:
  /// **'No sleep history yet'**
  String get noSleepHistory;

  /// No description provided for @noSleepHistoryHealthSupport.
  ///
  /// In en, this message translates to:
  /// **'Sleep sessions in Health Connect will appear here.'**
  String get noSleepHistoryHealthSupport;

  /// No description provided for @noSleepHistorySleepingSupport.
  ///
  /// In en, this message translates to:
  /// **'Your first night will appear here when you wake up.'**
  String get noSleepHistorySleepingSupport;

  /// No description provided for @noSleepHistorySupport.
  ///
  /// In en, this message translates to:
  /// **'Your nights will appear here after you wake up.'**
  String get noSleepHistorySupport;

  /// No description provided for @refreshSleepHistory.
  ///
  /// In en, this message translates to:
  /// **'Refresh sleep history'**
  String get refreshSleepHistory;

  /// No description provided for @refreshingSleepHistory.
  ///
  /// In en, this message translates to:
  /// **'Refreshing sleep history'**
  String get refreshingSleepHistory;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh your sleep history. Try again.'**
  String get refreshFailed;

  /// No description provided for @sessionSavedPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Saved. Google Health will update when it can.'**
  String get sessionSavedPendingSync;

  /// No description provided for @sessionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Session deleted.'**
  String get sessionDeleted;

  /// No description provided for @sessionSavedLocallyPermission.
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Allow Google Health write access to sync it.'**
  String get sessionSavedLocallyPermission;

  /// No description provided for @sessionAddedHealth.
  ///
  /// In en, this message translates to:
  /// **'Session added to Google Health.'**
  String get sessionAddedHealth;

  /// No description provided for @sessionAdded.
  ///
  /// In en, this message translates to:
  /// **'Session added.'**
  String get sessionAdded;

  /// No description provided for @sessionSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Session saved locally. Google Health will update when it can.'**
  String get sessionSavedLocally;

  /// No description provided for @addSleepSession.
  ///
  /// In en, this message translates to:
  /// **'Add a sleep session'**
  String get addSleepSession;

  /// No description provided for @opensSession.
  ///
  /// In en, this message translates to:
  /// **'Opens the session'**
  String get opensSession;

  /// No description provided for @anotherApp.
  ///
  /// In en, this message translates to:
  /// **'Another app'**
  String get anotherApp;

  /// No description provided for @anotherAppLower.
  ///
  /// In en, this message translates to:
  /// **'another app'**
  String get anotherAppLower;

  /// No description provided for @readOnlyFrom.
  ///
  /// In en, this message translates to:
  /// **'Read-only, from {app}'**
  String readOnlyFrom(String app);

  /// No description provided for @readOnlySession.
  ///
  /// In en, this message translates to:
  /// **'Read-only session'**
  String get readOnlySession;

  /// No description provided for @otherSleepy3Build.
  ///
  /// In en, this message translates to:
  /// **'another Sleepy3 build'**
  String get otherSleepy3Build;

  /// No description provided for @goalMetLower.
  ///
  /// In en, this message translates to:
  /// **'goal met'**
  String get goalMetLower;

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionTitle;

  /// No description provided for @newSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get newSessionTitle;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @fellAsleep.
  ///
  /// In en, this message translates to:
  /// **'Fell asleep'**
  String get fellAsleep;

  /// No description provided for @wokeUp.
  ///
  /// In en, this message translates to:
  /// **'Woke up'**
  String get wokeUp;

  /// No description provided for @wokeOn.
  ///
  /// In en, this message translates to:
  /// **'Woke {date}'**
  String wokeOn(String date);

  /// No description provided for @sessionHeroSpoken.
  ///
  /// In en, this message translates to:
  /// **'{duration}, {goal}, woke {date}'**
  String sessionHeroSpoken(String duration, String goal, String date);

  /// No description provided for @nightContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Night summary'**
  String get nightContextTitle;

  /// No description provided for @nightContextNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Not enough nights yet.'**
  String get nightContextNotEnough;

  /// No description provided for @nightContextDurationDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} vs your {nights, plural, =1{1-night} other{{nights}-night}} average'**
  String nightContextDurationDelta(String delta, int nights);

  /// No description provided for @nightContextDurationEven.
  ///
  /// In en, this message translates to:
  /// **'Same as your {nights, plural, =1{1-night} other{{nights}-night}} average'**
  String nightContextDurationEven(int nights);

  /// No description provided for @nightContextBedtimeLater.
  ///
  /// In en, this message translates to:
  /// **'Bedtime {delta} later'**
  String nightContextBedtimeLater(String delta);

  /// No description provided for @nightContextBedtimeEarlier.
  ///
  /// In en, this message translates to:
  /// **'Bedtime {delta} earlier'**
  String nightContextBedtimeEarlier(String delta);

  /// No description provided for @nightContextBedtimeEven.
  ///
  /// In en, this message translates to:
  /// **'Bedtime on your average'**
  String get nightContextBedtimeEven;

  /// No description provided for @nightContextWakeLater.
  ///
  /// In en, this message translates to:
  /// **'Wake {delta} later'**
  String nightContextWakeLater(String delta);

  /// No description provided for @nightContextWakeEarlier.
  ///
  /// In en, this message translates to:
  /// **'Wake {delta} earlier'**
  String nightContextWakeEarlier(String delta);

  /// No description provided for @nightContextWakeEven.
  ///
  /// In en, this message translates to:
  /// **'Wake on your average'**
  String get nightContextWakeEven;

  /// No description provided for @nightContextLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest session in this range'**
  String get nightContextLongest;

  /// No description provided for @nightContextRanked.
  ///
  /// In en, this message translates to:
  /// **'{ordinal} longest session in this range'**
  String nightContextRanked(String ordinal);

  /// No description provided for @nightContextSplitNight.
  ///
  /// In en, this message translates to:
  /// **'One of {count, plural, =1{1 session} other{{count} sessions}} that night'**
  String nightContextSplitNight(int count);

  /// No description provided for @goalDefault.
  ///
  /// In en, this message translates to:
  /// **'Your 8h goal'**
  String get goalDefault;

  /// No description provided for @goalMet.
  ///
  /// In en, this message translates to:
  /// **'Goal met'**
  String get goalMet;

  /// No description provided for @goalOver.
  ///
  /// In en, this message translates to:
  /// **'Goal met · {delta} over the 8h goal'**
  String goalOver(String delta);

  /// No description provided for @goalUnder.
  ///
  /// In en, this message translates to:
  /// **'{delta} short of the 8h goal'**
  String goalUnder(String delta);

  /// No description provided for @spokenGoalDefault.
  ///
  /// In en, this message translates to:
  /// **'8-hour goal'**
  String get spokenGoalDefault;

  /// No description provided for @spokenGoalMet.
  ///
  /// In en, this message translates to:
  /// **'goal met'**
  String get spokenGoalMet;

  /// No description provided for @spokenGoalOver.
  ///
  /// In en, this message translates to:
  /// **'goal met, {delta} over the 8-hour goal'**
  String spokenGoalOver(String delta);

  /// No description provided for @spokenGoalUnder.
  ///
  /// In en, this message translates to:
  /// **'{delta} short of the 8-hour goal'**
  String spokenGoalUnder(String delta);

  /// No description provided for @sessionDateTimeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title} date and time'**
  String sessionDateTimeSemantics(String title);

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get discardChangesTitle;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete session?'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get deleteSessionAction;

  /// No description provided for @deleteMessageHealth.
  ///
  /// In en, this message translates to:
  /// **'This night will be deleted from Google Health. Its local copy is removed too when there is one.'**
  String get deleteMessageHealth;

  /// No description provided for @deleteMessageHealthAndLocal.
  ///
  /// In en, this message translates to:
  /// **'This night will be deleted from Sleepy3 and Google Health.'**
  String get deleteMessageHealthAndLocal;

  /// No description provided for @deleteMessageLocal.
  ///
  /// In en, this message translates to:
  /// **'This night will be deleted from Sleepy3.'**
  String get deleteMessageLocal;

  /// No description provided for @healthNeedsPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Health needs permission'**
  String get healthNeedsPermissionTitle;

  /// No description provided for @allowWriteHealth.
  ///
  /// In en, this message translates to:
  /// **'Allow Sleepy3 to write sleep data in Google Health, then try again.'**
  String get allowWriteHealth;

  /// No description provided for @allowDeleteHealth.
  ///
  /// In en, this message translates to:
  /// **'Allow Sleepy3 to delete this session from Google Health, then try again.'**
  String get allowDeleteHealth;

  /// No description provided for @allowDeleteHealthShort.
  ///
  /// In en, this message translates to:
  /// **'Allow Sleepy3 to delete this session from Google Health.'**
  String get allowDeleteHealthShort;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save'**
  String get couldNotSave;

  /// No description provided for @couldNotSaveBody.
  ///
  /// In en, this message translates to:
  /// **'The session could not be saved. Try again.'**
  String get couldNotSaveBody;

  /// No description provided for @couldNotAdd.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add session'**
  String get couldNotAdd;

  /// No description provided for @couldNotAddBody.
  ///
  /// In en, this message translates to:
  /// **'The session could not be added. Try again.'**
  String get couldNotAddBody;

  /// No description provided for @couldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete'**
  String get couldNotDelete;

  /// No description provided for @couldNotDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The session could not be deleted. Try again.'**
  String get couldNotDeleteBody;

  /// No description provided for @healthNoticeStored.
  ///
  /// In en, this message translates to:
  /// **'This night is stored in Google Health. Saving updates the Health Connect record.'**
  String get healthNoticeStored;

  /// No description provided for @healthNoticeBoth.
  ///
  /// In en, this message translates to:
  /// **'This night is also in Google Health. Saving updates both copies.'**
  String get healthNoticeBoth;

  /// No description provided for @healthNoticeAdded.
  ///
  /// In en, this message translates to:
  /// **'This night will be added to Google Health.'**
  String get healthNoticeAdded;

  /// No description provided for @readOnlyOtherBuild.
  ///
  /// In en, this message translates to:
  /// **'This session was created in {app}, so it can\'t be edited from this build.'**
  String readOnlyOtherBuild(String app);

  /// No description provided for @readOnlySleepy3.
  ///
  /// In en, this message translates to:
  /// **'This session can\'t be edited from Sleepy3.'**
  String get readOnlySleepy3;

  /// No description provided for @readOnlyOtherApp.
  ///
  /// In en, this message translates to:
  /// **'This session was created in {app}, so it can\'t be edited from Sleepy3.'**
  String readOnlyOtherApp(String app);

  /// No description provided for @readOnlyDownloadedOtherBuild.
  ///
  /// In en, this message translates to:
  /// **'This session was created in {app}. Downloaded copies can\'t be edited from this build.'**
  String readOnlyDownloadedOtherBuild(String app);

  /// No description provided for @readOnlyDownloadedSleepy3.
  ///
  /// In en, this message translates to:
  /// **'This session was downloaded from Google Health. Switch to Google Health to edit it.'**
  String get readOnlyDownloadedSleepy3;

  /// No description provided for @readOnlyDownloadedOtherApp.
  ///
  /// In en, this message translates to:
  /// **'This session was created in {app}. Downloaded copies can\'t be edited in Local.'**
  String readOnlyDownloadedOtherApp(String app);

  /// No description provided for @readOnlyDownloadedUnknown.
  ///
  /// In en, this message translates to:
  /// **'This session was downloaded from Google Health. Downloaded copies can\'t be edited in Local.'**
  String get readOnlyDownloadedUnknown;

  /// No description provided for @errorEndNotAfterStart.
  ///
  /// In en, this message translates to:
  /// **'The wake time must be after the sleep time.'**
  String get errorEndNotAfterStart;

  /// No description provided for @errorTooShort.
  ///
  /// In en, this message translates to:
  /// **'A sleep session must be at least 10 minutes.'**
  String get errorTooShort;

  /// No description provided for @errorTooLong.
  ///
  /// In en, this message translates to:
  /// **'A sleep session cannot last 24 hours or longer.'**
  String get errorTooLong;

  /// No description provided for @errorStartInTheFuture.
  ///
  /// In en, this message translates to:
  /// **'The sleep time cannot be in the future.'**
  String get errorStartInTheFuture;

  /// No description provided for @errorEndInTheFuture.
  ///
  /// In en, this message translates to:
  /// **'The wake time cannot be in the future.'**
  String get errorEndInTheFuture;

  /// No description provided for @errorOverlapsClosedSession.
  ///
  /// In en, this message translates to:
  /// **'This session overlaps another sleep session.'**
  String get errorOverlapsClosedSession;

  /// No description provided for @errorOverlapsOpenSession.
  ///
  /// In en, this message translates to:
  /// **'This session overlaps the session in progress.'**
  String get errorOverlapsOpenSession;

  /// No description provided for @copySyncLastTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync last session?'**
  String get copySyncLastTitle;

  /// No description provided for @copyAddAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Add all previous sessions?'**
  String get copyAddAllTitle;

  /// No description provided for @copyDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download from Google Health?'**
  String get copyDownloadTitle;

  /// No description provided for @copySyncLastBody.
  ///
  /// In en, this message translates to:
  /// **'Send the most recent local session to Google Health.'**
  String get copySyncLastBody;

  /// No description provided for @copyAddAllBody.
  ///
  /// In en, this message translates to:
  /// **'Send every local session that is not in Google Health yet. Sessions you already added to Google Health manually may appear twice.'**
  String get copyAddAllBody;

  /// No description provided for @copyDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'Add every sleep session from Google Health to the local copy. Local sessions are not changed. Google Health also asks for access to your full history; without it, only the last 30 days are downloaded.'**
  String get copyDownloadBody;

  /// No description provided for @copySyncAction.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get copySyncAction;

  /// No description provided for @copyAddAllAction.
  ///
  /// In en, this message translates to:
  /// **'Add all'**
  String get copyAddAllAction;

  /// No description provided for @copyDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download all'**
  String get copyDownloadAction;

  /// No description provided for @copySyncingSession.
  ///
  /// In en, this message translates to:
  /// **'Syncing session.'**
  String get copySyncingSession;

  /// No description provided for @copySyncingSessions.
  ///
  /// In en, this message translates to:
  /// **'Syncing sessions.'**
  String get copySyncingSessions;

  /// No description provided for @copyDownloadingSessions.
  ///
  /// In en, this message translates to:
  /// **'Downloading sessions.'**
  String get copyDownloadingSessions;

  /// No description provided for @copyPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'This may take a moment.'**
  String get copyPleaseWait;

  /// No description provided for @copyCouldNotDownload.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download'**
  String get copyCouldNotDownload;

  /// No description provided for @copyCouldNotSync.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync'**
  String get copyCouldNotSync;

  /// No description provided for @copySomeFailed.
  ///
  /// In en, this message translates to:
  /// **'Some sessions weren\'t copied'**
  String get copySomeFailed;

  /// No description provided for @copyDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get copyDownloadComplete;

  /// No description provided for @copySyncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get copySyncComplete;

  /// No description provided for @copyNoSessions30Days.
  ///
  /// In en, this message translates to:
  /// **'There are no sleep sessions in the last 30 days of Google Health.'**
  String get copyNoSessions30Days;

  /// No description provided for @copyNoSessionsHealth.
  ///
  /// In en, this message translates to:
  /// **'There are no sleep sessions in Google Health.'**
  String get copyNoSessionsHealth;

  /// No description provided for @copyNoLocalSessions.
  ///
  /// In en, this message translates to:
  /// **'There are no local sessions to sync.'**
  String get copyNoLocalSessions;

  /// No description provided for @copySessionsSent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session sent to Google Health} other{{count} sessions sent to Google Health}}'**
  String copySessionsSent(int count);

  /// No description provided for @copySessionsSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session skipped} other{{count} sessions skipped}}'**
  String copySessionsSkipped(int count);

  /// No description provided for @copySessionsFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session failed} other{{count} sessions failed}}'**
  String copySessionsFailed(int count);

  /// No description provided for @copySessionsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session added} other{{count} sessions added}}'**
  String copySessionsAdded(int count);

  /// No description provided for @copySessionsUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session updated} other{{count} sessions updated}}'**
  String copySessionsUpdated(int count);

  /// No description provided for @copySessionsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session already up to date} other{{count} sessions already up to date}}'**
  String copySessionsUpToDate(int count);

  /// No description provided for @copyHistoryLimited.
  ///
  /// In en, this message translates to:
  /// **'{summary}. Only the last 30 days were downloaded. Allow full history in Google Health to copy older sessions.'**
  String copyHistoryLimited(String summary);

  /// No description provided for @healthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Health is not available on this device.'**
  String get healthUnavailable;

  /// No description provided for @healthUpdateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update Health Connect to use Google Health.'**
  String get healthUpdateRequired;

  /// No description provided for @healthPermissionRead.
  ///
  /// In en, this message translates to:
  /// **'Google Health needs permission to read sleep.'**
  String get healthPermissionRead;

  /// No description provided for @healthPermissionWrite.
  ///
  /// In en, this message translates to:
  /// **'Google Health needs permission to write sleep.'**
  String get healthPermissionWrite;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get copyFailed;

  /// No description provided for @historyLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Only the last 30 days are available'**
  String get historyLast30Days;

  /// No description provided for @historyLast30DaysAvailable.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days available'**
  String get historyLast30DaysAvailable;

  /// No description provided for @historyLast30DaysRange.
  ///
  /// In en, this message translates to:
  /// **'the last 30 days'**
  String get historyLast30DaysRange;

  /// No description provided for @historyAllowFullSupport.
  ///
  /// In en, this message translates to:
  /// **'Allow full history in Google Health to see older sessions.'**
  String get historyAllowFullSupport;

  /// No description provided for @historyAllowFullAction.
  ///
  /// In en, this message translates to:
  /// **'Allow full history'**
  String get historyAllowFullAction;

  /// No description provided for @historyPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Google Health needs permission to read older sleep sessions.'**
  String get historyPermissionDenied;

  /// No description provided for @syncBannerWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session waiting to sync} other{{count} sessions waiting to sync}}'**
  String syncBannerWaiting(int count);

  /// No description provided for @sleepDataSourceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the sleep data source.'**
  String get sleepDataSourceSaveFailed;

  /// No description provided for @timeRangeSeparator.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String timeRangeSeparator(String from, String to);

  /// No description provided for @timeRangeSpoken.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String timeRangeSpoken(String from, String to);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @spokenDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String spokenDurationMinutes(int minutes);

  /// No description provided for @spokenDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}} {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String spokenDurationHoursMinutes(int hours, int minutes);
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
