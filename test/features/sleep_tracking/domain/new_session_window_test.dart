import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/new_session_window.dart';

void main() {
  group('defaultNewSessionWindow', () {
    test('offers the last completed night after 07:00', () {
      final window = defaultNewSessionWindow(DateTime(2026, 10, 21, 10));

      expect(window.startedAt, DateTime(2026, 10, 20, 23));
      expect(window.endedAt, DateTime(2026, 10, 21, 7));
    });

    test('ends at now before 07:00', () {
      final window = defaultNewSessionWindow(DateTime(2026, 10, 21, 2, 30));

      expect(window.startedAt, DateTime(2026, 10, 20, 23));
      expect(window.endedAt, DateTime(2026, 10, 21, 2, 30));
    });

    test('uses 07:00 exactly as the switch point', () {
      final window = defaultNewSessionWindow(DateTime(2026, 10, 21, 7));

      expect(window.startedAt, DateTime(2026, 10, 20, 23));
      expect(window.endedAt, DateTime(2026, 10, 21, 7));
    });

    test('never produces a future or too short window', () {
      final midnight = defaultNewSessionWindow(DateTime(2026, 10, 21));
      final lateNight = defaultNewSessionWindow(
        DateTime(2026, 10, 21, 23, 59, 59),
      );
      final justBeforeSeven = defaultNewSessionWindow(
        DateTime(2026, 10, 21, 6, 59, 59),
      );

      for (final window in [midnight, lateNight, justBeforeSeven]) {
        expect(window.startedAt.isBefore(window.endedAt), isTrue);
        expect(window.endedAt.isAfter(DateTime(2026, 10, 21, 7)), isFalse);
        expect(
          window.endedAt.difference(window.startedAt),
          greaterThanOrEqualTo(const Duration(minutes: 10)),
        );
      }
      expect(justBeforeSeven.endedAt, DateTime(2026, 10, 21, 6, 59));
    });

    test('crosses a month boundary', () {
      final window = defaultNewSessionWindow(DateTime(2026, 11, 1, 2));

      expect(window.startedAt, DateTime(2026, 10, 31, 23));
      expect(window.endedAt, DateTime(2026, 11, 1, 2));
    });
  });
}
