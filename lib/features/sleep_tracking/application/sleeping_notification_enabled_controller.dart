import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';

/// Overridden in `main` with the value loaded before the first frame.
///
/// Missing preference means enabled, so the setting keeps the behavior of
/// versions that always showed the notification.
final initialSleepingNotificationEnabledProvider = Provider<bool>(
  (ref) => true,
);

/// Owns the sleep-status notification switch shown in Settings.
///
/// The state updates immediately and writes are serialized, matching the other
/// preference controllers. Permission is requested by the Settings row before
/// this controller is changed; this controller only persists the choice.
class SleepingNotificationEnabledController extends Notifier<bool> {
  Future<void> _writeQueue = Future<void>.value();

  @override
  bool build() => ref.watch(initialSleepingNotificationEnabledProvider);

  Future<void> setEnabled(bool enabled) async {
    if (enabled == state) return;
    state = enabled;

    final store = ref.read(settingsStoreProvider);
    final next = _writeQueue
        .then((_) => store.saveSleepingNotificationEnabled(enabled))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            'Sleepy3: could not persist the sleep status setting: '
            '$error\n$stackTrace',
          );
        });
    _writeQueue = next;
    await next;
  }
}

final sleepingNotificationEnabledProvider =
    NotifierProvider<SleepingNotificationEnabledController, bool>(
      SleepingNotificationEnabledController.new,
    );
