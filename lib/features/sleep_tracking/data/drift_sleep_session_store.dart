import 'package:drift/drift.dart';

import '../domain/sleep_session.dart';
import '../domain/sleep_session_store.dart';
import 'sleepy3_database.dart';

class DriftSleepSessionStore implements SleepSessionStore {
  DriftSleepSessionStore(this._db);

  final Sleepy3Database _db;

  @override
  Future<SleepSnapshot> load() async {
    final open = await _openRow();
    final last = await _lastClosedRow();

    return SleepSnapshot(
      openSession: open == null ? null : _toDomain(open),
      lastSession: last == null ? null : _toDomain(last),
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
    // Updating every open row also repairs duplicate opens left behind by an
    // old crash; the UI only ever creates one.
    await (_db.update(
      _db.sleepSessions,
    )..where((t) => t.endedAtMillis.isNull())).write(
      SleepSessionsCompanion(
        endedAtMillis: Value(endedAt.millisecondsSinceEpoch),
      ),
    );
  }

  Future<SleepSessionRow?> _openRow() {
    return (_db.select(_db.sleepSessions)
          ..where((t) => t.endedAtMillis.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAtMillis)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<SleepSessionRow?> _lastClosedRow() {
    return (_db.select(_db.sleepSessions)
          ..where((t) => t.endedAtMillis.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAtMillis)])
          ..limit(1))
        .getSingleOrNull();
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
