import 'sleep_session.dart';

/// The window of sleep history shown on the Stats screen.
enum SleepHistoryRange {
  /// Today and the six previous local days.
  week(7),

  /// Today and the twenty-nine previous local days.
  month(30),

  /// Today and the eighty-nine previous local days.
  threeMonths(90),

  /// Today and the three hundred sixty-four previous local days.
  year(365),

  /// Every stored night up to today.
  all(null);

  const SleepHistoryRange(this.dayCount);

  /// Number of calendar days in the window, or null for all history.
  final int? dayCount;

  /// Whether reading the whole range needs Health Connect's full history.
  ///
  /// Android only exposes records from the last 30 days without that
  /// permission, so Week and Month never need it.
  bool get requiresFullHistory => dayCount == null || dayCount! > 30;
}

/// One local wake day with the sessions that ended on it.
class SleepHistoryDay {
  const SleepHistoryDay({
    required this.date,
    required this.sessions,
    required this.total,
  });

  /// Local midnight of the day the sessions ended.
  final DateTime date;

  /// Sessions newest first.
  final List<SleepSession> sessions;

  /// Sum of the sessions, with negative durations clamped to zero.
  final Duration total;

  /// Number of closed sessions that ended on this day.
  int get sessionsCount => sessions.length;

  /// Whether the night is split into more than one session.
  bool get split => sessions.length > 1;

  /// The earliest start among sessions with a positive duration, in local
  /// time.
  ///
  /// A negative session is clock skew, not sleep, so it does not define the
  /// rhythm of the night. Null when no session recorded actual sleep.
  DateTime? get bedtime {
    SleepSession? earliest;
    for (final session in sessions) {
      if (session.duration <= Duration.zero) continue;
      if (earliest == null || session.startedAt.isBefore(earliest.startedAt)) {
        earliest = session;
      }
    }
    return earliest?.startedAt.toLocal();
  }

  /// The latest end among sessions with a positive duration, in local time.
  ///
  /// Null when no session recorded actual sleep.
  DateTime? get wake {
    SleepSession? latest;
    for (final session in sessions) {
      if (session.duration <= Duration.zero) continue;
      final endedAt = session.endedAt;
      if (endedAt == null) continue;
      if (latest == null || endedAt.isAfter(latest.endedAt!)) {
        latest = session;
      }
    }
    return latest?.endedAt?.toLocal();
  }

  /// Wall-clock time from [bedtime] to [wake], including any gap.
  ///
  /// Null when the day has no positive session. A clock-skewed end before the
  /// start is clamped to zero.
  Duration? get timeInBed {
    final start = bedtime;
    final end = wake;
    if (start == null || end == null) return null;
    final elapsed = end.difference(start);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Time inside [timeInBed] that the positive sessions do not cover.
  ///
  /// Overlapping sessions clamp the gap to zero.
  Duration get gaps {
    final inBed = timeInBed;
    if (inBed == null) return Duration.zero;
    final gap = inBed - total;
    return gap.isNegative ? Duration.zero : gap;
  }
}

/// One session as shown in the history list, tied to its wake day.
class SleepHistoryEntry {
  const SleepHistoryEntry({required this.date, required this.session});

  /// Local midnight of the wake day.
  final DateTime date;

  final SleepSession session;
}

/// Sleep grouped by local wake day for the selected range.
class SleepHistory {
  const SleepHistory({
    required this.days,
    required this.entries,
    required this.total,
    required this.average,
  });

  /// Days with data, newest first.
  final List<SleepHistoryDay> days;

  /// Every session in display order: newest day first, newest session first
  /// within a day.
  final List<SleepHistoryEntry> entries;

  /// Sum of every session in the range.
  final Duration total;

  /// Mean of the days with data, or null when the range is empty.
  final Duration? average;

  bool get hasData => days.isNotEmpty;

  /// Number of days with data, not the number of sessions.
  int get nights => days.length;
}

/// Groups closed sessions by the local day they ended and filters a range.
///
/// The rules match the Home summary: a session belongs entirely to its wake
/// day, only closed sessions count, and the average divides by the days with
/// data. A day with several sessions counts once for the average but sums all
/// its durations for the total.
///
/// Sessions ending after today are ignored. Days are built with calendar
/// arithmetic, not 24-hour durations, so DST transitions do not merge or shift
/// buckets.
SleepHistory buildSleepHistory({
  required DateTime now,
  required Iterable<SleepSession> sessions,
  required SleepHistoryRange range,
}) {
  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final end = DateTime(today.year, today.month, today.day + 1);
  final dayCount = range.dayCount;
  final start = dayCount == null
      ? null
      : DateTime(today.year, today.month, today.day - (dayCount - 1));

  final sessionsByDay = <DateTime, List<SleepSession>>{};
  for (final session in sessions) {
    final endedAt = session.endedAt;
    if (endedAt == null) continue;

    final localEnd = endedAt.toLocal();
    if (!localEnd.isBefore(end)) continue;
    if (start != null && localEnd.isBefore(start)) continue;

    final day = DateTime(localEnd.year, localEnd.month, localEnd.day);
    sessionsByDay.putIfAbsent(day, () => <SleepSession>[]).add(session);
  }

  final dayDates = sessionsByDay.keys.toList()..sort((a, b) => b.compareTo(a));

  final days = <SleepHistoryDay>[];
  var totalMicros = 0;

  for (final date in dayDates) {
    final daySessions = sessionsByDay[date]!
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    var dayMicros = 0;
    for (final session in daySessions) {
      final micros = session.duration.inMicroseconds;
      if (micros > 0) dayMicros += micros;
    }
    totalMicros += dayMicros;

    days.add(
      SleepHistoryDay(
        date: date,
        sessions: List.unmodifiable(daySessions),
        total: Duration(microseconds: dayMicros),
      ),
    );
  }

  final entries = <SleepHistoryEntry>[
    for (final day in days)
      for (final session in day.sessions)
        SleepHistoryEntry(date: day.date, session: session),
  ];

  return SleepHistory(
    days: List.unmodifiable(days),
    entries: List.unmodifiable(entries),
    total: Duration(microseconds: totalMicros),
    average: days.isEmpty
        ? null
        : Duration(microseconds: totalMicros ~/ days.length),
  );
}
