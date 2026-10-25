import 'sleep_session.dart';

/// The window of sleep history shown on the Stats screen.
enum SleepHistoryRange {
  /// Today and the six previous local days.
  sevenDays(7),

  /// Today and the twenty-nine previous local days.
  thirtyDays(30),

  /// Every stored night up to today.
  all(null);

  const SleepHistoryRange(this.dayCount);

  /// Number of calendar days in the window, or null for all history.
  final int? dayCount;
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

  /// Sessions in chronological order.
  final List<SleepSession> sessions;

  /// Sum of the sessions, with negative durations clamped to zero.
  final Duration total;
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

  /// Every session in display order: newest day first, chronological within a
  /// day.
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
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

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
