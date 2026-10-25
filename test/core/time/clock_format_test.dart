import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/core/time/clock_format.dart';
import 'package:sleepy3/core/time/day_phase.dart';

void main() {
  group('dayPhaseFor', () {
    test('day runs from 07:00 to 18:59', () {
      expect(dayPhaseFor(DateTime(2026, 10, 20, 6, 59, 59)), DayPhase.night);
      expect(dayPhaseFor(DateTime(2026, 10, 20, 7)), DayPhase.day);
      expect(dayPhaseFor(DateTime(2026, 10, 20, 18, 59, 59)), DayPhase.day);
      expect(dayPhaseFor(DateTime(2026, 10, 20, 19)), DayPhase.night);
    });

    test('midnight and noon fall on the expected side', () {
      expect(dayPhaseFor(DateTime(2026, 10, 20)), DayPhase.night);
      expect(dayPhaseFor(DateTime(2026, 10, 20, 12)), DayPhase.day);
    });
  });

  group('formatClockTime', () {
    test('uses two-digit hours in 24-hour mode', () {
      expect(
        formatClockTime(DateTime(2026, 10, 20, 0, 0, 5), use24HourFormat: true),
        '00:00:05',
      );
      expect(
        formatClockTime(
          DateTime(2026, 10, 20, 22, 30, 5),
          use24HourFormat: true,
        ),
        '22:30:05',
      );
    });

    test('drops the leading zero and omits the period in 12-hour mode', () {
      expect(
        formatClockTime(
          DateTime(2026, 10, 20, 0, 0, 5),
          use24HourFormat: false,
        ),
        '12:00:05',
      );
      expect(
        formatClockTime(
          DateTime(2026, 10, 20, 9, 5, 7),
          use24HourFormat: false,
        ),
        '9:05:07',
      );
      expect(
        formatClockTime(DateTime(2026, 10, 20, 12), use24HourFormat: false),
        '12:00:00',
      );
      expect(
        formatClockTime(
          DateTime(2026, 10, 20, 22, 30, 5),
          use24HourFormat: false,
        ),
        '10:30:05',
      );
    });
  });

  group('formatDayPeriod', () {
    test('changes at noon and midnight', () {
      expect(formatDayPeriod(DateTime(2026, 10, 20)), 'AM');
      expect(formatDayPeriod(DateTime(2026, 10, 20, 11, 59)), 'AM');
      expect(formatDayPeriod(DateTime(2026, 10, 20, 12)), 'PM');
      expect(formatDayPeriod(DateTime(2026, 10, 20, 23, 59)), 'PM');
    });
  });

  group('formatSessionTime', () {
    test('keeps minutes and drops seconds', () {
      final time = DateTime(2026, 10, 20, 22, 30, 59);

      expect(formatSessionTime(time, use24HourFormat: true), '22:30');
      expect(formatSessionTime(time, use24HourFormat: false), '10:30 PM');
      expect(
        formatSessionTime(DateTime(2026, 10, 20, 9, 5), use24HourFormat: false),
        '9:05 AM',
      );
      expect(
        formatSessionTime(DateTime(2026, 10, 20), use24HourFormat: false),
        '12:00 AM',
      );
      expect(
        formatSessionTime(DateTime(2026, 10, 20, 12), use24HourFormat: false),
        '12:00 PM',
      );
    });
  });

  test('formatClockDate is English and omits the year', () {
    expect(formatClockDate(DateTime(2026, 10, 20)), 'Tuesday, October 20');
  });

  test('formatClockLabel includes the period only in 12-hour mode', () {
    final time = DateTime(2026, 10, 20, 22, 30, 5);

    expect(formatClockLabel(time, use24HourFormat: true), '22:30:05');
    expect(formatClockLabel(time, use24HourFormat: false), '10:30:05 PM');
  });
}
