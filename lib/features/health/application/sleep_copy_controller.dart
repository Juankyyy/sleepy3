import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sleep_tracking/application/sleep_tracking_providers.dart';
import 'health_connect_gateway_provider.dart';
import 'health_sync_controller.dart';
import 'health_sync_store_provider.dart';
import 'sleep_copy_service.dart';

/// The copy action a person asked for in Settings.
enum SleepCopyAction {
  /// Send the most recent pending local session to Health Connect.
  syncLast,

  /// Send every pending local session to Health Connect, oldest first.
  uploadAll,

  /// Add every Health Connect session to the local database.
  downloadAll,
}

/// The copy action currently running and its last outcome.
class SleepCopyState {
  const SleepCopyState({
    this.running,
    this.lastAction,
    this.lastResult,
    this.lastError,
  });

  static const _unset = Object();

  /// The action in flight, or null when nothing is running.
  final SleepCopyAction? running;

  final SleepCopyAction? lastAction;
  final CopyResult? lastResult;
  final Object? lastError;

  bool get isRunning => running != null;

  SleepCopyState copyWith({
    Object? running = _unset,
    Object? lastAction = _unset,
    Object? lastResult = _unset,
    Object? lastError = _unset,
  }) {
    return SleepCopyState(
      running: identical(running, _unset)
          ? this.running
          : running as SleepCopyAction?,
      lastAction: identical(lastAction, _unset)
          ? this.lastAction
          : lastAction as SleepCopyAction?,
      lastResult: identical(lastResult, _unset)
          ? this.lastResult
          : lastResult as CopyResult?,
      lastError: identical(lastError, _unset) ? this.lastError : lastError,
    );
  }
}

/// Runs the explicit copy actions and keeps the sync status in step.
///
/// Copy actions never change the selected sleep data source. They only move
/// data between the local safety copy and Health Connect.
class SleepCopyController extends Notifier<SleepCopyState> {
  @override
  SleepCopyState build() => const SleepCopyState();

  Future<CopyResult> syncLastSession() => run(SleepCopyAction.syncLast);

  Future<CopyResult> uploadAllPreviousSessions() =>
      run(SleepCopyAction.uploadAll);

  Future<CopyResult> downloadAllFromHealthConnect() =>
      run(SleepCopyAction.downloadAll);

  /// Runs one copy action. Concurrent calls are rejected instead of racing.
  Future<CopyResult> run(SleepCopyAction action) async {
    if (state.isRunning) {
      return CopyResult(
        failure: SleepCopyFailure.failed,
        error: StateError('A copy action is already running'),
      );
    }

    state = state.copyWith(running: action, lastError: null);

    final service = ref.read(sleepCopyServiceProvider);
    CopyResult result;
    try {
      result = switch (action) {
        SleepCopyAction.syncLast => await service.syncLastSession(),
        SleepCopyAction.uploadAll => await service.uploadAllPreviousSessions(),
        SleepCopyAction.downloadAll =>
          await service.downloadAllFromHealthConnect(),
      };
    } catch (error, stackTrace) {
      debugPrint('Sleepy3: a sleep copy action failed: $error\n$stackTrace');
      result = CopyResult(failure: SleepCopyFailure.failed, error: error);
    }

    if (!ref.mounted) return result;

    state = state.copyWith(
      running: null,
      lastAction: action,
      lastResult: result,
      lastError: result.error,
    );

    // Settings shows the pending count and the last upload time, so both must
    // reflect a manual copy as soon as it finishes.
    final sync = ref.read(healthSyncControllerProvider.notifier);
    if (action != SleepCopyAction.downloadAll && result.added > 0) {
      sync.recordManualUpload(ref.read(sleepClockProvider)());
    }
    await sync.refreshPendingCount();

    return result;
  }
}

/// The copy service with the production gateway, stores and clock.
final sleepCopyServiceProvider = Provider<SleepCopyService>((ref) {
  return SleepCopyService(
    ref.watch(healthConnectGatewayProvider),
    ref.watch(healthSyncStoreProvider),
    ref.watch(sleepUploadServiceProvider),
    ref.watch(sleepClockProvider),
  );
});

final sleepCopyControllerProvider =
    NotifierProvider<SleepCopyController, SleepCopyState>(
      SleepCopyController.new,
    );
