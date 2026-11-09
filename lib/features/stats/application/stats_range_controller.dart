import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/application/health_history_permission_controller.dart';
import '../../health/application/sleep_data_source_controller.dart';
import '../../health/domain/health_history_access.dart';
import '../../health/domain/sleep_data_source.dart';
import '../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../sleep_tracking/domain/sleep_history.dart';

/// Owns the Stats range shared by the summary and the advanced sheet.
///
/// Selecting a range wider than Health Connect's 30-day fallback asks for the
/// full-history permission first and reloads the sessions, so both surfaces
/// read the same window. A denial still selects the range: the list keeps the
/// last 30 days already loaded and the banner explains the limit.
///
/// The controller lives for the whole app session, like the old local range in
/// `StatsScreen`, so returning from the advanced sheet or switching tabs keeps
/// the selected range.
class StatsRangeController extends Notifier<SleepHistoryRange> {
  @override
  SleepHistoryRange build() => SleepHistoryRange.week;

  /// Applies [range], asking for full history when Google Health needs it.
  Future<void> select(SleepHistoryRange range) async {
    if (range == state) return;

    final needsHistory =
        range.requiresFullHistory &&
        ref.read(sleepDataSourceProvider) == SleepDataSource.healthConnect &&
        ref.read(healthHistoryPermissionProvider) !=
            HealthHistoryAccess.authorized;

    if (needsHistory) {
      final granted = await ref
          .read(healthHistoryPermissionProvider.notifier)
          .ensureAuthorized();
      if (!ref.mounted) return;

      if (granted) {
        await ref
            .read(sleepTrackingControllerProvider.notifier)
            .reloadHistory();
        if (!ref.mounted) return;
      }
    }

    state = range;
  }
}

final statsRangeProvider =
    NotifierProvider<StatsRangeController, SleepHistoryRange>(
      StatsRangeController.new,
    );
