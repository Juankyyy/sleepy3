import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/settings/application/language_controller.dart';
import 'package:sleepy3/features/settings/application/settings_providers.dart';
import 'package:sleepy3/features/settings/application/time_format_controller.dart';
import 'package:sleepy3/features/settings/domain/app_language.dart';
import 'package:sleepy3/features/settings/domain/app_time_format.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleeping_notification_controller.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleeping_notification_enabled_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

import '../../settings/fakes.dart';
import '../fakes.dart';

void main() {
  group('SleepingNotificationController', () {
    late FakeSettingsStore store;
    late FakeSleepingNotificationPresenter presenter;
    final session = SleepSession(startedAt: DateTime(2026, 10, 20, 23));

    ProviderContainer createContainer({
      AppLanguage language = AppLanguage.english,
      AppTimeFormat timeFormat = AppTimeFormat.twentyFourHour,
      bool permissionAsked = false,
      bool enabled = true,
    }) {
      store = FakeSettingsStore(
        sleepNotificationPermissionAsked: permissionAsked,
        sleepingNotificationEnabled: enabled,
      );
      presenter = FakeSleepingNotificationPresenter();
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          sleepingNotificationPresenterProvider.overrideWithValue(presenter),
          initialSleepingNotificationEnabledProvider.overrideWithValue(enabled),
          initialLanguageProvider.overrideWithValue(language),
          initialTimeFormatProvider.overrideWithValue(timeFormat),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('cancels when there is no open session', () async {
      final container = createContainer();

      await container
          .read(sleepingNotificationControllerProvider)
          .sync(openSession: null);

      expect(presenter.cancels, 1);
      expect(presenter.shown, isEmpty);
    });

    test('shows the localized goal while sleeping', () async {
      final container = createContainer();

      await container
          .read(sleepingNotificationControllerProvider)
          .sync(openSession: session);

      expect(presenter.shown, hasLength(1));
      expect(presenter.shown.single.startedAt, session.startedAt);
      expect(presenter.shown.single.copy.title, 'Sleeping');
      expect(presenter.shown.single.copy.body, 'Goal 8h · until 07:00');
      expect(presenter.shown.single.copy.ongoingLabel, 'In progress');
      expect(presenter.shown.single.copy.channelName, 'Sleep status');
      expect(
        presenter.shown.single.copy.channelDescription,
        'A quiet timer while a sleep session is active.',
      );
    });

    test('uses the Spanish copy', () async {
      final container = createContainer(language: AppLanguage.spanish);

      await container
          .read(sleepingNotificationControllerProvider)
          .sync(openSession: session);

      expect(presenter.shown.single.copy.title, 'Durmiendo');
      expect(
        presenter.shown.single.copy.body,
        'Objetivo 8 h · hasta las 07:00',
      );
      expect(presenter.shown.single.copy.ongoingLabel, 'En curso');
      expect(presenter.shown.single.copy.channelName, 'Estado del sueño');
    });

    test('updates the notification when the start changes', () async {
      final container = createContainer();
      final controller = container.read(sleepingNotificationControllerProvider);

      await controller.sync(openSession: session);
      final retimed = session.retimeStart(DateTime(2026, 10, 20, 22));
      await controller.sync(openSession: retimed);

      expect(presenter.shown, hasLength(2));
      expect(presenter.shown.last.startedAt, retimed.startedAt);
      expect(presenter.shown.last.copy.body, 'Goal 8h · until 06:00');
    });

    test('does not prompt outside a sleep start', () async {
      final container = createContainer();
      presenter.notificationsAreEnabled = false;

      await container
          .read(sleepingNotificationControllerProvider)
          .sync(openSession: session);

      expect(presenter.permissionRequests, 0);
      expect(presenter.shown, isEmpty);
    });

    test('asks once and shows when granted', () async {
      final container = createContainer();
      presenter.notificationsAreEnabled = false;

      await container
          .read(sleepingNotificationControllerProvider)
          .sync(openSession: session, allowPermissionPrompt: true);

      expect(presenter.permissionRequests, 1);
      expect(presenter.shown, hasLength(1));
      expect(store.sleepNotificationPermissionAsked, isTrue);
      expect(store.sleepNotificationPermissionAskedSaves, [true]);
    });

    test('does not ask again after a previous answer', () async {
      final container = createContainer(permissionAsked: true);
      presenter.notificationsAreEnabled = false;

      await container
          .read(sleepingNotificationControllerProvider)
          .sync(openSession: session, allowPermissionPrompt: true);

      expect(presenter.permissionRequests, 0);
      expect(presenter.shown, isEmpty);
    });

    test('a denied permission leaves the notification hidden', () async {
      final container = createContainer();
      presenter.notificationsAreEnabled = false;
      presenter.permissionGranted = false;

      await container
          .read(sleepingNotificationControllerProvider)
          .sync(openSession: session, allowPermissionPrompt: true);

      expect(presenter.permissionRequests, 1);
      expect(presenter.shown, isEmpty);
      expect(store.sleepNotificationPermissionAsked, isTrue);
    });

    test('does not show when the setting is off', () async {
      final container = createContainer(enabled: false);

      await container
          .read(sleepingNotificationControllerProvider)
          .sync(openSession: session);

      expect(presenter.shown, isEmpty);
      expect(presenter.cancels, 1);
    });

    test('asks for permission on request and respects the flag', () async {
      final container = createContainer();
      presenter.notificationsAreEnabled = false;
      presenter.permissionGranted = false;
      final controller = container.read(sleepingNotificationControllerProvider);

      expect(await controller.requestPermission(), isFalse);
      expect(presenter.permissionRequests, 1);
      expect(store.sleepNotificationPermissionAsked, isTrue);

      expect(await controller.requestPermission(), isFalse);
      expect(presenter.permissionRequests, 1);

      presenter.notificationsAreEnabled = true;
      expect(await controller.requestPermission(), isTrue);
      expect(presenter.permissionRequests, 1);
    });

    test('opens the system notification settings', () async {
      final container = createContainer();

      await container
          .read(sleepingNotificationControllerProvider)
          .openNotificationSettings();

      expect(presenter.openSettingsCalls, 1);
    });

    test('serializes a quick sleep and wake', () async {
      final container = createContainer();
      final controller = container.read(sleepingNotificationControllerProvider);

      final sleep = controller.sync(openSession: session);
      final wake = controller.sync(openSession: null);
      await Future.wait([sleep, wake]);

      expect(presenter.events, ['show', 'cancel']);
    });
  });
}
