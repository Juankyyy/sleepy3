import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/stats/presentation/history_labels.dart';

void main() {
  final today = DateTime(2026, 10, 21);

  group('formatHistoryDay', () {
    test('uses Today and Yesterday for adjacent calendar days', () {
      expect(formatHistoryDay(today, today), 'Today');
      expect(formatHistoryDay(DateTime(2026, 10, 20), today), 'Yesterday');
    });

    test('abbreviates older dates and includes another year', () {
      expect(formatHistoryDay(DateTime(2026, 10, 19), today), 'Mon, Oct 19');
      expect(
        formatHistoryDay(DateTime(2025, 12, 29), today),
        'Mon, Dec 29, 2025',
      );
    });
  });

  group('formatHistoryDaySpoken', () {
    test('spells out adjacent and older dates', () {
      expect(formatHistoryDaySpoken(today, today), 'Today');
      expect(
        formatHistoryDaySpoken(DateTime(2026, 10, 20), today),
        'Yesterday',
      );
      expect(
        formatHistoryDaySpoken(DateTime(2026, 10, 19), today),
        'Monday, October 19',
      );
      expect(
        formatHistoryDaySpoken(DateTime(2025, 12, 29), today),
        'Monday, December 29, 2025',
      );
    });
  });

  group('formatHistoryTimeRange', () {
    final start = DateTime(2026, 10, 21, 22, 32);
    final end = DateTime(2026, 10, 22, 6, 45);

    test('uses the 12-hour system', () {
      expect(
        formatHistoryTimeRange(start, end, use24HourFormat: false),
        '10:32 PM – 6:45 AM',
      );
    });

    test('uses the 24-hour system', () {
      expect(
        formatHistoryTimeRange(start, end, use24HourFormat: true),
        '22:32 – 06:45',
      );
    });

    test('spells the range for screen readers', () {
      expect(
        formatHistoryTimeRangeSpoken(start, end, use24HourFormat: false),
        '10:32 PM to 6:45 AM',
      );
    });
  });
}
