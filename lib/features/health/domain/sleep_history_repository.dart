import '../../sleep_tracking/domain/sleep_session.dart';

/// Reads the finished sessions shown by Home and Stats.
///
/// There is one implementation per [SleepDataSource]; the selected source
/// decides which one the tracking controller uses. Implementations must only
/// return closed sessions and must never mix data from another source.
abstract interface class SleepHistoryRepository {
  /// Every closed session available in this source, oldest first.
  Future<List<SleepSession>> loadClosedSessions();
}
