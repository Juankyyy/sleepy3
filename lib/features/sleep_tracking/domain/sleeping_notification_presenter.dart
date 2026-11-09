/// The localized text used by the ongoing sleep-status notification.
///
/// The presenter receives it from the application layer so the domain stays
/// independent from Flutter's localization delegates.
class SleepingNotificationCopy {
  const SleepingNotificationCopy({
    required this.title,
    required this.body,
    required this.ongoingLabel,
    required this.channelName,
    required this.channelDescription,
  });

  final String title;
  final String body;

  /// A short header label such as `En curso` that explains why the card stays.
  final String ongoingLabel;

  final String channelName;
  final String channelDescription;
}

/// Publishes the ongoing notification shown while a sleep session is active.
///
/// Implementations are platform-backed; tests use a fake so permission and
/// display outcomes can be controlled.
abstract interface class SleepingNotificationPresenter {
  /// Whether the app can currently post notifications.
  Future<bool> notificationsEnabled();

  /// Asks Android for notification permission when a sleep starts.
  Future<bool> requestPermission();

  /// Shows or updates the sleep-status notification.
  ///
  /// The same notification id is reused, so calling this again refreshes the
  /// text and the chronometer base instead of creating a second notification.
  Future<void> show({
    required DateTime startedAt,
    required SleepingNotificationCopy copy,
  });

  /// Cancels the sleep-status notification.
  Future<void> cancel();
}
