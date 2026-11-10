import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/stats/domain/stats_summary_option.dart';

void main() {
  group('StatsSummaryOption', () {
    test('defaults to sleep duration', () {
      expect(
        StatsSummaryOption.defaultOption,
        StatsSummaryOption.sleepDuration,
      );
    });

    test('parses every stored name', () {
      for (final option in StatsSummaryOption.values) {
        expect(StatsSummaryOption.fromStorageValue(option.name), option);
      }
    });

    test('falls back to sleep duration for null or unknown values', () {
      expect(
        StatsSummaryOption.fromStorageValue(null),
        StatsSummaryOption.sleepDuration,
      );
      expect(
        StatsSummaryOption.fromStorageValue('moonPhase'),
        StatsSummaryOption.sleepDuration,
      );
    });
  });
}
