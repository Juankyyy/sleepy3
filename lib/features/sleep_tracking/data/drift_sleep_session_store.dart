import 'package:drift/drift.dart';

import '../../health/domain/stored_sleep_session.dart';
import '../domain/sleep_session.dart';
import '../domain/sleep_session_store.dart';
import 'sleepy3_database.dart';

class DriftSleepSessionStore implements SleepSessionStore {
  DriftSleepSessionStore(this._db);

  final Sleepy3Database _db;

  @override
  Future<SleepSnapshot> load() async {
    // One pass over the table keeps the open session and the full closed
    // history consistent with each other. The table is tiny: one row per
    // tracked night.
    final rows = await (_db.select(
      _db.sleepSessions,
    )..orderBy([(t) => OrderingTerm.asc(t.startedAtMillis)])).get();

    SleepSession? openSession;
    final closedSessions = <SleepSession>[];
    for (final row in rows) {
      final session = _toDomain(row);
      if (session.isOpen) {
        // A crash could leave duplicate open rows behind; keep the latest.
        openSession = session;
      } else {
        closedSessions.add(session);
      }
    }

    return SleepSnapshot(
      openSession: openSession,
      closedSessions: List.unmodifiable(closedSessions),
    );
  }

  @override
  Future<SleepSession?> loadOpenSession() async {
    final row =
        await (_db.select(_db.sleepSessions)
              ..where((t) => t.endedAtMillis.isNull())
              ..orderBy([
                (t) => OrderingTerm.desc(t.startedAtMillis),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<SleepSession>> loadClosedSessions() async {
    final rows =
        await (_db.select(_db.sleepSessions)
              ..where((t) => t.endedAtMillis.isNotNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.startedAtMillis),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    return List.unmodifiable(rows.map(_toDomain));
  }

  @override
  Future<void> startSession(SleepSession session) async {
    await _db
        .into(_db.sleepSessions)
        .insert(
          SleepSessionsCompanion.insert(
            startedAtMillis: session.startedAt.millisecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<SleepSession> insertClosedSession(SleepSession session) async {
    final endedAt = session.endedAt;
    if (endedAt == null) {
      throw ArgumentError.value(
        session,
        'session',
        'Only closed sessions can be inserted',
      );
    }

    final id = await _db
        .into(_db.sleepSessions)
        .insert(
          SleepSessionsCompanion.insert(
            startedAtMillis: session.startedAt.millisecondsSinceEpoch,
            endedAtMillis: Value(endedAt.millisecondsSinceEpoch),
            healthClientRecordId: Value(session.healthClientRecordId),
          ),
        );
    return session.withLocalId(id);
  }

  @override
  Future<bool> updateSession(
    int id,
    DateTime startedAt,
    DateTime endedAt, {
    bool markHealthPending = true,
  }) async {
    final updated =
        await (_db.update(_db.sleepSessions)..where(
              (row) =>
                  row.id.equals(id) &
                  row.origin.equals(SleepSessionOrigin.local.storageValue),
            ))
            .write(
              SleepSessionsCompanion(
                startedAtMillis: Value(startedAt.millisecondsSinceEpoch),
                endedAtMillis: Value(endedAt.millisecondsSinceEpoch),
                healthSyncedAtMillis: markHealthPending
                    ? const Value<int?>(null)
                    : const Value<int?>.absent(),
                healthSyncSkipped: const Value<bool>(false),
              ),
            );
    return updated > 0;
  }

  @override
  Future<bool> deleteSession(int id) async {
    final deleted =
        await (_db.delete(_db.sleepSessions)..where(
              (row) =>
                  row.id.equals(id) &
                  row.origin.equals(SleepSessionOrigin.local.storageValue),
            ))
            .go();
    return deleted > 0;
  }

  @override
  Future<void> finishOpenSession(DateTime endedAt) async {
    await _db.transaction(() async {
      // A crash could leave duplicate open rows behind. Close only the most
      // recent one and delete the older opens so the uploaded history never
      // contains overlapping sessions.
      final openRows =
          await (_db.select(_db.sleepSessions)
                ..where((t) => t.endedAtMillis.isNull())
                ..orderBy([
                  (t) => OrderingTerm.desc(t.startedAtMillis),
                  (t) => OrderingTerm.desc(t.id),
                ]))
              .get();
      if (openRows.isEmpty) return;

      final latest = openRows.first;
      await (_db.update(
        _db.sleepSessions,
      )..where((t) => t.id.equals(latest.id))).write(
        SleepSessionsCompanion(
          endedAtMillis: Value(endedAt.millisecondsSinceEpoch),
        ),
      );

      final duplicateIds = openRows.skip(1).map((row) => row.id).toList();
      if (duplicateIds.isNotEmpty) {
        await (_db.delete(
          _db.sleepSessions,
        )..where((t) => t.id.isIn(duplicateIds))).go();
      }
    });
  }

  @override
  Future<bool> updateOpenSessionStart(DateTime startedAt) async {
    final openRow =
        await (_db.select(_db.sleepSessions)
              ..where((t) => t.endedAtMillis.isNull())
              ..orderBy([
                (t) => OrderingTerm.desc(t.startedAtMillis),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (openRow == null) return false;

    final updated =
        await (_db.update(
          _db.sleepSessions,
        )..where((t) => t.id.equals(openRow.id))).write(
          SleepSessionsCompanion(
            startedAtMillis: Value(startedAt.millisecondsSinceEpoch),
          ),
        );
    return updated > 0;
  }

  @override
  Future<void> discardOpenSession() async {
    // A crash could leave duplicate open rows behind; remove them all.
    // Nothing is recorded, so there is no row to close.
    await (_db.delete(
      _db.sleepSessions,
    )..where((t) => t.endedAtMillis.isNull())).go();
  }

  @override
  Future<int> purgeUnrecordableSessions(
    Duration minimum,
    Duration maximum,
  ) async {
    // One pass over the tiny table keeps the rule in Dart and free of
    // database-specific date arithmetic. Only unpublished local rows are
    // removed: a stored Health Connect UUID means the record exists there,
    // and downloaded copies belong to Health Connect regardless.
    final rows = await _db.select(_db.sleepSessions).get();
    final purgeableIds = <int>[];

    for (final row in rows) {
      final endedAt = row.endedAtMillis;
      if (endedAt == null) continue;
      if (row.origin != SleepSessionOrigin.local.storageValue) continue;
      if (row.healthRecordId != null) continue;
      final duration = endedAt - row.startedAtMillis;
      if (duration < minimum.inMilliseconds ||
          duration >= maximum.inMilliseconds) {
        purgeableIds.add(row.id);
      }
    }

    if (purgeableIds.isEmpty) return 0;
    return await (_db.delete(
      _db.sleepSessions,
    )..where((t) => t.id.isIn(purgeableIds))).go();
  }

  SleepSession _toDomain(SleepSessionRow row) {
    final endedAt = row.endedAtMillis;
    return SleepSession(
      startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAtMillis),
      endedAt: endedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(endedAt),
      localId: row.id,
      isDownloaded: row.origin == SleepSessionOrigin.healthConnect.storageValue,
      healthRecordId: row.healthRecordId,
      healthClientRecordId: row.healthClientRecordId,
      sourceId: row.sourceId,
    );
  }
}
