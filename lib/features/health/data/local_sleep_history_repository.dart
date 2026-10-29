import '../../sleep_tracking/domain/sleep_session.dart';
import '../../sleep_tracking/domain/sleep_session_store.dart';
import '../domain/sleep_history_repository.dart';

/// [SleepHistoryRepository] backed by the local Drift database.
class LocalSleepHistoryRepository implements SleepHistoryRepository {
  const LocalSleepHistoryRepository(this._store);

  final SleepSessionStore _store;

  @override
  Future<List<SleepSession>> loadClosedSessions() =>
      _store.loadClosedSessions();
}
