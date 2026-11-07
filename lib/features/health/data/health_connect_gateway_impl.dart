import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

/// Maps one plugin data point to the gateway model.
///
/// On Android the `health` plugin reports the writing package in `source_name`
/// and leaves `source_id` empty. Prefer `source_id` when the platform provides
/// it, then fall back to the package name so Sleepy3 can recognise its own
/// records in Google Health mode.
@visibleForTesting
HealthSleepSession healthSleepSessionFromDataPoint(HealthDataPoint point) {
  final sourceId = point.sourceId.trim();
  final sourceName = point.sourceName.trim();
  return HealthSleepSession(
    uuid: point.uuid,
    startedAt: point.dateFrom,
    endedAt: point.dateTo,
    sourceId: sourceId.isNotEmpty ? sourceId : sourceName,
    sourceName: point.sourceName,
  );
}

/// `HealthConnectGateway` backed by the `health` plugin.
class HealthConnectGatewayImpl implements HealthConnectGateway {
  HealthConnectGatewayImpl({Health? health}) : _health = health ?? Health();

  static const _sleepType = HealthDataType.SLEEP_SESSION;

  /// Small native bridge that exposes Health Connect write metadata the
  /// plugin does not map to Dart.
  static const _bridgeChannel = MethodChannel('com.sleepy3.app/health_connect');

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
      for (final point in points) healthSleepSessionFromDataPoint(point),
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
  Future<HealthRecordUpdate?> updateSleepSession({
    required String healthRecordId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final token = await readSleepSessionWriteToken(healthRecordId);
    if (token == null) return null;

    final nextVersion = token.clientRecordVersion + 1;
    final uuid = await writeSleepSession(
      startedAt: startedAt,
      endedAt: endedAt,
      clientRecordId: token.clientRecordId,
      clientRecordVersion: nextVersion,
    );
    if (uuid == null || uuid.isEmpty) return null;

    return HealthRecordUpdate(
      healthRecordId: uuid,
      clientRecordId: token.clientRecordId,
      clientRecordVersion: nextVersion,
    );
  }

  @override
  Future<HealthRecordWriteToken?> readSleepSessionWriteToken(
    String healthRecordId,
  ) async {
    try {
      final result = await _bridgeChannel.invokeMapMethod<String, Object?>(
        'readSleepSessionWriteToken',
        {'healthRecordId': healthRecordId},
      );
      if (result == null) return null;

      final clientRecordId = result['clientRecordId'];
      final clientRecordVersion = result['clientRecordVersion'];
      if (clientRecordId is! String ||
          clientRecordId.isEmpty ||
          clientRecordVersion is! num) {
        return null;
      }
      return HealthRecordWriteToken(
        clientRecordId: clientRecordId,
        clientRecordVersion: clientRecordVersion.toInt(),
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read Health Connect record metadata: '
        '$error\n$stackTrace',
      );
      return null;
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: Health Connect record metadata bridge is unavailable: '
        '$error\n$stackTrace',
      );
      return null;
    }
  }

  @override
  Future<SleepRecordDeleteResult> deleteSleepSession({
    String? clientRecordId,
    String? healthRecordId,
  }) async {
    final clientId = _normalizeId(clientRecordId);
    final uuid = _normalizeId(healthRecordId);
    if (clientId == null && uuid == null) {
      return SleepRecordDeleteResult.failed;
    }

    try {
      final status = await _bridgeChannel.invokeMethod<String>(
        'deleteSleepSession',
        {'clientRecordId': clientId, 'healthRecordId': uuid},
      );
      switch (status) {
        case 'deleted':
          return SleepRecordDeleteResult.deleted;
        case 'notFound':
          return SleepRecordDeleteResult.notFound;
        case 'permission':
          return SleepRecordDeleteResult.permission;
        default:
          return SleepRecordDeleteResult.failed;
      }
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: Health Connect delete bridge failed: '
        '$error\n$stackTrace',
      );
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: Health Connect delete bridge is unavailable: '
        '$error\n$stackTrace',
      );
    }

    // Older builds without the bridge still get the plugin's boolean. It
    // cannot distinguish a missing record from a permission failure.
    try {
      final confirmed = clientId != null
          ? await _health.deleteByClientRecordId(
              dataTypeKey: _sleepType,
              clientRecordId: clientId,
            )
          : await _health.deleteByUUID(uuid: uuid!, type: _sleepType);
      return confirmed
          ? SleepRecordDeleteResult.deleted
          : SleepRecordDeleteResult.failed;
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not delete a Health Connect record: '
        '$error\n$stackTrace',
      );
      return SleepRecordDeleteResult.failed;
    }
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
