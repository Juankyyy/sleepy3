import 'sleep_session.dart';

/// Number of local days shown in the Home summary.
const recentSleepSummaryDayCount = 3;

/// The closed sleep recorded for one local calendar day.
class SleepDaySummary {
  const SleepDaySummary({required this.date, required this.duration});

  /// Local midnight of the day the sessions ended.
  final DateTime date;

  /// Total closed sleep for the day, or null when no session ended that day.
  ///
  /// A null is different from [Duration.zero]: a closed session can legitimately
  /// last no time at all after clock skew is clamped.
  final Duration? duration;

  bool get hasData => duration != null;
}

/// Closed sleep for the recent days, newest day last.
class RecentSleepSummary {
  const RecentSleepSummary({required this.days, required this.average});

  /// One entry per local day, oldest first, ending with today.
  final List<SleepDaySummary> days;

  /// Mean of the days with data, or null when no day has data.
  final Duration? average;

  bool get hasData => average != null;

  /// The entry [daysAgo] days before today (0 is today).
  SleepDaySummary dayBefore(int daysAgo) => days[days.length - 1 - daysAgo];
}

/// Groups closed sessions by the local day they ended.
///
/// A session belongs entirely to the day of its wake time, even when it started
/// the day before. Only closed sessions count; an open session has no known
/// duration yet. The average divides by the days with data, not by
/// [dayCount], so a missing night is ignored instead of counted as zero.
///
/// Sessions outside the window are skipped before grouping, so the caller can
/// pass the whole history without paying for old nights on every clock tick.
///
/// Days are built with calendar arithmetic (`day - 1`) instead of subtracting
/// 24-hour durations, so a DST transition does not shift or merge buckets.
RecentSleepSummary buildRecentSleepSummary({
  required DateTime now,
  required Iterable<SleepSession> sessions,
  int dayCount = recentSleepSummaryDayCount,
}) {
  assert(dayCount > 0);

  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final windowStart = DateTime(
    today.year,
    today.month,
    today.day - (dayCount - 1),
  );
  final windowEnd = DateTime(today.year, today.month, today.day + 1);

  final microsByDay = <DateTime, int>{};
  for (final session in sessions) {
    final endedAt = session.endedAt;
    if (endedAt == null) continue;

    final localEnd = endedAt.toLocal();
    if (localEnd.isBefore(windowStart) || !localEnd.isBefore(windowEnd)) {
      continue;
    }

    final day = DateTime(localEnd.year, localEnd.month, localEnd.day);
    final duration = session.duration;
    final micros = duration.isNegative ? 0 : duration.inMicroseconds;
    microsByDay.update(day, (total) => total + micros, ifAbsent: () => micros);
  }

  final days = <SleepDaySummary>[];
  var totalMicros = 0;
  var daysWithData = 0;

  for (var offset = dayCount - 1; offset >= 0; offset--) {
    final date = DateTime(today.year, today.month, today.day - offset);
    final micros = microsByDay[date];
    if (micros != null) {
      totalMicros += micros;
      daysWithData++;
    }
    days.add(
      SleepDaySummary(
        date: date,
        duration: micros == null ? null : Duration(microseconds: micros),
      ),
    );
  }

  return RecentSleepSummary(
    days: List.unmodifiable(days),
    average: daysWithData == 0
        ? null
        : Duration(microseconds: totalMicros ~/ daysWithData),
  );
}
