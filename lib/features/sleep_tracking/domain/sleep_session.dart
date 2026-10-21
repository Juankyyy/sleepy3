/// One sleep session.
///
/// A session starts when the user taps "Dormir" and ends when they tap
/// "Despertar". An open session has no [endedAt] yet.
class SleepSession {
  const SleepSession({required this.startedAt, this.endedAt});

  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isOpen => endedAt == null;

  /// Time slept. Returns [Duration.zero] while the session is still open.
  Duration get duration {
    final end = endedAt;
    if (end == null) return Duration.zero;
    return end.difference(startedAt);
  }

  SleepSession finish(DateTime at) {
    final end = at.isBefore(startedAt) ? startedAt : at;
    return SleepSession(startedAt: startedAt, endedAt: end);
  }

  @override
  String toString() => 'SleepSession(startedAt: $startedAt, endedAt: $endedAt)';
}
