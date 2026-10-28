import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';

import 'fakes.dart';

void main() {
  final night = HealthSleepSession(
    uuid: 'night-1',
    startedAt: DateTime(2026, 10, 26, 23),
    endedAt: DateTime(2026, 10, 27, 7),
    sourceId: 'com.sleepy3.app',
    sourceName: 'Sleepy3',
  );

  group('availability and permissions', () {
    test('reports the configured availability', () async {
      final gateway = FakeHealthConnectGateway(
        availability: HealthConnectAvailability.updateRequired,
      );

      expect(
        await gateway.checkAvailability(),
        HealthConnectAvailability.updateRequired,
      );
      expect(await gateway.hasPermissions(read: true, write: true), isFalse);
      expect(
        await gateway.requestPermissions(read: true, write: true),
        isFalse,
      );
      expect(gateway.permissionRequestCalls, 1);
    });

    test('reads the configured read and write grants', () async {
      final gateway = FakeHealthConnectGateway(
        readPermission: true,
        writePermission: false,
      );

      expect(await gateway.hasPermissions(read: true, write: false), isTrue);
      expect(await gateway.hasPermissions(read: true, write: true), isFalse);
      expect(await gateway.hasPermissions(read: false, write: true), isFalse);
      expect(await gateway.hasPermissions(read: false, write: false), isTrue);
    });

    test('a permission request only grants the configured scopes', () async {
      final gateway = FakeHealthConnectGateway(
        readPermission: false,
        writePermission: false,
        grantReadOnRequest: true,
        grantWriteOnRequest: false,
      );

      expect(
        await gateway.requestPermissions(read: true, write: true),
        isFalse,
      );
      expect(gateway.readPermission, isTrue);
      expect(gateway.writePermission, isFalse);
    });

    test('history permission is requested only once', () async {
      final gateway = FakeHealthConnectGateway(
        historyPermission: false,
        grantHistoryOnRequest: true,
      );

      expect(await gateway.isHistoryAuthorized(), isFalse);
      expect(await gateway.requestHistoryPermission(), isTrue);
      expect(await gateway.isHistoryAuthorized(), isTrue);
      expect(await gateway.requestHistoryPermission(), isTrue);
      expect(gateway.historyPermissionRequestCalls, 2);
    });
  });

  group('sleep sessions', () {
    test('reads sessions in range, oldest first', () async {
      final later = HealthSleepSession(
        uuid: 'night-2',
        startedAt: DateTime(2026, 10, 27, 23),
        endedAt: DateTime(2026, 10, 28, 7),
      );
      final gateway = FakeHealthConnectGateway(sessions: [later, night]);

      final sessions = await gateway.readSleepSessions(
        from: DateTime(2026, 10, 26),
        to: DateTime(2026, 10, 28),
      );

      expect(sessions.map((session) => session.uuid), ['night-1', 'night-2']);
      expect(gateway.lastReadFrom, DateTime(2026, 10, 26));
      expect(gateway.lastReadTo, DateTime(2026, 10, 28));
    });

    test('writes a session and returns its UUID', () async {
      final gateway = FakeHealthConnectGateway();

      final uuid = await gateway.writeSleepSession(
        startedAt: night.startedAt,
        endedAt: night.endedAt,
        clientRecordId: 'sleepy3-1761523200000',
      );

      expect(uuid, 'fake-sleepy3-1761523200000');
      expect(gateway.writes, hasLength(1));
      expect(gateway.sessions.single.uuid, uuid);
      expect(gateway.sessions.single.sourceName, 'Sleepy3');
    });

    test(
      'writing twice with the same client record id is idempotent',
      () async {
        final gateway = FakeHealthConnectGateway();

        final first = await gateway.writeSleepSession(
          startedAt: night.startedAt,
          endedAt: night.endedAt,
          clientRecordId: 'sleepy3-1',
        );
        final second = await gateway.writeSleepSession(
          startedAt: night.startedAt,
          endedAt: night.endedAt,
          clientRecordId: 'sleepy3-1',
        );

        expect(second, first);
        expect(gateway.writes, hasLength(2));
        expect(gateway.sessions, hasLength(1));
      },
    );

    test('a rejected write returns null and stores nothing', () async {
      final gateway = FakeHealthConnectGateway(writeSucceeds: false);

      final uuid = await gateway.writeSleepSession(
        startedAt: night.startedAt,
        endedAt: night.endedAt,
        clientRecordId: 'sleepy3-1',
      );

      expect(uuid, isNull);
      expect(gateway.writes, hasLength(1));
      expect(gateway.sessions, isEmpty);
    });

    test('a failing read throws and leaves the error visible', () async {
      final failure = StateError('health connect is offline');
      final gateway = FakeHealthConnectGateway()..readError = failure;

      expect(
        gateway.readSleepSessions(
          from: DateTime(2026, 10, 26),
          to: DateTime(2026, 10, 28),
        ),
        throwsA(same(failure)),
      );
    });
  });

  test('records install requests', () async {
    final gateway = FakeHealthConnectGateway(
      availability: HealthConnectAvailability.unavailable,
    );

    await gateway.installHealthConnect();

    expect(gateway.installCalls, 1);
  });
}
