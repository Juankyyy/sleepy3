import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_notifications.dart';

/// The plugin shared by every local notification in the app.
final localNotificationsProvider = Provider<LocalNotifications>((ref) {
  return LocalNotifications(
    onTap: () {
      ref.read(notificationHomeRequestProvider.notifier).requestHome();
    },
  );
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
