import 'package:flutter/foundation.dart';

import '../../sleep_tracking/domain/sleep_session.dart';
import '../domain/health_connect_gateway.dart';
import '../domain/health_history_access.dart';
import '../domain/health_sleep_session.dart';
import '../domain/health_sync_store.dart';
import '../domain/sleep_history_repository.dart';
import '../domain/stored_sleep_session.dart';

/// [SleepHistoryRepository] backed by Health Connect.
///
/// This reads every `SLEEP_SESSION` Health Connect exposes, regardless of the
/// app that wrote it. The times always come from Health Connect; the optional
/// [syncStore] only adds the local row identity when a copy exists, so the
/// editor can update that copy. Without the history permission the read stops
/// at [healthConnectHistoryLimit], matching the window Android enforces.
class HealthConnectSleepHistoryRepository implements SleepHistoryRepository {
  HealthConnectSleepHistoryRepository(
    this._gateway,
    this._clock, {
    this.fullHistory = false,
    this.syncStore,
  });

  /// Reads from the epoch so no record is excluded by a range guess.
  static final DateTime _earliest = DateTime.fromMillisecondsSinceEpoch(0);

  final HealthConnectGateway _gateway;
  final DateTime Function() _clock;

  /// Whether records older than [healthConnectHistoryLimit] are read.
  final bool fullHistory;

  /// Source of the local copy metadata attached to each record.
  ///
  /// Null when the caller only needs the platform history.
  final HealthSyncStore? syncStore;

  @override
  Future<List<SleepSession>> loadClosedSessions() async {
    final now = _clock();
    final records = await _gateway.readSleepSessions(
      from: fullHistory ? _earliest : now.subtract(healthConnectHistoryLimit),
      // A record from another device can end slightly in the future when the
      // clocks disagree. Include that day so the session is not dropped.
      to: now.add(const Duration(days: 1)),
    );
    final localCopies = await _loadLocalCopies();

    final sessions = <SleepSession>[
      for (final record in records)
        if (!record.endedAt.isBefore(record.startedAt))
          _toSession(record, localCopies[record.uuid]),
    ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    return List.unmodifiable(sessions);
  }

  /// Reads every local copy once and indexes it by Health Connect UUID.
  ///
  /// A failure here must not hide the platform history: the records are still
  /// returned, just without the local metadata that lets the user edit them.
  Future<Map<String, StoredSleepSession>> _loadLocalCopies() async {
    final store = syncStore;
    if (store == null) return const {};

    try {
      final rows = await store.loadLocalSessionsWithHealthRecordId();
      final copies = <String, StoredSleepSession>{};
      for (final row in rows) {
        final recordId = row.healthRecordId;
        if (recordId == null) continue;
        // The store returns rows oldest first; keep the first copy of a UUID.
        copies.putIfAbsent(recordId, () => row);
      }
      return copies;
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read local session metadata: '
        '$error\n$stackTrace',
      );
      return const {};
    }
  }

  SleepSession _toSession(
    HealthSleepSession record,
    StoredSleepSession? local,
  ) {
    return SleepSession(
      startedAt: record.startedAt,
      endedAt: record.endedAt,
      localId: local?.id,
      healthRecordId: record.uuid.isEmpty ? null : record.uuid,
      healthClientRecordId: local?.healthClientRecordId,
      sourceId: record.sourceId.isEmpty ? null : record.sourceId,
    );
  }
}
