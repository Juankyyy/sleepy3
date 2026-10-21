import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_duration.dart';

void main() {
  group('formatSleepDuration', () {
    test('formats minutes only', () {
      expect(formatSleepDuration(const Duration(minutes: 35)), '35m');
    });

    test('formats hours and minutes', () {
      expect(
        formatSleepDuration(const Duration(hours: 7, minutes: 45)),
        '7h 45m',
      );
    });

    test('keeps zero minutes visible when hours exist', () {
      expect(formatSleepDuration(const Duration(hours: 8)), '8h 0m');
    });

    test('formats zero and negative durations as zero', () {
      expect(formatSleepDuration(Duration.zero), '0m');
      expect(formatSleepDuration(const Duration(minutes: -10)), '0m');
    });
  });
}
