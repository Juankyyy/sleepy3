import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/application/sleep_copy_service.dart';
import 'package:sleepy3/features/health/application/sleep_upload_service.dart';
import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/health/domain/stored_sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

import '../fakes.dart';

void main() {
  group('SleepCopyService', () {
    late DateTime now;
    late FakeHealthConnectGateway gateway;
    late FakeHealthSyncStore store;
    late SleepCopyService service;

    final olderStart = DateTime(2026, 10, 18, 22);
    final olderEnd = DateTime(2026, 10, 19, 6);
    final newerStart = DateTime(2026, 10, 19, 22);
    final newerEnd = DateTime(2026, 10, 20, 6);

    SleepSession session(DateTime start, DateTime end) =>
        SleepSession(startedAt: start, endedAt: end);

    HealthSleepSession record(String uuid, DateTime start, DateTime end) =>
        HealthSleepSession(uuid: uuid, startedAt: start, endedAt: end);

    void create({List<HealthSleepSession> sessions = const []}) {
      now = DateTime(2026, 10, 21, 6, 20);
      gateway = FakeHealthConnectGateway(sessions: sessions);
      store = FakeHealthSyncStore();
      service = SleepCopyService(
        gateway,
        store,
        SleepUploadService(gateway, store, () => now),
        () => now,
      );
    }

    test('sync last does nothing when there are no pending sessions', () async {
      create();

      final result = await service.syncLastSession();

      expect(result.total, 0);
      expect(result.added, 0);
      expect(gateway.writes, isEmpty);
      expect(gateway.permissionRequestCalls, 0);
    });

    test('sync last uploads only the newest pending session', () async {
      create();
      final older = store.addLocal(session(olderStart, olderEnd));
      final newer = store.addLocal(session(newerStart, newerEnd));

      final result = await service.syncLastSession();

      expect(result.total, 1);
      expect(result.added, 1);
      expect(gateway.writes.single.startedAt, newerStart);
      expect(
        store.rows.firstWhere((row) => row.id == older.id).isPendingUpload,
        isTrue,
      );
      expect(
        store.rows.firstWhere((row) => row.id == newer.id).healthSyncedAt,
        now,
      );
    });

    test('sync last marks a zero duration session as skipped', () async {
      create();
      store.addLocal(session(olderStart, olderStart));

      final result = await service.syncLastSession();

      expect(result.total, 1);
      expect(result.skipped, 1);
      expect(gateway.writes, isEmpty);
      expect(store.rows.single.healthSyncSkipped, isTrue);
    });

    test(
      'sync last asks for write access and fails cleanly when denied',
      () async {
        create();
        gateway.writePermission = false;
        gateway.grantWriteOnRequest = false;
        store.addLocal(session(olderStart, olderEnd));

        final result = await service.syncLastSession();

        expect(result.failure, SleepCopyFailure.permissionDenied);
        expect(result.added, 0);
        expect(gateway.permissionRequestCalls, 1);
        expect(gateway.writes, isEmpty);
        expect(store.rows.single.isPendingUpload, isTrue);
      },
    );

    test('sync last reports unavailable and outdated Health Connect', () async {
      create();
      store.addLocal(session(olderStart, olderEnd));

      gateway.availability = HealthConnectAvailability.unavailable;
      expect(
        (await service.syncLastSession()).failure,
        SleepCopyFailure.unavailable,
      );

      gateway.availability = HealthConnectAvailability.updateRequired;
      expect(
        (await service.syncLastSession()).failure,
        SleepCopyFailure.updateRequired,
      );
      expect(gateway.writes, isEmpty);
    });

    test('add all uploads pending sessions oldest first', () async {
      create();
      store.addLocal(session(olderStart, olderEnd));
      store.addLocal(session(newerStart, newerEnd));
      store.addLocal(
        session(DateTime(2026, 10, 17, 22), DateTime(2026, 10, 18, 6)),
        synced: true,
      );
      store.addLocal(
        session(DateTime(2026, 10, 16, 22), DateTime(2026, 10, 16, 22)),
        skipped: true,
      );
      store.rows.add(
        StoredSleepSession(
          id: 99,
          session: session(
            DateTime(2026, 10, 15, 22),
            DateTime(2026, 10, 16, 6),
          ),
          healthRecordId: 'downloaded',
          healthSyncedAt: now,
          origin: SleepSessionOrigin.healthConnect,
        ),
      );

      final result = await service.uploadAllPreviousSessions();

      expect(result.total, 2);
      expect(result.added, 2);
      expect(result.skipped, 0);
      expect(result.failed, 0);
      expect(gateway.writes.map((write) => write.startedAt), [
        olderStart,
        newerStart,
      ]);
      expect(await store.loadPendingCount(), 0);
    });

    test('add all does nothing when nothing is pending', () async {
      create();
      store.addLocal(session(olderStart, olderEnd), synced: true);

      final result = await service.uploadAllPreviousSessions();

      expect(result.total, 0);
      expect(gateway.writes, isEmpty);
      expect(gateway.permissionRequestCalls, 0);
    });

    test('add all keeps going after a partial failure', () async {
      create();
      store.addLocal(session(olderStart, olderEnd));
      store.addLocal(session(newerStart, newerEnd));
      gateway.failWriteStarts.add(olderStart);

      final result = await service.uploadAllPreviousSessions();

      expect(result.total, 2);
      expect(result.added, 1);
      expect(result.failed, 1);
      expect(result.error, isA<StateError>());
      expect(store.rows[0].isPendingUpload, isTrue);
      expect(store.rows[1].healthSyncedAt, now);
    });

    test('download adds every new Health Connect session', () async {
      create(
        sessions: [
          record('a', olderStart, olderEnd),
          record('b', newerStart, newerEnd),
        ],
      );

      final result = await service.downloadAllFromHealthConnect();

      expect(result.total, 2);
      expect(result.added, 2);
      expect(result.updated, 0);
      expect(store.rows, hasLength(2));
      expect(
        store.rows.every(
          (row) => row.origin == SleepSessionOrigin.healthConnect,
        ),
        isTrue,
      );
      expect(store.rows.every((row) => row.healthSyncedAt == now), isTrue);
      expect(await store.loadPendingCount(), 0);
    });

    test('download updates an existing downloaded row', () async {
      create(sessions: [record('a', newerStart, newerEnd)]);
      store.rows.add(
        StoredSleepSession(
          id: 1,
          session: session(olderStart, olderEnd),
          healthRecordId: 'a',
          healthSyncedAt: DateTime(2026, 10, 20),
          origin: SleepSessionOrigin.healthConnect,
        ),
      );

      final result = await service.downloadAllFromHealthConnect();

      expect(result.total, 1);
      expect(result.updated, 1);
      expect(result.added, 0);
      expect(store.rows.single.session.startedAt, newerStart);
      expect(store.rows.single.session.endedAt, newerEnd);
      expect(store.rows.single.healthSyncedAt, DateTime(2026, 10, 20));
    });

    test('download skips an unchanged downloaded row', () async {
      create(sessions: [record('a', olderStart, olderEnd)]);
      store.rows.add(
        StoredSleepSession(
          id: 1,
          session: session(olderStart, olderEnd),
          healthRecordId: 'a',
          healthSyncedAt: DateTime(2026, 10, 20),
          origin: SleepSessionOrigin.healthConnect,
        ),
      );

      final result = await service.downloadAllFromHealthConnect();

      expect(result.total, 1);
      expect(result.skipped, 1);
      expect(result.updated, 0);
      expect(store.rows, hasLength(1));
    });

    test('download never overwrites a local row by id', () async {
      create(sessions: [record('a', newerStart, newerEnd)]);
      store.rows.add(
        StoredSleepSession(
          id: 1,
          session: session(olderStart, olderEnd),
          healthRecordId: 'a',
          healthSyncedAt: DateTime(2026, 10, 20),
          origin: SleepSessionOrigin.local,
        ),
      );

      final result = await service.downloadAllFromHealthConnect();

      expect(result.total, 1);
      expect(result.skipped, 1);
      expect(result.updated, 0);
      expect(store.rows.single.session.startedAt, olderStart);
      expect(store.rows.single.origin, SleepSessionOrigin.local);
    });

    test('download never overwrites a local row with the same times', () async {
      create(sessions: [record('a', olderStart, olderEnd)]);
      store.addLocal(session(olderStart, olderEnd));

      final result = await service.downloadAllFromHealthConnect();

      expect(result.total, 1);
      expect(result.skipped, 1);
      expect(store.rows, hasLength(1));
      expect(store.rows.single.origin, SleepSessionOrigin.local);
      expect(store.rows.single.healthRecordId, isNull);
      expect(store.rows.single.healthSyncedAt, isNull);
    });

    test('download deduplicates a missing id by exact times', () async {
      create(sessions: [record('', olderStart, olderEnd)]);
      store.rows.add(
        StoredSleepSession(
          id: 1,
          session: session(olderStart, olderEnd),
          healthSyncedAt: DateTime(2026, 10, 20),
          origin: SleepSessionOrigin.healthConnect,
        ),
      );

      final result = await service.downloadAllFromHealthConnect();

      expect(result.total, 1);
      expect(result.skipped, 1);
      expect(store.rows, hasLength(1));
    });

    test('download stores a missing id as null', () async {
      create(sessions: [record('   ', olderStart, olderEnd)]);

      final result = await service.downloadAllFromHealthConnect();

      expect(result.added, 1);
      expect(store.rows.single.healthRecordId, isNull);
      expect(store.rows.single.origin, SleepSessionOrigin.healthConnect);
    });

    test('repeating a download is idempotent', () async {
      create(sessions: [record('a', olderStart, olderEnd)]);

      final first = await service.downloadAllFromHealthConnect();
      final second = await service.downloadAllFromHealthConnect();

      expect(first.added, 1);
      expect(second.added, 0);
      expect(second.skipped, 1);
      expect(store.rows, hasLength(1));
    });

    test('downloaded sessions are never uploaded again', () async {
      create(sessions: [record('a', olderStart, olderEnd)]);
      await service.downloadAllFromHealthConnect();

      final result = await service.uploadAllPreviousSessions();

      expect(result.total, 0);
      expect(gateway.writes, isEmpty);
    });

    test(
      'download asks for read access and fails cleanly when denied',
      () async {
        create(sessions: [record('a', olderStart, olderEnd)]);
        gateway.readPermission = false;
        gateway.grantReadOnRequest = false;

        final result = await service.downloadAllFromHealthConnect();

        expect(result.failure, SleepCopyFailure.permissionDenied);
        expect(gateway.permissionRequestCalls, 1);
        expect(gateway.lastReadFrom, isNull);
        expect(store.rows, isEmpty);
      },
    );

    test('download keeps going after a partial failure', () async {
      create(
        sessions: [
          record('a', olderStart, olderEnd),
          record('b', newerStart, newerEnd),
        ],
      );
      store.failInsertStarts.add(olderStart);

      final result = await service.downloadAllFromHealthConnect();

      expect(result.total, 2);
      expect(result.added, 1);
      expect(result.failed, 1);
      expect(result.error, isA<StateError>());
      expect(store.rows, hasLength(1));
      expect(store.rows.single.healthRecordId, 'b');
    });

    test('download skips a record that ends before it starts', () async {
      create(
        sessions: [
          HealthSleepSession(
            uuid: 'bad',
            startedAt: newerStart,
            endedAt: olderStart,
          ),
        ],
      );

      final result = await service.downloadAllFromHealthConnect();

      expect(result.total, 1);
      expect(result.skipped, 1);
      expect(store.rows, isEmpty);
    });

    test(
      'download reports a read failure without touching local rows',
      () async {
        create();
        store.addLocal(session(olderStart, olderEnd));
        gateway.readError = StateError('offline');

        final result = await service.downloadAllFromHealthConnect();

        expect(result.failure, SleepCopyFailure.failed);
        expect(result.error, isA<StateError>());
        expect(store.rows, hasLength(1));
      },
    );
  });
}
