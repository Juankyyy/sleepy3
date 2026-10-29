import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/settings/application/theme_mode_controller.dart';

import '../../settings/fakes.dart';
import '../fakes.dart';

void main() {
  group('SleepDataSourceController', () {
    late FakeSettingsStore store;
    late FakeHealthConnectGateway gateway;
    late ProviderContainer container;

    void create({
      SleepDataSource initial = SleepDataSource.local,
      FakeSettingsStore? settingsStore,
      FakeHealthConnectGateway? healthGateway,
    }) {
      store = settingsStore ?? FakeSettingsStore(sleepDataSource: initial);
      gateway = healthGateway ?? FakeHealthConnectGateway();
      container = ProviderContainer.test(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          initialSleepDataSourceProvider.overrideWithValue(initial),
          healthConnectGatewayProvider.overrideWithValue(gateway),
        ],
      );
    }

    SleepDataSourceController controller() =>
        container.read(sleepDataSourceProvider.notifier);

    SleepDataSource active() => container.read(sleepDataSourceProvider);

    test('starts with the startup preference', () {
      create(initial: SleepDataSource.healthConnect);

      expect(active(), SleepDataSource.healthConnect);
    });

    test('switching to Google Health requests access and saves it', () async {
      create(
        healthGateway: FakeHealthConnectGateway(
          readPermission: false,
          writePermission: false,
          grantReadOnRequest: true,
          grantWriteOnRequest: true,
        ),
      );

      final result = await controller().select(SleepDataSource.healthConnect);

      expect(result.succeeded, isTrue);
      expect(result.source, SleepDataSource.healthConnect);
      expect(active(), SleepDataSource.healthConnect);
      expect(store.sourceSaves, [SleepDataSource.healthConnect]);
      expect(gateway.permissionRequestCalls, 1);
    });

    test('does not ask again when the permissions already exist', () async {
      create(
        healthGateway: FakeHealthConnectGateway(
          readPermission: true,
          writePermission: true,
        ),
      );

      final result = await controller().select(SleepDataSource.healthConnect);

      expect(result.succeeded, isTrue);
      expect(gateway.permissionRequestCalls, 0);
    });

    test('a denied permission keeps Local and saves nothing', () async {
      create(
        healthGateway: FakeHealthConnectGateway(
          readPermission: false,
          writePermission: false,
          grantReadOnRequest: false,
          grantWriteOnRequest: false,
        ),
      );

      final result = await controller().select(SleepDataSource.healthConnect);

      expect(result.succeeded, isFalse);
      expect(result.failure, SleepDataSourceChangeFailure.permissionDenied);
      expect(result.source, SleepDataSource.local);
      expect(active(), SleepDataSource.local);
      expect(store.sourceSaves, isEmpty);
    });

    test('a permission error keeps Local', () async {
      create(
        healthGateway: FakeHealthConnectGateway(
          readPermission: false,
          writePermission: false,
        )..permissionError = StateError('permission dialog failed'),
      );

      final result = await controller().select(SleepDataSource.healthConnect);

      expect(result.failure, SleepDataSourceChangeFailure.permissionDenied);
      expect(active(), SleepDataSource.local);
      expect(store.sourceSaves, isEmpty);
    });

    test('unavailable Health Connect keeps Local', () async {
      create(
        healthGateway: FakeHealthConnectGateway(
          availability: HealthConnectAvailability.unavailable,
        ),
      );

      final result = await controller().select(SleepDataSource.healthConnect);

      expect(result.failure, SleepDataSourceChangeFailure.unavailable);
      expect(active(), SleepDataSource.local);
      expect(store.sourceSaves, isEmpty);
    });

    test('an update requirement keeps Local', () async {
      create(
        healthGateway: FakeHealthConnectGateway(
          availability: HealthConnectAvailability.updateRequired,
        ),
      );

      final result = await controller().select(SleepDataSource.healthConnect);

      expect(result.failure, SleepDataSourceChangeFailure.updateRequired);
      expect(active(), SleepDataSource.local);
      expect(store.sourceSaves, isEmpty);
    });

    test('a failed save keeps the previous source', () async {
      create(settingsStore: FakeSettingsStore(failWrites: true));

      final result = await controller().select(SleepDataSource.healthConnect);

      expect(result.failure, SleepDataSourceChangeFailure.saveFailed);
      expect(active(), SleepDataSource.local);
      expect(store.sourceSaves, isEmpty);
    });

    test('selecting the active source does not save again', () async {
      create(
        initial: SleepDataSource.healthConnect,
        healthGateway: FakeHealthConnectGateway(
          readPermission: true,
          writePermission: true,
        ),
      );

      final result = await controller().select(SleepDataSource.healthConnect);

      expect(result.succeeded, isTrue);
      expect(store.sourceSaves, isEmpty);
    });

    test('switching back to Local keeps the permissions', () async {
      create(
        initial: SleepDataSource.healthConnect,
        healthGateway: FakeHealthConnectGateway(
          readPermission: true,
          writePermission: true,
        ),
      );

      final result = await controller().select(SleepDataSource.local);

      expect(result.succeeded, isTrue);
      expect(active(), SleepDataSource.local);
      expect(store.sourceSaves, [SleepDataSource.local]);
      expect(gateway.readPermission, isTrue);
      expect(gateway.writePermission, isTrue);
      expect(gateway.permissionRequestCalls, 0);
    });
  });
}
