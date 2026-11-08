import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../settings/application/language_controller.dart';
import '../domain/reminder_notification_copy.dart';
import '../domain/sleep_reminder.dart';
import 'reminder_providers.dart';

export 'reminder_providers.dart';

/// The reminder preference plus the current Android notification status.
class SleepReminderState {
  const SleepReminderState({
    required this.reminder,
    this.systemNotificationsEnabled,
  });

  final SleepReminder reminder;

  /// Null until the app has checked Android; false shows the Settings warning.
  final bool? systemNotificationsEnabled;

  bool get enabled => reminder.enabled;

  SleepReminderState copyWith({
    SleepReminder? reminder,
    bool? systemNotificationsEnabled,
  }) {
    return SleepReminderState(
      reminder: reminder ?? this.reminder,
      systemNotificationsEnabled:
          systemNotificationsEnabled ?? this.systemNotificationsEnabled,
    );
  }
}

/// Why a reminder change was rejected. The visible preference does not change.
enum SleepReminderChangeFailure {
  /// The user denied Android's notification permission.
  notificationsDenied,

  /// The platform scheduler could not schedule or cancel the notification.
  schedulingFailed,
}

/// Owns the reminder preference and keeps Android's scheduled notification in
/// sync with it.
///
/// The app calls [sync] on launch, on resume, when Sleep/Wake changes and when
/// the language changes. Scheduling is serialized so a rapid Sleep/Wake cannot
/// leave an old reminder armed.
class SleepReminderController extends Notifier<SleepReminderState> {
  Future<void> _writeQueue = Future<void>.value();
  Future<void> _schedulingQueue = Future<void>.value();
  bool _isSleeping = false;

  @override
  SleepReminderState build() {
    return SleepReminderState(
      reminder: ref.watch(initialSleepReminderProvider),
    );
  }

  Future<SleepReminderChangeFailure?> setEnabled(bool enabled) {
    return _enqueueScheduling(() => _setEnabled(enabled));
  }

  Future<SleepReminderChangeFailure?> _setEnabled(bool enabled) async {
    if (enabled == state.reminder.enabled) return null;

    final scheduler = ref.read(sleepReminderSchedulerProvider);

    if (!enabled) {
      try {
        await scheduler.cancel();
      } catch (error, stackTrace) {
        debugPrint(
          'Sleepy3: could not cancel the sleep reminder: '
          '$error\n$stackTrace',
        );
        return SleepReminderChangeFailure.schedulingFailed;
      }
      if (!ref.mounted) return null;

      final updated = state.reminder.copyWith(enabled: false);
      state = state.copyWith(reminder: updated);
      await _save(updated);
      return null;
    }

    final bool granted;
    try {
      granted = await scheduler.requestPermission();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not request notification permission: '
        '$error\n$stackTrace',
      );
      return SleepReminderChangeFailure.schedulingFailed;
    }
    if (!granted || !ref.mounted) {
      return granted ? null : SleepReminderChangeFailure.notificationsDenied;
    }

    final updated = state.reminder.copyWith(enabled: true);
    if (!_isSleeping) {
      try {
        await scheduler.schedule(reminder: updated, copy: _copy());
      } catch (error, stackTrace) {
        debugPrint(
          'Sleepy3: could not schedule the sleep reminder: '
          '$error\n$stackTrace',
        );
        return SleepReminderChangeFailure.schedulingFailed;
      }
      if (!ref.mounted) return null;
    }

    state = state.copyWith(reminder: updated, systemNotificationsEnabled: true);
    await _save(updated);
    return null;
  }

  Future<SleepReminderChangeFailure?> setTime({
    required int hour,
    required int minute,
  }) {
    return _enqueueScheduling(() => _setTime(hour: hour, minute: minute));
  }

  Future<SleepReminderChangeFailure?> _setTime({
    required int hour,
    required int minute,
  }) async {
    if (hour == state.reminder.hour && minute == state.reminder.minute) {
      return null;
    }

    final updated = state.reminder.copyWith(hour: hour, minute: minute);
    if (updated.enabled && !_isSleeping) {
      try {
        await ref
            .read(sleepReminderSchedulerProvider)
            .schedule(reminder: updated, copy: _copy());
      } catch (error, stackTrace) {
        debugPrint(
          'Sleepy3: could not reschedule the sleep reminder: '
          '$error\n$stackTrace',
        );
        return SleepReminderChangeFailure.schedulingFailed;
      }
      if (!ref.mounted) return null;
    }

    state = state.copyWith(reminder: updated);
    await _save(updated);
    return null;
  }

  /// Re-arms or cancels the reminder for the current app state.
  ///
  /// It never asks for permission; the system dialog only appears from an
  /// explicit settings change.
  Future<void> sync({required bool isSleeping}) {
    return _enqueueScheduling(() => _syncNow(isSleeping: isSleeping));
  }

  /// Runs one scheduling mutation at a time.
  ///
  /// App resume, Sleep/Wake and a settings tap can otherwise interleave two
  /// `zonedSchedule` calls and leave the older time armed.
  Future<T> _enqueueScheduling<T>(Future<T> Function() action) {
    final result = Completer<T>();
    final next = _schedulingQueue.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    _schedulingQueue = next.catchError((Object error, StackTrace stackTrace) {
      debugPrint(
        'Sleepy3: could not sync the sleep reminder: '
        '$error\n$stackTrace',
      );
    });
    return result.future;
  }

  Future<void> openNotificationSettings() async {
    try {
      await ref.read(sleepReminderSchedulerProvider).openNotificationSettings();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not open the notification settings: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _syncNow({required bool isSleeping}) async {
    _isSleeping = isSleeping;
    if (!ref.mounted || !state.reminder.enabled) return;

    final scheduler = ref.read(sleepReminderSchedulerProvider);

    try {
      final enabled = await scheduler.notificationsEnabled();
      if (!ref.mounted) return;
      if (enabled != state.systemNotificationsEnabled) {
        state = state.copyWith(systemNotificationsEnabled: enabled);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read the notification permission: '
        '$error\n$stackTrace',
      );
    }

    if (!ref.mounted) return;
    if (isSleeping) {
      try {
        await scheduler.cancel();
      } catch (error, stackTrace) {
        debugPrint(
          'Sleepy3: could not pause the sleep reminder: '
          '$error\n$stackTrace',
        );
      }
      return;
    }

    try {
      await scheduler.schedule(reminder: state.reminder, copy: _copy());
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not arm the sleep reminder: '
        '$error\n$stackTrace',
      );
    }
  }

  ReminderNotificationCopy _copy() {
    final l10n = lookupAppLocalizations(
      ref.read(languageControllerProvider).locale,
    );
    return ReminderNotificationCopy(
      title: l10n.sleepReminderNotificationTitle,
      body: l10n.sleepReminderNotificationBody,
      channelName: l10n.sleepReminderChannelName,
      channelDescription: l10n.sleepReminderChannelDescription,
    );
  }

  Future<void> _save(SleepReminder reminder) {
    final store = ref.read(settingsStoreProvider);
    final next = _writeQueue
        .then((_) => store.saveSleepReminder(reminder))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            'Sleepy3: could not persist the sleep reminder: '
            '$error\n$stackTrace',
          );
        });
    _writeQueue = next;
    return next;
  }
}

final sleepReminderControllerProvider =
    NotifierProvider<SleepReminderController, SleepReminderState>(
      SleepReminderController.new,
    );
