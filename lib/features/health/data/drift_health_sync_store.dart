import 'package:drift/drift.dart';

import '../../sleep_tracking/data/sleepy3_database.dart';
import '../../sleep_tracking/domain/sleep_session.dart';
import '../domain/health_sync_store.dart';
import '../domain/stored_sleep_session.dart';

/// [HealthSyncStore] over the app's single Drift database.
class DriftHealthSyncStore implements HealthSyncStore {
  DriftHealthSyncStore(this._db);

  final Sleepy3Database _db;

  Expression<bool> _isPending($SleepSessionsTable row) {
    return row.origin.equals(SleepSessionOrigin.local.storageValue) &
        row.endedAtMillis.isNotNull() &
        row.healthSyncedAtMillis.isNull() &
        row.healthSyncSkipped.equals(false);
  }

  @override
  Future<List<StoredSleepSession>> loadPendingUploads() async {
    final rows =
        await (_db.select(_db.sleepSessions)
              ..where(_isPending)
              ..orderBy([
                (row) => OrderingTerm.asc(row.startedAtMillis),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    return List.unmodifiable(rows.map(_toDomain));
  }

  @override
  Future<List<StoredSleepSession>> loadPendingUpdates() async {
    final rows =
        await (_db.select(_db.sleepSessions)
              ..where((row) => _isPending(row) & row.healthRecordId.isNotNull())
              ..orderBy([
                (row) => OrderingTerm.asc(row.startedAtMillis),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    return List.unmodifiable(rows.map(_toDomain));
  }

  @override
  Future<List<StoredSleepSession>> loadLocalSessionsWithHealthRecordId() async {
    final rows =
        await (_db.select(_db.sleepSessions)
              ..where(
                (row) =>
                    row.origin.equals(SleepSessionOrigin.local.storageValue) &
                    row.healthRecordId.isNotNull() &
                    row.endedAtMillis.isNotNull(),
              )
              ..orderBy([
                (row) => OrderingTerm.asc(row.startedAtMillis),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    return List.unmodifiable(rows.map(_toDomain));
  }

  @override
  Future<StoredSleepSession?> loadLatestPendingUpload() async {
    final row =
        await (_db.select(_db.sleepSessions)
              ..where(_isPending)
              ..orderBy([
                (row) => OrderingTerm.desc(row.startedAtMillis),
                (row) => OrderingTerm.desc(row.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> markUploadAttempt(int rowId, int version) async {
    await (_db.update(_db.sleepSessions)..where((row) => row.id.equals(rowId)))
        .write(SleepSessionsCompanion(healthRecordVersion: Value(version)));
  }

  @override
  Future<void> markUploaded(
    int rowId,
    String healthRecordId,
    DateTime syncedAt, {
    required String clientRecordId,
    required int version,
  }) async {
    await (_db.update(
      _db.sleepSessions,
    )..where((row) => row.id.equals(rowId))).write(
      SleepSessionsCompanion(
        healthRecordId: Value(healthRecordId),
        healthClientRecordId: Value(clientRecordId),
        healthRecordVersion: Value(version),
        healthSyncedAtMillis: Value(syncedAt.millisecondsSinceEpoch),
        healthSyncSkipped: const Value(false),
      ),
    );
  }

  @override
  Future<void> markPendingUpdate(int rowId) async {
    await (_db.update(_db.sleepSessions)..where(
          (row) =>
              row.id.equals(rowId) &
              row.origin.equals(SleepSessionOrigin.local.storageValue),
        ))
        .write(
          const SleepSessionsCompanion(
            healthSyncedAtMillis: Value(null),
            healthSyncSkipped: Value(false),
          ),
        );
  }

  @override
  Future<void> markSkipped(int rowId) async {
    await (_db.update(_db.sleepSessions)..where((row) => row.id.equals(rowId)))
        .write(const SleepSessionsCompanion(healthSyncSkipped: Value(true)));
  }

  @override
  Future<StoredSleepSession?> findByHealthRecordId(
    String healthRecordId,
  ) async {
    final row =
        await (_db.select(_db.sleepSessions)
              ..where((row) => row.healthRecordId.equals(healthRecordId))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<StoredSleepSession?> findById(int rowId) async {
    final row =
        await (_db.select(_db.sleepSessions)
              ..where((row) => row.id.equals(rowId))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<StoredSleepSession?> findByExactTimes(
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    final row =
        await (_db.select(_db.sleepSessions)
              ..where(
                (row) =>
                    row.startedAtMillis.equals(
                      startedAt.millisecondsSinceEpoch,
                    ) &
                    row.endedAtMillis.equals(endedAt.millisecondsSinceEpoch),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.id)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<int> insertDownloaded(
    SleepSession session,
    String? healthRecordId,
    DateTime syncedAt,
  ) async {
    final endedAt = session.endedAt;
    if (endedAt == null) {
      throw ArgumentError.value(
        session,
        'session',
        'Downloaded sessions must be closed',
      );
    }
    final normalizedId = _normalizeRecordId(healthRecordId);
    return _db
        .into(_db.sleepSessions)
        .insert(
          SleepSessionsCompanion.insert(
            startedAtMillis: session.startedAt.millisecondsSinceEpoch,
            endedAtMillis: Value(endedAt.millisecondsSinceEpoch),
            healthRecordId: Value(normalizedId),
            healthRecordVersion: Value(normalizedId == null ? 0 : 1),
            healthSyncedAtMillis: Value(syncedAt.millisecondsSinceEpoch),
            origin: Value(SleepSessionOrigin.healthConnect.storageValue),
          ),
        );
  }

  @override
  Future<bool> updateDownloaded(
    int rowId,
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    final updated =
        await (_db.update(_db.sleepSessions)..where(
              (row) =>
                  row.id.equals(rowId) &
                  row.origin.equals(
                    SleepSessionOrigin.healthConnect.storageValue,
                  ),
            ))
            .write(
              SleepSessionsCompanion(
                startedAtMillis: Value(startedAt.millisecondsSinceEpoch),
                endedAtMillis: Value(endedAt.millisecondsSinceEpoch),
              ),
            );
    return updated > 0;
  }

  @override
  Future<bool> deleteDownloaded(int rowId) async {
    final deleted =
        await (_db.delete(_db.sleepSessions)..where(
              (row) =>
                  row.id.equals(rowId) &
                  row.origin.equals(
                    SleepSessionOrigin.healthConnect.storageValue,
                  ),
            ))
            .go();
    return deleted > 0;
  }

  @override
  Future<int> loadPendingCount() async {
    final count = _db.sleepSessions.id.count();
    final row =
        await (_db.selectOnly(_db.sleepSessions)
              ..addColumns([count])
              ..where(_isPending(_db.sleepSessions)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  StoredSleepSession _toDomain(SleepSessionRow row) {
    final endedAt = row.endedAtMillis;
    return StoredSleepSession(
      id: row.id,
      session: SleepSession(
        startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAtMillis),
        endedAt: endedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(endedAt),
      ),
      healthRecordId: row.healthRecordId,
      healthClientRecordId: row.healthClientRecordId,
      healthRecordVersion: row.healthRecordVersion,
      healthSyncedAt: row.healthSyncedAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.healthSyncedAtMillis!),
      healthSyncSkipped: row.healthSyncSkipped,
      origin: SleepSessionOrigin.fromStorageValue(row.origin),
    );
  }

  String? _normalizeRecordId(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
