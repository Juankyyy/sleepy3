import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/application/health_connect_gateway_provider.dart';
import '../../health/application/health_sync_controller.dart';
import '../../health/application/health_sync_store_provider.dart';
import '../../health/application/sleep_upload_service.dart';
import '../../health/domain/health_connect_gateway.dart';
import '../../health/domain/health_sync_store.dart';
import '../../health/domain/sleep_data_source.dart';
import '../../health/domain/sleepy3_health_source.dart';
import '../../health/domain/stored_sleep_session.dart';
import '../domain/session_edit.dart';
import '../domain/sleep_session.dart';
import '../domain/sleep_session_store.dart';
import 'sleep_tracking_providers.dart';

/// What happened after the user saved or deleted a closed session.
enum SleepSessionEditStatus {
  /// The session was saved and every copy is up to date.
  saved,

  /// The local copy was saved but Health Connect still needs the update.
  savedPendingSync,

  /// The session and its local copy were deleted.
  deleted,

  /// Google Health needs write access before the action can finish.
  permissionNeeded,

  /// Nothing changed, or an unexpected error stopped the action.
  failed,
}

/// The outcome of editing or deleting one closed session.
class SleepSessionEditResult {
  const SleepSessionEditResult(this.status, {this.session, this.error});

  const SleepSessionEditResult.saved(this.session)
    : status = SleepSessionEditStatus.saved,
      error = null;

  const SleepSessionEditResult.savedPendingSync(this.session)
    : status = SleepSessionEditStatus.savedPendingSync,
      error = null;

  const SleepSessionEditResult.deleted()
    : status = SleepSessionEditStatus.deleted,
      session = null,
      error = null;

  const SleepSessionEditResult.permissionNeeded({this.session})
    : status = SleepSessionEditStatus.permissionNeeded,
      error = null;

  const SleepSessionEditResult.failed({this.error, this.session})
    : status = SleepSessionEditStatus.failed;

  final SleepSessionEditStatus status;

  /// The updated session, when a local copy changed.
  final SleepSession? session;

  /// A store, gateway or validation error, when there is one.
  final Object? error;

  bool get hasLocalChange =>
      status == SleepSessionEditStatus.saved ||
      status == SleepSessionEditStatus.savedPendingSync ||
      (status == SleepSessionEditStatus.permissionNeeded && session != null);

  bool get isDeleted => status == SleepSessionEditStatus.deleted;
}

/// Applies edits and deletions to the selected sleep data source.
///
/// In Local mode the Drift row is the source of truth: an edit is saved
/// immediately and only then sent to Health Connect, leaving it pending when
/// the platform call fails. In Google Health mode Health Connect goes first,
/// and the local copy and visible list only change after the platform confirms.
class SleepSessionEditService {
  SleepSessionEditService(
    this._sessions,
    this._sync,
    this._gateway,
    this._upload,
    this._clock,
  );

  final SleepSessionStore _sessions;
  final HealthSyncStore _sync;
  final HealthConnectGateway _gateway;
  final SleepUploadService _upload;
  final DateTime Function() _clock;

  /// Saves new times for one closed session.
  ///
  /// [otherClosedSessions] must not include the session being edited; it is
  /// used for the overlap check.
  Future<SleepSessionEditResult> updateSession({
    required SleepSession session,
    required DateTime startedAt,
    required DateTime endedAt,
    required SleepDataSource source,
    required Iterable<SleepSession> otherClosedSessions,
    SleepSession? openSession,
  }) async {
    if (_accessFor(session, source) != SessionEditAccess.editAndDelete) {
      return const SleepSessionEditResult.failed();
    }

    if (startedAt == session.startedAt && endedAt == session.endedAt) {
      return SleepSessionEditResult.saved(session);
    }

    final errors = validateSessionEdit(
      draft: SessionEditDraft(
        startedAt: startedAt,
        endedAt: endedAt,
        originalStartedAt: session.startedAt,
        originalEndedAt: session.endedAt,
      ),
      now: _clock(),
      otherClosedSessions: otherClosedSessions,
      openSession: openSession,
    );
    if (errors.isNotEmpty) {
      return SleepSessionEditResult.failed(error: errors.first);
    }

    try {
      return source == SleepDataSource.local
          ? await _updateLocal(session, startedAt, endedAt)
          : await _updateHealthConnect(session, startedAt, endedAt);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not update a closed session: $error\n$stackTrace',
      );
      return SleepSessionEditResult.failed(error: error);
    }
  }

  /// Deletes one closed session.
  Future<SleepSessionEditResult> deleteSession({
    required SleepSession session,
    required SleepDataSource source,
  }) async {
    if (_accessFor(session, source) == SessionEditAccess.readOnly) {
      return const SleepSessionEditResult.failed();
    }

    try {
      return source == SleepDataSource.local
          ? await _deleteLocal(session)
          : await _deleteHealthConnect(session);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not delete a closed session: $error\n$stackTrace',
      );
      return SleepSessionEditResult.failed(error: error);
    }
  }

  SessionEditAccess _accessFor(SleepSession session, SleepDataSource source) {
    return sessionEditAccess(
      session,
      healthConnectSource: source == SleepDataSource.healthConnect,
      isOwnHealthRecord: isSleepy3HealthRecord(session.sourceId),
    );
  }

  Future<SleepSessionEditResult> _updateLocal(
    SleepSession session,
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    final localId = session.localId;
    if (localId == null) return const SleepSessionEditResult.failed();

    final stored = await _sync.findById(localId);
    final updated = await _sessions.updateSession(localId, startedAt, endedAt);
    if (!updated) {
      return const SleepSessionEditResult.failed();
    }

    final updatedSession = session.withTimes(startedAt, endedAt);
    final recordId = stored?.healthRecordId ?? session.healthRecordId;
    if (recordId == null) {
      return SleepSessionEditResult.saved(updatedSession);
    }
    if (stored == null) {
      // The local copy is saved and pending, but there is no version or client
      // record id to update the platform record with right now.
      return SleepSessionEditResult.savedPendingSync(updatedSession);
    }

    switch (await _writeAccess()) {
      case _WriteAccess.denied:
        return SleepSessionEditResult.permissionNeeded(session: updatedSession);
      case _WriteAccess.unavailable:
        return SleepSessionEditResult.savedPendingSync(updatedSession);
      case _WriteAccess.granted:
        final result = await _upload.updateSyncedSession(
          stored,
          startedAt,
          endedAt,
        );
        return result.status == SleepUploadStatus.uploaded
            ? SleepSessionEditResult.saved(updatedSession)
            : SleepSessionEditResult.savedPendingSync(updatedSession);
    }
  }

  Future<SleepSessionEditResult> _updateHealthConnect(
    SleepSession session,
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    final localId = session.localId;
    if (localId == null || session.healthClientRecordId == null) {
      return const SleepSessionEditResult.failed();
    }

    switch (await _writeAccess()) {
      case _WriteAccess.denied:
        return const SleepSessionEditResult.permissionNeeded();
      case _WriteAccess.unavailable:
        return const SleepSessionEditResult.failed();
      case _WriteAccess.granted:
        break;
    }

    final stored = await _sync.findById(localId);
    if (stored == null) return const SleepSessionEditResult.failed();

    final upload = await _upload.updateSyncedSession(
      stored,
      startedAt,
      endedAt,
    );
    if (upload.status != SleepUploadStatus.uploaded) {
      return SleepSessionEditResult.failed(error: upload.error);
    }

    final bool localUpdated;
    if (stored.origin == SleepSessionOrigin.local) {
      localUpdated = await _sessions.updateSession(
        localId,
        startedAt,
        endedAt,
        markHealthPending: false,
      );
    } else {
      localUpdated = await _sync.updateDownloaded(localId, startedAt, endedAt);
    }
    if (!localUpdated) return const SleepSessionEditResult.failed();

    return SleepSessionEditResult.saved(session.withTimes(startedAt, endedAt));
  }

  Future<SleepSessionEditResult> _deleteLocal(SleepSession session) async {
    final localId = session.localId;
    if (localId == null) return const SleepSessionEditResult.failed();

    final stored = await _sync.findById(localId);
    final healthRecordId = stored?.healthRecordId ?? session.healthRecordId;
    final clientRecordId =
        stored?.healthClientRecordId ?? session.healthClientRecordId;

    // Every local row has a stable client id after the v4 migration, but only
    // a stored Health Connect UUID proves the record actually exists there.
    if (healthRecordId == null) {
      final deleted = await _sessions.deleteSession(localId);
      return deleted
          ? const SleepSessionEditResult.deleted()
          : const SleepSessionEditResult.failed();
    }

    switch (await _writeAccess()) {
      case _WriteAccess.denied:
        return const SleepSessionEditResult.permissionNeeded();
      case _WriteAccess.unavailable:
        return const SleepSessionEditResult.failed();
      case _WriteAccess.granted:
        final deletedOnHealth = await _gateway.deleteSleepSession(
          clientRecordId: clientRecordId,
          healthRecordId: healthRecordId,
        );
        if (!deletedOnHealth) {
          return const SleepSessionEditResult.failed();
        }
    }

    final deleted = await _sessions.deleteSession(localId);
    return deleted
        ? const SleepSessionEditResult.deleted()
        : const SleepSessionEditResult.failed();
  }

  Future<SleepSessionEditResult> _deleteHealthConnect(
    SleepSession session,
  ) async {
    final clientRecordId = session.healthClientRecordId;
    final healthRecordId = session.healthRecordId;
    if (clientRecordId == null && healthRecordId == null) {
      return const SleepSessionEditResult.failed();
    }

    switch (await _writeAccess()) {
      case _WriteAccess.denied:
        return const SleepSessionEditResult.permissionNeeded();
      case _WriteAccess.unavailable:
        return const SleepSessionEditResult.failed();
      case _WriteAccess.granted:
        final deleted = await _gateway.deleteSleepSession(
          clientRecordId: clientRecordId,
          healthRecordId: healthRecordId,
        );
        if (!deleted) return const SleepSessionEditResult.failed();
    }

    // Health Connect is the source of truth in this mode. Removing the local
    // copy is cleanup; a failure there must not keep the record in the list.
    final localId = session.localId;
    if (localId != null) {
      try {
        final stored = await _sync.findById(localId);
        if (stored != null) {
          if (stored.origin == SleepSessionOrigin.local) {
            await _sessions.deleteSession(stored.id);
          } else {
            await _sync.deleteDownloaded(stored.id);
          }
        }
      } catch (error, stackTrace) {
        debugPrint(
          'Sleepy3: could not delete the local copy of a Health Connect '
          'record: $error\n$stackTrace',
        );
      }
    }

    return const SleepSessionEditResult.deleted();
  }

  Future<_WriteAccess> _writeAccess() async {
    try {
      final availability = await _gateway.checkAvailability();
      if (availability != HealthConnectAvailability.available) {
        return _WriteAccess.unavailable;
      }
      final granted = await _gateway.hasPermissions(read: false, write: true);
      return granted ? _WriteAccess.granted : _WriteAccess.denied;
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not check Health Connect write access: '
        '$error\n$stackTrace',
      );
      return _WriteAccess.unavailable;
    }
  }
}

enum _WriteAccess { granted, denied, unavailable }

/// The edit service with the production stores, gateway and clock.
final sleepSessionEditServiceProvider = Provider<SleepSessionEditService>((
  ref,
) {
  return SleepSessionEditService(
    ref.watch(sleepSessionStoreProvider),
    ref.watch(healthSyncStoreProvider),
    ref.watch(healthConnectGatewayProvider),
    ref.watch(sleepUploadServiceProvider),
    ref.watch(sleepClockProvider),
  );
});
