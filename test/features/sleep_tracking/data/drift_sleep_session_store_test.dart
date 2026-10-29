import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/data/drift_sleep_session_store.dart';
import 'package:sleepy3/features/sleep_tracking/data/sleepy3_database.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  late Sleepy3Database database;
  late DriftSleepSessionStore store;

  setUp(() {
    database = Sleepy3Database.forTesting(NativeDatabase.memory());
    store = DriftSleepSessionStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('loads an empty database', () async {
    final snapshot = await store.load();

    expect(snapshot.openSession, isNull);
    expect(snapshot.lastSession, isNull);
    expect(snapshot.closedSessions, isEmpty);
  });

  test('round-trips an open session', () async {
    final startedAt = DateTime(2026, 10, 20, 22, 30, 15, 123);
    await store.startSession(SleepSession(startedAt: startedAt));

    final snapshot = await store.load();
    expect(snapshot.openSession?.startedAt, startedAt);
    expect(snapshot.openSession?.endedAt, isNull);
    expect(snapshot.lastSession, isNull);
    expect(snapshot.closedSessions, isEmpty);
  });

  test('closes the open session and keeps the last closed one', () async {
    final startedAt = DateTime(2026, 10, 20, 22, 30);
    final endedAt = startedAt.add(const Duration(hours: 7, minutes: 45));
    await store.startSession(SleepSession(startedAt: startedAt));
    await store.finishOpenSession(endedAt);

    final snapshot = await store.load();
    expect(snapshot.openSession, isNull);
    expect(snapshot.lastSession?.startedAt, startedAt);
    expect(snapshot.lastSession?.endedAt, endedAt);
    expect(
      snapshot.lastSession?.duration,
      const Duration(hours: 7, minutes: 45),
    );
    expect(snapshot.closedSessions, hasLength(1));
    expect(snapshot.closedSessions.single.endedAt, endedAt);
  });

  test('loads every closed session in start order', () async {
    Future<void> insert(DateTime startedAt, DateTime? endedAt) {
      return database
          .into(database.sleepSessions)
          .insert(
            SleepSessionsCompanion.insert(
              startedAtMillis: startedAt.millisecondsSinceEpoch,
              endedAtMillis: Value(endedAt?.millisecondsSinceEpoch),
            ),
          );
    }

    await insert(DateTime(2026, 10, 18, 23), DateTime(2026, 10, 19, 7));
    await insert(DateTime(2026, 10, 21, 0, 30), DateTime(2026, 10, 21, 6, 30));
    await insert(DateTime(2026, 10, 17, 23), DateTime(2026, 10, 18, 23, 59));
    await insert(DateTime(2026, 10, 22), DateTime(2026, 10, 22, 7));
    // An open session has no wake day yet.
    await insert(DateTime(2026, 10, 20, 23), null);

    final snapshot = await store.load();

    expect(snapshot.closedSessions.map((session) => session.endedAt).toList(), [
      DateTime(2026, 10, 18, 23, 59),
      DateTime(2026, 10, 19, 7),
      DateTime(2026, 10, 21, 6, 30),
      DateTime(2026, 10, 22, 7),
    ]);
    expect(snapshot.openSession?.startedAt, DateTime(2026, 10, 20, 23));
    expect(snapshot.lastSession?.startedAt, DateTime(2026, 10, 22));
  });

  test('loads the open and closed halves on their own', () async {
    await store.startSession(
      SleepSession(startedAt: DateTime(2026, 10, 20, 22)),
    );
    await database
        .into(database.sleepSessions)
        .insert(
          SleepSessionsCompanion.insert(
            startedAtMillis: DateTime(2026, 10, 18, 23).millisecondsSinceEpoch,
            endedAtMillis: Value(
              DateTime(2026, 10, 19, 7).millisecondsSinceEpoch,
            ),
          ),
        );

    expect(
      (await store.loadOpenSession())?.startedAt,
      DateTime(2026, 10, 20, 22),
    );
    final closed = await store.loadClosedSessions();
    expect(closed, hasLength(1));
    expect(closed.single.endedAt, DateTime(2026, 10, 19, 7));
  });

  test('loadOpenSession keeps only the most recent open row', () async {
    Future<void> insertOpen(DateTime startedAt) {
      return database
          .into(database.sleepSessions)
          .insert(
            SleepSessionsCompanion.insert(
              startedAtMillis: startedAt.millisecondsSinceEpoch,
            ),
          );
    }

    await insertOpen(DateTime(2026, 10, 18, 23));
    await insertOpen(DateTime(2026, 10, 19, 23));

    expect(
      (await store.loadOpenSession())?.startedAt,
      DateTime(2026, 10, 19, 23),
    );
  });

  test('keeps the open session and the last closed session separate', () async {
    final firstStart = DateTime(2026, 10, 19, 23);
    final firstEnd = DateTime(2026, 10, 20, 7);
    await store.startSession(SleepSession(startedAt: firstStart));
    await store.finishOpenSession(firstEnd);

    final secondStart = DateTime(2026, 10, 20, 23);
    await store.startSession(SleepSession(startedAt: secondStart));

    final snapshot = await store.load();
    expect(snapshot.openSession?.startedAt, secondStart);
    expect(snapshot.lastSession?.startedAt, firstStart);
    expect(snapshot.lastSession?.endedAt, firstEnd);
    expect(snapshot.closedSessions, hasLength(1));
  });

  test('finishing without an open session is a no-op', () async {
    await store.finishOpenSession(DateTime(2026, 10, 21, 7));

    final snapshot = await store.load();
    expect(snapshot.openSession, isNull);
    expect(snapshot.lastSession, isNull);
    expect(snapshot.closedSessions, isEmpty);
  });

  test('closes only the latest open row and drops older duplicates', () async {
    final first = DateTime(2026, 10, 18, 23);
    final second = DateTime(2026, 10, 19, 23);
    await database
        .into(database.sleepSessions)
        .insert(
          SleepSessionsCompanion.insert(
            startedAtMillis: first.millisecondsSinceEpoch,
          ),
        );
    await database
        .into(database.sleepSessions)
        .insert(
          SleepSessionsCompanion.insert(
            startedAtMillis: second.millisecondsSinceEpoch,
          ),
        );

    final endedAt = DateTime(2026, 10, 20, 7);
    await store.finishOpenSession(endedAt);

    final snapshot = await store.load();
    expect(snapshot.openSession, isNull);
    expect(snapshot.closedSessions, hasLength(1));
    expect(snapshot.lastSession?.startedAt, second);
    expect(snapshot.lastSession?.endedAt, endedAt);
  });
}
