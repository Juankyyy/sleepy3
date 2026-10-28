import 'sleep_session.dart';

/// The state restored when the app starts.
class SleepSnapshot {
  const SleepSnapshot({this.openSession, this.closedSessions = const []});

  static const empty = SleepSnapshot();

  /// A session that was running when the app last closed, if any.
  final SleepSession? openSession;

  /// Every finished session, oldest first.
  ///
  /// Stats groups them by wake day and Home picks the recent window. Keeping
  /// the full history here gives both screens one source of truth and lets
  /// Stats update as soon as a session is finished.
  final List<SleepSession> closedSessions;

  /// The most recently stored closed session, used for the session line.
  SleepSession? get lastSession =>
      closedSessions.isEmpty ? null : closedSessions.last;
}

/// Persistence boundary for sleep sessions.
///
/// The controller updates its in-memory state first, then writes through this
/// interface in order, so the two buttons never wait for disk I/O.
abstract interface class SleepSessionStore {
  /// Loads the startup snapshot: the open session, if any, and every closed
  /// session ordered oldest first.
  Future<SleepSnapshot> load();

  Future<void> startSession(SleepSession session);

  /// Closes the most recent open session at [endedAt].
  ///
  /// Older open rows left behind by a crash are deleted so the history cannot
  /// grow overlapping sessions that would be uploaded to Health Connect.
  Future<void> finishOpenSession(DateTime endedAt);
}
