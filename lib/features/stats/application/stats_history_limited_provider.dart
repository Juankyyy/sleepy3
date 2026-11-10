import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/application/health_history_permission_controller.dart';
import '../../health/application/sleep_data_source_controller.dart';
import '../../health/domain/health_history_access.dart';
import '../../health/domain/sleep_data_source.dart';
import 'stats_range_controller.dart';

/// Whether the visible Stats range reaches past the 30-day Health Connect
/// history window.
///
/// Stats, the advanced sheet and the summary-block picker all use this same
/// flag so every chart names the limited window consistently.
final statsHistoryLimitedProvider = Provider<bool>((ref) {
  final source = ref.watch(sleepDataSourceProvider);
  final range = ref.watch(statsRangeProvider);
  final permission = ref.watch(healthHistoryPermissionProvider);
  return source == SleepDataSource.healthConnect &&
      range.requiresFullHistory &&
      permission != HealthHistoryAccess.authorized;
});
