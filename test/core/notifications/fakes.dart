import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sleepy3/core/notifications/local_notifications.dart';

/// Drives [LocalNotifications] without the platform channel.
class FakeNotificationPlatform {
  FakeNotificationPlatform({this.launchDetails});

  final NotificationAppLaunchDetails? launchDetails;
  DidReceiveNotificationResponseCallback? onResponse;
  bool initialized = false;

  /// The real class with the plugin behavior replaced by this fake.
  LocalNotifications build() {
    return LocalNotifications(
      initialize: initialize,
      readLaunchDetails: () async => launchDetails,
    );
  }

  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    initialized = true;
    onResponse = onDidReceiveNotificationResponse;
    return true;
  }

  /// Simulates a tap or action tap while the app is running.
  void emit(NotificationResponse response) => onResponse?.call(response);
}
