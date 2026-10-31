import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/application/sleep_upload_service.dart';
import 'package:sleepy3/features/health/domain/stored_sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

import '../fakes.dart';

void main() {
  group('SleepUploadService', () {
    late DateTime now;
    late FakeHealthConnectGateway gateway;
    late FakeHealthSyncStore store;
    late SleepUploadService service;

    final startedAt = DateTime(2026, 10, 20, 22, 30);
    final endedAt = DateTime(2026, 10, 21, 6, 15);
    final closed = SleepSession(startedAt: startedAt, endedAt: endedAt);

    void create({List<SleepSession> pending = const []}) {
      now = DateTime(2026, 10, 21, 6, 20);
      gateway = FakeHealthConnectGateway();
      store = FakeHealthSyncStore();
      for (final session in pending) {
        store.addLocal(session);
      }
      service = SleepUploadService(gateway, store, () => now);
    }

    test('uses a stable client record id from the start time', () {
      create();

      expect(
        SleepUploadService.clientRecordIdFor(startedAt),
        'sleepy3-${startedAt.millisecondsSinceEpoch}',
      );
    });

    test('uploads and marks the local row as synced', () async {
      create(pending: [closed]);

      final result = await service.uploadSession(closed);

      expect(result.status, SleepUploadStatus.uploaded);
      expect(result.healthRecordId, isNotNull);
      expect(
        gateway.writes.single.clientRecordId,
        'sleepy3-${startedAt.millisecondsSinceEpoch}',
      );
      expect(gateway.writes.single.clientRecordVersion, 1);
      expect(store.rows.single.healthSyncedAt, now);
      expect(
        store.rows.single.healthClientRecordId,
        'sleepy3-${startedAt.millisecondsSinceEpoch}',
      );
      expect(store.rows.single.healthRecordVersion, 1);
      expect(await store.loadPendingCount(), 0);
    });

    test('skips a zero duration session without writing', () async {
      final zero = SleepSession(startedAt: startedAt, endedAt: startedAt);
      create(pending: [zero]);

      final result = await service.uploadSession(zero);

      expect(result.status, SleepUploadStatus.skipped);
      expect(gateway.writes, isEmpty);
      expect(store.rows.single.healthSyncSkipped, isTrue);
      expect(await store.loadPendingCount(), 0);
    });

    test('a failed write leaves the row pending', () async {
      create(pending: [closed]);
      gateway.writeError = StateError('offline');

      final result = await service.uploadSession(closed);

      expect(result.status, SleepUploadStatus.failed);
      expect(result.error, isA<StateError>());
      expect(store.rows.single.healthSyncedAt, isNull);
      expect(store.rows.single.healthRecordVersion, 1);
      expect(await store.loadPendingCount(), 1);

      // The next attempt uses a higher version for the same client record id.
      gateway.writeError = null;
      final retry = await service.uploadSession(closed);

      expect(retry.status, SleepUploadStatus.uploaded);
      expect(
        gateway.writes.last.clientRecordId,
        gateway.writes.first.clientRecordId,
      );
      expect(gateway.writes.last.clientRecordVersion, 2);
      expect(gateway.sessions, hasLength(1));
      expect(store.rows.single.healthRecordVersion, 2);
    });

    test('retries oldest first and keeps retries idempotent', () async {
      final older = SleepSession(
        startedAt: startedAt.subtract(const Duration(days: 1)),
        endedAt: endedAt.subtract(const Duration(days: 1)),
      );
      create(pending: [closed, older]);

      final first = await service.retryPending();

      expect(first.total, 2);
      expect(first.uploaded, 2);
      expect(first.failed, 0);
      expect(gateway.writes.map((write) => write.startedAt), [
        older.startedAt,
        closed.startedAt,
      ]);
      expect(gateway.writes.map((write) => write.clientRecordVersion), [1, 1]);
      expect(await store.loadPendingCount(), 0);

      final second = await service.retryPending();

      expect(second.total, 0);
      expect(gateway.writes, hasLength(2));
    });

    test(
      'reuses the stored client record id and increments the version',
      () async {
        create();
        final stored = store.addLocal(
          closed,
          healthRecordId: 'health-record-1',
          healthClientRecordId: 'sleepy3-custom',
          healthRecordVersion: 4,
        );

        final result = await service.uploadStored(stored);

        expect(result.status, SleepUploadStatus.uploaded);
        expect(gateway.writes.single.clientRecordId, 'sleepy3-custom');
        expect(gateway.writes.single.clientRecordVersion, 5);
        expect(store.rows.single.healthClientRecordId, 'sleepy3-custom');
        expect(store.rows.single.healthRecordVersion, 5);
      },
    );

    test('retries only updates when asked', () async {
      create();
      final update = store.addLocal(
        closed,
        healthRecordId: 'health-record-1',
        healthClientRecordId: 'sleepy3-1',
      );
      final newSession = SleepSession(
        startedAt: startedAt.subtract(const Duration(days: 1)),
        endedAt: endedAt.subtract(const Duration(days: 1)),
      );
      final newRow = store.addLocal(newSession);

      final result = await service.retryPending(updatesOnly: true);

      expect(result.total, 1);
      expect(result.uploaded, 1);
      expect(gateway.writes.single.clientRecordId, 'sleepy3-1');
      expect(
        store.rows.firstWhere((row) => row.id == update.id).healthSyncedAt,
        now,
      );
      expect(
        store.rows.firstWhere((row) => row.id == newRow.id).healthSyncedAt,
        isNull,
      );
    });

    test('updates a synchronized session without making it pending', () async {
      create();
      final stored = store.addLocal(
        closed,
        synced: true,
        healthRecordId: 'health-record-1',
        healthClientRecordId: 'sleepy3-1',
        healthRecordVersion: 2,
      );
      final newStart = startedAt.add(const Duration(minutes: 30));
      final newEnd = endedAt.add(const Duration(minutes: 30));

      final result = await service.updateSyncedSession(
        stored,
        newStart,
        newEnd,
      );

      expect(result.status, SleepUploadStatus.uploaded);
      expect(gateway.writes.single.startedAt, newStart);
      expect(gateway.writes.single.endedAt, newEnd);
      expect(gateway.writes.single.clientRecordId, 'sleepy3-1');
      expect(gateway.writes.single.clientRecordVersion, 3);
      expect(store.rows.single.healthSyncedAt, now);
      expect(store.rows.single.healthRecordVersion, 3);
    });

    test(
      'derives the stable id from the original start when missing',
      () async {
        create();
        final stored = store.addLocal(
          closed,
          synced: true,
          healthRecordId: 'health-record-1',
          healthRecordVersion: 1,
        );
        final newStart = startedAt.add(const Duration(minutes: 30));
        final newEnd = endedAt.add(const Duration(minutes: 30));

        final result = await service.updateSyncedSession(
          stored,
          newStart,
          newEnd,
        );

        expect(result.status, SleepUploadStatus.uploaded);
        expect(
          gateway.writes.single.clientRecordId,
          'sleepy3-${startedAt.millisecondsSinceEpoch}',
        );
        expect(gateway.writes.single.clientRecordVersion, 2);
      },
    );

    test('does not upload a downloaded session again', () async {
      final downloaded = StoredSleepSession(
        id: 7,
        session: closed,
        healthRecordId: 'health-record',
        healthSyncedAt: endedAt,
        origin: SleepSessionOrigin.healthConnect,
      );
      create();
      store.rows.add(downloaded);

      final result = await service.uploadSession(closed);

      expect(result.status, SleepUploadStatus.skipped);
      expect(gateway.writes, isEmpty);
    });
  });
}
