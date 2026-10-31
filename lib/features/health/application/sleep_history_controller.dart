import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sleep_tracking/application/sleep_tracking_providers.dart';
import '../data/health_connect_sleep_history_repository.dart';
import '../data/local_sleep_history_repository.dart';
import '../domain/health_history_access.dart';
import '../domain/sleep_data_source.dart';
import '../domain/sleep_history_repository.dart';
import 'health_connect_gateway_provider.dart';
import 'health_history_permission_controller.dart';
import 'sleep_data_source_controller.dart';

/// The repository for the selected source.
///
/// Rebuilds when the preference changes, so a load started after a switch can
/// never keep reading the previous source. The Google Health repository also
/// rebuilds when the history permission changes, which switches it between the
/// full history and the 30-day fallback.
final sleepHistoryRepositoryProvider = Provider<SleepHistoryRepository>((ref) {
  final source = ref.watch(sleepDataSourceProvider);

  return switch (source) {
    SleepDataSource.local => LocalSleepHistoryRepository(
      ref.watch(sleepSessionStoreProvider),
    ),
    SleepDataSource.healthConnect => HealthConnectSleepHistoryRepository(
      ref.watch(healthConnectGatewayProvider),
      ref.watch(sleepClockProvider),
      fullHistory:
          ref.watch(healthHistoryPermissionProvider) ==
          HealthHistoryAccess.authorized,
    ),
  };
});

/// Guards asynchronous history loads so only the newest one reaches the UI.
///
/// A source change or a Retry invalidates every load already in flight. The
/// caller compares the generation it started with before writing state, which
/// keeps a slow Google Health read from overwriting a newer Local result.
class SleepHistoryController {
  int _generation = 0;

  /// Starts a new load and returns its generation.
  int begin() => ++_generation;

  /// Marks every in-flight load as stale.
  void invalidate() => _generation++;

  /// Whether [generation] is still the newest load.
  bool isCurrent(int generation) => generation == _generation;
}
