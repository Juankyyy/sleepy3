import 'sleep_session.dart';

/// The state restored when the app starts.
class SleepSnapshot {
  const SleepSnapshot({this.openSession, this.lastSession});

  static const empty = SleepSnapshot();

  /// A session that was running when the app last closed, if any.
  final SleepSession? openSession;

  /// The most recently finished session, used for the session line.
  final SleepSession? lastSession;
}

/// Persistence boundary for sleep sessions.
///
/// The controller updates its in-memory state first, then writes through this
/// interface in order, so the two buttons never wait for disk I/O.
abstract interface class SleepSessionStore {
  Future<SleepSnapshot> load();

  Future<void> startSession(SleepSession session);

  Future<void> finishOpenSession(DateTime endedAt);
}
