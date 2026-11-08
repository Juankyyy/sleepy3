import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/reminders/domain/sleep_reminder.dart';

void main() {
  group('SleepReminder', () {
    test('defaults to disabled at 22:00', () {
      expect(SleepReminder.defaults.enabled, isFalse);
      expect(SleepReminder.defaults.hour, 22);
      expect(SleepReminder.defaults.minute, 0);
    });

    test('stores the time as HH:mm', () {
      const reminder = SleepReminder(enabled: true, hour: 7, minute: 5);

      expect(reminder.storageValue, '07:05');
    });

    test('copies only the values that change', () {
      final reminder = SleepReminder.defaults.copyWith(
        enabled: true,
        hour: 23,
        minute: 30,
      );

      expect(reminder.enabled, isTrue);
      expect(reminder.hour, 23);
      expect(reminder.minute, 30);
    });
  });

  group('parseReminderTime', () {
    test('parses a valid stored time', () {
      expect(parseReminderTime('22:00'), (hour: 22, minute: 0));
      expect(parseReminderTime('07:05'), (hour: 7, minute: 5));
    });

    test('returns null for missing or malformed values', () {
      expect(parseReminderTime(null), isNull);
      expect(parseReminderTime(''), isNull);
      expect(parseReminderTime('22'), isNull);
      expect(parseReminderTime('24:00'), isNull);
      expect(parseReminderTime('22:60'), isNull);
      expect(parseReminderTime('night'), isNull);
    });
  });

  group('nextSleepReminderOccurrence', () {
    test('uses today when the time has not passed', () {
      final now = DateTime(2026, 11, 8, 20, 30);

      final next = nextSleepReminderOccurrence(now, hour: 22, minute: 0);

      expect(next, DateTime(2026, 11, 8, 22, 0));
    });

    test('uses tomorrow when the time has passed', () {
      final now = DateTime(2026, 11, 8, 22, 1);

      final next = nextSleepReminderOccurrence(now, hour: 22, minute: 0);

      expect(next, DateTime(2026, 11, 9, 22, 0));
    });

    test('uses tomorrow when the time is exactly now', () {
      final now = DateTime(2026, 11, 8, 22, 0);

      final next = nextSleepReminderOccurrence(now, hour: 22, minute: 0);

      expect(next, DateTime(2026, 11, 9, 22, 0));
    });

    test('crosses a month boundary with calendar arithmetic', () {
      final now = DateTime(2026, 1, 31, 23, 0);

      final next = nextSleepReminderOccurrence(now, hour: 22, minute: 0);

      expect(next, DateTime(2026, 2, 1, 22, 0));
    });
  });
}
