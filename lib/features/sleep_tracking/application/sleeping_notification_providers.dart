import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../data/local_sleeping_notification_presenter.dart';
import '../domain/sleeping_notification_presenter.dart';

/// The platform presenter used by `SleepingNotificationController`.
///
/// Tests override it with a fake. It shares the app's only notification plugin
/// with the daily reminder.
final sleepingNotificationPresenterProvider =
    Provider<SleepingNotificationPresenter>((ref) {
      return LocalSleepingNotificationPresenter(
        ref.watch(localNotificationsProvider),
      );
    });
