import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sleepy3/core/time/clock_format.dart';
import 'package:sleepy3/core/time/day_phase.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

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
      expect(formatDayPeriod(DateTime(2026, 10, 20), localeName: 'en'), 'AM');
      expect(
        formatDayPeriod(DateTime(2026, 10, 20, 11, 59), localeName: 'en'),
        'AM',
      );
      expect(
        formatDayPeriod(DateTime(2026, 10, 20, 12), localeName: 'en'),
        'PM',
      );
      expect(
        formatDayPeriod(DateTime(2026, 10, 20, 23, 59), localeName: 'en'),
        'PM',
      );
    });

    test('uses the Spanish periods', () {
      expect(
        formatDayPeriod(DateTime(2026, 10, 20, 9), localeName: 'es'),
        'a.\u202Fm.',
      );
      expect(
        formatDayPeriod(DateTime(2026, 10, 20, 22), localeName: 'es'),
        'p.\u202Fm.',
      );
    });
  });

  group('formatSessionTime', () {
    test('keeps minutes and drops seconds', () {
      final time = DateTime(2026, 10, 20, 22, 30, 59);

      expect(
        formatSessionTime(time, use24HourFormat: true, localeName: 'en'),
        '22:30',
      );
      expect(
        formatSessionTime(time, use24HourFormat: false, localeName: 'en'),
        '10:30 PM',
      );
      expect(
        formatSessionTime(
          DateTime(2026, 10, 20, 9, 5),
          use24HourFormat: false,
          localeName: 'en',
        ),
        '9:05 AM',
      );
      expect(
        formatSessionTime(
          DateTime(2026, 10, 20),
          use24HourFormat: false,
          localeName: 'en',
        ),
        '12:00 AM',
      );
      expect(
        formatSessionTime(
          DateTime(2026, 10, 20, 12),
          use24HourFormat: false,
          localeName: 'en',
        ),
        '12:00 PM',
      );
    });

    test('localizes the period in Spanish', () {
      expect(
        formatSessionTime(
          DateTime(2026, 10, 20, 22, 30),
          use24HourFormat: false,
          localeName: 'es',
        ),
        '10:30 p.\u202Fm.',
      );
      expect(
        formatSessionTime(
          DateTime(2026, 10, 20, 9, 5),
          use24HourFormat: false,
          localeName: 'es',
        ),
        '9:05 a.\u202Fm.',
      );
    });
  });

  group('formatHourLabel', () {
    test('keeps 24-hour labels with minutes', () {
      final time = DateTime(2000, 1, 1, 18);

      expect(
        formatHourLabel(time, use24HourFormat: true, localeName: 'en'),
        '18:00',
      );
      expect(
        formatHourLabel(time, use24HourFormat: true, localeName: 'es'),
        '18:00',
      );
    });

    test('forces 12-hour labels in English', () {
      String label(int hour) => formatHourLabel(
        DateTime(2000, 1, 1, hour),
        use24HourFormat: false,
        localeName: 'en',
      );

      expect(label(18), '6 PM');
      expect(label(0), '12 AM');
      expect(label(6), '6 AM');
      expect(label(12), '12 PM');
    });

    test('forces 12-hour labels in a locale that prefers 24 hours', () {
      String label(int hour) => formatHourLabel(
        DateTime(2000, 1, 1, hour),
        use24HourFormat: false,
        localeName: 'es',
      );

      expect(label(18), '6 p.\u202Fm.');
      expect(label(0), '12 a.\u202Fm.');
      expect(label(6), '6 a.\u202Fm.');
      expect(label(12), '12 p.\u202Fm.');
    });
  });

  test('formatClockDate follows the locale and omits the year', () {
    final date = DateTime(2026, 10, 20);
    expect(formatClockDate(date, localeName: 'en'), 'Tuesday, October 20');
    expect(formatClockDate(date, localeName: 'es'), 'martes, 20 de octubre');
  });

  test('formatClockLabel includes the period only in 12-hour mode', () {
    final time = DateTime(2026, 10, 20, 22, 30, 5);

    expect(
      formatClockLabel(time, use24HourFormat: true, localeName: 'en'),
      '22:30:05',
    );
    expect(
      formatClockLabel(time, use24HourFormat: false, localeName: 'en'),
      '10:30:05 PM',
    );
    expect(
      formatClockLabel(time, use24HourFormat: false, localeName: 'es'),
      '10:30:05 p.\u202Fm.',
    );
  });
}
