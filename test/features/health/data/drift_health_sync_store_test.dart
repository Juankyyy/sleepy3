import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/data/drift_health_sync_store.dart';
import 'package:sleepy3/features/health/domain/stored_sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/data/sleepy3_database.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  group('Drift schema v3', () {
    test('migrates a v2 database without losing sessions', () async {
      final startedAt = DateTime(2026, 10, 20, 22, 30, 15, 123);
      final endedAt = DateTime(2026, 10, 21, 7, 15);
      final database = Sleepy3Database.forTesting(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
              CREATE TABLE sleep_sessions (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                started_at_millis INTEGER NOT NULL,
                ended_at_millis INTEGER NULL
              )
            ''');
            raw.execute('''
              CREATE TABLE preferences (
                setting_key TEXT NOT NULL,
                setting_value TEXT NOT NULL,
                PRIMARY KEY (setting_key)
              )
            ''');
            raw.execute(
              'INSERT INTO sleep_sessions '
              '(started_at_millis, ended_at_millis) VALUES (?, ?)',
              [
                startedAt.millisecondsSinceEpoch,
                endedAt.millisecondsSinceEpoch,
              ],
            );
            raw.execute(
              "INSERT INTO preferences (setting_key, setting_value) "
              "VALUES ('theme_mode', 'dark')",
            );
            raw.userVersion = 2;
          },
        ),
      );
      addTearDown(database.close);

      final rows = await database.select(database.sleepSessions).get();

      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.startedAtMillis, startedAt.millisecondsSinceEpoch);
      expect(row.endedAtMillis, endedAt.millisecondsSinceEpoch);
      expect(row.healthRecordId, isNull);
      expect(row.healthSyncedAtMillis, isNull);
      expect(row.healthSyncSkipped, isFalse);
      expect(row.origin, SleepSessionOrigin.local.storageValue);

      final preferences = await database.select(database.preferences).get();
      expect(preferences.single.settingValue, 'dark');

      // The migration must also add the unique record index, not only columns.
      Future<int> insert(String recordId) {
        return database
            .into(database.sleepSessions)
            .insert(
              SleepSessionsCompanion.insert(
                startedAtMillis: DateTime(2026, 10, 22).millisecondsSinceEpoch,
                endedAtMillis: Value(
                  DateTime(2026, 10, 23).millisecondsSinceEpoch,
                ),
                healthRecordId: Value(recordId),
              ),
            );
      }

      await insert('health-record-1');
      await expectLater(insert('health-record-1'), throwsA(anything));
    });

    test('new rows default to local and unsynced', () async {
      final database = Sleepy3Database.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final startedAt = DateTime(2026, 10, 20, 23);
      final endedAt = DateTime(2026, 10, 21, 7);

      final id = await database
          .into(database.sleepSessions)
          .insert(
            SleepSessionsCompanion.insert(
              startedAtMillis: startedAt.millisecondsSinceEpoch,
              endedAtMillis: Value(endedAt.millisecondsSinceEpoch),
            ),
          );

      final row = await (database.select(
        database.sleepSessions,
      )..where((row) => row.id.equals(id))).getSingle();
      expect(row.healthRecordId, isNull);
      expect(row.healthSyncedAtMillis, isNull);
      expect(row.healthSyncSkipped, isFalse);
      expect(row.origin, SleepSessionOrigin.local.storageValue);
    });

    test('rejects two rows with the same health record id', () async {
      final database = Sleepy3Database.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      Future<int> insert(String recordId) {
        return database
            .into(database.sleepSessions)
            .insert(
              SleepSessionsCompanion.insert(
                startedAtMillis: DateTime(2026, 10, 20).millisecondsSinceEpoch,
                endedAtMillis: Value(
                  DateTime(2026, 10, 21).millisecondsSinceEpoch,
                ),
                healthRecordId: Value(recordId),
                origin: Value(SleepSessionOrigin.healthConnect.storageValue),
              ),
            );
      }

      await insert('health-record-1');
      await expectLater(insert('health-record-1'), throwsA(anything));
    });

    test('allows many rows without a health record id', () async {
      final database = Sleepy3Database.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      Future<int> insert(DateTime startedAt) {
        return database
            .into(database.sleepSessions)
            .insert(
              SleepSessionsCompanion.insert(
                startedAtMillis: startedAt.millisecondsSinceEpoch,
                endedAtMillis: Value(
                  startedAt
                      .add(const Duration(hours: 8))
                      .millisecondsSinceEpoch,
                ),
              ),
            );
      }

      await insert(DateTime(2026, 10, 20));
      await insert(DateTime(2026, 10, 21));
      await insert(DateTime(2026, 10, 22));

      final rows = await database.select(database.sleepSessions).get();
      expect(rows, hasLength(3));
      expect(rows.map((row) => row.healthRecordId), everyElement(isNull));
    });
  });

  group('DriftHealthSyncStore', () {
    late Sleepy3Database database;
    late DriftHealthSyncStore store;

    setUp(() {
      database = Sleepy3Database.forTesting(NativeDatabase.memory());
      store = DriftHealthSyncStore(database);
    });

    tearDown(() async {
      await database.close();
    });

    Future<int> insertRow({
      required DateTime startedAt,
      DateTime? endedAt,
      String? healthRecordId,
      DateTime? healthSyncedAt,
      bool healthSyncSkipped = false,
      SleepSessionOrigin origin = SleepSessionOrigin.local,
    }) {
      return database
          .into(database.sleepSessions)
          .insert(
            SleepSessionsCompanion.insert(
              startedAtMillis: startedAt.millisecondsSinceEpoch,
              endedAtMillis: Value(endedAt?.millisecondsSinceEpoch),
              healthRecordId: Value(healthRecordId),
              healthSyncedAtMillis: Value(
                healthSyncedAt?.millisecondsSinceEpoch,
              ),
              healthSyncSkipped: Value(healthSyncSkipped),
              origin: Value(origin.storageValue),
            ),
          );
    }

    DateTime endOf(DateTime startedAt) =>
        startedAt.add(const Duration(hours: 8));

    test('loads only closed local unsynced sessions, oldest first', () async {
      final older = DateTime(2026, 10, 18, 22);
      final newer = DateTime(2026, 10, 19, 22);
      final olderId = await insertRow(startedAt: older, endedAt: endOf(older));
      final newerId = await insertRow(startedAt: newer, endedAt: endOf(newer));
      // None of these are pending uploads.
      await insertRow(startedAt: DateTime(2026, 10, 20, 22));
      await insertRow(
        startedAt: DateTime(2026, 10, 20, 1),
        endedAt: endOf(DateTime(2026, 10, 20, 1)),
        healthSyncedAt: DateTime(2026, 10, 20, 10),
      );
      await insertRow(
        startedAt: DateTime(2026, 10, 20, 2),
        endedAt: endOf(DateTime(2026, 10, 20, 2)),
        healthSyncSkipped: true,
      );
      await insertRow(
        startedAt: DateTime(2026, 10, 20, 3),
        endedAt: endOf(DateTime(2026, 10, 20, 3)),
        origin: SleepSessionOrigin.healthConnect,
      );

      final pending = await store.loadPendingUploads();

      expect(pending.map((row) => row.id), [olderId, newerId]);
      expect(pending.every((row) => row.isPendingUpload), isTrue);
      expect(await store.loadPendingCount(), 2);
    });

    test('loads the most recent pending session', () async {
      final older = DateTime(2026, 10, 18, 22);
      final newer = DateTime(2026, 10, 19, 22);
      await insertRow(startedAt: older, endedAt: endOf(older));
      final newerId = await insertRow(startedAt: newer, endedAt: endOf(newer));
      await insertRow(
        startedAt: DateTime(2026, 10, 20, 22),
        endedAt: endOf(DateTime(2026, 10, 20, 22)),
        healthSyncedAt: DateTime(2026, 10, 21, 7),
      );

      final latest = await store.loadLatestPendingUpload();

      expect(latest?.id, newerId);
      expect(latest?.session.startedAt, newer);
    });

    test('returns null with no pending sessions', () async {
      expect(await store.loadLatestPendingUpload(), isNull);
      expect(await store.loadPendingUploads(), isEmpty);
      expect(await store.loadPendingCount(), 0);
    });

    test('markUploaded records the record id and clears pending', () async {
      final startedAt = DateTime(2026, 10, 20, 22);
      final id = await insertRow(
        startedAt: startedAt,
        endedAt: endOf(startedAt),
      );
      final syncedAt = DateTime(2026, 10, 21, 7, 5);

      await store.markUploaded(id, 'health-record-1', syncedAt);

      expect(await store.loadPendingUploads(), isEmpty);
      expect(await store.loadPendingCount(), 0);
      final stored = await store.findByHealthRecordId('health-record-1');
      expect(stored?.id, id);
      expect(stored?.healthSyncedAt, syncedAt);
      expect(stored?.session.startedAt, startedAt);
      expect(stored?.isPendingUpload, isFalse);
    });

    test('markSkipped removes the session from pending uploads', () async {
      final startedAt = DateTime(2026, 10, 20, 22);
      final id = await insertRow(
        startedAt: startedAt,
        endedAt: endOf(startedAt),
      );
      final skippedAt = DateTime(2026, 10, 20, 22); // zero duration is enough
      final skippedId = await insertRow(
        startedAt: skippedAt,
        endedAt: skippedAt,
      );

      await store.markSkipped(skippedId);

      final pending = await store.loadPendingUploads();
      expect(pending.map((row) => row.id), [id]);
      expect(await store.loadPendingCount(), 1);
    });

    test('finds rows by exact start and end times across origins', () async {
      final startedAt = DateTime(2026, 10, 20, 22);
      final endedAt = endOf(startedAt);
      final localId = await insertRow(startedAt: startedAt, endedAt: endedAt);
      final downloadedId = await insertRow(
        startedAt: startedAt.add(const Duration(days: 1)),
        endedAt: endedAt.add(const Duration(days: 1)),
        healthRecordId: 'health-record-1',
        origin: SleepSessionOrigin.healthConnect,
      );

      final local = await store.findByExactTimes(startedAt, endedAt);
      final downloaded = await store.findByExactTimes(
        startedAt.add(const Duration(days: 1)),
        endedAt.add(const Duration(days: 1)),
      );

      expect(local?.id, localId);
      expect(local?.origin, SleepSessionOrigin.local);
      expect(downloaded?.id, downloadedId);
      expect(downloaded?.origin, SleepSessionOrigin.healthConnect);
    });

    test('finds a row by health record id', () async {
      final startedAt = DateTime(2026, 10, 20, 22);
      final id = await insertRow(
        startedAt: startedAt,
        endedAt: endOf(startedAt),
        healthRecordId: 'health-record-1',
        origin: SleepSessionOrigin.healthConnect,
        healthSyncedAt: DateTime(2026, 10, 21, 7),
      );

      expect((await store.findByHealthRecordId('health-record-1'))?.id, id);
      expect(await store.findByHealthRecordId('missing-record'), isNull);
    });

    test('insertDownloaded stores a downloaded closed session', () async {
      final startedAt = DateTime(2026, 10, 20, 22);
      final endedAt = endOf(startedAt);
      final syncedAt = DateTime(2026, 10, 21, 8);

      final id = await store.insertDownloaded(
        SleepSession(startedAt: startedAt, endedAt: endedAt),
        'health-record-1',
        syncedAt,
      );

      final stored = await store.findByHealthRecordId('health-record-1');
      expect(stored?.id, id);
      expect(stored?.session.startedAt, startedAt);
      expect(stored?.session.endedAt, endedAt);
      expect(stored?.origin, SleepSessionOrigin.healthConnect);
      expect(stored?.healthSyncedAt, syncedAt);
      expect(stored?.healthSyncSkipped, isFalse);
      expect(await store.loadPendingCount(), 0);
    });

    test('insertDownloaded stores an empty record id as null', () async {
      final startedAt = DateTime(2026, 10, 20, 22);

      final id = await store.insertDownloaded(
        SleepSession(startedAt: startedAt, endedAt: endOf(startedAt)),
        '   ',
        DateTime(2026, 10, 21, 8),
      );

      final row = await (database.select(
        database.sleepSessions,
      )..where((row) => row.id.equals(id))).getSingle();
      expect(row.healthRecordId, isNull);
    });

    test('insertDownloaded rejects an open session', () async {
      await expectLater(
        store.insertDownloaded(
          SleepSession(startedAt: DateTime(2026, 10, 20, 22)),
          null,
          DateTime(2026, 10, 21, 8),
        ),
        throwsArgumentError,
      );
      expect(await database.select(database.sleepSessions).get(), isEmpty);
    });

    test('updateDownloaded changes only downloaded rows', () async {
      final startedAt = DateTime(2026, 10, 20, 22);
      final downloadedId = await insertRow(
        startedAt: startedAt,
        endedAt: endOf(startedAt),
        healthRecordId: 'health-record-1',
        healthSyncedAt: DateTime(2026, 10, 21, 7),
        origin: SleepSessionOrigin.healthConnect,
      );
      final localId = await insertRow(
        startedAt: startedAt.add(const Duration(days: 1)),
        endedAt: endOf(startedAt.add(const Duration(days: 1))),
      );

      final newStart = startedAt.add(const Duration(minutes: 30));
      final newEnd = endOf(startedAt).add(const Duration(minutes: 10));
      final updatedDownloaded = await store.updateDownloaded(
        downloadedId,
        newStart,
        newEnd,
      );
      final updatedLocal = await store.updateDownloaded(
        localId,
        newStart,
        newEnd,
      );

      expect(updatedDownloaded, isTrue);
      expect(updatedLocal, isFalse);
      final downloaded = await store.findByHealthRecordId('health-record-1');
      expect(downloaded?.session.startedAt, newStart);
      expect(downloaded?.session.endedAt, newEnd);
      final local = await store.findByExactTimes(
        startedAt.add(const Duration(days: 1)),
        endOf(startedAt.add(const Duration(days: 1))),
      );
      expect(local?.id, localId);
      expect(local?.session.startedAt, startedAt.add(const Duration(days: 1)));
    });
  });
}
