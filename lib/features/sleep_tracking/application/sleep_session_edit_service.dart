import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/application/current_app_package_provider.dart';
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
    this._clock, {
    this.currentPackage = 'com.sleepy3.app',
  });

  final SleepSessionStore _sessions;
  final HealthSyncStore _sync;
  final HealthConnectGateway _gateway;
  final SleepUploadService _upload;
  final DateTime Function() _clock;

  /// Package of the running build. Health Connect only lets this package
  /// change the records it wrote.
  final String currentPackage;

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
      isOwnHealthRecord: isHealthRecordOwnedBy(
        session.sourceId,
        currentPackage,
      ),
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
        final token = await _readToken(recordId);
        final result = await _upload.updateSyncedSession(
          stored,
          startedAt,
          endedAt,
          token: token,
        );
        if (result.status != SleepUploadStatus.uploaded) {
          return SleepSessionEditResult.savedPendingSync(updatedSession);
        }
        return SleepSessionEditResult.saved(
          updatedSession.withHealthIdentity(
            healthRecordId: result.healthRecordId,
            healthClientRecordId:
                token?.clientRecordId ?? stored.healthClientRecordId,
          ),
        );
    }
  }

  Future<SleepSessionEditResult> _updateHealthConnect(
    SleepSession session,
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    final localId = session.localId;
    final healthRecordId = session.healthRecordId;
    final hasLocalClientId =
        localId != null && session.healthClientRecordId != null;
    if (healthRecordId == null && !hasLocalClientId) {
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

    final stored = localId == null ? null : await _sync.findById(localId);

    // A record with no UUID only has its local client id. This is a fallback
    // for a pending row that reached the Google Health list with an older id.
    if (healthRecordId == null) {
      if (stored == null || stored.healthClientRecordId == null) {
        return const SleepSessionEditResult.failed();
      }
      final upload = await _upload.updateSyncedSession(
        stored,
        startedAt,
        endedAt,
      );
      if (upload.status != SleepUploadStatus.uploaded) {
        return SleepSessionEditResult.failed(error: upload.error);
      }

      final localUpdated = await _updateLocalCopy(stored, startedAt, endedAt);
      if (!localUpdated) return const SleepSessionEditResult.failed();

      return SleepSessionEditResult.saved(
        session
            .withTimes(startedAt, endedAt)
            .withHealthIdentity(
              healthRecordId: upload.healthRecordId,
              healthClientRecordId: stored.healthClientRecordId,
            ),
      );
    }

    // Health Connect is the authority on the client id and version. A row
    // migrated from an older version can carry an id that no longer matches the
    // record, and reusing it would create a duplicate instead of an update.
    final token = await _readToken(healthRecordId);
    if (token == null) return const SleepSessionEditResult.failed();

    if (stored != null) {
      final upload = await _upload.updateSyncedSession(
        stored,
        startedAt,
        endedAt,
        token: token,
      );
      if (upload.status != SleepUploadStatus.uploaded) {
        return SleepSessionEditResult.failed(error: upload.error);
      }

      final localUpdated = await _updateLocalCopy(stored, startedAt, endedAt);
      if (!localUpdated) return const SleepSessionEditResult.failed();

      return SleepSessionEditResult.saved(
        session
            .withTimes(startedAt, endedAt)
            .withHealthIdentity(
              healthRecordId: upload.healthRecordId,
              healthClientRecordId: token.clientRecordId,
            ),
      );
    }

    // A Google Health record can exist without a local copy, for example after
    // reinstalling the app. Update it in place through its platform token.
    final updated = await _gateway.updateSleepSession(
      healthRecordId: healthRecordId,
      startedAt: startedAt,
      endedAt: endedAt,
    );
    if (updated == null) return const SleepSessionEditResult.failed();

    return SleepSessionEditResult.saved(
      session
          .withTimes(startedAt, endedAt)
          .withHealthIdentity(
            healthRecordId: updated.healthRecordId,
            healthClientRecordId: updated.clientRecordId,
          ),
    );
  }

  Future<bool> _updateLocalCopy(
    StoredSleepSession stored,
    DateTime startedAt,
    DateTime endedAt,
  ) {
    if (stored.origin == SleepSessionOrigin.local) {
      return _sessions.updateSession(
        stored.id,
        startedAt,
        endedAt,
        markHealthPending: false,
      );
    }
    return _sync.updateDownloaded(stored.id, startedAt, endedAt);
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
        final deletedOnHealth = await _deleteHealthRecord(
          healthRecordId: healthRecordId,
          clientRecordId: clientRecordId,
          startedAt: stored?.session.startedAt ?? session.startedAt,
          endedAt: stored?.session.endedAt ?? session.endedAt!,
        );
        if (deletedOnHealth == SleepRecordDeleteResult.permission) {
          return const SleepSessionEditResult.permissionNeeded();
        }
        if (deletedOnHealth != SleepRecordDeleteResult.deleted) {
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
        final deleted = await _deleteHealthRecord(
          healthRecordId: healthRecordId,
          clientRecordId: clientRecordId,
          startedAt: session.startedAt,
          endedAt: session.endedAt!,
        );
        if (deleted == SleepRecordDeleteResult.permission) {
          return const SleepSessionEditResult.permissionNeeded();
        }
        if (deleted != SleepRecordDeleteResult.deleted) {
          return const SleepSessionEditResult.failed();
        }
    }

    // Health Connect is the source of truth in this mode. Removing the local
    // copy is cleanup; a failure there must not keep the record in the list.
    await _cleanupLocalCopy(session);
    return const SleepSessionEditResult.deleted();
  }

  /// Deletes one Sleepy3 record, trying every stored identity.
  ///
  /// UUID first: a record migrated from an older version can carry a client id
  /// that no longer matches the record. If neither id works, the record is
  /// looked up again by its exact times. A record that no longer exists counts
  /// as deleted, so a stale local row cannot block the action forever.
  Future<SleepRecordDeleteResult> _deleteHealthRecord({
    required String? healthRecordId,
    required String? clientRecordId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final attempts = <({String? healthRecordId, String? clientRecordId})>[
      if (healthRecordId != null)
        (healthRecordId: healthRecordId, clientRecordId: null),
      if (clientRecordId != null)
        (healthRecordId: null, clientRecordId: clientRecordId),
    ];
    if (attempts.isEmpty) return SleepRecordDeleteResult.failed;

    var sawPermission = false;
    var sawFailure = false;
    var sawNotFound = false;
    for (final attempt in attempts) {
      final result = await _gateway.deleteSleepSession(
        healthRecordId: attempt.healthRecordId,
        clientRecordId: attempt.clientRecordId,
      );
      debugPrint(
        'Sleepy3: delete attempt '
        '${attempt.healthRecordId != null ? 'uuid' : 'client id'} -> '
        '$result',
      );
      switch (result) {
        case SleepRecordDeleteResult.deleted:
          return SleepRecordDeleteResult.deleted;
        case SleepRecordDeleteResult.permission:
          sawPermission = true;
        case SleepRecordDeleteResult.notFound:
          sawNotFound = true;
        case SleepRecordDeleteResult.failed:
          sawFailure = true;
      }
    }
    if (sawPermission) return SleepRecordDeleteResult.permission;
    // Only a missing id is safe to repair by reading the record again. A real
    // platform failure must stay visible instead of being reported as deleted.
    if (sawFailure || !sawNotFound) return SleepRecordDeleteResult.failed;

    return _deleteByExactTimes(startedAt, endedAt);
  }

  /// Finds the current record by its exact times and deletes it.
  ///
  /// Returns [SleepRecordDeleteResult.deleted] when no Sleepy3 record covers
  /// the interval: there is nothing left to delete.
  Future<SleepRecordDeleteResult> _deleteByExactTimes(
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    try {
      final records = await _gateway.readSleepSessions(
        from: startedAt,
        to: endedAt.add(const Duration(seconds: 1)),
      );
      final exact = records
          .where(
            (record) =>
                record.startedAt == startedAt && record.endedAt == endedAt,
          )
          .toList(growable: false);
      final own = exact
          .where(
            (record) => isHealthRecordOwnedBy(record.sourceId, currentPackage),
          )
          .toList(growable: false);

      // A Sleepy3 record at these times belongs to the other build. Health
      // Connect will not let this package delete it.
      if (own.isEmpty &&
          exact.any((record) => isSleepy3HealthRecord(record.sourceId))) {
        return SleepRecordDeleteResult.permission;
      }

      var sawFailure = false;
      for (final record in own) {
        final result = await _gateway.deleteSleepSession(
          healthRecordId: record.uuid,
        );
        switch (result) {
          case SleepRecordDeleteResult.deleted:
            return SleepRecordDeleteResult.deleted;
          case SleepRecordDeleteResult.permission:
            return SleepRecordDeleteResult.permission;
          case SleepRecordDeleteResult.notFound:
            break;
          case SleepRecordDeleteResult.failed:
            sawFailure = true;
        }
      }
      return sawFailure
          ? SleepRecordDeleteResult.failed
          : SleepRecordDeleteResult.deleted;
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not re-read a session to delete it: '
        '$error\n$stackTrace',
      );
      return SleepRecordDeleteResult.failed;
    }
  }

  Future<void> _cleanupLocalCopy(SleepSession session) async {
    final localId = session.localId;
    if (localId == null) return;
    try {
      final stored = await _sync.findById(localId);
      if (stored == null) return;
      if (stored.origin == SleepSessionOrigin.local) {
        await _sessions.deleteSession(stored.id);
      } else {
        await _sync.deleteDownloaded(stored.id);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not delete the local copy of a Health Connect '
        'record: $error\n$stackTrace',
      );
    }
  }

  Future<HealthRecordWriteToken?> _readToken(String healthRecordId) async {
    try {
      return await _gateway.readSleepSessionWriteToken(healthRecordId);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read a Health Connect record token: '
        '$error\n$stackTrace',
      );
      return null;
    }
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
    currentPackage: ref.watch(currentAppPackageProvider),
  );
});
