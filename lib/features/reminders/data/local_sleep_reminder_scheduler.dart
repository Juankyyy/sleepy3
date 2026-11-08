import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
  LocalSleepReminderScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? clock,
    VoidCallback? onTap,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _clock = clock ?? DateTime.now,
       _onNotificationTap = onTap;

  static const notificationId = 1001;
  static const channelId = 'sleep_reminder';

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _clock;
  final VoidCallback? _onNotificationTap;

  Future<void>? _initializing;
  bool _initialized = false;

  @override
  Future<bool> notificationsEnabled() async {
    await _ensureInitialized();
    final android = _android;
    if (android == null) return false;
    return await android.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final android = _android;
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission();
    if (granted == false) return false;
    // On Android 12 and older the request returns null because there is no
    // runtime permission. The notification block is still a valid answer.
    return await android.areNotificationsEnabled() ?? true;
  }

  @override
  Future<void> schedule({
    required SleepReminder reminder,
    required ReminderNotificationCopy copy,
  }) async {
    await _ensureInitialized();

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

    await _plugin.zonedSchedule(
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
    await _ensureInitialized();
    await _plugin.cancel(id: notificationId);
  }

  @override
  Future<void> openNotificationSettings() async {
    await _ensureInitialized();
    await _android?.openAppNotificationSettings();
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _ensureInitialized() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      tz_data.initializeTimeZones();
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));

      final initialized = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (_) => _onNotificationTap?.call(),
      );
      if (initialized == false) {
        throw StateError('The notification plugin did not initialize.');
      }
      _initialized = true;
    } catch (error, stackTrace) {
      _initializing = null;
      debugPrint(
        'Sleepy3: could not initialize notifications: $error\n$stackTrace',
      );
      rethrow;
    }
  }
}
