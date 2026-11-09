import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock_format.dart';
import '../../../l10n/l10n.dart';
import '../../settings/application/language_controller.dart';
import '../../settings/application/time_format_controller.dart';
import '../domain/sleep_goal.dart';
import '../domain/sleep_session.dart';
import '../domain/sleeping_notification_presenter.dart';
import 'sleeping_notification_enabled_controller.dart';
import 'sleeping_notification_providers.dart';

export 'sleeping_notification_providers.dart';

/// Owns the ongoing notification shown while a sleep session is active.
///
/// The session start is handed to Android as the notification's chronometer
/// base, so the elapsed time keeps counting even when the app process is gone.
/// Calls are serialized: a quick Sleep/Wake cannot leave an old notification
/// visible.
class SleepingNotificationController {
  SleepingNotificationController(this._ref);

  final Ref _ref;
  Future<void> _queue = Future<void>.value();

  /// Shows or cancels the notification for [openSession].
  ///
  /// [allowPermissionPrompt] is true only when the user just started a sleep;
  /// app launches and resumes never open the system dialog.
  Future<void> sync({
    required SleepSession? openSession,
    bool allowPermissionPrompt = false,
  }) {
    final result = Completer<void>();
    final next = _queue.then((_) async {
      try {
        await _syncNow(
          openSession: openSession,
          allowPermissionPrompt: allowPermissionPrompt,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Sleepy3: could not update the sleep notification: '
          '$error\n$stackTrace',
        );
      }
      result.complete();
    });
    _queue = next;
    return result.future;
  }

  Future<void> _syncNow({
    required SleepSession? openSession,
    required bool allowPermissionPrompt,
  }) async {
    final presenter = _ref.read(sleepingNotificationPresenterProvider);

    if (!_ref.read(sleepingNotificationEnabledProvider)) {
      await presenter.cancel();
      return;
    }

    if (openSession == null) {
      await presenter.cancel();
      return;
    }

    if (!await presenter.notificationsEnabled()) {
      if (!allowPermissionPrompt) return;
      if (!await _askForPermission(presenter)) return;
    }

    await presenter.show(
      startedAt: openSession.startedAt,
      copy: _copy(openSession.startedAt),
    );
  }

  /// Asks for notification permission when the user enables the notification
  /// from Settings. Returns whether notifications are now allowed.
  ///
  /// The same one-time flag as the first Sleep is used, so a previous denial is
  /// respected and the Settings row can offer the system settings instead of
  /// opening the dialog again.
  Future<bool> requestPermission() async {
    final presenter = _ref.read(sleepingNotificationPresenterProvider);
    if (await presenter.notificationsEnabled()) return true;
    return _askForPermission(presenter);
  }

  /// Opens the app's notification settings in Android.
  Future<void> openNotificationSettings() async {
    try {
      await _ref
          .read(sleepingNotificationPresenterProvider)
          .openNotificationSettings();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not open the notification settings: '
        '$error\n$stackTrace',
      );
    }
  }

  /// Asks for notification permission once, when a sleep starts or the user
  /// enables the notification from Settings.
  ///
  /// The flag lives in `preferences`, so a denial is respected on later nights
  /// and Android never shows the dialog again from this path. The user can
  /// still enable notifications in Android settings; the next sync picks that
  /// up because [SleepingNotificationPresenter.notificationsEnabled] is read
  /// first.
  Future<bool> _askForPermission(
    SleepingNotificationPresenter presenter,
  ) async {
    final store = _ref.read(settingsStoreProvider);
    try {
      final alreadyAsked = await store.loadSleepNotificationPermissionAsked();
      if (alreadyAsked) return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read the sleep notification permission flag: '
        '$error\n$stackTrace',
      );
      return false;
    }

    final granted = await presenter.requestPermission();
    try {
      await store.saveSleepNotificationPermissionAsked(true);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not persist the sleep notification permission flag: '
        '$error\n$stackTrace',
      );
    }
    return granted;
  }

  SleepingNotificationCopy _copy(DateTime startedAt) {
    final l10n = lookupAppLocalizations(
      _ref.read(languageControllerProvider).locale,
    );
    final timeFormat = _ref.read(timeFormatControllerProvider);
    final goalEnd = startedAt.add(dailySleepGoal);
    return SleepingNotificationCopy(
      title: l10n.sleepingNotificationTitle,
      body: l10n.sleepingNotificationBody(
        l10n.formatGoalDelta(dailySleepGoal),
        formatSessionTime(
          goalEnd,
          use24HourFormat: timeFormat.uses24HourFormat,
          localeName: l10n.localeName,
        ),
      ),
      ongoingLabel: l10n.sleepingNotificationOngoing,
      channelName: l10n.sleepingNotificationChannelName,
      channelDescription: l10n.sleepingNotificationChannelDescription,
    );
  }
}

final sleepingNotificationControllerProvider =
    Provider<SleepingNotificationController>(
      SleepingNotificationController.new,
    );
