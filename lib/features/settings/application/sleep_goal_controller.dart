import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sleep_tracking/domain/sleep_goal.dart';
import 'settings_providers.dart';

/// Overridden in `main` with the preference loaded before the first frame.
final initialSleepGoalProvider = Provider<Duration>((ref) => defaultSleepGoal);

/// Owns the nightly goal used by Home, Stats and the sleep notification.
///
/// The state updates immediately. A failed write is logged but does not revert
/// the visible choice, matching the other settings controllers.
class SleepGoalController extends Notifier<Duration> {
  Future<void> _writeQueue = Future<void>.value();

  @override
  Duration build() => ref.watch(initialSleepGoalProvider);

  Future<void> setGoal(Duration goal) async {
    if (!isSelectableSleepGoal(goal) || goal == state) return;
    state = goal;

    final store = ref.read(settingsStoreProvider);
    final next = _writeQueue.then((_) => store.saveSleepGoal(goal)).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      debugPrint(
        'Sleepy3: could not persist the sleep goal: '
        '$error\n$stackTrace',
      );
    });
    _writeQueue = next;
    await next;
  }
}

final sleepGoalProvider = NotifierProvider<SleepGoalController, Duration>(
  SleepGoalController.new,
);
