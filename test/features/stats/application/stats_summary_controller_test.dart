import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/application/settings_providers.dart';
import 'package:sleepy3/features/stats/application/stats_summary_controller.dart';
import 'package:sleepy3/features/stats/domain/stats_summary_option.dart';

import '../../settings/fakes.dart';

void main() {
  group('StatsSummaryController', () {
    test('starts with the startup preference', () {
      final container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
          initialStatsSummaryOptionProvider.overrideWithValue(
            StatsSummaryOption.keyData,
          ),
        ],
      );

      expect(
        container.read(statsSummaryControllerProvider),
        StatsSummaryOption.keyData,
      );
    });

    test('selects a block and persists it', () async {
      final store = FakeSettingsStore();
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );

      await container
          .read(statsSummaryControllerProvider.notifier)
          .select(StatsSummaryOption.keyMetrics);

      expect(
        container.read(statsSummaryControllerProvider),
        StatsSummaryOption.keyMetrics,
      );
      expect(store.statsSummarySaves, [StatsSummaryOption.keyMetrics]);
    });

    test('keeps the visible choice when the write fails', () async {
      final store = FakeSettingsStore()..failWrites = true;
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );

      await container
          .read(statsSummaryControllerProvider.notifier)
          .select(StatsSummaryOption.weekday);

      expect(
        container.read(statsSummaryControllerProvider),
        StatsSummaryOption.weekday,
      );
      expect(store.statsSummarySaves, isEmpty);
    });

    test('does not write when the block is already selected', () async {
      final store = FakeSettingsStore();
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );

      await container
          .read(statsSummaryControllerProvider.notifier)
          .select(StatsSummaryOption.sleepDuration);

      expect(store.statsSummarySaves, isEmpty);
    });
  });
}
