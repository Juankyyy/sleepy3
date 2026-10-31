import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_controller.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/settings/application/theme_mode_controller.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_providers.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

import '../../settings/fakes.dart';
import '../fakes.dart';

void main() {
  group('HealthSyncController', () {
    late DateTime now;
    late FakeHealthConnectGateway gateway;
    late FakeHealthSyncStore store;
    late FakeSettingsStore settingsStore;
    late ProviderContainer container;

    void create({
      SleepDataSource source = SleepDataSource.healthConnect,
      FakeHealthConnectGateway? healthGateway,
      FakeHealthSyncStore? healthStore,
    }) {
      now = DateTime(2026, 10, 21, 6, 20);
      gateway = healthGateway ?? FakeHealthConnectGateway();
      store = healthStore ?? FakeHealthSyncStore();
      settingsStore = FakeSettingsStore(sleepDataSource: source);
      container = ProviderContainer.test(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          healthConnectGatewayProvider.overrideWithValue(gateway),
          healthSyncStoreProvider.overrideWithValue(store),
          initialSleepDataSourceProvider.overrideWithValue(source),
          settingsStoreProvider.overrideWithValue(settingsStore),
        ],
      );
    }

    HealthSyncController controller() =>
        container.read(healthSyncControllerProvider.notifier);

    HealthSyncState state() => container.read(healthSyncControllerProvider);

    test('reports a connected Health Connect with sleep access', () async {
      create();

      await controller().refresh();

      expect(state().connection, HealthConnectConnectionStatus.connected);
      expect(state().pendingCount, 0);
    });

    test('reports missing permissions instead of crashing', () async {
      create(
        healthGateway: FakeHealthConnectGateway(
          readPermission: false,
          writePermission: false,
        ),
      );

      await controller().refresh();

      expect(
        state().connection,
        HealthConnectConnectionStatus.permissionNeeded,
      );
    });

    test('maps unavailable and outdated Health Connect', () async {
      create(
        healthGateway: FakeHealthConnectGateway(
          availability: HealthConnectAvailability.unavailable,
        ),
      );
      await controller().refresh();
      expect(state().connection, HealthConnectConnectionStatus.notAvailable);

      gateway.availability = HealthConnectAvailability.updateRequired;
      await controller().refresh();
      expect(state().connection, HealthConnectConnectionStatus.updateRequired);
    });

    test('reconnect asks again and reports the new state', () async {
      create(
        healthGateway: FakeHealthConnectGateway(
          readPermission: false,
          writePermission: false,
          grantReadOnRequest: true,
          grantWriteOnRequest: true,
        ),
      );
      await controller().refresh();
      expect(
        state().connection,
        HealthConnectConnectionStatus.permissionNeeded,
      );

      final granted = await controller().reconnect();

      expect(granted, isTrue);
      expect(gateway.permissionRequestCalls, 1);
      expect(state().connection, HealthConnectConnectionStatus.connected);
    });

    test('retries pending uploads and updates the count', () async {
      final session = SleepSession(
        startedAt: DateTime(2026, 10, 20, 22),
        endedAt: DateTime(2026, 10, 21, 6),
      );
      create(healthStore: FakeHealthSyncStore()..addLocal(session));

      final result = await controller().retryPending();

      expect(result.uploaded, 1);
      expect(gateway.writes, hasLength(1));
      expect(state().pendingCount, 0);
      expect(state().lastSyncedAt, now);
    });

    test('Google Health retries new uploads and updates', () async {
      final newSession = SleepSession(
        startedAt: DateTime(2026, 10, 20, 22),
        endedAt: DateTime(2026, 10, 21, 6),
      );
      final update = SleepSession(
        startedAt: DateTime(2026, 10, 19, 22),
        endedAt: DateTime(2026, 10, 20, 6),
      );
      final healthStore = FakeHealthSyncStore()
        ..addLocal(newSession)
        ..addLocal(
          update,
          healthRecordId: 'health-record-1',
          healthClientRecordId: 'sleepy3-1',
        );
      create(healthStore: healthStore);

      final result = await controller().retryPending();

      expect(result.total, 2);
      expect(result.uploaded, 2);
      expect(gateway.writes, hasLength(2));
      expect(
        gateway.writes.map((write) => write.clientRecordId),
        contains('sleepy3-1'),
      );
      expect(state().pendingCount, 0);
    });

    test('Local mode never uploads automatically', () async {
      final session = SleepSession(
        startedAt: DateTime(2026, 10, 20, 22),
        endedAt: DateTime(2026, 10, 21, 6),
      );
      create(
        source: SleepDataSource.local,
        healthStore: FakeHealthSyncStore()..addLocal(session),
      );

      final result = await controller().retryPending();

      expect(result.total, 0);
      expect(gateway.writes, isEmpty);
      expect(store.rows.single.healthSyncedAt, isNull);
    });

    test('Local mode retries only updates of synchronized sessions', () async {
      final update = SleepSession(
        startedAt: DateTime(2026, 10, 20, 22),
        endedAt: DateTime(2026, 10, 21, 6),
      );
      final newSession = SleepSession(
        startedAt: DateTime(2026, 10, 19, 22),
        endedAt: DateTime(2026, 10, 20, 6),
      );
      final healthStore = FakeHealthSyncStore()
        ..addLocal(
          update,
          healthRecordId: 'health-record-1',
          healthClientRecordId: 'sleepy3-1',
        )
        ..addLocal(newSession);
      create(source: SleepDataSource.local, healthStore: healthStore);

      final result = await controller().retryPending();

      expect(result.total, 1);
      expect(result.uploaded, 1);
      expect(gateway.writes, hasLength(1));
      expect(gateway.writes.single.clientRecordId, 'sleepy3-1');
      expect(store.rows.first.healthSyncedAt, now);
      expect(store.rows.last.healthSyncedAt, isNull);
      expect(state().pendingCount, 1);
    });
  });
}
