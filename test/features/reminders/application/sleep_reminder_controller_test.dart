import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/reminders/application/sleep_reminder_controller.dart';
import 'package:sleepy3/features/reminders/domain/sleep_reminder.dart';
import 'package:sleepy3/features/settings/application/language_controller.dart';
import 'package:sleepy3/features/settings/domain/app_language.dart';

import '../../settings/fakes.dart';
import '../fakes.dart';

void main() {
  group('SleepReminderController', () {
    late FakeSettingsStore store;
    late FakeSleepReminderScheduler scheduler;

    setUp(() {
      store = FakeSettingsStore();
      scheduler = FakeSleepReminderScheduler();
    });

    ProviderContainer createContainer({
      SleepReminder initial = SleepReminder.defaults,
      AppLanguage language = AppLanguage.english,
    }) {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          initialSleepReminderProvider.overrideWithValue(initial),
          sleepReminderSchedulerProvider.overrideWithValue(scheduler),
          initialLanguageProvider.overrideWithValue(language),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('starts disabled at 22:00 by default', () {
      final container = createContainer();

      final state = container.read(sleepReminderControllerProvider);

      expect(state.reminder, SleepReminder.defaults);
      expect(state.systemNotificationsEnabled, isNull);
    });

    test('enabling asks permission, schedules and persists', () async {
      final container = createContainer();
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      final failure = await controller.setEnabled(true);

      expect(failure, isNull);
      expect(scheduler.permissionRequests, 1);
      expect(scheduler.scheduled, hasLength(1));
      expect(
        scheduler.scheduled.single.reminder,
        const SleepReminder(enabled: true, hour: 22, minute: 0),
      );
      expect(
        scheduler.scheduled.single.copy.title,
        'Time to record your sleep',
      );
      expect(
        container
            .read(sleepReminderControllerProvider)
            .systemNotificationsEnabled,
        isTrue,
      );
      expect(
        store.reminderSaves.single,
        const SleepReminder(enabled: true, hour: 22, minute: 0),
      );
    });

    test('a denied permission leaves the reminder disabled', () async {
      scheduler.permissionGranted = false;
      final container = createContainer();
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      final failure = await controller.setEnabled(true);

      expect(failure, SleepReminderChangeFailure.notificationsDenied);
      expect(container.read(sleepReminderControllerProvider).enabled, isFalse);
      expect(scheduler.scheduled, isEmpty);
      expect(store.reminderSaves, isEmpty);
    });

    test('a scheduling failure leaves the reminder disabled', () async {
      scheduler.throwOnSchedule = true;
      final container = createContainer();
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      final failure = await controller.setEnabled(true);

      expect(failure, SleepReminderChangeFailure.schedulingFailed);
      expect(container.read(sleepReminderControllerProvider).enabled, isFalse);
      expect(store.reminderSaves, isEmpty);
    });

    test('disabling cancels and persists', () async {
      final container = createContainer(
        initial: const SleepReminder(enabled: true, hour: 22, minute: 0),
      );
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      final failure = await controller.setEnabled(false);

      expect(failure, isNull);
      expect(scheduler.cancels, 1);
      expect(container.read(sleepReminderControllerProvider).enabled, isFalse);
      expect(
        store.reminderSaves.single,
        const SleepReminder(enabled: false, hour: 22, minute: 0),
      );
    });

    test('a failed cancel keeps the reminder enabled', () async {
      scheduler.throwOnCancel = true;
      final container = createContainer(
        initial: const SleepReminder(enabled: true, hour: 22, minute: 0),
      );
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      final failure = await controller.setEnabled(false);

      expect(failure, SleepReminderChangeFailure.schedulingFailed);
      expect(container.read(sleepReminderControllerProvider).enabled, isTrue);
      expect(store.reminderSaves, isEmpty);
    });

    test('changing the time reschedules an enabled reminder', () async {
      final container = createContainer(
        initial: const SleepReminder(enabled: true, hour: 22, minute: 0),
      );
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      final failure = await controller.setTime(hour: 23, minute: 30);

      expect(failure, isNull);
      expect(
        scheduler.scheduled.single.reminder,
        const SleepReminder(enabled: true, hour: 23, minute: 30),
      );
      expect(
        container.read(sleepReminderControllerProvider).reminder,
        const SleepReminder(enabled: true, hour: 23, minute: 30),
      );
      expect(store.reminderSaves.single.hour, 23);
      expect(store.reminderSaves.single.minute, 30);
    });

    test('changing the time while disabled only persists it', () async {
      final container = createContainer();
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      final failure = await controller.setTime(hour: 21, minute: 15);

      expect(failure, isNull);
      expect(scheduler.scheduled, isEmpty);
      expect(store.reminderSaves.single.hour, 21);
      expect(store.reminderSaves.single.minute, 15);
    });

    test('enabling while sleeping waits until Wake to schedule', () async {
      final container = createContainer();
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      await controller.sync(isSleeping: true);
      final failure = await controller.setEnabled(true);

      expect(failure, isNull);
      expect(scheduler.scheduled, isEmpty);
      expect(container.read(sleepReminderControllerProvider).enabled, isTrue);

      await controller.sync(isSleeping: false);

      expect(scheduler.scheduled, hasLength(1));
    });

    test('changing the time while sleeping waits until Wake', () async {
      final container = createContainer(
        initial: const SleepReminder(enabled: true, hour: 22, minute: 0),
      );
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      await controller.sync(isSleeping: true);
      final failure = await controller.setTime(hour: 23, minute: 15);

      expect(failure, isNull);
      expect(scheduler.scheduled, isEmpty);
      expect(container.read(sleepReminderControllerProvider).reminder.hour, 23);

      await controller.sync(isSleeping: false);

      expect(
        scheduler.scheduled.single.reminder,
        const SleepReminder(enabled: true, hour: 23, minute: 15),
      );
    });

    test('sync pauses an enabled reminder while sleeping', () async {
      final container = createContainer(
        initial: const SleepReminder(enabled: true, hour: 22, minute: 0),
      );

      await container
          .read(sleepReminderControllerProvider.notifier)
          .sync(isSleeping: true);

      expect(scheduler.cancels, 1);
      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.notificationsEnabledChecks, 1);
    });

    test(
      'sync arms the reminder when awake and reports blocked notifications',
      () async {
        scheduler.notificationsAreEnabled = false;
        final container = createContainer(
          initial: const SleepReminder(enabled: true, hour: 22, minute: 0),
        );

        await container
            .read(sleepReminderControllerProvider.notifier)
            .sync(isSleeping: false);

        expect(scheduler.scheduled, hasLength(1));
        expect(
          container
              .read(sleepReminderControllerProvider)
              .systemNotificationsEnabled,
          isFalse,
        );
      },
    );

    test('sync does nothing while the reminder is disabled', () async {
      final container = createContainer();

      await container
          .read(sleepReminderControllerProvider.notifier)
          .sync(isSleeping: false);

      expect(scheduler.notificationsEnabledChecks, 0);
      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancels, 0);
    });

    test('uses the current language for the notification copy', () async {
      final container = createContainer(language: AppLanguage.spanish);
      final controller = container.read(
        sleepReminderControllerProvider.notifier,
      );

      await controller.setEnabled(true);

      expect(
        scheduler.scheduled.single.copy.title,
        'Hora de registrar tu sueño',
      );
      expect(
        scheduler.scheduled.single.copy.body,
        'Abre Sleepy3 y toca Dormir cuando apagues la luz.',
      );
      expect(
        scheduler.scheduled.single.copy.channelName,
        'Recordatorio de sueño',
      );
    });
  });
}
