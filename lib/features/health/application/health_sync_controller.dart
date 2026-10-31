import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sleep_tracking/application/sleep_tracking_providers.dart';
import '../../sleep_tracking/domain/sleep_session.dart';
import '../domain/health_connect_gateway.dart';
import '../domain/sleep_data_source.dart';
import 'health_connect_gateway_provider.dart';
import 'health_sync_store_provider.dart';
import 'sleep_data_source_controller.dart';
import 'sleep_upload_service.dart';

/// The connection state shown in Settings for Google Health.
enum HealthConnectConnectionStatus {
  /// The platform has not answered yet.
  checking,

  /// Health Connect is installed, up to date and sleep permissions are granted.
  connected,

  /// Health Connect is installed but the user must grant sleep access.
  permissionNeeded,

  /// Health Connect is not installed or not supported.
  notAvailable,

  /// Health Connect is installed but must be updated.
  updateRequired,
}

/// The pending-upload queue and the Health Connect connection state.
class HealthSyncState {
  const HealthSyncState({
    this.connection = HealthConnectConnectionStatus.checking,
    this.pendingCount = 0,
    this.syncing = false,
    this.lastSyncedAt,
    this.lastError,
  });

  static const _unset = Object();

  final HealthConnectConnectionStatus connection;

  /// Local sessions that still need to be written to Health Connect.
  final int pendingCount;

  /// True while an upload is in flight.
  final bool syncing;

  /// When the last successful upload finished.
  final DateTime? lastSyncedAt;

  /// The last upload or connection error, for Settings.
  final Object? lastError;

  HealthSyncState copyWith({
    HealthConnectConnectionStatus? connection,
    int? pendingCount,
    bool? syncing,
    Object? lastSyncedAt = _unset,
    Object? lastError = _unset,
  }) {
    return HealthSyncState(
      connection: connection ?? this.connection,
      pendingCount: pendingCount ?? this.pendingCount,
      syncing: syncing ?? this.syncing,
      lastSyncedAt: identical(lastSyncedAt, _unset)
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
      lastError: identical(lastError, _unset) ? this.lastError : lastError,
    );
  }
}

/// Owns the upload queue and reports the Health Connect connection state.
///
/// Uploads never block the Sleep/Wake buttons: the local row is already
/// closed before this controller runs. Retrying is safe because every write
/// uses a stable Health Connect [SleepUploadService.clientRecordIdFor].
class HealthSyncController extends Notifier<HealthSyncState> {
  Future<SleepUploadBatchResult>? _retryFuture;

  @override
  HealthSyncState build() {
    Future.microtask(_refreshPendingCount);
    return const HealthSyncState();
  }

  /// Re-checks availability, permissions and the pending queue.
  Future<void> refresh() => _runRefresh();

  /// Re-reads only the pending queue, without touching the platform.
  Future<void> refreshPendingCount() => _refreshPendingCount();

  /// Records a manual copy that successfully wrote to Health Connect.
  void recordManualUpload(DateTime syncedAt) {
    state = state.copyWith(lastSyncedAt: syncedAt, lastError: null);
  }

  /// Writes one just-finished session after Wake.
  ///
  /// The local row is the safety copy and stays untouched while Health Connect
  /// is written. On failure it stays pending for [retryPending].
  Future<SleepUploadResult> uploadFinishedSession(SleepSession session) async {
    state = state.copyWith(syncing: true, lastError: null);

    SleepUploadResult result;
    try {
      result = await ref
          .read(sleepUploadServiceProvider)
          .uploadSession(session);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not upload the finished session: '
        '$error\n$stackTrace',
      );
      result = SleepUploadResult(SleepUploadStatus.failed, error: error);
    }

    if (!ref.mounted) return result;

    state = state.copyWith(
      syncing: false,
      lastSyncedAt: result.status == SleepUploadStatus.uploaded
          ? ref.read(sleepClockProvider)()
          : state.lastSyncedAt,
      lastError: result.error,
    );

    if (result.isFailure) {
      // A revoked permission or a missing Health Connect changes the Settings
      // status as well as leaving the row pending.
      await refresh();
    } else {
      await _refreshPendingCount();
    }
    return result;
  }

  /// Retries pending uploads.
  ///
  /// In Google Health mode every pending row is sent. In Local mode only
  /// updates of sessions that already exist in Health Connect are sent; new
  /// local sessions are never uploaded automatically.
  ///
  /// Concurrent calls share one run so an app resume and a banner tap cannot
  /// upload the same session twice at the same time.
  Future<SleepUploadBatchResult> retryPending() {
    final updatesOnly =
        ref.read(sleepDataSourceProvider) == SleepDataSource.local;

    final running = _retryFuture;
    if (running != null) return running;

    final future = _runRetryPending(updatesOnly: updatesOnly);
    _retryFuture = future;
    future.whenComplete(() {
      if (identical(_retryFuture, future)) _retryFuture = null;
    });
    return future;
  }

  /// Asks for sleep read/write access and refreshes the reported state.
  Future<bool> reconnect() async {
    var granted = false;
    try {
      granted = await ref
          .read(healthConnectGatewayProvider)
          .requestPermissions(read: true, write: true);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not request Health Connect permissions: '
        '$error\n$stackTrace',
      );
    }

    if (!ref.mounted) return granted;
    if (granted) state = state.copyWith(lastError: null);
    await refresh();
    return granted;
  }

  /// Opens the store page so the user can install or update Health Connect.
  Future<void> install() =>
      ref.read(healthConnectGatewayProvider).installHealthConnect();

  Future<void> _runRefresh() async {
    var connection = HealthConnectConnectionStatus.notAvailable;
    Object? error;

    try {
      final availability = await ref
          .read(healthConnectGatewayProvider)
          .checkAvailability();
      switch (availability) {
        case HealthConnectAvailability.available:
          final granted = await ref
              .read(healthConnectGatewayProvider)
              .hasPermissions(read: true, write: true);
          connection = granted
              ? HealthConnectConnectionStatus.connected
              : HealthConnectConnectionStatus.permissionNeeded;
        case HealthConnectAvailability.updateRequired:
          connection = HealthConnectConnectionStatus.updateRequired;
        case HealthConnectAvailability.unavailable:
          connection = HealthConnectConnectionStatus.notAvailable;
      }
    } catch (exception, stackTrace) {
      debugPrint(
        'Sleepy3: could not check the Health Connect status: '
        '$exception\n$stackTrace',
      );
      error = exception;
    }

    final pending = await _loadPendingCount();
    if (!ref.mounted) return;

    state = state.copyWith(
      connection: connection,
      pendingCount: pending,
      lastError: error ?? state.lastError,
    );
  }

  Future<void> _refreshPendingCount() async {
    final pending = await _loadPendingCount();
    if (!ref.mounted) return;
    state = state.copyWith(pendingCount: pending);
  }

  Future<int> _loadPendingCount() async {
    try {
      return await ref.read(healthSyncStoreProvider).loadPendingCount();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read the pending upload count: '
        '$error\n$stackTrace',
      );
      return state.pendingCount;
    }
  }

  Future<SleepUploadBatchResult> _runRetryPending({
    required bool updatesOnly,
  }) async {
    state = state.copyWith(syncing: true, lastError: null);

    final result = await ref
        .read(sleepUploadServiceProvider)
        .retryPending(updatesOnly: updatesOnly);

    if (!ref.mounted) return result;

    state = state.copyWith(
      syncing: false,
      lastSyncedAt: result.uploaded > 0
          ? ref.read(sleepClockProvider)()
          : state.lastSyncedAt,
      lastError: result.error,
    );

    if (result.failed > 0 || result.error != null) {
      await refresh();
    } else {
      await _refreshPendingCount();
    }
    return result;
  }
}

/// The upload service with the production gateway, store and clock.
final sleepUploadServiceProvider = Provider<SleepUploadService>((ref) {
  return SleepUploadService(
    ref.watch(healthConnectGatewayProvider),
    ref.watch(healthSyncStoreProvider),
    ref.watch(sleepClockProvider),
  );
});

final healthSyncControllerProvider =
    NotifierProvider<HealthSyncController, HealthSyncState>(
      HealthSyncController.new,
    );
