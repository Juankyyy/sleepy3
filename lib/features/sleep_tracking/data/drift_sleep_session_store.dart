import 'package:drift/drift.dart';

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

  SleepSession _toDomain(SleepSessionRow row) {
    final endedAt = row.endedAtMillis;
    return SleepSession(
      startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAtMillis),
      endedAt: endedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(endedAt),
    );
  }
}
