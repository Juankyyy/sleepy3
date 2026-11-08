/// The user's optional nightly reminder to record sleep.
///
/// The hour is kept in local wall-clock time: the notification repeats at the
/// same time every day, including across daylight-saving changes.
class SleepReminder {
  const SleepReminder({
    required this.enabled,
    required this.hour,
    required this.minute,
  }) : assert(hour >= 0 && hour < 24),
       assert(minute >= 0 && minute < 60);

  /// Disabled, at 22:00 until the user chooses another time.
  static const defaults = SleepReminder(enabled: false, hour: 22, minute: 0);

  final bool enabled;
  final int hour;
  final int minute;

  SleepReminder copyWith({bool? enabled, int? hour, int? minute}) {
    return SleepReminder(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  /// The stable format used in the `preferences` table, for example `22:00`.
  String get storageValue =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) {
    return other is SleepReminder &&
        other.enabled == enabled &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(enabled, hour, minute);
}

/// Parses a stored `HH:mm` value, returning null for missing or invalid data.
///
/// The settings store keeps the fallback decision separate so a malformed row
/// cannot change the reminder by accident.
({int hour, int minute})? parseReminderTime(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour >= 24 || minute < 0 || minute >= 60) return null;
  return (hour: hour, minute: minute);
}

/// The next local occurrence of [hour]:[minute], strictly after [now].
///
/// Uses calendar arithmetic rather than adding 24 hours so a daylight-saving
/// change cannot move the wall-clock time.
DateTime nextSleepReminderOccurrence(
  DateTime now, {
  required int hour,
  required int minute,
}) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  if (today.isAfter(now)) return today;
  return DateTime(now.year, now.month, now.day + 1, hour, minute);
}
