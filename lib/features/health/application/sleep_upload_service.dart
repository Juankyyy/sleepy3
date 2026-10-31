import 'package:flutter/foundation.dart';

import '../../sleep_tracking/domain/sleep_session.dart';
import '../domain/health_connect_gateway.dart';
import '../domain/health_sync_store.dart';
import '../domain/stored_sleep_session.dart';

/// What happened to one session upload attempt.
enum SleepUploadStatus {
  /// Health Connect accepted the record and the local row is marked as synced.
  uploaded,

  /// The session cannot be uploaded: zero duration, already synced or
  /// downloaded from Health Connect.
  skipped,

  /// The write failed or Health Connect rejected it. The row stays pending.
  failed,
}

/// The outcome of uploading one session.
class SleepUploadResult {
  const SleepUploadResult(this.status, {this.healthRecordId, this.error});

  final SleepUploadStatus status;

  /// The Health Connect UUID when [status] is [SleepUploadStatus.uploaded].
  final String? healthRecordId;

  /// The exception that made [status] [SleepUploadStatus.failed], if any.
  final Object? error;

  bool get isFailure => status == SleepUploadStatus.failed;
}

/// The outcome of retrying every pending upload.
class SleepUploadBatchResult {
  const SleepUploadBatchResult({
    this.uploaded = 0,
    this.skipped = 0,
    this.failed = 0,
    this.total = 0,
    this.error,
  });

  final int uploaded;
  final int skipped;
  final int failed;

  /// Rows considered, including skipped ones.
  final int total;

  /// The last exception, or a store read error.
  final Object? error;

  bool get succeeded => error == null && failed == 0;
}

/// Uploads closed local sessions to Health Connect.
///
/// The upload is idempotent: every write uses a stable `clientRecordId`
/// derived from the start time, so retrying the same session updates the same
/// Health Connect record instead of creating another one.
class SleepUploadService {
  SleepUploadService(this._gateway, this._store, this._clock);

  final HealthConnectGateway _gateway;
  final HealthSyncStore _store;
  final DateTime Function() _clock;

  /// The stable Health Connect client record id for a session.
  static String clientRecordIdFor(DateTime startedAt) =>
      'sleepy3-${startedAt.millisecondsSinceEpoch}';

  /// Uploads one finished session, if it is still pending.
  ///
  /// A missing local row is not fatal: the write is attempted anyway so a
  /// session is not lost when the safety copy failed, but only a found row can
  /// be marked as uploaded.
  Future<SleepUploadResult> uploadSession(SleepSession session) async {
    if (session.isOpen) {
      throw ArgumentError.value(
        session,
        'session',
        'Only closed sessions can be uploaded',
      );
    }

    StoredSleepSession? stored;
    try {
      stored = await _store.findByExactTimes(
        session.startedAt,
        session.endedAt!,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not find the local session to upload: '
        '$error\n$stackTrace',
      );
    }

    return _upload(session, stored);
  }

  /// Uploads a row that was already loaded from the sync store.
  ///
  /// Used by the copy actions, which already know which row they are sending,
  /// so the row cannot be confused with another one with the same times.
  Future<SleepUploadResult> uploadStored(StoredSleepSession stored) =>
      _upload(stored.session, stored);

  /// Uploads every local session that still needs Health Connect.
  Future<SleepUploadBatchResult> retryPending() async {
    List<StoredSleepSession> pending;
    try {
      pending = await _store.loadPendingUploads();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not load pending uploads: $error\n$stackTrace',
      );
      return SleepUploadBatchResult(error: error);
    }

    var uploaded = 0;
    var skipped = 0;
    var failed = 0;
    Object? lastError;

    for (final stored in pending) {
      final result = await _upload(stored.session, stored);
      switch (result.status) {
        case SleepUploadStatus.uploaded:
          uploaded++;
        case SleepUploadStatus.skipped:
          skipped++;
        case SleepUploadStatus.failed:
          failed++;
          lastError = result.error ?? lastError;
      }
    }

    return SleepUploadBatchResult(
      uploaded: uploaded,
      skipped: skipped,
      failed: failed,
      total: pending.length,
      error: lastError,
    );
  }

  Future<SleepUploadResult> _upload(
    SleepSession session,
    StoredSleepSession? stored,
  ) async {
    try {
      // A row that is already synced, skipped or downloaded from Health
      // Connect is not uploaded again.
      if (stored != null && !stored.isPendingUpload) {
        return const SleepUploadResult(SleepUploadStatus.skipped);
      }

      if (session.duration <= Duration.zero) {
        if (stored != null) await _store.markSkipped(stored.id);
        return const SleepUploadResult(SleepUploadStatus.skipped);
      }

      final uuid = await _gateway.writeSleepSession(
        startedAt: session.startedAt,
        endedAt: session.endedAt!,
        clientRecordId: clientRecordIdFor(session.startedAt),
      );
      if (uuid == null || uuid.isEmpty) {
        return const SleepUploadResult(SleepUploadStatus.failed);
      }

      if (stored != null) {
        await _store.markUploaded(stored.id, uuid, _clock());
      }
      return SleepUploadResult(
        SleepUploadStatus.uploaded,
        healthRecordId: uuid,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not upload a sleep session: $error\n$stackTrace',
      );
      return SleepUploadResult(SleepUploadStatus.failed, error: error);
    }
  }
}
