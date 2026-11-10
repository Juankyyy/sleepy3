// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get apply => 'Apply';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get allow => 'Allow';

  @override
  String get notNow => 'Not now';

  @override
  String get navHome => 'Home';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get mainNavigation => 'Main navigation';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSupport =>
      'Theme, stats, reminders, sleep data and app info.';

  @override
  String get appearance => 'Appearance';

  @override
  String get reminders => 'Reminders';

  @override
  String get sleepReminder => 'Sleep reminder';

  @override
  String get sleepReminderOff => 'Off';

  @override
  String sleepReminderEveryDay(String time) {
    return 'Every day at $time';
  }

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get notificationsOff => 'Notifications are off';

  @override
  String get notificationsOffSupport =>
      'Allow Sleepy3 to send the notification.';

  @override
  String get notificationsPermissionNeeded =>
      'Allow notifications to get the sleep reminder.';

  @override
  String get sleepReminderScheduleFailed =>
      'Couldn\'t set the sleep reminder. Try again.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get sleepReminderNotificationTitle => 'Time to record your sleep';

  @override
  String get sleepReminderNotificationBody =>
      'Open Sleepy3 and tap Sleep when you turn off the lights.';

  @override
  String get sleepReminderChannelName => 'Sleep reminder';

  @override
  String get sleepReminderChannelDescription =>
      'A nightly reminder to record your sleep.';

  @override
  String get sleepingNotificationTitle => 'Sleeping';

  @override
  String sleepingNotificationBody(String goal, String time) {
    return 'Goal $goal · until $time';
  }

  @override
  String get sleepingNotificationChannelName => 'Sleep status';

  @override
  String get sleepingNotificationChannelDescription =>
      'A quiet timer while a sleep session is active.';

  @override
  String get sleepingNotificationOngoing => 'In progress';

  @override
  String get sleepStatusNotification => 'Sleep in progress';

  @override
  String get sleepStatusNotificationSupport =>
      'Shows a live timer while you sleep.';

  @override
  String get sleepStatusNotificationOff => 'Off';

  @override
  String get sleepStatusNotificationPermissionNeeded =>
      'Allow notifications to show your sleep status.';

  @override
  String get sleepData => 'Sleep data';

  @override
  String get googleHealth => 'Google Health';

  @override
  String get about => 'About';

  @override
  String get theme => 'Theme';

  @override
  String get timeFormat => 'Time format';

  @override
  String get language => 'Language';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get timeFormat12 => '12-hour';

  @override
  String get timeFormat24 => '24-hour';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get privacy => 'Privacy';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Licenses';

  @override
  String get privacyLocal => 'On-device only.';

  @override
  String get privacyHealth =>
      'Stored in Health Connect. Google Health can read it.';

  @override
  String get source => 'Source';

  @override
  String get import => 'Import';

  @override
  String get importSupport => 'Download from Google Health to the local copy.';

  @override
  String get sleepDataSourceDialogTitle => 'Sleep data source';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceHealth => 'Google Health';

  @override
  String get copyLocalSessionsTitle => 'Copy local sessions?';

  @override
  String localSessionsNotInHealth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count local sessions are not in Google Health yet.',
      one: '1 local session is not in Google Health yet.',
    );
    return '$_temp0';
  }

  @override
  String get sync => 'Sync';

  @override
  String get add => 'Add';

  @override
  String get syncRecentSupport => 'Send the most recent one.';

  @override
  String get addAllSupport => 'Send every local session.';

  @override
  String get status => 'Status';

  @override
  String get connected => 'Connected';

  @override
  String connectedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Connected · $count pending',
      one: 'Connected · 1 pending',
    );
    return '$_temp0';
  }

  @override
  String connectedLastSync(String time) {
    return 'Connected · Last sync $time';
  }

  @override
  String get permissionNeeded => 'Permission needed';

  @override
  String get notAvailable => 'Not available';

  @override
  String get updateRequired => 'Update required';

  @override
  String get checking => 'Checking.';

  @override
  String get connect => 'Connect';

  @override
  String get connectSupport => 'Allow Sleepy3 to read and write sleep.';

  @override
  String get install => 'Install';

  @override
  String get installSupport => 'Get or update Health Connect.';

  @override
  String get syncSupport => 'Send the most recent local session.';

  @override
  String get addSupport => 'Send local sessions that aren\'t in Google Health.';

  @override
  String get healthPermissionReadWrite =>
      'Google Health needs permission to read and write sleep.';

  @override
  String get sleepAction => 'Sleep';

  @override
  String get wakeAction => 'Wake';

  @override
  String get slideToWake => 'Slide to wake';

  @override
  String get slideToWakeHint =>
      'Slide the circle to the right, or double tap to confirm.';

  @override
  String get wakeSlideJustNow => 'Just now';

  @override
  String get wakeSlideJustNowSemantics =>
      'You just fell asleep. Slide to wake.';

  @override
  String wakeSlideSemantics(String duration) {
    return 'Sleeping for $duration. Slide to wake.';
  }

  @override
  String get savingSession => 'Saving session';

  @override
  String get sessionSaved => 'Session saved';

  @override
  String get sessionDiscarded => 'Session discarded';

  @override
  String get sessionSaveFailed => 'Couldn\'t save the session';

  @override
  String get dayStatus => 'Day · ready to wake';

  @override
  String get nightStatus => 'Night · time to rest';

  @override
  String get dayStatusSpoken => 'Day, ready to wake';

  @override
  String get nightStatusSpoken => 'Night, time to rest';

  @override
  String currentTime(String time) {
    return 'Current time $time';
  }

  @override
  String sleepingSince(String time) {
    return 'Sleeping since $time';
  }

  @override
  String lastSession(String duration) {
    return 'Last session: $duration';
  }

  @override
  String get noActiveSession => 'No active session';

  @override
  String get tapSleepAtNight => 'Tap Sleep when you turn off the lights';

  @override
  String get sleepTooShortTitle => 'Sleep too short';

  @override
  String get sleepTooShortBody =>
      'Sleeps shorter than 10 minutes are not recorded. Are you sure you want to discard this session?';

  @override
  String get keepSleeping => 'Keep sleeping';

  @override
  String get discardSession => 'Discard session';

  @override
  String get sleepTooLongTitle => 'Sleep too long';

  @override
  String get sleepTooLongBody =>
      'Sleeps longer than 24 hours are not recorded. Edit the start time to keep this session, or discard it.';

  @override
  String get editStartTime => 'Edit start time';

  @override
  String get startTimeNotSaved => 'Start time not saved';

  @override
  String get selectSleepDate => 'Select sleep date';

  @override
  String get selectSleepTime => 'Select sleep time';

  @override
  String get selectWakeDate => 'Select wake date';

  @override
  String get selectWakeTime => 'Select wake time';

  @override
  String get last3Days => 'Last 3 days';

  @override
  String last3DaysAverage(String average) {
    return 'Last 3 days · $average avg';
  }

  @override
  String get last3DaysNoAverage => 'Last 3 days · — avg';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get noAverageSpoken => ', no average';

  @override
  String averageSpoken(String duration) {
    return ', average $duration';
  }

  @override
  String get noSessionSpoken => 'no session';

  @override
  String get loadingSleepHistorySemantic => 'Loading sleep history';

  @override
  String get loadingSleepHistory => 'Loading sleep history…';

  @override
  String get historyLoadError => 'Couldn\'t load your sleep history';

  @override
  String get historyLoadErrorSupport => 'Your sessions are safe. Try again.';

  @override
  String get statsTitle => 'Stats';

  @override
  String get statsSupport => 'Your sleep, night by night.';

  @override
  String statsSupportingSleeping(String time) {
    return 'Sleeping since $time · it will appear when you wake.';
  }

  @override
  String get advancedStatsTitle => 'Advanced stats';

  @override
  String get advancedStatsAction => 'View advanced stats';

  @override
  String get statsSummary => 'Stats summary';

  @override
  String get statsSummarySupport =>
      'Choose the block shown above View advanced stats. Only one at a time.';

  @override
  String statsSummaryCurrentBlock(String block) {
    return 'Current block: $block';
  }

  @override
  String get statsSummaryKeyMetrics => 'Key metrics';

  @override
  String get statsSummaryKeyData => 'Key data';

  @override
  String get history => 'History';

  @override
  String get timeRange => 'Time range';

  @override
  String get rangeWeek => 'Week';

  @override
  String get rangeMonth => 'Month';

  @override
  String get rangeThreeMonths => '3 months';

  @override
  String get rangeYear => 'Year';

  @override
  String get rangeAll => 'All';

  @override
  String get averageSleep => 'Average sleep';

  @override
  String get noNightsInRange => 'No nights in this range';

  @override
  String summarySupporting(int nights, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
    );
    return 'Across $_temp0 · $total total';
  }

  @override
  String get showAll => 'Show all';

  @override
  String summarySpoken(String average, int nights, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
    );
    return 'Average sleep $average, across $_temp0, $total total';
  }

  @override
  String get summarySpokenNoNights => 'Average sleep, no nights in this range';

  @override
  String heroCoverageWindow(int recorded, int window) {
    String _temp0 = intl.Intl.pluralLogic(
      window,
      locale: localeName,
      other: '$window nights',
      one: '1 night',
    );
    return '$recorded of $_temp0';
  }

  @override
  String heroCoverageAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights recorded',
      one: '1 night recorded',
    );
    return '$_temp0';
  }

  @override
  String heroComparison(String previous, String delta) {
    return 'vs $previous: $delta';
  }

  @override
  String get previousRangeWeek => 'previous week';

  @override
  String get previousRangeMonth => 'previous month';

  @override
  String get previousRangeThreeMonths => 'previous 3 months';

  @override
  String get previousRangeYear => 'previous year';

  @override
  String get metricGoalHitRate => 'Goal hit rate';

  @override
  String metricGoalHitSupport(int met, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total nights',
      one: '1 night',
    );
    return '$met of $_temp0';
  }

  @override
  String metricPercent(int percent) {
    return '$percent%';
  }

  @override
  String get metricScheduleConsistency => 'Schedule consistency';

  @override
  String get metricBedtime => 'bedtime';

  @override
  String metricVariability(String duration) {
    return '±$duration';
  }

  @override
  String get metricSleepBalance => 'Sleep balance';

  @override
  String metricBalanceSurplus(String goal) {
    return 'surplus · vs $goal goal';
  }

  @override
  String metricBalanceDebt(String goal) {
    return 'debt · vs $goal goal';
  }

  @override
  String metricBalanceEven(String goal) {
    return 'even · vs $goal goal';
  }

  @override
  String get metricBestStreak => 'Best streak';

  @override
  String metricBestStreakSupport(int count) {
    return 'current $count';
  }

  @override
  String metricNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String get metricNeedsTwoNights => 'Needs 2 nights';

  @override
  String durationSignedPositive(String duration) {
    return '+$duration';
  }

  @override
  String durationSignedNegative(String duration) {
    return '−$duration';
  }

  @override
  String get chartSleepDurationTitle => 'Sleep duration';

  @override
  String chartSleepDurationSupport(String range, int nights, String goal) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights recorded',
      one: '1 night recorded',
    );
    return '$range · $_temp0 · Goal $goal';
  }

  @override
  String chartTooltipDate(String date, String duration) {
    return '$date · $duration';
  }

  @override
  String chartTooltipSessions(String date, String duration, int sessions) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sessions',
      one: '1 session',
    );
    return '$date · $duration · $_temp0';
  }

  @override
  String chartTooltipAverageValue(String duration) {
    return '$duration avg';
  }

  @override
  String chartTooltipNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String chartTooltipNoData(String range) {
    return '$range · No night recorded';
  }

  @override
  String chartDurationSpoken(
    String range,
    String average,
    String best,
    String worst,
    int short,
    int missing,
    String goal,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: '$short nights under the $goal goal',
      one: '1 night under the $goal goal',
      zero: 'No nights under the $goal goal',
    );
    String _temp1 = intl.Intl.pluralLogic(
      missing,
      locale: localeName,
      other: '$missing nights with no data',
      one: '1 night with no data',
      zero: 'No nights without data',
    );
    return 'Sleep duration for $range. Average $average. Best night $best. Shortest night $worst. $_temp0. $_temp1.';
  }

  @override
  String get chartSleepWindowTitle => 'Sleep window';

  @override
  String chartSleepWindowSupport(String range) {
    return 'Bedtime to wake · $range';
  }

  @override
  String chartWindowSpoken(
    String range,
    String bedtime,
    String wake,
    int missing,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      missing,
      locale: localeName,
      other: '$missing nights have no data',
      one: '1 night has no data',
      zero: 'Every night has data',
    );
    return 'Sleep window for $range. Average bedtime $bedtime and average wake $wake. $_temp0.';
  }

  @override
  String get chartWeekdayTitle => 'By weekday';

  @override
  String chartWeekdaySupport(String range) {
    return 'Average by wake day · $range';
  }

  @override
  String get chartWeekdayBest => 'Best';

  @override
  String chartWeekdaySpoken(
    String range,
    String best,
    String average,
    int count,
  ) {
    return 'Average sleep by weekday for $range. $best is the longest average with $average. $count of 7 weekdays have data.';
  }

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightBestNight => 'Best night';

  @override
  String get insightShortestNight => 'Shortest night';

  @override
  String get insightAverageBedtime => 'Average bedtime';

  @override
  String get insightAverageWake => 'Average wake';

  @override
  String get insightBedtimeVariability => 'Bedtime varies by';

  @override
  String get insightSplitNights => 'Nights with more than one session';

  @override
  String get insightDistribution => 'Distribution';

  @override
  String insightDistributionSpoken(
    int underSix,
    int sixToSeven,
    int sevenToEight,
    int eightToNine,
    int ninePlus,
  ) {
    return 'Sleep duration distribution. $underSix nights under 6 hours, $sixToSeven from 6 to 7 hours, $sevenToEight from 7 to 8 hours, $eightToNine from 8 to 9 hours and $ninePlus of 9 hours or more.';
  }

  @override
  String get sleepBandUnderSix => 'Under 6h';

  @override
  String get sleepBandSixToSeven => '6–7h';

  @override
  String get sleepBandSevenToEight => '7–8h';

  @override
  String get sleepBandEightToNine => '8–9h';

  @override
  String get sleepBandNinePlus => '9h+';

  @override
  String get noSleepHistoryHealth => 'No sleep history in Google Health';

  @override
  String get noSleepHistory => 'No sleep history yet';

  @override
  String get noSleepHistoryHealthSupport =>
      'Sleep sessions in Health Connect will appear here.';

  @override
  String get noSleepHistorySleepingSupport =>
      'Your first night will appear here when you wake up.';

  @override
  String get noSleepHistorySupport =>
      'Your nights will appear here after you wake up.';

  @override
  String get refreshSleepHistory => 'Refresh sleep history';

  @override
  String get refreshingSleepHistory => 'Refreshing sleep history';

  @override
  String get refreshFailed =>
      'Couldn\'t refresh your sleep history. Try again.';

  @override
  String get sessionSavedPendingSync =>
      'Saved. Google Health will update when it can.';

  @override
  String get sessionDeleted => 'Session deleted.';

  @override
  String get sessionSavedLocallyPermission =>
      'Saved locally. Allow Google Health write access to sync it.';

  @override
  String get sessionAddedHealth => 'Session added to Google Health.';

  @override
  String get sessionAdded => 'Session added.';

  @override
  String get sessionSavedLocally =>
      'Session saved locally. Google Health will update when it can.';

  @override
  String get addSleepSession => 'Add a sleep session';

  @override
  String get opensSession => 'Opens the session';

  @override
  String get anotherApp => 'Another app';

  @override
  String get anotherAppLower => 'another app';

  @override
  String readOnlyFrom(String app) {
    return 'Read-only, from $app';
  }

  @override
  String get readOnlySession => 'Read-only session';

  @override
  String get otherSleepy3Build => 'another Sleepy3 build';

  @override
  String get goalMetLower => 'goal met';

  @override
  String get sessionTitle => 'Session';

  @override
  String get newSessionTitle => 'New session';

  @override
  String get addAction => 'Add';

  @override
  String get fellAsleep => 'Fell asleep';

  @override
  String get wokeUp => 'Woke up';

  @override
  String wokeOn(String date) {
    return 'Woke $date';
  }

  @override
  String sessionHeroSpoken(String duration, String goal, String date) {
    return '$duration, $goal, woke $date';
  }

  @override
  String get nightContextTitle => 'Night summary';

  @override
  String get nightContextNotEnough => 'Not enough nights yet.';

  @override
  String nightContextDurationDelta(String delta, int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights-night',
      one: '1-night',
    );
    return '$delta vs your $_temp0 average';
  }

  @override
  String nightContextDurationEven(int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights-night',
      one: '1-night',
    );
    return 'Same as your $_temp0 average';
  }

  @override
  String nightContextBedtimeLater(String delta) {
    return 'Bedtime $delta later';
  }

  @override
  String nightContextBedtimeEarlier(String delta) {
    return 'Bedtime $delta earlier';
  }

  @override
  String get nightContextBedtimeEven => 'Bedtime on your average';

  @override
  String nightContextWakeLater(String delta) {
    return 'Wake $delta later';
  }

  @override
  String nightContextWakeEarlier(String delta) {
    return 'Wake $delta earlier';
  }

  @override
  String get nightContextWakeEven => 'Wake on your average';

  @override
  String get nightContextLongest => 'Longest session in this range';

  @override
  String nightContextRanked(String ordinal) {
    return '$ordinal longest session in this range';
  }

  @override
  String nightContextSplitNight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return 'One of $_temp0 that night';
  }

  @override
  String get goalDefault => 'Your 8h goal';

  @override
  String get goalMet => 'Goal met';

  @override
  String goalOver(String delta) {
    return 'Goal met · $delta over the 8h goal';
  }

  @override
  String goalUnder(String delta) {
    return '$delta short of the 8h goal';
  }

  @override
  String get spokenGoalDefault => '8-hour goal';

  @override
  String get spokenGoalMet => 'goal met';

  @override
  String spokenGoalOver(String delta) {
    return 'goal met, $delta over the 8-hour goal';
  }

  @override
  String spokenGoalUnder(String delta) {
    return '$delta short of the 8-hour goal';
  }

  @override
  String sessionDateTimeSemantics(String title) {
    return '$title date and time';
  }

  @override
  String get discardChangesTitle => 'Discard unsaved changes?';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get deleteSessionTitle => 'Delete session?';

  @override
  String get deleteSessionAction => 'Delete session';

  @override
  String get deleteMessageHealth =>
      'This night will be deleted from Google Health. Its local copy is removed too when there is one.';

  @override
  String get deleteMessageHealthAndLocal =>
      'This night will be deleted from Sleepy3 and Google Health.';

  @override
  String get deleteMessageLocal => 'This night will be deleted from Sleepy3.';

  @override
  String get healthNeedsPermissionTitle => 'Google Health needs permission';

  @override
  String get allowWriteHealth =>
      'Allow Sleepy3 to write sleep data in Google Health, then try again.';

  @override
  String get allowDeleteHealth =>
      'Allow Sleepy3 to delete this session from Google Health, then try again.';

  @override
  String get allowDeleteHealthShort =>
      'Allow Sleepy3 to delete this session from Google Health.';

  @override
  String get couldNotSave => 'Couldn\'t save';

  @override
  String get couldNotSaveBody => 'The session could not be saved. Try again.';

  @override
  String get couldNotAdd => 'Couldn\'t add session';

  @override
  String get couldNotAddBody => 'The session could not be added. Try again.';

  @override
  String get couldNotDelete => 'Couldn\'t delete';

  @override
  String get couldNotDeleteBody =>
      'The session could not be deleted. Try again.';

  @override
  String get healthNoticeStored =>
      'This night is stored in Google Health. Saving updates the Health Connect record.';

  @override
  String get healthNoticeBoth =>
      'This night is also in Google Health. Saving updates both copies.';

  @override
  String get healthNoticeAdded => 'This night will be added to Google Health.';

  @override
  String readOnlyOtherBuild(String app) {
    return 'This session was created in $app, so it can\'t be edited from this build.';
  }

  @override
  String get readOnlySleepy3 => 'This session can\'t be edited from Sleepy3.';

  @override
  String readOnlyOtherApp(String app) {
    return 'This session was created in $app, so it can\'t be edited from Sleepy3.';
  }

  @override
  String readOnlyDownloadedOtherBuild(String app) {
    return 'This session was created in $app. Downloaded copies can\'t be edited from this build.';
  }

  @override
  String get readOnlyDownloadedSleepy3 =>
      'This session was downloaded from Google Health. Switch to Google Health to edit it.';

  @override
  String readOnlyDownloadedOtherApp(String app) {
    return 'This session was created in $app. Downloaded copies can\'t be edited in Local.';
  }

  @override
  String get readOnlyDownloadedUnknown =>
      'This session was downloaded from Google Health. Downloaded copies can\'t be edited in Local.';

  @override
  String get errorEndNotAfterStart =>
      'The wake time must be after the sleep time.';

  @override
  String get errorTooShort => 'A sleep session must be at least 10 minutes.';

  @override
  String get errorTooLong => 'A sleep session cannot last 24 hours or longer.';

  @override
  String get errorStartInTheFuture => 'The sleep time cannot be in the future.';

  @override
  String get errorEndInTheFuture => 'The wake time cannot be in the future.';

  @override
  String get errorOverlapsClosedSession =>
      'This session overlaps another sleep session.';

  @override
  String get errorOverlapsOpenSession =>
      'This session overlaps the session in progress.';

  @override
  String get copySyncLastTitle => 'Sync last session?';

  @override
  String get copyAddAllTitle => 'Add all previous sessions?';

  @override
  String get copyDownloadTitle => 'Download from Google Health?';

  @override
  String get copySyncLastBody =>
      'Send the most recent local session to Google Health.';

  @override
  String get copyAddAllBody =>
      'Send every local session that is not in Google Health yet. Sessions you already added to Google Health manually may appear twice.';

  @override
  String get copyDownloadBody =>
      'Add every sleep session from Google Health to the local copy. Local sessions are not changed. Google Health also asks for access to your full history; without it, only the last 30 days are downloaded.';

  @override
  String get copySyncAction => 'Sync';

  @override
  String get copyAddAllAction => 'Add all';

  @override
  String get copyDownloadAction => 'Download all';

  @override
  String get copySyncingSession => 'Syncing session.';

  @override
  String get copySyncingSessions => 'Syncing sessions.';

  @override
  String get copyDownloadingSessions => 'Downloading sessions.';

  @override
  String get copyPleaseWait => 'This may take a moment.';

  @override
  String get copyCouldNotDownload => 'Couldn\'t download';

  @override
  String get copyCouldNotSync => 'Couldn\'t sync';

  @override
  String get copySomeFailed => 'Some sessions weren\'t copied';

  @override
  String get copyDownloadComplete => 'Download complete';

  @override
  String get copySyncComplete => 'Sync complete';

  @override
  String get copyNoSessions30Days =>
      'There are no sleep sessions in the last 30 days of Google Health.';

  @override
  String get copyNoSessionsHealth =>
      'There are no sleep sessions in Google Health.';

  @override
  String get copyNoLocalSessions => 'There are no local sessions to sync.';

  @override
  String copySessionsSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions sent to Google Health',
      one: '1 session sent to Google Health',
    );
    return '$_temp0';
  }

  @override
  String copySessionsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions skipped',
      one: '1 session skipped',
    );
    return '$_temp0';
  }

  @override
  String copySessionsFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions failed',
      one: '1 session failed',
    );
    return '$_temp0';
  }

  @override
  String copySessionsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions added',
      one: '1 session added',
    );
    return '$_temp0';
  }

  @override
  String copySessionsUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions updated',
      one: '1 session updated',
    );
    return '$_temp0';
  }

  @override
  String copySessionsUpToDate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions already up to date',
      one: '1 session already up to date',
    );
    return '$_temp0';
  }

  @override
  String copyHistoryLimited(String summary) {
    return '$summary. Only the last 30 days were downloaded. Allow full history in Google Health to copy older sessions.';
  }

  @override
  String get healthUnavailable =>
      'Google Health is not available on this device.';

  @override
  String get healthUpdateRequired =>
      'Update Health Connect to use Google Health.';

  @override
  String get healthPermissionRead =>
      'Google Health needs permission to read sleep.';

  @override
  String get healthPermissionWrite =>
      'Google Health needs permission to write sleep.';

  @override
  String get copyFailed => 'Something went wrong. Try again.';

  @override
  String get historyLast30Days => 'Only the last 30 days are available';

  @override
  String get historyLast30DaysAvailable => 'Last 30 days available';

  @override
  String get historyLast30DaysRange => 'the last 30 days';

  @override
  String get historyAllowFullSupport =>
      'Allow full history in Google Health to see older sessions.';

  @override
  String get historyAllowFullAction => 'Allow full history';

  @override
  String get historyPermissionDenied =>
      'Google Health needs permission to read older sleep sessions.';

  @override
  String syncBannerWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions waiting to sync',
      one: '1 session waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get sleepDataSourceSaveFailed =>
      'Couldn\'t save the sleep data source.';

  @override
  String timeRangeSeparator(String from, String to) {
    return '$from – $to';
  }

  @override
  String timeRangeSpoken(String from, String to) {
    return '$from to $to';
  }

  @override
  String durationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String durationHours(int hours) {
    return '${hours}h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String spokenDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String spokenDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0 $_temp1';
  }
}
