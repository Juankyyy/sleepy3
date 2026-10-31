import '../../sleep_tracking/domain/sleep_session.dart';
import '../domain/health_connect_gateway.dart';
import '../domain/health_history_access.dart';
import '../domain/sleep_history_repository.dart';

/// [SleepHistoryRepository] backed by Health Connect.
///
/// This reads every `SLEEP_SESSION` Health Connect exposes, regardless of the
/// app that wrote it. The local copy in Drift is never read here. Without the
/// history permission the read stops at [healthConnectHistoryLimit], matching
/// the window Android enforces.
class HealthConnectSleepHistoryRepository implements SleepHistoryRepository {
  HealthConnectSleepHistoryRepository(
    this._gateway,
    this._clock, {
    this.fullHistory = false,
  });

  /// Reads from the epoch so no record is excluded by a range guess.
  static final DateTime _earliest = DateTime.fromMillisecondsSinceEpoch(0);

  final HealthConnectGateway _gateway;
  final DateTime Function() _clock;

  /// Whether records older than [healthConnectHistoryLimit] are read.
  final bool fullHistory;

  @override
  Future<List<SleepSession>> loadClosedSessions() async {
    final now = _clock();
    final records = await _gateway.readSleepSessions(
      from: fullHistory ? _earliest : now.subtract(healthConnectHistoryLimit),
      // A record from another device can end slightly in the future when the
      // clocks disagree. Include that day so the session is not dropped.
      to: now.add(const Duration(days: 1)),
    );

    final sessions = <SleepSession>[
      for (final record in records)
        if (!record.endedAt.isBefore(record.startedAt))
          SleepSession(startedAt: record.startedAt, endedAt: record.endedAt),
    ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    return List.unmodifiable(sessions);
  }
}
