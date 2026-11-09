import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../data/local_sleep_reminder_scheduler.dart';
import '../domain/sleep_reminder.dart';
import '../domain/sleep_reminder_scheduler.dart';

/// Overridden in `main` with the value loaded before the first frame.
final initialSleepReminderProvider = Provider<SleepReminder>(
  (ref) => SleepReminder.defaults,
);

/// The platform scheduler used by `SleepReminderController`.
///
/// Tests override it with a fake. It shares the app's only notification plugin
/// with the sleep-status notification, so both taps open Home without
/// initializing `flutter_local_notifications` twice.
final sleepReminderSchedulerProvider = Provider<SleepReminderScheduler>((ref) {
  return LocalSleepReminderScheduler(ref.watch(localNotificationsProvider));
});
