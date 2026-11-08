import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/domain/stored_sleep_session.dart';
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

  test(
    'inserts a closed local session with its Health Connect identity',
    () async {
      final startedAt = DateTime(2026, 10, 20, 23);
      final endedAt = DateTime(2026, 10, 21, 7);
      final clientRecordId = 'sleepy3-${startedAt.millisecondsSinceEpoch}';

      final created = await store.insertClosedSession(
        SleepSession(
          startedAt: startedAt,
          endedAt: endedAt,
          healthClientRecordId: clientRecordId,
        ),
      );

      expect(created.localId, isNotNull);
      expect(created.startedAt, startedAt);
      expect(created.endedAt, endedAt);
      expect(created.healthClientRecordId, clientRecordId);

      final row = await database.select(database.sleepSessions).getSingle();
      expect(row.origin, SleepSessionOrigin.local.storageValue);
      expect(row.healthClientRecordId, clientRecordId);
      expect(row.healthRecordId, isNull);
      expect(row.healthRecordVersion, 0);
      expect(row.healthSyncedAtMillis, isNull);
      expect(row.healthSyncSkipped, isFalse);

      final closed = await store.loadClosedSessions();
      expect(closed.single.localId, created.localId);
      expect(closed.single.endedAt, endedAt);
    },
  );

  test('refuses to insert an open session', () async {
    expect(
      () => store.insertClosedSession(
        SleepSession(startedAt: DateTime(2026, 10, 20, 23)),
      ),
      throwsArgumentError,
    );
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

  test('discardOpenSession removes the open row without recording', () async {
    final startedAt = DateTime(2026, 10, 20, 22, 30);
    await store.startSession(SleepSession(startedAt: startedAt));

    await store.discardOpenSession();

    final snapshot = await store.load();
    expect(snapshot.openSession, isNull);
    expect(snapshot.lastSession, isNull);
    expect(snapshot.closedSessions, isEmpty);
  });

  test(
    'discardOpenSession keeps closed sessions and drops open duplicates',
    () async {
      await database
          .into(database.sleepSessions)
          .insert(
            SleepSessionsCompanion.insert(
              startedAtMillis: DateTime(
                2026,
                10,
                18,
                23,
              ).millisecondsSinceEpoch,
              endedAtMillis: Value(
                DateTime(2026, 10, 19, 7).millisecondsSinceEpoch,
              ),
            ),
          );
      await store.startSession(
        SleepSession(startedAt: DateTime(2026, 10, 20, 23)),
      );
      await store.startSession(
        SleepSession(startedAt: DateTime(2026, 10, 19, 20)),
      );

      await store.discardOpenSession();

      final snapshot = await store.load();
      expect(snapshot.openSession, isNull);
      expect(snapshot.closedSessions, hasLength(1));
      expect(snapshot.lastSession?.endedAt, DateTime(2026, 10, 19, 7));
    },
  );

  group('Health Connect identity', () {
    Future<int> insertSession({
      required DateTime startedAt,
      DateTime? endedAt,
      String? healthRecordId,
      String? healthClientRecordId,
      DateTime? healthSyncedAt,
      bool healthSyncSkipped = false,
      SleepSessionOrigin origin = SleepSessionOrigin.local,
      String? sourceId,
    }) {
      return database
          .into(database.sleepSessions)
          .insert(
            SleepSessionsCompanion.insert(
              startedAtMillis: startedAt.millisecondsSinceEpoch,
              endedAtMillis: Value(endedAt?.millisecondsSinceEpoch),
              healthRecordId: Value(healthRecordId),
              healthClientRecordId: Value(healthClientRecordId),
              healthSyncedAtMillis: Value(
                healthSyncedAt?.millisecondsSinceEpoch,
              ),
              healthSyncSkipped: Value(healthSyncSkipped),
              origin: Value(origin.storageValue),
              sourceId: Value(sourceId),
            ),
          );
    }

    test('maps row id and Health Connect metadata when loading', () async {
      final startedAt = DateTime(2026, 10, 20, 23);
      final endedAt = DateTime(2026, 10, 21, 7);
      final id = await insertSession(
        startedAt: startedAt,
        endedAt: endedAt,
        healthRecordId: 'health-record-1',
        healthClientRecordId: 'sleepy3-1',
      );

      final session = (await store.loadClosedSessions()).single;

      expect(session.localId, id);
      expect(session.isDownloaded, isFalse);
      expect(session.isEditableLocal, isTrue);
      expect(session.healthRecordId, 'health-record-1');
      expect(session.healthClientRecordId, 'sleepy3-1');
      expect(session.sourceId, isNull);
      expect(session.startedAt, startedAt);
      expect(session.endedAt, endedAt);
    });

    test('marks downloaded rows as read-only copies', () async {
      final startedAt = DateTime(2026, 10, 20, 23);
      final id = await insertSession(
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(hours: 8)),
        healthRecordId: 'downloaded-1',
        healthSyncedAt: DateTime(2026, 10, 21, 8),
        origin: SleepSessionOrigin.healthConnect,
        sourceId: 'com.example.other',
      );

      final session = (await store.loadClosedSessions()).single;

      expect(session.localId, id);
      expect(session.isDownloaded, isTrue);
      expect(session.isEditableLocal, isFalse);
      expect(session.healthRecordId, 'downloaded-1');
      expect(session.healthClientRecordId, isNull);
      expect(session.sourceId, 'com.example.other');
    });

    test(
      'updateSession writes local rows and queues a Health Connect update',
      () async {
        final startedAt = DateTime(2026, 10, 20, 23);
        final endedAt = DateTime(2026, 10, 21, 7);
        final id = await insertSession(
          startedAt: startedAt,
          endedAt: endedAt,
          healthRecordId: 'health-record-1',
          healthSyncedAt: DateTime(2026, 10, 21, 8),
          healthSyncSkipped: true,
        );
        final newStart = startedAt.subtract(const Duration(minutes: 30));
        final newEnd = endedAt.add(const Duration(minutes: 15));

        expect(await store.updateSession(id, newStart, newEnd), isTrue);

        final row = await (database.select(
          database.sleepSessions,
        )..where((row) => row.id.equals(id))).getSingle();
        expect(row.startedAtMillis, newStart.millisecondsSinceEpoch);
        expect(row.endedAtMillis, newEnd.millisecondsSinceEpoch);
        expect(row.healthSyncedAtMillis, isNull);
        expect(row.healthSyncSkipped, isFalse);

        final session = (await store.loadClosedSessions()).single;
        expect(session.startedAt, newStart);
        expect(session.endedAt, newEnd);
      },
    );

    test('updateSession can keep the sync time', () async {
      final startedAt = DateTime(2026, 10, 20, 23);
      final endedAt = DateTime(2026, 10, 21, 7);
      final syncedAt = DateTime(2026, 10, 21, 8);
      final id = await insertSession(
        startedAt: startedAt,
        endedAt: endedAt,
        healthSyncedAt: syncedAt,
        healthSyncSkipped: true,
      );
      final newStart = startedAt.add(const Duration(minutes: 10));
      final newEnd = endedAt.add(const Duration(minutes: 20));

      expect(
        await store.updateSession(
          id,
          newStart,
          newEnd,
          markHealthPending: false,
        ),
        isTrue,
      );

      final row = await (database.select(
        database.sleepSessions,
      )..where((row) => row.id.equals(id))).getSingle();
      expect(row.startedAtMillis, newStart.millisecondsSinceEpoch);
      expect(row.endedAtMillis, newEnd.millisecondsSinceEpoch);
      expect(row.healthSyncedAtMillis, syncedAt.millisecondsSinceEpoch);
      expect(row.healthSyncSkipped, isFalse);
    });

    test('updateSession refuses downloaded rows', () async {
      final startedAt = DateTime(2026, 10, 20, 23);
      final endedAt = DateTime(2026, 10, 21, 7);
      final id = await insertSession(
        startedAt: startedAt,
        endedAt: endedAt,
        healthRecordId: 'downloaded-1',
        origin: SleepSessionOrigin.healthConnect,
      );

      expect(
        await store.updateSession(
          id,
          startedAt.add(const Duration(hours: 1)),
          endedAt.add(const Duration(hours: 1)),
        ),
        isFalse,
      );
      expect(
        await store.updateSession(
          9999,
          startedAt.add(const Duration(hours: 1)),
          endedAt.add(const Duration(hours: 1)),
        ),
        isFalse,
      );

      final session = (await store.loadClosedSessions()).single;
      expect(session.startedAt, startedAt);
      expect(session.endedAt, endedAt);
    });

    test('deleteSession removes only local rows', () async {
      final startedAt = DateTime(2026, 10, 20, 23);
      final localId = await insertSession(
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(hours: 8)),
      );
      final downloadedId = await insertSession(
        startedAt: startedAt.add(const Duration(days: 1)),
        endedAt: startedAt.add(const Duration(days: 1, hours: 8)),
        healthRecordId: 'downloaded-1',
        origin: SleepSessionOrigin.healthConnect,
      );

      expect(await store.deleteSession(downloadedId), isFalse);
      expect(await store.deleteSession(9999), isFalse);
      expect(await store.deleteSession(localId), isTrue);

      final rows = await database.select(database.sleepSessions).get();
      expect(rows.map((row) => row.id), [downloadedId]);
    });

    test(
      'purgeUnrecordableSessions removes unpublished short and long rows',
      () async {
        final startedAt = DateTime(2026, 10, 20, 23);
        await insertSession(
          startedAt: startedAt,
          endedAt: startedAt.add(const Duration(minutes: 5)),
        );
        await insertSession(
          startedAt: startedAt.add(const Duration(days: 1)),
          endedAt: startedAt.add(const Duration(days: 1, minutes: 5)),
        );
        await insertSession(
          startedAt: startedAt.add(const Duration(days: 3)),
          endedAt: startedAt.add(const Duration(days: 3, hours: 25)),
        );

        final purged = await store.purgeUnrecordableSessions(
          minimumRecordableSleep,
          maximumRecordableSleep,
        );

        expect(purged, 3);
        final rows = await database.select(database.sleepSessions).get();
        expect(rows, isEmpty);
      },
    );

    test(
      'purgeUnrecordableSessions keeps the rows that belong to Health Connect',
      () async {
        final startedAt = DateTime(2026, 10, 20, 23);
        final syncedId = await insertSession(
          startedAt: startedAt,
          endedAt: startedAt.add(const Duration(minutes: 5)),
          healthRecordId: 'health-record-1',
        );
        final downloadedId = await insertSession(
          startedAt: startedAt.add(const Duration(days: 1)),
          endedAt: startedAt.add(const Duration(days: 1, minutes: 5)),
          healthRecordId: 'downloaded-1',
          origin: SleepSessionOrigin.healthConnect,
        );
        final syncedLongId = await insertSession(
          startedAt: startedAt.add(const Duration(days: 2)),
          endedAt: startedAt.add(const Duration(days: 3, hours: 2)),
          healthRecordId: 'health-record-2',
        );

        expect(
          await store.purgeUnrecordableSessions(
            minimumRecordableSleep,
            maximumRecordableSleep,
          ),
          0,
        );

        final rows = await database.select(database.sleepSessions).get();
        expect(
          rows.map((row) => row.id),
          unorderedEquals(<int>[syncedId, downloadedId, syncedLongId]),
        );
      },
    );

    test(
      'purgeUnrecordableSessions keeps in-range rows and open rows',
      () async {
        final startedAt = DateTime(2026, 10, 20, 23);
        final exactMinimumId = await insertSession(
          startedAt: startedAt,
          endedAt: startedAt.add(minimumRecordableSleep),
        );
        final justUnderMaximumId = await insertSession(
          startedAt: startedAt.add(const Duration(days: 2)),
          endedAt: startedAt.add(
            const Duration(days: 2, hours: 23, minutes: 59, seconds: 59),
          ),
        );
        final exactMaximumId = await insertSession(
          startedAt: startedAt.add(const Duration(days: 4)),
          endedAt: startedAt.add(const Duration(days: 5)),
        );

        expect(
          await store.purgeUnrecordableSessions(
            minimumRecordableSleep,
            maximumRecordableSleep,
          ),
          1,
        );

        // An open session is never a purge candidate.
        await store.startSession(SleepSession(startedAt: startedAt));
        expect(
          await store.purgeUnrecordableSessions(
            minimumRecordableSleep,
            maximumRecordableSleep,
          ),
          0,
        );

        final rows = await database.select(database.sleepSessions).get();
        expect(rows.map((row) => row.id), contains(exactMinimumId));
        expect(rows.map((row) => row.id), contains(justUnderMaximumId));
        expect(rows.map((row) => row.id), isNot(contains(exactMaximumId)));
        expect(rows.where((row) => row.endedAtMillis == null), isNotEmpty);
      },
    );

    test('updateOpenSessionStart moves only the open row', () async {
      final startedAt = DateTime(2026, 10, 20, 23);
      final closedId = await insertSession(
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(hours: 8)),
      );
      await store.startSession(
        SleepSession(startedAt: DateTime(2026, 10, 21, 20)),
      );

      final newStart = DateTime(2026, 10, 21, 18, 15);
      expect(await store.updateOpenSessionStart(newStart), isTrue);

      final snapshot = await store.load();
      expect(snapshot.openSession?.startedAt, newStart);
      expect(snapshot.closedSessions.single.localId, closedId);
      expect(
        snapshot.closedSessions.single.startedAt,
        DateTime(2026, 10, 20, 23),
      );
    });

    test('updateOpenSessionStart is a no-op without an open row', () async {
      expect(
        await store.updateOpenSessionStart(DateTime(2026, 10, 21, 18)),
        isFalse,
      );

      final snapshot = await store.load();
      expect(snapshot.openSession, isNull);
    });
  });
}
