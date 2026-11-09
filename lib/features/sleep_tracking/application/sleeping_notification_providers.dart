import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../data/native_sleeping_notification_presenter.dart';
import '../domain/sleeping_notification_presenter.dart';

/// The platform presenter used by `SleepingNotificationController`.
///
/// Tests override it with a fake. The native bridge draws the custom card while
/// the shared plugin still owns the permission checks and the daily reminder.
final sleepingNotificationPresenterProvider =
    Provider<SleepingNotificationPresenter>((ref) {
      return NativeSleepingNotificationPresenter(
        ref.watch(localNotificationsProvider),
        onOpened: () {
          ref.read(notificationHomeRequestProvider.notifier).requestHome();
        },
      );
    });
