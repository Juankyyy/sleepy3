import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:sleepy3/features/health/data/health_connect_gateway_impl.dart';
import 'package:sleepy3/features/health/domain/health_connect_gateway.dart';

void main() {
  group('healthConnectAvailabilityFromSdkStatus', () {
    test('maps an available SDK', () {
      expect(
        healthConnectAvailabilityFromSdkStatus(
          HealthConnectSdkStatus.sdkAvailable,
        ),
        HealthConnectAvailability.available,
      );
    });

    test('maps an SDK that needs an update', () {
      expect(
        healthConnectAvailabilityFromSdkStatus(
          HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired,
        ),
        HealthConnectAvailability.updateRequired,
      );
    });

    test('maps an unavailable SDK', () {
      expect(
        healthConnectAvailabilityFromSdkStatus(
          HealthConnectSdkStatus.sdkUnavailable,
        ),
        HealthConnectAvailability.unavailable,
      );
    });

    test('treats a missing status as unavailable', () {
      expect(
        healthConnectAvailabilityFromSdkStatus(null),
        HealthConnectAvailability.unavailable,
      );
    });
  });

  group('healthDataAccessForPermission', () {
    test('maps read to READ', () {
      expect(
        healthDataAccessForPermission(read: true, write: false),
        HealthDataAccess.READ,
      );
    });

    test('maps write to WRITE', () {
      expect(
        healthDataAccessForPermission(read: false, write: true),
        HealthDataAccess.WRITE,
      );
    });

    test('maps read and write to READ_WRITE', () {
      expect(
        healthDataAccessForPermission(read: true, write: true),
        HealthDataAccess.READ_WRITE,
      );
    });

    test('returns null when no access is requested', () {
      expect(healthDataAccessForPermission(read: false, write: false), isNull);
    });
  });

  group('healthSleepSessionFromDataPoint', () {
    HealthDataPoint point({
      String sourceId = '',
      String sourceName = 'com.sleepy3.app',
    }) {
      return HealthDataPoint(
        uuid: 'record-1',
        value: NumericHealthValue(numericValue: 480),
        type: HealthDataType.SLEEP_SESSION,
        unit: HealthDataUnit.MINUTE,
        dateFrom: DateTime(2026, 10, 20, 22),
        dateTo: DateTime(2026, 10, 21, 6),
        sourcePlatform: HealthPlatformType.googleHealthConnect,
        sourceDeviceId: 'device',
        sourceId: sourceId,
        sourceName: sourceName,
      );
    }

    test('uses source_name when Android leaves source_id empty', () {
      final session = healthSleepSessionFromDataPoint(point());

      expect(session.sourceId, 'com.sleepy3.app');
      expect(session.startedAt, DateTime(2026, 10, 20, 22));
      expect(session.endedAt, DateTime(2026, 10, 21, 6));
    });

    test('prefers a non-empty source_id', () {
      final session = healthSleepSessionFromDataPoint(
        point(sourceId: 'com.example.other', sourceName: 'com.sleepy3.app'),
      );

      expect(session.sourceId, 'com.example.other');
    });
  });
}
