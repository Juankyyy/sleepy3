import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_history_permission_controller.dart';
import 'package:sleepy3/features/health/domain/health_history_access.dart';

import '../fakes.dart';

void main() {
  group('HealthHistoryPermissionController', () {
    late FakeHealthConnectGateway gateway;
    late ProviderContainer container;

    void create({bool authorized = false, bool grantOnRequest = true}) {
      gateway = FakeHealthConnectGateway(
        historyPermission: authorized,
        grantHistoryOnRequest: grantOnRequest,
      );
      container = ProviderContainer.test(
        overrides: [healthConnectGatewayProvider.overrideWithValue(gateway)],
      );
    }

    HealthHistoryPermissionController controller() =>
        container.read(healthHistoryPermissionProvider.notifier);

    HealthHistoryAccess access() =>
        container.read(healthHistoryPermissionProvider);

    test('starts unknown', () {
      create();

      expect(access(), HealthHistoryAccess.unknown);
    });

    test('refresh records an existing grant without asking again', () async {
      create(authorized: true);

      expect(await controller().refresh(), HealthHistoryAccess.authorized);
      expect(access(), HealthHistoryAccess.authorized);
      expect(gateway.historyPermissionRequestCalls, 0);
    });

    test('refresh marks a missing permission as denied', () async {
      create();

      expect(await controller().refresh(), HealthHistoryAccess.denied);
      expect(access(), HealthHistoryAccess.denied);
      expect(gateway.historyPermissionRequestCalls, 0);
    });

    test('an existing grant is reused without a dialog', () async {
      create(authorized: true);

      expect(await controller().ensureAuthorized(), isTrue);
      expect(access(), HealthHistoryAccess.authorized);
      expect(gateway.historyPermissionRequestCalls, 0);
    });

    test('ensure asks for the history permission and grants it', () async {
      create(grantOnRequest: true);

      expect(await controller().ensureAuthorized(), isTrue);
      expect(access(), HealthHistoryAccess.authorized);
      expect(gateway.historyPermissionRequestCalls, 1);
      expect(gateway.historyPermission, isTrue);
    });

    test('a denied request limits the history', () async {
      create(grantOnRequest: false);

      expect(await controller().ensureAuthorized(), isFalse);
      expect(access(), HealthHistoryAccess.denied);
      expect(gateway.historyPermissionRequestCalls, 1);
      expect(gateway.historyPermission, isFalse);
    });

    test('concurrent callers share one platform request', () async {
      create(grantOnRequest: true);
      final first = controller().ensureAuthorized();
      final second = controller().ensureAuthorized();

      expect(await Future.wait([first, second]), [true, true]);
      expect(gateway.historyPermissionRequestCalls, 1);
    });

    test('a platform failure is treated as denied', () async {
      create();
      gateway.historyError = StateError('offline');

      expect(await controller().ensureAuthorized(), isFalse);
      expect(access(), HealthHistoryAccess.denied);
    });
  });
}
