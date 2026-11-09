import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/notifications/local_notifications.dart';
import '../domain/sleeping_notification_presenter.dart';

/// Publishes the sleep-status notification through the shared local
/// notification plugin.
class LocalSleepingNotificationPresenter
    implements SleepingNotificationPresenter {
  LocalSleepingNotificationPresenter(this._notifications);

  static const notificationId = 1002;
  static const channelId = 'sleep_status';

  final LocalNotifications _notifications;

  @override
  Future<bool> notificationsEnabled() {
    return _notifications.notificationsEnabled();
  }

  @override
  Future<bool> requestPermission() {
    return _notifications.requestPermission();
  }

  @override
  Future<void> show({
    required DateTime startedAt,
    required SleepingNotificationCopy copy,
  }) async {
    await _notifications.ensureInitialized();
    await _notifications.plugin.show(
      id: notificationId,
      title: copy.title,
      body: copy.body,
      notificationDetails: sleepingNotificationDetails(
        startedAt: startedAt,
        copy: copy,
      ),
      payload: 'sleeping',
    );
  }

  @override
  Future<void> cancel() async {
    await _notifications.ensureInitialized();
    await _notifications.plugin.cancel(id: notificationId);
  }
}

/// The Android notification used while a sleep session is active.
///
/// Android renders the elapsed time from [startedAt] with its own chronometer,
/// so it keeps counting even when the app process is gone. The channel is low
/// importance and silent, and the notification is ongoing: it is a status, not
/// an alert.
@visibleForTesting
NotificationDetails sleepingNotificationDetails({
  required DateTime startedAt,
  required SleepingNotificationCopy copy,
}) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      LocalSleepingNotificationPresenter.channelId,
      copy.channelName,
      channelDescription: copy.channelDescription,
      icon: 'ic_notification',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      channelShowBadge: false,
      silent: true,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: true,
      when: startedAt.millisecondsSinceEpoch,
      usesChronometer: true,
      category: AndroidNotificationCategory.stopwatch,
    ),
  );
}
