import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_notifications.dart';

/// The plugin shared by every local notification in the app.
///
/// Taps and action taps are delivered as a stream; [Sleepy3App] listens and
/// routes them, so this core provider stays independent from the features.
final localNotificationsProvider = Provider<LocalNotifications>((ref) {
  return LocalNotifications();
});

/// Increments whenever a local notification is tapped.
///
/// `Sleepy3Shell` listens to it and selects Home, so the user lands on the
/// large Sleep action even when another tab was open.
final notificationHomeRequestProvider =
    NotifierProvider<NotificationHomeRequestController, int>(
      NotificationHomeRequestController.new,
    );

class NotificationHomeRequestController extends Notifier<int> {
  @override
  int build() => 0;

  void requestHome() => state++;
}

/// Set when the ongoing sleep card's Wake action is tapped.
///
/// `SleepHomeScreen` listens and runs the same Wake flow as the large action,
/// including the short and long sleep confirmations. The request is consumed
/// with [NotificationWakeRequestController.take] so a rebuilt Home cannot
/// close a newer session by replaying an old tap.
final notificationWakeRequestProvider =
    NotifierProvider<NotificationWakeRequestController, bool>(
      NotificationWakeRequestController.new,
    );

class NotificationWakeRequestController extends Notifier<bool> {
  @override
  bool build() => false;

  void requestWake() => state = true;

  /// Returns whether a Wake was pending and clears it.
  bool take() {
    if (!state) return false;
    state = false;
    return true;
  }
}
