import 'package:flutter/foundation.dart';

import '../../sleep_tracking/domain/sleep_session.dart';
import '../domain/health_connect_gateway.dart';
import '../domain/health_history_access.dart';
import '../domain/health_sleep_session.dart';
import '../domain/health_sync_store.dart';
import '../domain/stored_sleep_session.dart';
import 'sleep_upload_service.dart';

/// Why a copy action could not start or finish.
enum SleepCopyFailure {
  /// Health Connect is not installed or is not supported.
  unavailable,

  /// Health Connect is installed but needs an update.
  updateRequired,

  /// The user did not grant the permission the action needs.
  permissionDenied,

  /// The platform or the local database failed.
  failed,
}

/// The outcome of a copy action between the local database and Health Connect.
///
/// Uploads count successful writes in [added]. Downloads count new rows in
/// [added] and changed downloaded rows in [updated]. [skipped] covers rows that
/// were already in place or that must not be overwritten, and [total] is every
/// record the action considered.
class CopyResult {
  const CopyResult({
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.failed = 0,
    this.total = 0,
    this.historyLimited = false,
    this.failure,
    this.error,
  });

  final int added;
  final int updated;
  final int skipped;
  final int failed;
  final int total;

  /// Whether a download only covered the last [healthConnectHistoryLimit]
  /// because the history permission is not granted.
  final bool historyLimited;

  /// Set when the action could not run at all.
  final SleepCopyFailure? failure;

  /// The last exception, if any. Only for diagnostics and tests.
  final Object? error;

  bool get succeeded => failure == null && failed == 0;

  /// Whether any local or Health Connect row changed.
  bool get hasChanges => added > 0 || updated > 0;
}

/// Moves sleep sessions between the local database and Health Connect.
///
/// Uploads only ever send rows that started in Sleepy3 and are still pending.
/// Downloads only ever add rows or update rows that came from Health Connect,
/// so a local session is never overwritten. Repeating an action is safe:
/// uploads reuse a stable client record id and downloads deduplicate by record
/// id and, when it is missing, by exact start and end times.
class SleepCopyService {
  SleepCopyService(this._gateway, this._store, this._upload, this._clock);

  /// Reads from the epoch when the history permission is granted, so no record
  /// is excluded by a range guess.
  static final DateTime _earliest = DateTime.fromMillisecondsSinceEpoch(0);

  final HealthConnectGateway _gateway;
  final HealthSyncStore _store;
  final SleepUploadService _upload;
  final DateTime Function() _clock;

  /// Uploads the most recent pending local session, if there is one.
  Future<CopyResult> syncLastSession() async {
    StoredSleepSession? latest;
    try {
      latest = await _store.loadLatestPendingUpload();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not load the latest pending session: '
        '$error\n$stackTrace',
      );
      return CopyResult(failure: SleepCopyFailure.failed, error: error);
    }

    if (latest == null) return const CopyResult();

    final blocked = await _ensurePermissions(write: true);
    if (blocked != null) return blocked;

    final result = await _upload.uploadStored(latest);
    return _uploadResult(result, total: 1);
  }

  /// Uploads every pending local session, oldest first.
  Future<CopyResult> uploadAllPreviousSessions() async {
    List<StoredSleepSession> pending;
    try {
      pending = await _store.loadPendingUploads();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not load the pending sessions: $error\n$stackTrace',
      );
      return CopyResult(failure: SleepCopyFailure.failed, error: error);
    }

    if (pending.isEmpty) return const CopyResult();

    final blocked = await _ensurePermissions(write: true);
    if (blocked != null) return blocked;

    var added = 0;
    var skipped = 0;
    var failed = 0;
    Object? lastError;

    for (final stored in pending) {
      final result = await _upload.uploadStored(stored);
      switch (result.status) {
        case SleepUploadStatus.uploaded:
          added++;
        case SleepUploadStatus.skipped:
          skipped++;
        case SleepUploadStatus.failed:
          failed++;
          lastError = result.error ?? lastError;
      }
    }

    return CopyResult(
      added: added,
      skipped: skipped,
      failed: failed,
      total: pending.length,
      error: lastError,
    );
  }

  /// Downloads every Health Connect sleep session into the local database.
  ///
  /// Without the history permission only the last
  /// [healthConnectHistoryLimit] are read, and [CopyResult.historyLimited] says
  /// so. The caller asks for the permission before starting.
  Future<CopyResult> downloadAllFromHealthConnect() async {
    final blocked = await _ensurePermissions(read: true);
    if (blocked != null) return blocked;

    final now = _clock();
    final fullHistory = await _isHistoryAuthorized();
    List<HealthSleepSession> records;
    try {
      records = await _gateway.readSleepSessions(
        from: fullHistory ? _earliest : now.subtract(healthConnectHistoryLimit),
        // A record from another device can end slightly in the future when the
        // clocks disagree. Include that day so the session is not dropped.
        to: now.add(const Duration(days: 1)),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read Health Connect sessions: '
        '$error\n$stackTrace',
      );
      return CopyResult(failure: SleepCopyFailure.failed, error: error);
    }

    var added = 0;
    var updated = 0;
    var skipped = 0;
    var failed = 0;
    Object? lastError;

    for (final record in records) {
      if (record.endedAt.isBefore(record.startedAt)) {
        skipped++;
        continue;
      }

      try {
        switch (await _downloadOne(record, now)) {
          case _DownloadOutcome.added:
            added++;
          case _DownloadOutcome.updated:
            updated++;
          case _DownloadOutcome.skipped:
            skipped++;
        }
      } catch (error, stackTrace) {
        failed++;
        lastError = error;
        debugPrint(
          'Sleepy3: could not store a downloaded session: '
          '$error\n$stackTrace',
        );
      }
    }

    return CopyResult(
      added: added,
      updated: updated,
      skipped: skipped,
      failed: failed,
      total: records.length,
      historyLimited: !fullHistory,
      error: lastError,
    );
  }

  Future<_DownloadOutcome> _downloadOne(
    HealthSleepSession record,
    DateTime syncedAt,
  ) async {
    final uuid = record.uuid.trim();

    if (uuid.isNotEmpty) {
      final byId = await _store.findByHealthRecordId(uuid);
      if (byId != null) {
        // A local row is never overwritten by a download, even when Health
        // Connect has a record with the same id.
        if (byId.origin == SleepSessionOrigin.local) {
          return _DownloadOutcome.skipped;
        }
        if (_hasSameTimes(byId.session, record)) {
          return _DownloadOutcome.skipped;
        }

        final changed = await _store.updateDownloaded(
          byId.id,
          record.startedAt,
          record.endedAt,
        );
        return changed ? _DownloadOutcome.updated : _DownloadOutcome.skipped;
      }
    }

    final byTimes = await _store.findByExactTimes(
      record.startedAt,
      record.endedAt,
    );
    if (byTimes != null) {
      // A local row already covers this time range, or a downloaded row with a
      // missing id already represents it. Neither needs a new row.
      return _DownloadOutcome.skipped;
    }

    await _store.insertDownloaded(
      SleepSession(startedAt: record.startedAt, endedAt: record.endedAt),
      uuid.isEmpty ? null : uuid,
      syncedAt,
    );
    return _DownloadOutcome.added;
  }

  /// Whether Health Connect will return records older than the fallback
  /// window. A platform failure counts as no access: a download must still
  /// work with the last [healthConnectHistoryLimit].
  Future<bool> _isHistoryAuthorized() async {
    try {
      return await _gateway.isHistoryAuthorized();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read the Health Connect history permission: '
        '$error\n$stackTrace',
      );
      return false;
    }
  }

  Future<CopyResult?> _ensurePermissions({
    bool read = false,
    bool write = false,
  }) async {
    final HealthConnectAvailability availability;
    try {
      availability = await _gateway.checkAvailability();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not check Health Connect availability: '
        '$error\n$stackTrace',
      );
      return CopyResult(failure: SleepCopyFailure.failed, error: error);
    }

    switch (availability) {
      case HealthConnectAvailability.available:
        break;
      case HealthConnectAvailability.updateRequired:
        return const CopyResult(failure: SleepCopyFailure.updateRequired);
      case HealthConnectAvailability.unavailable:
        return const CopyResult(failure: SleepCopyFailure.unavailable);
    }

    try {
      final granted =
          await _gateway.hasPermissions(read: read, write: write) ||
          await _gateway.requestPermissions(read: read, write: write);
      if (!granted) {
        return const CopyResult(failure: SleepCopyFailure.permissionDenied);
      }
      return null;
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not get Health Connect permissions: '
        '$error\n$stackTrace',
      );
      return CopyResult(failure: SleepCopyFailure.failed, error: error);
    }
  }

  CopyResult _uploadResult(SleepUploadResult result, {required int total}) {
    return switch (result.status) {
      SleepUploadStatus.uploaded => CopyResult(added: 1, total: total),
      SleepUploadStatus.skipped => CopyResult(skipped: 1, total: total),
      SleepUploadStatus.failed => CopyResult(
        failed: 1,
        total: total,
        error: result.error,
      ),
    };
  }

  bool _hasSameTimes(SleepSession session, HealthSleepSession record) {
    final endedAt = session.endedAt;
    return endedAt != null &&
        session.startedAt.millisecondsSinceEpoch ==
            record.startedAt.millisecondsSinceEpoch &&
        endedAt.millisecondsSinceEpoch == record.endedAt.millisecondsSinceEpoch;
  }
}

enum _DownloadOutcome { added, updated, skipped }
