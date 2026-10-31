import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_controller.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/health/application/sleep_copy_controller.dart';
import 'package:sleepy3/features/health/application/sleep_copy_service.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_providers.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

import '../fakes.dart';

void main() {
  group('SleepCopyController', () {
    late DateTime now;
    late FakeHealthConnectGateway gateway;
    late FakeHealthSyncStore store;
    late ProviderContainer container;

    final startedAt = DateTime(2026, 10, 20, 22);
    final endedAt = DateTime(2026, 10, 21, 6);

    void create({List<HealthSleepSession> sessions = const []}) {
      now = DateTime(2026, 10, 21, 6, 20);
      gateway = FakeHealthConnectGateway(sessions: sessions);
      store = FakeHealthSyncStore();
      container = ProviderContainer.test(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          healthConnectGatewayProvider.overrideWithValue(gateway),
          healthSyncStoreProvider.overrideWithValue(store),
        ],
      );
    }

    SleepCopyController controller() =>
        container.read(sleepCopyControllerProvider.notifier);

    SleepCopyState state() => container.read(sleepCopyControllerProvider);

    test(
      'sync last records the result and refreshes the sync status',
      () async {
        create();
        store.addLocal(SleepSession(startedAt: startedAt, endedAt: endedAt));

        final result = await controller().syncLastSession();

        expect(result.added, 1);
        expect(result.failure, isNull);
        expect(state().running, isNull);
        expect(state().lastAction, SleepCopyAction.syncLast);
        expect(state().lastResult, same(result));
        expect(state().lastError, isNull);

        final sync = container.read(healthSyncControllerProvider);
        expect(sync.pendingCount, 0);
        expect(sync.lastSyncedAt, now);
      },
    );

    test('download records the result without changing the source', () async {
      create(
        sessions: [
          HealthSleepSession(
            uuid: 'record-1',
            startedAt: startedAt,
            endedAt: endedAt,
          ),
        ],
      );

      final result = await controller().downloadAllFromHealthConnect();

      expect(result.added, 1);
      expect(state().lastAction, SleepCopyAction.downloadAll);
      expect(state().lastResult, same(result));
      expect(container.read(healthSyncControllerProvider).pendingCount, 0);
      expect(store.rows.single.healthRecordId, 'record-1');
    });

    test('a denied permission is returned to the caller', () async {
      create();
      gateway.writePermission = false;
      gateway.grantWriteOnRequest = false;
      store.addLocal(SleepSession(startedAt: startedAt, endedAt: endedAt));

      final result = await controller().uploadAllPreviousSessions();

      expect(result.failure, SleepCopyFailure.permissionDenied);
      expect(result.added, 0);
      expect(state().running, isNull);
      expect(state().lastAction, SleepCopyAction.uploadAll);
      expect(store.rows.single.isPendingUpload, isTrue);
    });
  });
}
