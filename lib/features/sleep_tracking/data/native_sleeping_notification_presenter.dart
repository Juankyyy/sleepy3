import 'package:flutter/services.dart';

import '../../../core/notifications/local_notifications.dart';
import '../domain/sleeping_notification_presenter.dart';

/// Posts the sleep-status notification through the native card bridge.
///
/// `flutter_local_notifications` does not expose RemoteViews, so the Kotlin
/// bridge owns the custom layout while this presenter keeps the shared
/// permission API and the rest of the notification logic in Dart.
class NativeSleepingNotificationPresenter
    implements SleepingNotificationPresenter {
  NativeSleepingNotificationPresenter(
    this._notifications, {
    required this.onOpened,
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handleCall);
  }

  static const channelName = 'com.sleepy3.app/sleeping_notification';

  final LocalNotifications _notifications;
  final VoidCallback onOpened;
  final MethodChannel _channel;

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
  }) {
    return _channel.invokeMethod<void>('show', {
      'startedAtMillis': startedAt.millisecondsSinceEpoch,
      'title': copy.title,
      'body': copy.body,
      'ongoingLabel': copy.ongoingLabel,
      'channelName': copy.channelName,
      'channelDescription': copy.channelDescription,
    });
  }

  @override
  Future<void> cancel() {
    return _channel.invokeMethod<void>('cancel');
  }

  @override
  Future<void> openNotificationSettings() {
    return _notifications.openNotificationSettings();
  }

  Future<Object?> _handleCall(MethodCall call) async {
    if (call.method == 'opened') onOpened();
    return null;
  }
}
