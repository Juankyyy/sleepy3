import 'sleep_session.dart';

/// The state restored when the app starts.
class SleepSnapshot {
  const SleepSnapshot({
    this.openSession,
    this.lastSession,
    this.recentSessions = const [],
  });

  static const empty = SleepSnapshot();

  /// A session that was running when the app last closed, if any.
  final SleepSession? openSession;

  /// The most recently finished session, used for the session line.
  final SleepSession? lastSession;

  /// Closed sessions that ended in the recent summary window, oldest first.
  final List<SleepSession> recentSessions;
}

/// Persistence boundary for sleep sessions.
///
/// The controller updates its in-memory state first, then writes through this
/// interface in order, so the two buttons never wait for disk I/O.
abstract interface class SleepSessionStore {
  /// Loads the startup snapshot, using [now] to bound the recent summary.
  Future<SleepSnapshot> load({required DateTime now});

  Future<void> startSession(SleepSession session);

  Future<void> finishOpenSession(DateTime endedAt);
}
