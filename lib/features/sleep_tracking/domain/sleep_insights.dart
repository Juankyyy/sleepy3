import 'sleep_clock.dart';
import 'sleep_goal.dart';
import 'sleep_history.dart';
import 'sleep_session.dart';

const _daysPerWeek = 7;

/// The five bands used by the sleep duration distribution.
///
/// The boundaries are [0, 6), [6, 7), [7, 8), [8, 9) and [9, infinity) hours.
enum SleepDurationBand {
  underSixHours,
  sixToSevenHours,
  sevenToEightHours,
  eightToNineHours,
  nineHoursPlus,
}

/// How many recorded nights fall in one duration band.
class SleepDurationBucket {
  const SleepDurationBucket({required this.band, required this.nights});

  final SleepDurationBand band;

  /// Number of nights with a recorded total in this band.
  final int nights;
}

/// One local day in the insights window, including days with no data.
class SleepInsightsDay {
  const SleepInsightsDay({required this.date, this.history});

  /// Local midnight of the day the sessions ended.
  final DateTime date;

  /// The grouped history for this day, or null when no session ended on it.
  final SleepHistoryDay? history;

  bool get hasData => history != null;

  /// Number of closed sessions that ended on this day.
  int get sessionsCount => history?.sessionsCount ?? 0;

  /// Whether the night is split into more than one session.
  bool get split => history?.split ?? false;

  /// Sum of the positive sessions, clamped at zero.
  Duration get total => history?.total ?? Duration.zero;

  /// Earliest start among the positive sessions, in local time.
  DateTime? get bedtime => history?.bedtime;

  /// Latest end among the positive sessions, in local time.
  DateTime? get wake => history?.wake;

  /// Wall-clock time from [bedtime] to [wake], including gaps.
  Duration? get timeInBed => history?.timeInBed;

  /// Time inside [timeInBed] not covered by positive sessions.
  Duration get gaps => history?.gaps ?? Duration.zero;
}

/// The average duration for one weekday.
class SleepWeekdayStat {
  const SleepWeekdayStat({
    required this.weekday,
    required this.nights,
    required this.average,
  });

  /// [DateTime.monday] through [DateTime.sunday].
  final int weekday;

  /// Number of recorded nights for this weekday.
  final int nights;

  /// Mean total sleep of those nights.
  final Duration average;
}

/// How the selected range compares with the period immediately before it.
class SleepInsightsComparison {
  const SleepInsightsComparison({
    required this.previousAverage,
    required this.averageDelta,
    required this.previousNights,
    required this.previousCoverage,
  });

  /// Mean sleep of the previous window.
  final Duration previousAverage;

  /// Current mean minus previous mean. Positive means more sleep now.
  final Duration averageDelta;

  /// Recorded nights in the previous window.
  final int previousNights;

  /// Recorded days divided by the days of the previous window, from 0 to 1.
  final double previousCoverage;
}

/// One bucket of the duration and sleep-window charts.
///
/// A daily bucket covers one wake day, weekly buckets cover seven calendar days
/// and monthly buckets follow calendar months. The first and last bucket of a
/// window can be shorter.
class SleepChartBucket {
  const SleepChartBucket({
    required this.start,
    required this.endExclusive,
    required this.recordedDays,
    required this.sessionsCount,
    required this.averageDuration,
    required this.averageBedtime,
    required this.averageWake,
    required this.earliestBedtime,
    required this.latestBedtime,
    required this.earliestWake,
    required this.latestWake,
    required this.splitNights,
  });

  /// Local midnight of the first day in the bucket.
  final DateTime start;

  /// Local midnight after the last day in the bucket.
  final DateTime endExclusive;

  /// Days with data in the bucket.
  final int recordedDays;

  /// Closed sessions across every recorded day in the bucket.
  final int sessionsCount;

  /// Mean sleep per recorded night, or null when the bucket is empty.
  ///
  /// Weekly and monthly buckets average the nights instead of summing them,
  /// so every bucket is comparable with the 8-hour goal.
  final Duration? averageDuration;

  /// Circular mean of the bedtimes, as time since local midnight.
  final Duration? averageBedtime;

  /// Circular mean of the wake times, as time since local midnight.
  final Duration? averageWake;

  /// Earliest bedtime around [averageBedtime].
  ///
  /// Times may wrap: with a mean near midnight, [earliestBedtime] is later on
  /// the clock than [latestBedtime].
  final Duration? earliestBedtime;

  /// Latest bedtime around [averageBedtime].
  final Duration? latestBedtime;

  /// Earliest wake time around [averageWake].
  final Duration? earliestWake;

  /// Latest wake time around [averageWake].
  final Duration? latestWake;

  /// Nights in the bucket split across more than one session.
  final int splitNights;

  bool get hasData => recordedDays > 0;
}

/// Everything Stats can say about the selected range.
///
/// The builder uses the same wake-day grouping as [SleepHistory]: a session
/// belongs to the local day it ended, only closed sessions count, and sessions
/// ending after today are ignored. Days are built with calendar arithmetic, so
/// a DST transition does not merge or shift buckets.
class SleepInsights {
  const SleepInsights({
    required this.range,
    required this.windowStart,
    required this.windowEndExclusive,
    required this.days,
    required this.recordedDays,
    required this.coverage,
    required this.total,
    required this.average,
    required this.median,
    required this.bestDay,
    required this.worstDay,
    required this.goalHitRate,
    required this.goalNights,
    required this.shortNights,
    required this.longNights,
    required this.sleepBalance,
    required this.currentGoalStreak,
    required this.longestGoalStreak,
    required this.averageBedtime,
    required this.averageWake,
    required this.bedtimeVariability,
    required this.wakeVariability,
    required this.averageSessionsPerNight,
    required this.splitNights,
    required this.weekdayStats,
    required this.durationBuckets,
    required this.comparison,
    required this.chartBuckets,
  });

  final SleepHistoryRange range;

  /// Local midnight of the first day in the window.
  final DateTime windowStart;

  /// Local midnight after the last day in the window.
  final DateTime windowEndExclusive;

  /// Every day in the window, newest first, including days with no data.
  final List<SleepInsightsDay> days;

  /// Days with at least one closed session.
  final int recordedDays;

  /// [recordedDays] divided by the days in the window, from 0 to 1.
  final double coverage;

  /// Sum of the positive sessions in the window.
  final Duration total;

  /// Mean of the days with data, or null when the window is empty.
  final Duration? average;

  /// Median total of the days with data, or null when the window is empty.
  final Duration? median;

  /// The recorded day with the longest total, or null when the window is
  /// empty. Ties keep the most recent day.
  final SleepInsightsDay? bestDay;

  /// The recorded day with the shortest total, or null when the window is
  /// empty. Ties keep the most recent day.
  final SleepInsightsDay? worstDay;

  /// Recorded nights that reached the 8-hour goal, divided by
  /// [recordedDays]. Null when the window is empty.
  final double? goalHitRate;

  /// Recorded nights whose total is at least the 8-hour goal.
  final int goalNights;

  /// Recorded nights below the goal.
  final int shortNights;

  /// Recorded nights above the goal.
  final int longNights;

  /// [total] minus eight hours for every recorded night. Positive is a
  /// surplus; negative is a debt. Null when the window is empty.
  final Duration? sleepBalance;

  /// Consecutive goal nights ending today or yesterday.
  ///
  /// A missing day or a missed goal breaks the run. When the last recorded
  /// night is older than yesterday, the current streak is zero.
  final int currentGoalStreak;

  /// Longest run of consecutive goal nights inside the selected window.
  final int longestGoalStreak;

  /// Circular mean bedtime, as time since local midnight.
  final Duration? averageBedtime;

  /// Circular mean wake time, as time since local midnight.
  final Duration? averageWake;

  /// Circular standard deviation of the bedtimes, in minutes. Null with fewer
  /// than two recorded nights.
  final Duration? bedtimeVariability;

  /// Circular standard deviation of the wake times, in minutes. Null with
  /// fewer than two recorded nights.
  final Duration? wakeVariability;

  /// Closed sessions divided by recorded days.
  final double? averageSessionsPerNight;

  /// Days with more than one closed session.
  final int splitNights;

  /// Seven entries, Monday first. A weekday with no data is null.
  final List<SleepWeekdayStat?> weekdayStats;

  /// The five duration bands, always in [SleepDurationBand] order.
  final List<SleepDurationBucket> durationBuckets;

  /// The previous period for fixed ranges, or null in All, when the previous
  /// period has no data, or when its coverage is below 50 %.
  final SleepInsightsComparison? comparison;

  /// Daily, weekly or monthly buckets for the charts, oldest first.
  final List<SleepChartBucket> chartBuckets;

  bool get hasData => recordedDays > 0;

  int get windowDays => days.length;
}

/// Builds the advanced Stats metrics for [range].
///
/// [now] is injected by [LocalDayBuilder]; this function never reads the clock
/// itself. The open session is ignored because it has no known duration.
SleepInsights buildSleepInsights({
  required DateTime now,
  required Iterable<SleepSession> sessions,
  required SleepHistoryRange range,
}) {
  final sessionList = sessions.toList(growable: false);
  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final windowEndExclusive = DateTime(today.year, today.month, today.day + 1);

  final history = buildSleepHistory(
    now: now,
    sessions: sessionList,
    range: range,
  );

  final dayCount = range.dayCount;
  final windowStart = dayCount != null
      ? DateTime(today.year, today.month, today.day - (dayCount - 1))
      : history.days.isEmpty
      ? today
      : history.days.last.date;

  final days = _buildDays(
    windowStart: windowStart,
    windowEndExclusive: windowEndExclusive,
    history: history,
  );

  final recordedDays = history.nights;
  final goalNights = days
      .where((day) => day.hasData && day.total >= dailySleepGoal)
      .length;
  final shortNights = days
      .where((day) => day.hasData && day.total < dailySleepGoal)
      .length;
  final longNights = days
      .where((day) => day.hasData && day.total > dailySleepGoal)
      .length;

  final bedtimes = <DateTime>[];
  final wakes = <DateTime>[];
  var sessionCount = 0;
  var splitNights = 0;
  for (final day in days) {
    if (!day.hasData) continue;
    sessionCount += day.sessionsCount;
    if (day.split) splitNights++;

    final bedtime = day.bedtime;
    if (bedtime != null) bedtimes.add(bedtime);
    final wake = day.wake;
    if (wake != null) wakes.add(wake);
  }

  final bedtimeSummary = summarizeSleepClockTimes(bedtimes);
  final wakeSummary = summarizeSleepClockTimes(wakes);
  final streaks = _goalStreaks(days);
  final bestAndWorst = _bestAndWorst(days);

  return SleepInsights(
    range: range,
    windowStart: windowStart,
    windowEndExclusive: windowEndExclusive,
    days: days,
    recordedDays: recordedDays,
    coverage: days.isEmpty ? 0 : recordedDays / days.length,
    total: history.total,
    average: history.average,
    median: _median(days),
    bestDay: bestAndWorst.best,
    worstDay: bestAndWorst.worst,
    goalHitRate: recordedDays == 0 ? null : goalNights / recordedDays,
    goalNights: goalNights,
    shortNights: shortNights,
    longNights: longNights,
    sleepBalance: recordedDays == 0
        ? null
        : history.total - dailySleepGoal * recordedDays,
    currentGoalStreak: streaks.current,
    longestGoalStreak: streaks.longest,
    averageBedtime: bedtimeSummary.average,
    averageWake: wakeSummary.average,
    bedtimeVariability: bedtimeSummary.variability,
    wakeVariability: wakeSummary.variability,
    averageSessionsPerNight: recordedDays == 0
        ? null
        : sessionCount / recordedDays,
    splitNights: splitNights,
    weekdayStats: _weekdayStats(days),
    durationBuckets: _durationBuckets(days),
    comparison: _comparison(
      range: range,
      today: today,
      sessions: sessionList,
      currentAverage: history.average,
    ),
    chartBuckets: _chartBuckets(
      range: range,
      history: history,
      windowStart: windowStart,
      windowEndExclusive: windowEndExclusive,
      windowDays: days.length,
    ),
  );
}

/// Every day in the window, newest first, paired with its history when it has
/// data.
List<SleepInsightsDay> _buildDays({
  required DateTime windowStart,
  required DateTime windowEndExclusive,
  required SleepHistory history,
}) {
  final historyByDate = {for (final day in history.days) day.date: day};
  final days = <SleepInsightsDay>[];

  for (
    var date = windowStart;
    date.isBefore(windowEndExclusive);
    date = DateTime(date.year, date.month, date.day + 1)
  ) {
    days.add(SleepInsightsDay(date: date, history: historyByDate[date]));
  }

  return List.unmodifiable(days.reversed);
}

Duration? _median(List<SleepInsightsDay> days) {
  final totals = <int>[
    for (final day in days)
      if (day.hasData) day.total.inMicroseconds,
  ]..sort();
  if (totals.isEmpty) return null;

  final middle = totals.length ~/ 2;
  if (totals.length.isOdd) {
    return Duration(microseconds: totals[middle]);
  }
  return Duration(microseconds: (totals[middle - 1] + totals[middle]) ~/ 2);
}

({SleepInsightsDay? best, SleepInsightsDay? worst}) _bestAndWorst(
  List<SleepInsightsDay> days,
) {
  SleepInsightsDay? best;
  SleepInsightsDay? worst;

  // Days are newest first, so a strict comparison keeps the most recent day
  // when two days tie.
  for (final day in days) {
    if (!day.hasData) continue;
    if (best == null || day.total > best.total) best = day;
    if (worst == null || day.total < worst.total) worst = day;
  }

  return (best: best, worst: worst);
}

({int current, int longest}) _goalStreaks(List<SleepInsightsDay> days) {
  var longest = 0;
  var run = 0;
  for (final day in days.reversed) {
    if (day.hasData && day.total >= dailySleepGoal) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }

  var current = 0;
  if (days.isNotEmpty) {
    var start = -1;
    if (days[0].hasData) {
      start = 0;
    } else if (days.length > 1 && days[1].hasData) {
      start = 1;
    }

    for (var index = start; index >= 0 && index < days.length; index++) {
      final day = days[index];
      if (!day.hasData || day.total < dailySleepGoal) break;
      current++;
    }
  }

  return (current: current, longest: longest);
}

List<SleepWeekdayStat?> _weekdayStats(List<SleepInsightsDay> days) {
  final totals = List<int>.filled(_daysPerWeek, 0);
  final nights = List<int>.filled(_daysPerWeek, 0);

  for (final day in days) {
    if (!day.hasData) continue;
    final index = day.date.weekday - DateTime.monday;
    totals[index] += day.total.inMicroseconds;
    nights[index]++;
  }

  return List<SleepWeekdayStat?>.unmodifiable([
    for (var index = 0; index < _daysPerWeek; index++)
      nights[index] == 0
          ? null
          : SleepWeekdayStat(
              weekday: index + DateTime.monday,
              nights: nights[index],
              average: Duration(microseconds: totals[index] ~/ nights[index]),
            ),
  ]);
}

List<SleepDurationBucket> _durationBuckets(List<SleepInsightsDay> days) {
  final counts = List<int>.filled(SleepDurationBand.values.length, 0);

  for (final day in days) {
    if (!day.hasData) continue;
    counts[_bandFor(day.total).index]++;
  }

  return List<SleepDurationBucket>.unmodifiable([
    for (final band in SleepDurationBand.values)
      SleepDurationBucket(band: band, nights: counts[band.index]),
  ]);
}

SleepDurationBand _bandFor(Duration total) {
  if (total < const Duration(hours: 6)) return SleepDurationBand.underSixHours;
  if (total < const Duration(hours: 7)) {
    return SleepDurationBand.sixToSevenHours;
  }
  if (total < const Duration(hours: 8)) {
    return SleepDurationBand.sevenToEightHours;
  }
  if (total < const Duration(hours: 9)) {
    return SleepDurationBand.eightToNineHours;
  }
  return SleepDurationBand.nineHoursPlus;
}

SleepInsightsComparison? _comparison({
  required SleepHistoryRange range,
  required DateTime today,
  required List<SleepSession> sessions,
  required Duration? currentAverage,
}) {
  final dayCount = range.dayCount;
  if (dayCount == null || currentAverage == null) return null;

  final previousNow = DateTime(today.year, today.month, today.day - dayCount);
  final previous = buildSleepHistory(
    now: previousNow,
    sessions: sessions,
    range: range,
  );
  final previousAverage = previous.average;
  if (previousAverage == null) return null;

  final coverage = previous.nights / dayCount;
  if (coverage < 0.5) return null;

  return SleepInsightsComparison(
    previousAverage: previousAverage,
    averageDelta: currentAverage - previousAverage,
    previousNights: previous.nights,
    previousCoverage: coverage,
  );
}

enum _BucketMode { daily, weekly, monthly }

List<SleepChartBucket> _chartBuckets({
  required SleepHistoryRange range,
  required SleepHistory history,
  required DateTime windowStart,
  required DateTime windowEndExclusive,
  required int windowDays,
}) {
  final mode = switch (range) {
    SleepHistoryRange.week || SleepHistoryRange.month => _BucketMode.daily,
    SleepHistoryRange.threeMonths => _BucketMode.weekly,
    SleepHistoryRange.year => _BucketMode.monthly,
    SleepHistoryRange.all =>
      windowDays > 180 ? _BucketMode.monthly : _BucketMode.weekly,
  };

  final buckets = <SleepChartBucket>[];
  switch (mode) {
    case _BucketMode.daily:
      for (
        var date = windowStart;
        date.isBefore(windowEndExclusive);
        date = DateTime(date.year, date.month, date.day + 1)
      ) {
        final end = DateTime(date.year, date.month, date.day + 1);
        buckets.add(
          _buildBucket(
            start: date,
            endExclusive: end,
            historyDays: history.days,
          ),
        );
      }
    case _BucketMode.weekly:
      var start = windowStart;
      while (start.isBefore(windowEndExclusive)) {
        final next = DateTime(start.year, start.month, start.day + 7);
        final end = next.isBefore(windowEndExclusive)
            ? next
            : windowEndExclusive;
        buckets.add(
          _buildBucket(
            start: start,
            endExclusive: end,
            historyDays: history.days,
          ),
        );
        start = next;
      }
    case _BucketMode.monthly:
      var cursor = DateTime(windowStart.year, windowStart.month);
      while (cursor.isBefore(windowEndExclusive)) {
        final start = cursor.isBefore(windowStart) ? windowStart : cursor;
        final next = DateTime(cursor.year, cursor.month + 1);
        final end = next.isBefore(windowEndExclusive)
            ? next
            : windowEndExclusive;
        buckets.add(
          _buildBucket(
            start: start,
            endExclusive: end,
            historyDays: history.days,
          ),
        );
        cursor = next;
      }
  }

  return List<SleepChartBucket>.unmodifiable(buckets);
}

SleepChartBucket _buildBucket({
  required DateTime start,
  required DateTime endExclusive,
  required List<SleepHistoryDay> historyDays,
}) {
  final days = [
    for (final day in historyDays)
      if (!day.date.isBefore(start) && day.date.isBefore(endExclusive)) day,
  ];

  var totalMicros = 0;
  var sessionsCount = 0;
  var splitNights = 0;
  final bedtimes = <DateTime>[];
  final wakes = <DateTime>[];
  for (final day in days) {
    totalMicros += day.total.inMicroseconds;
    sessionsCount += day.sessionsCount;
    if (day.split) splitNights++;

    final bedtime = day.bedtime;
    if (bedtime != null) bedtimes.add(bedtime);
    final wake = day.wake;
    if (wake != null) wakes.add(wake);
  }

  final bedtimeSummary = summarizeSleepClockTimes(bedtimes);
  final wakeSummary = summarizeSleepClockTimes(wakes);

  return SleepChartBucket(
    start: start,
    endExclusive: endExclusive,
    recordedDays: days.length,
    sessionsCount: sessionsCount,
    averageDuration: days.isEmpty
        ? null
        : Duration(microseconds: totalMicros ~/ days.length),
    averageBedtime: bedtimeSummary.average,
    averageWake: wakeSummary.average,
    earliestBedtime: bedtimeSummary.earliest,
    latestBedtime: bedtimeSummary.latest,
    earliestWake: wakeSummary.earliest,
    latestWake: wakeSummary.latest,
    splitNights: splitNights,
  );
}
