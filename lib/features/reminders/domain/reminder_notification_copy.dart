/// The localized text used by the scheduled sleep reminder.
///
/// The scheduler receives it from the application layer so the domain stays
/// independent from Flutter's localization delegates.
class ReminderNotificationCopy {
  const ReminderNotificationCopy({
    required this.title,
    required this.body,
    required this.startActionLabel,
    required this.channelName,
    required this.channelDescription,
  });

  final String title;
  final String body;

  /// The button that opens the app and starts a sleep session.
  final String startActionLabel;

  final String channelName;
  final String channelDescription;
}
