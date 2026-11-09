import 'dart:math' as math;

import 'sleep_clock.dart';
import 'sleep_history.dart';
import 'sleep_session.dart';

/// The factual context of one session against the previous nights.
class SessionNightContext {
  const SessionNightContext({
    required this.baselineNights,
    required this.averageDuration,
    required this.durationDelta,
    required this.averageBedtime,
    required this.bedtimeDelta,
    required this.averageWake,
    required this.wakeDelta,
    required this.rank,
    required this.totalSessions,
    required this.nightSessionCount,
  });

  /// Recorded nights used for the average, excluding the viewed night.
  final int baselineNights;

  /// Mean total sleep of [baselineNights], or null when there are none.
  final Duration? averageDuration;

  /// This session minus [averageDuration]. Positive means longer.
  final Duration? durationDelta;

  /// Circular mean bedtime of the baseline nights.
  final Duration? averageBedtime;

  /// Signed minutes from [averageBedtime] to this session's bedtime.
  ///
  /// Positive means later. Null when there is no baseline bedtime.
  final Duration? bedtimeDelta;

  /// Circular mean wake time of the baseline nights.
  final Duration? averageWake;

  /// Signed minutes from [averageWake] to this session's wake time.
  ///
  /// Positive means later. Null when there is no baseline wake.
  final Duration? wakeDelta;

  /// Position by length inside the selected range, or null when the session
  /// is outside that range.
  final int? rank;

  /// Closed sessions in the selected range, including this one.
  final int totalSessions;

  /// Sessions that ended on this session's wake day, including this one.
  final int nightSessionCount;

  /// True when the three previous-night comparisons can be shown.
  bool get hasComparison => baselineNights >= 2 && averageDuration != null;

  /// True when the night is split across more than one session.
  bool get isSplitNight => nightSessionCount > 1;
}

/// Builds the Night context card for [session].
///
/// The baseline is the last seven recorded nights before the session's own
/// wake day, so the card never compares a night with itself. The rank uses
/// [range], the range currently selected in Stats. [now] is injected so the
/// function never reads the clock.
SessionNightContext buildSessionNightContext({
  required DateTime now,
  required SleepSession session,
  required Iterable<SleepSession> sessions,
  required SleepHistoryRange range,
}) {
  final endedAt = session.endedAt;
  if (endedAt == null) {
    return const SessionNightContext(
      baselineNights: 0,
      averageDuration: null,
      durationDelta: null,
      averageBedtime: null,
      bedtimeDelta: null,
      averageWake: null,
      wakeDelta: null,
      rank: null,
      totalSessions: 0,
      nightSessionCount: 1,
    );
  }

  final localEnd = endedAt.toLocal();
  final wakeDay = DateTime(localEnd.year, localEnd.month, localEnd.day);
  final all = sessions.toList(growable: false);
  final others = [
    for (final candidate in all)
      if (!_isSameSession(candidate, session)) candidate,
  ];

  final baselineHistory = buildSleepHistory(
    now: endedAt,
    sessions: others,
    range: SleepHistoryRange.all,
  );
  final baselineDays = baselineHistory.days
      .where((day) => day.date.isBefore(wakeDay))
      .take(7)
      .toList(growable: false);

  final averageDuration = _averageDuration(baselineDays);
  final bedtimes = baselineDays.map((day) => day.bedtime).whereType<DateTime>();
  final wakes = baselineDays.map((day) => day.wake).whereType<DateTime>();
  final bedtimeSummary = summarizeSleepClockTimes(bedtimes);
  final wakeSummary = summarizeSleepClockTimes(wakes);
  final sessionDuration = _positiveDuration(session.duration);

  return SessionNightContext(
    baselineNights: baselineDays.length,
    averageDuration: averageDuration,
    durationDelta: averageDuration == null
        ? null
        : sessionDuration - averageDuration,
    averageBedtime: bedtimeSummary.average,
    bedtimeDelta: _bedtimeDelta(session.startedAt, bedtimeSummary.average),
    averageWake: wakeSummary.average,
    wakeDelta: _wakeDelta(endedAt, wakeSummary.average),
    rank: _rank(
      now: now,
      session: session,
      sessions: [...others, session],
      range: range,
    ),
    totalSessions: _totalSessions(
      now: now,
      sessions: [...others, session],
      range: range,
    ),
    nightSessionCount: _nightSessionCount(
      now: now,
      session: session,
      sessions: [...others, session],
      wakeDay: wakeDay,
    ),
  );
}

Duration? _averageDuration(List<SleepHistoryDay> days) {
  if (days.isEmpty) return null;
  var totalMicros = 0;
  for (final day in days) {
    totalMicros += day.total.inMicroseconds;
  }
  return Duration(microseconds: totalMicros ~/ days.length);
}

Duration? _bedtimeDelta(DateTime startedAt, Duration? average) {
  if (average == null) return null;
  return Duration(
    minutes: signedClockOffsetMinutes(
      sleepClockMinuteOfDay(startedAt),
      average.inMinutes,
    ),
  );
}

Duration? _wakeDelta(DateTime endedAt, Duration? average) {
  if (average == null) return null;
  return Duration(
    minutes: signedClockOffsetMinutes(
      sleepClockMinuteOfDay(endedAt),
      average.inMinutes,
    ),
  );
}

int? _rank({
  required DateTime now,
  required SleepSession session,
  required List<SleepSession> sessions,
  required SleepHistoryRange range,
}) {
  final history = buildSleepHistory(now: now, sessions: sessions, range: range);
  final entries = history.entries;
  final inRange = entries.any(
    (entry) => _isSameSession(entry.session, session),
  );
  if (!inRange) return null;

  final duration = _positiveDuration(session.duration).inMicroseconds;
  final ahead = entries.where((entry) {
    if (_isSameSession(entry.session, session)) return false;
    return _positiveDuration(entry.session.duration).inMicroseconds > duration;
  }).length;
  return ahead + 1;
}

int _totalSessions({
  required DateTime now,
  required List<SleepSession> sessions,
  required SleepHistoryRange range,
}) {
  return buildSleepHistory(
    now: now,
    sessions: sessions,
    range: range,
  ).entries.length;
}

int _nightSessionCount({
  required DateTime now,
  required SleepSession session,
  required List<SleepSession> sessions,
  required DateTime wakeDay,
}) {
  final history = buildSleepHistory(
    now: now,
    sessions: sessions,
    range: SleepHistoryRange.all,
  );
  SleepHistoryDay? day;
  for (final candidate in history.days) {
    if (candidate.date == wakeDay) {
      day = candidate;
      break;
    }
  }
  if (day == null) return 1;

  final counted = day.sessions.any(
    (candidate) => _isSameSession(candidate, session),
  );
  return math.max(1, day.sessionsCount + (counted ? 0 : 1));
}

Duration _positiveDuration(Duration duration) =>
    duration.isNegative ? Duration.zero : duration;

bool _isSameSession(SleepSession a, SleepSession b) {
  if (identical(a, b)) return true;
  if (a.hasSameIdentityAs(b)) return true;
  return a.startedAt == b.startedAt && a.endedAt == b.endedAt;
}
