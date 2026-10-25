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

  group('formatSpokenSleepDuration', () {
    test('uses singular hour and minute', () {
      expect(
        formatSpokenSleepDuration(const Duration(hours: 1, minutes: 1)),
        '1 hour 1 minute',
      );
    });

    test('speaks minutes only', () {
      expect(
        formatSpokenSleepDuration(const Duration(minutes: 35)),
        '35 minutes',
      );
    });

    test('keeps zero minutes when hours exist', () {
      expect(
        formatSpokenSleepDuration(const Duration(hours: 8)),
        '8 hours 0 minutes',
      );
    });

    test('speaks zero and negative durations as zero', () {
      expect(formatSpokenSleepDuration(Duration.zero), '0 minutes');
      expect(
        formatSpokenSleepDuration(const Duration(minutes: -10)),
        '0 minutes',
      );
    });
  });
}
