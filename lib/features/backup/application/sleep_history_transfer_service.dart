import 'package:flutter/foundation.dart';

import '../../health/domain/health_sync_store.dart';
import '../../health/domain/sleep_data_source.dart';
import '../../sleep_tracking/domain/sleep_session.dart';
import '../../sleep_tracking/domain/sleep_session_store.dart';
import '../domain/sleep_history_file.dart';

/// The encoded history and how many sessions it contains.
class SleepHistoryExport {
  const SleepHistoryExport({
    required this.contents,
    required this.sessionCount,
  });

  final String contents;
  final int sessionCount;
}

/// What an import would do before anything is written.
class SleepHistoryImportPreview {
  const SleepHistoryImportPreview({
    required this.file,
    required this.importable,
    required this.duplicates,
  });

  final SleepHistoryFile file;

  /// Valid sessions that are not already in the database, oldest first.
  final List<SleepHistoryEntry> importable;

  /// Valid sessions that exactly match one already stored, or another entry
  /// in the same file.
  final int duplicates;

  int get newSessions => importable.length;

  int get invalidEntries => file.invalidEntries;

  int get totalSessions => importable.length + duplicates + invalidEntries;

  bool get hasNewSessions => importable.isNotEmpty;

  /// Whether the import adds rows that can later be sent with Add.
  bool get hasLocalSessions => importable.any((entry) => !entry.isDownloaded);

  /// Whether the import adds read-only copies of Health Connect records.
  bool get hasDownloadedSessions =>
      importable.any((entry) => entry.isDownloaded);
}

/// The outcome of writing an import preview to the local database.
class SleepHistoryImportResult {
  const SleepHistoryImportResult({
    this.added = 0,
    this.skipped = 0,
    this.failed = 0,
    this.error,
  });

  /// Rows written locally.
  final int added;

  /// Sessions already present or unreadable in the file.
  final int skipped;

  /// Rows that could not be written.
  final int failed;

  /// The last write error, if any. Only for diagnostics and tests.
  final Object? error;
}

/// Reads and writes Sleepy3 history files against the local database.
///
/// The service never calls Health Connect: the caller passes the history that
/// is visible in Stats, which may come from the local database or from the
/// selected Google Health source. New sessions are stored locally and stay
/// there until the user explicitly sends them with `Add`. Exported downloaded
/// copies keep their record identity and read-only status so a restore is
/// faithful to the original.
class SleepHistoryTransferService {
  SleepHistoryTransferService(this._sessions, this._sync, this._clock);

  final SleepSessionStore _sessions;
  final HealthSyncStore _sync;
  final DateTime Function() _clock;

  /// Encodes the history currently shown in Stats.
  ///
  /// In Google Health every entry is written as a read-only Health Connect
  /// copy, because the visible rows are snapshots of platform records. In
  /// Local the rows keep their own provenance: copied downloads stay
  /// read-only and sessions started in Sleepy3 stay local.
  SleepHistoryExport exportHistory(
    Iterable<SleepSession> sessions, {
    required SleepDataSource source,
  }) {
    final file = SleepHistoryFile.fromSessions(
      sessions,
      exportedAt: _clock(),
      markAsDownloaded: source == SleepDataSource.healthConnect,
    );
    return SleepHistoryExport(
      contents: file.encode(),
      sessionCount: file.sessions.length,
    );
  }

  /// Compares [file] with the stored sessions without writing anything.
  Future<SleepHistoryImportPreview> preview(SleepHistoryFile file) async {
    final existing = await _sessions.loadClosedSessions();

    final times = <String>{};
    final recordIds = <String>{};
    final clientIds = <String>{};
    for (final session in existing) {
      final endedAt = session.endedAt;
      if (endedAt == null) continue;
      times.add(_timeKey(session.startedAt, endedAt));
      final recordId = _normalize(session.healthRecordId);
      if (recordId != null) recordIds.add(recordId);
      final clientId = _normalize(session.healthClientRecordId);
      if (clientId != null) clientIds.add(clientId);
    }

    final importable = <SleepHistoryEntry>[];
    var duplicates = 0;

    for (final entry in file.sessions) {
      final recordId = _normalize(entry.healthRecordId);
      final clientId = _normalize(entry.healthClientRecordId);
      final duplicateById =
          (recordId != null && recordIds.contains(recordId)) ||
          (clientId != null && clientIds.contains(clientId));
      final duplicateByTime = !times.add(
        _timeKey(entry.startedAt, entry.endedAt),
      );
      if (duplicateById || duplicateByTime) {
        duplicates++;
        continue;
      }

      if (recordId != null) recordIds.add(recordId);
      if (clientId != null) clientIds.add(clientId);
      importable.add(entry);
    }

    return SleepHistoryImportPreview(
      file: file,
      importable: List.unmodifiable(importable),
      duplicates: duplicates,
    );
  }

  /// Writes the sessions in [preview] to the local database.
  ///
  /// A failure on one row does not stop the rest; the result counts it.
  Future<SleepHistoryImportResult> import(
    SleepHistoryImportPreview preview,
  ) async {
    final syncedAt = _clock();
    var added = 0;
    var failed = 0;
    Object? lastError;

    for (final entry in preview.importable) {
      try {
        if (entry.isDownloaded) {
          await _sync.insertDownloaded(
            entry.toSession(),
            _normalize(entry.healthRecordId),
            syncedAt,
          );
        } else {
          // A restored local session must not inherit the Health Connect
          // identity of the device it came from: the record may not exist on
          // this phone, and Add can upload it as a new one later. The block
          // keeps the automatic retry from sending it before the user asks.
          await _sessions.insertClosedSession(
            SleepSession(startedAt: entry.startedAt, endedAt: entry.endedAt),
            blockHealthSync: true,
          );
        }
        added++;
      } catch (error, stackTrace) {
        failed++;
        lastError = error;
        debugPrint(
          'Sleepy3: could not import a sleep session: $error\n$stackTrace',
        );
      }
    }

    return SleepHistoryImportResult(
      added: added,
      skipped: preview.duplicates + preview.invalidEntries,
      failed: failed,
      error: lastError,
    );
  }

  static String _timeKey(DateTime startedAt, DateTime endedAt) =>
      '${startedAt.millisecondsSinceEpoch}-${endedAt.millisecondsSinceEpoch}';

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
