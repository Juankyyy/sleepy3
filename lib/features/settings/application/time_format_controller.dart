import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_time_format.dart';
import 'settings_providers.dart';

export 'settings_providers.dart';

/// Owns the 12/24-hour preference and persists changes in order.
///
/// The state updates immediately. A failed write is logged but does not revert
/// the visible choice, matching how session writes behave.
class TimeFormatController extends Notifier<AppTimeFormat> {
  Future<void> _writeQueue = Future<void>.value();

  @override
  AppTimeFormat build() => ref.watch(initialTimeFormatProvider);

  Future<void> setFormat(AppTimeFormat format) async {
    if (format == state) return;
    state = format;

    final store = ref.read(settingsStoreProvider);
    final next = _writeQueue
        .then((_) => store.saveTimeFormat(format))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            'Sleepy3: could not persist the time format: $error\n$stackTrace',
          );
        });
    _writeQueue = next;
    await next;
  }
}

final timeFormatControllerProvider =
    NotifierProvider<TimeFormatController, AppTimeFormat>(
      TimeFormatController.new,
    );
