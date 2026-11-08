import 'reminder_notification_copy.dart';
import 'sleep_reminder.dart';

/// Schedules the optional daily reminder in the operating system.
///
/// Implementations are platform-backed; tests use a fake so permission and
/// scheduling outcomes can be controlled.
abstract interface class SleepReminderScheduler {
  /// Whether the app can currently post notifications.
  Future<bool> notificationsEnabled();

  /// Asks Android for notification permission when the user enables the
  /// reminder. Returns whether notifications are now allowed.
  Future<bool> requestPermission();

  /// Replaces the pending reminder with the one described by [reminder].
  Future<void> schedule({
    required SleepReminder reminder,
    required ReminderNotificationCopy copy,
  });

  /// Cancels the pending reminder and any copy already shown.
  Future<void> cancel();

  /// Opens the app's notification settings in Android.
  Future<void> openNotificationSettings();
}
