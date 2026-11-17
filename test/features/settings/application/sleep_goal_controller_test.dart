import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/application/settings_providers.dart';
import 'package:sleepy3/features/settings/application/sleep_goal_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_goal.dart';

import '../fakes.dart';

void main() {
  group('SleepGoalController', () {
    test('starts with the startup preference', () {
      final container = ProviderContainer.test(
        overrides: [
          initialSleepGoalProvider.overrideWithValue(
            const Duration(hours: 6, minutes: 30),
          ),
        ],
      );

      expect(
        container.read(sleepGoalProvider),
        const Duration(hours: 6, minutes: 30),
      );
    });

    test('sets the goal and persists it', () async {
      final store = FakeSettingsStore();
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );

      await container
          .read(sleepGoalProvider.notifier)
          .setGoal(const Duration(hours: 10));

      expect(container.read(sleepGoalProvider), const Duration(hours: 10));
      expect(store.sleepGoalSaves, [const Duration(hours: 10)]);
    });

    test('keeps the visible goal when the write fails', () async {
      final store = FakeSettingsStore()..failWrites = true;
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );

      await container
          .read(sleepGoalProvider.notifier)
          .setGoal(const Duration(hours: 6));

      expect(container.read(sleepGoalProvider), const Duration(hours: 6));
      expect(store.sleepGoalSaves, isEmpty);
    });

    test('does not write when the goal is already selected', () async {
      final store = FakeSettingsStore();
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );

      await container
          .read(sleepGoalProvider.notifier)
          .setGoal(defaultSleepGoal);

      expect(store.sleepGoalSaves, isEmpty);
    });

    test('ignores goals outside the picker options', () async {
      final store = FakeSettingsStore();
      final container = ProviderContainer.test(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );

      await container
          .read(sleepGoalProvider.notifier)
          .setGoal(const Duration(hours: 5));
      await container
          .read(sleepGoalProvider.notifier)
          .setGoal(const Duration(hours: 8, minutes: 15));

      expect(container.read(sleepGoalProvider), defaultSleepGoal);
      expect(store.sleepGoalSaves, isEmpty);
    });
  });
}
