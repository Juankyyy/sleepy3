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
      expect(store.rows.single.healthSyncedAt, now);
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
      expect(await store.loadPendingCount(), 1);
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
      expect(await store.loadPendingCount(), 0);

      final second = await service.retryPending();

      expect(second.total, 0);
      expect(gateway.writes, hasLength(2));
    });

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
