import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../domain/stats_summary_option.dart';

/// Overridden in `main` with the preference loaded before the first frame.
final initialStatsSummaryOptionProvider = Provider<StatsSummaryOption>(
  (ref) => StatsSummaryOption.defaultOption,
);

/// Owns the Stats summary block and persists changes in order.
///
/// The state updates immediately. A failed write is logged but does not revert
/// the visible choice, matching the other settings controllers.
class StatsSummaryController extends Notifier<StatsSummaryOption> {
  Future<void> _writeQueue = Future<void>.value();

  @override
  StatsSummaryOption build() => ref.watch(initialStatsSummaryOptionProvider);

  Future<void> select(StatsSummaryOption option) async {
    if (option == state) return;
    state = option;

    final store = ref.read(settingsStoreProvider);
    final next = _writeQueue
        .then((_) => store.saveStatsSummaryOption(option))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            'Sleepy3: could not persist the stats summary block: '
            '$error\n$stackTrace',
          );
        });
    _writeQueue = next;
    await next;
  }
}

final statsSummaryControllerProvider =
    NotifierProvider<StatsSummaryController, StatsSummaryOption>(
      StatsSummaryController.new,
    );
