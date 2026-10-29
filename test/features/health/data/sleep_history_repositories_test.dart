import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/data/health_connect_sleep_history_repository.dart';
import 'package:sleepy3/features/health/data/local_sleep_history_repository.dart';
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
      );
      final early = HealthSleepSession(
        uuid: 'early',
        startedAt: DateTime(2026, 10, 19, 22),
        endedAt: DateTime(2026, 10, 20, 5),
      );
      final gateway = FakeHealthConnectGateway(sessions: [late, early]);

      final sessions = await HealthConnectSleepHistoryRepository(
        gateway,
        () => now,
      ).loadClosedSessions();

      expect(sessions, hasLength(2));
      expect(sessions.first.startedAt, early.startedAt);
      expect(sessions.first.endedAt, early.endedAt);
      expect(sessions.last.startedAt, late.startedAt);
      expect(sessions.last.endedAt, late.endedAt);
    });

    test('reads from the epoch through the next day', () async {
      final gateway = FakeHealthConnectGateway();

      await HealthConnectSleepHistoryRepository(
        gateway,
        () => now,
      ).loadClosedSessions();

      expect(gateway.lastReadFrom, DateTime.fromMillisecondsSinceEpoch(0));
      expect(gateway.lastReadTo, now.add(const Duration(days: 1)));
    });

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
