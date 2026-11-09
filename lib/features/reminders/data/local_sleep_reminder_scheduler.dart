import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/notifications/local_notifications.dart';
import '../domain/reminder_notification_copy.dart';
import '../domain/sleep_reminder.dart';
import '../domain/sleep_reminder_scheduler.dart';

/// Schedules the reminder through Android's AlarmManager using
/// `flutter_local_notifications`.
///
/// The callbacks are intentionally small. A tap opens the app, and the
/// application layer decides which screen to show; the scheduler only reports
/// that the notification was tapped.
class LocalSleepReminderScheduler implements SleepReminderScheduler {
  LocalSleepReminderScheduler(this._notifications, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const notificationId = 1001;
  static const channelId = 'sleep_reminder';

  final LocalNotifications _notifications;
  final DateTime Function() _clock;

  Future<void>? _timeZonesInitializing;

  @override
  Future<bool> notificationsEnabled() {
    return _notifications.notificationsEnabled();
  }

  @override
  Future<bool> requestPermission() {
    return _notifications.requestPermission();
  }

  @override
  Future<void> schedule({
    required SleepReminder reminder,
    required ReminderNotificationCopy copy,
  }) async {
    await _notifications.ensureInitialized();
    await _ensureTimeZones();

    final next = nextSleepReminderOccurrence(
      _clock(),
      hour: reminder.hour,
      minute: reminder.minute,
    );
    final scheduledDate = tz.TZDateTime.from(next, tz.local);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        copy.channelName,
        channelDescription: copy.channelDescription,
        icon: 'ic_notification',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
    );

    await _notifications.plugin.zonedSchedule(
      id: notificationId,
      title: copy.title,
      body: copy.body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'sleep-reminder',
    );
  }

  @override
  Future<void> cancel() async {
    await _notifications.ensureInitialized();
    await _notifications.plugin.cancel(id: notificationId);
  }

  @override
  Future<void> openNotificationSettings() {
    return _notifications.openNotificationSettings();
  }

  Future<void> _ensureTimeZones() {
    return _timeZonesInitializing ??= _initializeTimeZones();
  }

  Future<void> _initializeTimeZones() async {
    try {
      tz_data.initializeTimeZones();
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));
    } catch (error, stackTrace) {
      _timeZonesInitializing = null;
      debugPrint(
        'Sleepy3: could not initialize time zones: $error\n$stackTrace',
      );
      rethrow;
    }
  }
}
