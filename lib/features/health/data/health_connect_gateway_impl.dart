import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../domain/health_connect_gateway.dart';
import '../domain/health_sleep_session.dart';

/// Maps the SDK status exposed by the `health` plugin to the app-facing state.
///
/// A missing status (the plugin could not answer, or the platform is not
/// Android) is treated as unavailable.
@visibleForTesting
HealthConnectAvailability healthConnectAvailabilityFromSdkStatus(
  HealthConnectSdkStatus? status,
) {
  return switch (status) {
    HealthConnectSdkStatus.sdkAvailable => HealthConnectAvailability.available,
    HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
      HealthConnectAvailability.updateRequired,
    _ => HealthConnectAvailability.unavailable,
  };
}

/// Maps the app's read/write flags to the plugin's access level.
///
/// Returns null when no access is requested, so callers can skip the platform
/// call entirely.
@visibleForTesting
HealthDataAccess? healthDataAccessForPermission({
  required bool read,
  required bool write,
}) {
  if (read && write) return HealthDataAccess.READ_WRITE;
  if (read) return HealthDataAccess.READ;
  if (write) return HealthDataAccess.WRITE;
  return null;
}

/// `HealthConnectGateway` backed by the `health` plugin.
class HealthConnectGatewayImpl implements HealthConnectGateway {
  HealthConnectGatewayImpl({Health? health}) : _health = health ?? Health();

  static const _sleepType = HealthDataType.SLEEP_SESSION;

  final Health _health;
  Future<void>? _configuration;

  Future<void> _ensureConfigured() {
    return _configuration ??= () async {
      try {
        await _health.configure();
      } catch (error, stackTrace) {
        // Configuration only loads the device id. Health Connect calls still
        // work without it, so a failure must not disable the gateway.
        debugPrint(
          'Sleepy3: could not configure the health plugin: $error\n$stackTrace',
        );
      }
    }();
  }

  @override
  Future<HealthConnectAvailability> checkAvailability() async {
    await _ensureConfigured();
    final status = await _health.getHealthConnectSdkStatus();
    return healthConnectAvailabilityFromSdkStatus(status);
  }

  @override
  Future<bool> hasPermissions({bool read = true, bool write = false}) async {
    final access = healthDataAccessForPermission(read: read, write: write);
    if (access == null) return true;
    if (!await _isAvailable()) return false;

    try {
      final granted = await _health.hasPermissions(
        const [_sleepType],
        permissions: [access],
      );
      return granted ?? false;
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read Health Connect permissions: '
        '$error\n$stackTrace',
      );
      return false;
    }
  }

  @override
  Future<bool> requestPermissions({
    bool read = true,
    bool write = false,
  }) async {
    final access = healthDataAccessForPermission(read: read, write: write);
    if (access == null) return true;
    if (!await _isAvailable()) return false;

    try {
      // The plugin reports true when the dialog returns any grant, even if the
      // user skipped one of the requested scopes. Verify the whole request.
      await _health.requestAuthorization(
        const [_sleepType],
        permissions: [access],
      );
      return await hasPermissions(read: read, write: write);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not request Health Connect permissions: '
        '$error\n$stackTrace',
      );
      return false;
    }
  }

  @override
  Future<bool> requestHistoryPermission() async {
    if (!await _isAvailable()) return false;

    try {
      await _health.requestHealthDataHistoryAuthorization();
      return await isHistoryAuthorized();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not request Health Connect history permission: '
        '$error\n$stackTrace',
      );
      return false;
    }
  }

  @override
  Future<bool> isHistoryAuthorized() async {
    if (!await _isAvailable()) return false;

    try {
      return await _health.isHealthDataHistoryAuthorized();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read Health Connect history permission: '
        '$error\n$stackTrace',
      );
      return false;
    }
  }

  @override
  Future<List<HealthSleepSession>> readSleepSessions({
    required DateTime from,
    required DateTime to,
  }) async {
    await _ensureConfigured();
    final points = await _health.getHealthDataFromTypes(
      types: const [_sleepType],
      startTime: from,
      endTime: to,
    );

    final sessions = [
      for (final point in points)
        HealthSleepSession(
          uuid: point.uuid,
          startedAt: point.dateFrom,
          endedAt: point.dateTo,
          sourceId: point.sourceId,
          sourceName: point.sourceName,
        ),
    ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return sessions;
  }

  @override
  Future<String?> writeSleepSession({
    required DateTime startedAt,
    required DateTime endedAt,
    required String clientRecordId,
    required int clientRecordVersion,
  }) async {
    if (endedAt.isBefore(startedAt)) {
      throw ArgumentError.value(
        endedAt,
        'endedAt',
        'must not be before startedAt',
      );
    }
    if (clientRecordVersion < 1) {
      throw ArgumentError.value(
        clientRecordVersion,
        'clientRecordVersion',
        'must be at least 1',
      );
    }

    await _ensureConfigured();
    final uuid = await _health.writeHealthDataUUID(
      value: 0,
      type: _sleepType,
      startTime: startedAt,
      endTime: endedAt,
      clientRecordId: clientRecordId,
      clientRecordVersion: clientRecordVersion.toDouble(),
      recordingMethod: RecordingMethod.manual,
    );

    // The plugin stringifies a null method-channel result as "null".
    if (uuid == null || uuid.isEmpty || uuid == 'null') return null;
    return uuid;
  }

  @override
  Future<bool> deleteSleepSession({
    String? clientRecordId,
    String? healthRecordId,
  }) async {
    final clientId = _normalizeId(clientRecordId);
    if (clientId != null) {
      return _health.deleteByClientRecordId(
        dataTypeKey: _sleepType,
        clientRecordId: clientId,
      );
    }

    final uuid = _normalizeId(healthRecordId);
    if (uuid != null) {
      return _health.deleteByUUID(uuid: uuid, type: _sleepType);
    }

    throw ArgumentError(
      'deleteSleepSession needs a clientRecordId or a healthRecordId',
    );
  }

  String? _normalizeId(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<void> installHealthConnect() async {
    try {
      await _health.installHealthConnect();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not open the Health Connect store page: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<bool> _isAvailable() async =>
      await checkAvailability() == HealthConnectAvailability.available;
}
