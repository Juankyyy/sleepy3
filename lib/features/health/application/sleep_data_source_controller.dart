import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../domain/health_connect_gateway.dart';
import '../domain/sleep_data_source.dart';
import 'health_connect_gateway_provider.dart';

/// Overridden in `main` with the source loaded before the first frame.
final initialSleepDataSourceProvider = Provider<SleepDataSource>(
  (ref) => SleepDataSource.local,
);

/// Why a source change was rejected. The active source does not change.
enum SleepDataSourceChangeFailure {
  /// Health Connect is not installed or not supported.
  unavailable,

  /// Health Connect is installed but needs an update.
  updateRequired,

  /// The user did not grant read and write access to sleep.
  permissionDenied,

  /// The preference could not be written.
  saveFailed,
}

/// The outcome of [SleepDataSourceController.select].
class SleepDataSourceChangeResult {
  const SleepDataSourceChangeResult({required this.source, this.failure});

  /// The source that is active after the attempt.
  final SleepDataSource source;

  /// Null on success.
  final SleepDataSourceChangeFailure? failure;

  bool get succeeded => failure == null;
}

/// Owns the selected sleep data source and its persisted preference.
///
/// Switching to Google Health checks availability and asks for read and write
/// access first. A denied permission or a missing Health Connect leaves the
/// previous source active. Switching back to Local only saves the preference
/// and never revokes permissions.
class SleepDataSourceController extends Notifier<SleepDataSource> {
  @override
  SleepDataSource build() => ref.watch(initialSleepDataSourceProvider);

  Future<SleepDataSourceChangeResult> select(SleepDataSource target) async {
    if (target == SleepDataSource.healthConnect) {
      final failure = await _prepareHealthConnect();
      if (failure != null) {
        return SleepDataSourceChangeResult(source: state, failure: failure);
      }
    }

    if (target != state) {
      try {
        await ref.read(settingsStoreProvider).saveSleepDataSource(target);
      } catch (error, stackTrace) {
        debugPrint(
          'Sleepy3: could not persist the sleep data source: '
          '$error\n$stackTrace',
        );
        return SleepDataSourceChangeResult(
          source: state,
          failure: SleepDataSourceChangeFailure.saveFailed,
        );
      }
      state = target;
    }

    return SleepDataSourceChangeResult(source: state);
  }

  /// Returns null when Health Connect is ready, or the failure reason.
  Future<SleepDataSourceChangeFailure?> _prepareHealthConnect() async {
    final gateway = ref.read(healthConnectGatewayProvider);

    final HealthConnectAvailability availability;
    try {
      availability = await gateway.checkAvailability();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not check Health Connect availability: '
        '$error\n$stackTrace',
      );
      return SleepDataSourceChangeFailure.unavailable;
    }

    switch (availability) {
      case HealthConnectAvailability.available:
        break;
      case HealthConnectAvailability.updateRequired:
        return SleepDataSourceChangeFailure.updateRequired;
      case HealthConnectAvailability.unavailable:
        return SleepDataSourceChangeFailure.unavailable;
    }

    try {
      final granted = await gateway.hasPermissions(read: true, write: true);
      if (granted) return null;

      final requested = await gateway.requestPermissions(
        read: true,
        write: true,
      );
      return requested ? null : SleepDataSourceChangeFailure.permissionDenied;
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not get Health Connect permissions: '
        '$error\n$stackTrace',
      );
      return SleepDataSourceChangeFailure.permissionDenied;
    }
  }
}

final sleepDataSourceProvider =
    NotifierProvider<SleepDataSourceController, SleepDataSource>(
      SleepDataSourceController.new,
    );
