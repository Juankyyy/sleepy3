import 'sleep_session.dart';

/// The state restored when the app starts.
class SleepSnapshot {
  const SleepSnapshot({this.openSession, this.closedSessions = const []});

  static const empty = SleepSnapshot();

  /// A session that was running when the app last closed, if any.
  final SleepSession? openSession;

  /// Every finished session, oldest first.
  ///
  /// The app no longer loads this before the first frame: Home and Stats read
  /// the selected source asynchronously. It stays available for callers that
  /// need both halves at once, such as migrations and tests.
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

  /// The open session left behind by a crash or the last run, if any.
  ///
  /// When duplicate open rows exist, the most recent one wins, matching what
  /// [finishOpenSession] will close.
  Future<SleepSession?> loadOpenSession();

  /// Every finished session ordered oldest first.
  Future<List<SleepSession>> loadClosedSessions();

  Future<void> startSession(SleepSession session);

  /// Updates the times of a local session.
  ///
  /// Only rows started in Sleepy3 can change; downloaded rows are copies and
  /// are never written here. Returns false when [id] is not a local row or
  /// does not exist.
  ///
  /// With [markHealthPending] the row is queued for a Health Connect update by
  /// clearing its sync time. The skipped flag is always cleared so an edited
  /// session with a positive duration becomes eligible again.
  Future<bool> updateSession(
    int id,
    DateTime startedAt,
    DateTime endedAt, {
    bool markHealthPending = true,
  });

  /// Deletes a local session.
  ///
  /// Downloaded copies are never deleted here. Returns false when [id] is not a
  /// local row or does not exist.
  Future<bool> deleteSession(int id);

  /// Closes the most recent open session at [endedAt].
  ///
  /// Older open rows left behind by a crash are deleted so the history cannot
  /// grow overlapping sessions that would be uploaded to Health Connect.
  Future<void> finishOpenSession(DateTime endedAt);
}
