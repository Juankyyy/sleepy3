import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/application/settings_providers.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleeping_notification_enabled_controller.dart';

import '../../settings/fakes.dart';

void main() {
  group('SleepingNotificationEnabledController', () {
    late FakeSettingsStore store;

    ProviderContainer createContainer({bool initial = true}) {
      store = FakeSettingsStore(sleepingNotificationEnabled: initial);
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          initialSleepingNotificationEnabledProvider.overrideWithValue(initial),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('starts enabled', () {
      final container = createContainer();

      expect(container.read(sleepingNotificationEnabledProvider), isTrue);
    });

    test('persists disabling and enabling the notification', () async {
      final container = createContainer();
      final controller = container.read(
        sleepingNotificationEnabledProvider.notifier,
      );

      await controller.setEnabled(false);

      expect(container.read(sleepingNotificationEnabledProvider), isFalse);
      expect(store.sleepingNotificationEnabled, isFalse);
      expect(store.sleepingNotificationEnabledSaves, [false]);

      await controller.setEnabled(true);

      expect(container.read(sleepingNotificationEnabledProvider), isTrue);
      expect(store.sleepingNotificationEnabled, isTrue);
      expect(store.sleepingNotificationEnabledSaves, [false, true]);
    });

    test('keeps the visible state when the write fails', () async {
      final container = createContainer();
      store.failWrites = true;

      await container
          .read(sleepingNotificationEnabledProvider.notifier)
          .setEnabled(false);

      expect(container.read(sleepingNotificationEnabledProvider), isFalse);
      expect(store.sleepingNotificationEnabledSaves, isEmpty);
    });
  });
}
