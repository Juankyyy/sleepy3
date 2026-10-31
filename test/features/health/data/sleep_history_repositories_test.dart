import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/data/health_connect_sleep_history_repository.dart';
import 'package:sleepy3/features/health/data/local_sleep_history_repository.dart';
import 'package:sleepy3/features/health/domain/health_history_access.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';

import '../../sleep_tracking/fakes.dart';
import '../fakes.dart';

void main() {
  group('LocalSleepHistoryRepository', () {
    test('returns the closed sessions from the local store', () async {
      final sessions = [
        SleepSession(
          startedAt: DateTime(2026, 10, 19, 23),
          endedAt: DateTime(2026, 10, 20, 7),
        ),
        SleepSession(
          startedAt: DateTime(2026, 10, 20, 23),
          endedAt: DateTime(2026, 10, 21, 6),
        ),
      ];
      final store = FakeSleepSessionStore(
        snapshot: SleepSnapshot(closedSessions: sessions),
      );

      final loaded = await LocalSleepHistoryRepository(store)
          .loadClosedSessions();

      expect(loaded, sessions);
      expect(store.closedLoads, 1);
    });
  });

  group('HealthConnectSleepHistoryRepository', () {
    final now = DateTime(2026, 10, 21, 10);

    test('maps every record and sorts by start time', () async {
      final late = HealthSleepSession(
        uuid: 'late',
        startedAt: DateTime(2026, 10, 20, 23),
        endedAt: DateTime(2026, 10, 21, 6),
        sourceId: 'com.example.other',
      );
      final early = HealthSleepSession(
        uuid: 'early',
        startedAt: DateTime(2026, 10, 19, 22),
        endedAt: DateTime(2026, 10, 20, 5),
        sourceId: 'com.sleepy3.app',
      );
      final gateway = FakeHealthConnectGateway(sessions: [late, early]);

      final sessions = await HealthConnectSleepHistoryRepository(
        gateway,
        () => now,
      ).loadClosedSessions();

      expect(sessions, hasLength(2));
      expect(sessions.first.startedAt, early.startedAt);
      expect(sessions.first.endedAt, early.endedAt);
      expect(sessions.first.healthRecordId, 'early');
      expect(sessions.first.sourceId, 'com.sleepy3.app');
      expect(sessions.last.startedAt, late.startedAt);
      expect(sessions.last.endedAt, late.endedAt);
      expect(sessions.last.healthRecordId, 'late');
    });

    test('attaches the metadata of the matching local copy', () async {
      final ownStart = DateTime(2026, 10, 19, 22);
      final ownEnd = DateTime(2026, 10, 20, 6);
      final gateway = FakeHealthConnectGateway(
        sessions: [
          HealthSleepSession(
            uuid: 'own-record',
            startedAt: ownStart,
            endedAt: ownEnd,
            sourceId: 'com.sleepy3.app',
          ),
          HealthSleepSession(
            uuid: 'other-record',
            startedAt: DateTime(2026, 10, 20, 22),
            endedAt: DateTime(2026, 10, 21, 6),
            sourceId: 'com.example.other',
          ),
        ],
      );
      final syncStore = FakeHealthSyncStore()
        ..addLocal(
          SleepSession(
            startedAt: ownStart.add(const Duration(minutes: 5)),
            endedAt: ownEnd.add(const Duration(minutes: 5)),
          ),
          synced: true,
          healthRecordId: 'own-record',
          healthClientRecordId: 'sleepy3-1',
          id: 12,
        )
        ..addLocal(
          SleepSession(
            startedAt: DateTime(2026, 10, 18, 22),
            endedAt: DateTime(2026, 10, 19, 6),
          ),
          synced: true,
          healthRecordId: 'unrelated-record',
          healthClientRecordId: 'sleepy3-2',
          id: 13,
        );

      final sessions = await HealthConnectSleepHistoryRepository(
        gateway,
        () => now,
        syncStore: syncStore,
      ).loadClosedSessions();

      // One read for the whole history, not one per record.
      expect(syncStore.localMetadataLoads, 1);
      expect(sessions, hasLength(2));

      final own = sessions.first;
      expect(own.localId, 12);
      expect(own.healthRecordId, 'own-record');
      expect(own.healthClientRecordId, 'sleepy3-1');
      expect(own.sourceId, 'com.sleepy3.app');
      // Health Connect stays the source of truth for the visible times.
      expect(own.startedAt, ownStart);
      expect(own.endedAt, ownEnd);

      final other = sessions.last;
      expect(other.localId, isNull);
      expect(other.healthClientRecordId, isNull);
      expect(other.sourceId, 'com.example.other');
    });

    test('shows the history when local metadata cannot be read', () async {
      final gateway = FakeHealthConnectGateway(
        sessions: [
          HealthSleepSession(
            uuid: 'own-record',
            startedAt: DateTime(2026, 10, 19, 22),
            endedAt: DateTime(2026, 10, 20, 6),
            sourceId: 'com.sleepy3.app',
          ),
        ],
      );
      final syncStore = FakeHealthSyncStore()
        ..loadError = StateError('local metadata unavailable');

      final sessions = await HealthConnectSleepHistoryRepository(
        gateway,
        () => now,
        syncStore: syncStore,
      ).loadClosedSessions();

      expect(syncStore.localMetadataLoads, 1);
      expect(sessions, hasLength(1));
      expect(sessions.single.healthRecordId, 'own-record');
      expect(sessions.single.localId, isNull);
      expect(sessions.single.healthClientRecordId, isNull);
    });

    test('reads the full history through the next day when granted', () async {
      final gateway = FakeHealthConnectGateway();

      await HealthConnectSleepHistoryRepository(
        gateway,
        () => now,
        fullHistory: true,
      ).loadClosedSessions();

      expect(gateway.lastReadFrom, DateTime.fromMillisecondsSinceEpoch(0));
      expect(gateway.lastReadTo, now.add(const Duration(days: 1)));
    });

    test(
      'limits the read to the last 30 days without history access',
      () async {
        final gateway = FakeHealthConnectGateway();

        await HealthConnectSleepHistoryRepository(
          gateway,
          () => now,
        ).loadClosedSessions();

        expect(gateway.lastReadFrom, now.subtract(healthConnectHistoryLimit));
        expect(gateway.lastReadTo, now.add(const Duration(days: 1)));
      },
    );

    test('drops records whose end is before their start', () async {
      final gateway = FakeHealthConnectGateway(
        sessions: [
          HealthSleepSession(
            uuid: 'invalid',
            startedAt: DateTime(2026, 10, 21, 6),
            endedAt: DateTime(2026, 10, 21, 5),
          ),
        ],
      );

      final sessions = await HealthConnectSleepHistoryRepository(
        gateway,
        () => now,
      ).loadClosedSessions();

      expect(sessions, isEmpty);
    });

    test('propagates a read failure', () async {
      final gateway = FakeHealthConnectGateway()..readError = StateError('no');

      expect(
        HealthConnectSleepHistoryRepository(
          gateway,
          () => now,
        ).loadClosedSessions(),
        throwsStateError,
      );
    });
  });
}
