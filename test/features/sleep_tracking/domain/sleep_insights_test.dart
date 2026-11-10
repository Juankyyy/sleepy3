import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_history.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_insights.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  final now = DateTime(2026, 10, 21, 10);

  DateTime daysAgo(int days) => DateTime(now.year, now.month, now.day - days);

  SleepSession closed(DateTime start, DateTime end) =>
      SleepSession(startedAt: start, endedAt: end);

  /// A night ending at 07:00 on [day] with [duration] of sleep.
  SleepSession nightEnding(DateTime day, Duration duration) {
    final end = DateTime(day.year, day.month, day.day, 7);
    return closed(end.subtract(duration), end);
  }

  SleepInsights insightsFor(
    List<SleepSession> sessions, {
    SleepHistoryRange range = SleepHistoryRange.week,
    DateTime? at,
  }) {
    return buildSleepInsights(now: at ?? now, sessions: sessions, range: range);
  }

  test('builds an empty week with every day and no invented metrics', () {
    final insights = insightsFor(const []);

    expect(insights.windowStart, DateTime(2026, 10, 15));
    expect(insights.windowEndExclusive, DateTime(2026, 10, 22));
    expect(insights.windowDays, 7);
    expect(insights.days.map((day) => day.date), [
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 20),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 18),
      DateTime(2026, 10, 17),
      DateTime(2026, 10, 16),
      DateTime(2026, 10, 15),
    ]);
    expect(insights.days.every((day) => !day.hasData), isTrue);

    expect(insights.recordedDays, 0);
    expect(insights.coverage, 0);
    expect(insights.total, Duration.zero);
    expect(insights.average, isNull);
    expect(insights.median, isNull);
    expect(insights.bestDay, isNull);
    expect(insights.worstDay, isNull);
    expect(insights.goalHitRate, isNull);
    expect(insights.goalNights, 0);
    expect(insights.shortNights, 0);
    expect(insights.longNights, 0);
    expect(insights.sleepBalance, isNull);
    expect(insights.currentGoalStreak, 0);
    expect(insights.longestGoalStreak, 0);
    expect(insights.averageBedtime, isNull);
    expect(insights.averageWake, isNull);
    expect(insights.bedtimeVariability, isNull);
    expect(insights.wakeVariability, isNull);
    expect(insights.averageSessionsPerNight, isNull);
    expect(insights.weekdayStats, hasLength(7));
    expect(insights.weekdayStats.every((stat) => stat == null), isTrue);
    expect(
      insights.durationBuckets.map((bucket) => bucket.nights),
      everyElement(0),
    );
    expect(insights.comparison, isNull);
    expect(insights.chartBuckets, hasLength(7));
    expect(insights.chartBuckets.every((bucket) => !bucket.hasData), isTrue);
  });

  test('a night exactly at the goal counts as met', () {
    final insights = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 8)),
    ]);

    expect(insights.recordedDays, 1);
    expect(insights.coverage, closeTo(1 / 7, 1e-9));
    expect(insights.total, const Duration(hours: 8));
    expect(insights.average, const Duration(hours: 8));
    expect(insights.median, const Duration(hours: 8));
    expect(insights.bestDay?.date, daysAgo(0));
    expect(insights.worstDay?.date, daysAgo(0));
    expect(insights.goalHitRate, 1);
    expect(insights.goalNights, 1);
    expect(insights.shortNights, 0);
    expect(insights.longNights, 0);
    expect(insights.sleepBalance, Duration.zero);
    expect(insights.currentGoalStreak, 1);
    expect(insights.longestGoalStreak, 1);
    expect(insights.averageBedtime, const Duration(hours: 23));
    expect(insights.averageWake, const Duration(hours: 7));
    expect(insights.bedtimeVariability, isNull);
    expect(insights.wakeVariability, isNull);
    expect(insights.averageSessionsPerNight, 1);

    final weekday = insights.weekdayStats[daysAgo(0).weekday - 1];
    expect(weekday, isNotNull);
    expect(weekday!.nights, 1);
    expect(weekday.average, const Duration(hours: 8));
    expect(
      insights.durationBuckets[SleepDurationBand.eightToNineHours.index].nights,
      1,
    );

    final lastBucket = insights.chartBuckets.last;
    expect(lastBucket.start, daysAgo(0));
    expect(lastBucket.recordedDays, 1);
    expect(lastBucket.sessionsCount, 1);
    expect(lastBucket.averageDuration, const Duration(hours: 8));
    expect(lastBucket.averageBedtime, const Duration(hours: 23));
    expect(lastBucket.averageWake, const Duration(hours: 7));
  });

  test('averages recorded days, takes the median and reports the balance', () {
    final insights = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 9)),
      nightEnding(daysAgo(1), const Duration(hours: 6)),
      nightEnding(daysAgo(3), const Duration(hours: 8)),
    ]);

    expect(insights.recordedDays, 3);
    expect(insights.coverage, closeTo(3 / 7, 1e-9));
    expect(insights.total, const Duration(hours: 23));
    expect(insights.average, const Duration(hours: 7, minutes: 40));
    expect(insights.median, const Duration(hours: 8));
    expect(insights.bestDay?.date, daysAgo(0));
    expect(insights.bestDay?.total, const Duration(hours: 9));
    expect(insights.worstDay?.date, daysAgo(1));
    expect(insights.worstDay?.total, const Duration(hours: 6));
    expect(insights.goalHitRate, closeTo(2 / 3, 1e-9));
    expect(insights.goalNights, 2);
    expect(insights.shortNights, 1);
    expect(insights.longNights, 1);
    expect(insights.sleepBalance, const Duration(hours: -1));
    expect(insights.currentGoalStreak, 1);
    expect(insights.longestGoalStreak, 1);

    final buckets = insights.durationBuckets;
    expect(buckets[SleepDurationBand.sixToSevenHours.index].nights, 1);
    expect(buckets[SleepDurationBand.eightToNineHours.index].nights, 1);
    expect(buckets[SleepDurationBand.nineHoursPlus.index].nights, 1);
  });

  test('reports a surplus when the night is longer than the goal', () {
    final insights = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 10)),
    ]);

    expect(insights.sleepBalance, const Duration(hours: 2));
    expect(insights.goalNights, 1);
    expect(insights.longNights, 1);
    expect(insights.shortNights, 0);
    expect(insights.goalHitRate, 1);
  });

  test('uses the even median when two nights are recorded', () {
    final insights = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 8)),
      nightEnding(daysAgo(1), const Duration(hours: 6)),
    ]);

    expect(insights.median, const Duration(hours: 7));
    expect(insights.average, const Duration(hours: 7));
  });

  test('keeps the current streak when the last night is yesterday', () {
    final insights = insightsFor([
      nightEnding(daysAgo(1), const Duration(hours: 8)),
      nightEnding(daysAgo(2), const Duration(hours: 8)),
    ]);

    expect(insights.currentGoalStreak, 2);
    expect(insights.longestGoalStreak, 2);
  });

  test(
    'drops the current streak when the last night is older than yesterday',
    () {
      final insights = insightsFor([
        nightEnding(daysAgo(2), const Duration(hours: 8)),
        nightEnding(daysAgo(3), const Duration(hours: 8)),
      ]);

      expect(insights.currentGoalStreak, 0);
      expect(insights.longestGoalStreak, 2);
    },
  );

  test('a missing day breaks both streaks', () {
    final insights = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 8)),
      nightEnding(daysAgo(2), const Duration(hours: 8)),
    ]);

    expect(insights.currentGoalStreak, 1);
    expect(insights.longestGoalStreak, 1);
  });

  test('a missed goal breaks the current streak', () {
    final insights = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 7)),
      nightEnding(daysAgo(1), const Duration(hours: 8)),
    ]);

    expect(insights.currentGoalStreak, 0);
    expect(insights.longestGoalStreak, 1);
  });

  test('sums multiple sessions but uses the first bedtime and last wake', () {
    final first = closed(DateTime(2026, 10, 21, 1), DateTime(2026, 10, 21, 3));
    final second = closed(
      DateTime(2026, 10, 21, 4),
      DateTime(2026, 10, 21, 10),
    );
    final single = nightEnding(daysAgo(1), const Duration(hours: 8));
    final insights = insightsFor([first, second, single]);

    final day = insights.days.first;
    expect(day.sessionsCount, 2);
    expect(day.total, const Duration(hours: 8));
    expect(day.bedtime, DateTime(2026, 10, 21, 1));
    expect(day.wake, DateTime(2026, 10, 21, 10));
    expect(day.timeInBed, const Duration(hours: 9));
    expect(day.gaps, const Duration(hours: 1));

    expect(insights.recordedDays, 2);
    expect(insights.total, const Duration(hours: 16));
    expect(insights.average, const Duration(hours: 8));
    expect(insights.goalNights, 2);
    expect(insights.averageBedtime, Duration.zero);
    expect(insights.averageWake, const Duration(hours: 8, minutes: 30));
    expect(insights.averageSessionsPerNight, 1.5);
    expect(insights.chartBuckets.last.sessionsCount, 2);
  });

  test('uses a circular mean around midnight, never a naive average', () {
    final insights = insightsFor([
      closed(DateTime(2026, 10, 20, 23, 50), DateTime(2026, 10, 21, 7, 50)),
      closed(DateTime(2026, 10, 19, 0, 10), DateTime(2026, 10, 19, 8, 10)),
    ]);

    expect(insights.averageBedtime, Duration.zero);
    expect(insights.averageWake, const Duration(hours: 8));
    expect(insights.bedtimeVariability, const Duration(minutes: 10));
    expect(insights.wakeVariability, const Duration(minutes: 10));
  });

  test('keeps calendar buckets across a DST transition', () {
    // In Europe/Madrid the clocks move forward on 2026-03-29. The host may use
    // another zone, so the assertion follows the sessions' real durations.
    final first = closed(DateTime(2026, 3, 28, 23), DateTime(2026, 3, 29, 7));
    final second = closed(
      DateTime(2026, 3, 29, 23, 30),
      DateTime(2026, 3, 30, 7),
    );
    final insights = insightsFor([
      first,
      second,
    ], at: DateTime(2026, 3, 30, 10));

    expect(insights.days[0].date, DateTime(2026, 3, 30));
    expect(insights.days[1].date, DateTime(2026, 3, 29));
    expect(insights.recordedDays, 2);
    expect(insights.total, first.duration + second.duration);
    expect(
      insights.average,
      Duration(
        microseconds:
            (first.duration.inMicroseconds + second.duration.inMicroseconds) ~/
            2,
      ),
    );
    expect(insights.chartBuckets.last.start, DateTime(2026, 3, 30));
  });

  test('clamps negative durations and keeps them out of the rhythm', () {
    final valid = nightEnding(daysAgo(0), const Duration(hours: 8));
    final negative = closed(
      DateTime(2026, 10, 20, 7),
      DateTime(2026, 10, 20, 6),
    );
    final insights = insightsFor([valid, negative]);

    expect(insights.recordedDays, 2);
    expect(insights.total, const Duration(hours: 8));
    expect(insights.average, const Duration(hours: 4));
    expect(insights.median, const Duration(hours: 4));
    expect(insights.bestDay?.date, daysAgo(0));
    expect(insights.worstDay?.date, daysAgo(1));
    expect(insights.worstDay?.total, Duration.zero);
    expect(insights.goalNights, 1);
    expect(insights.shortNights, 1);
    expect(insights.sleepBalance, const Duration(hours: -8));
    expect(insights.averageBedtime, const Duration(hours: 23));
    expect(insights.averageWake, const Duration(hours: 7));
    expect(insights.bedtimeVariability, isNull);
    expect(insights.wakeVariability, isNull);
  });

  test('a day with only a negative session has no rhythm', () {
    final insights = insightsFor([
      closed(DateTime(2026, 10, 21, 7), DateTime(2026, 10, 21, 6)),
    ]);

    final day = insights.days.first;
    expect(day.hasData, isTrue);
    expect(day.total, Duration.zero);
    expect(day.bedtime, isNull);
    expect(day.wake, isNull);
    expect(day.timeInBed, isNull);
    expect(day.gaps, Duration.zero);
    expect(insights.recordedDays, 1);
    expect(insights.average, Duration.zero);
    expect(insights.median, Duration.zero);
    expect(insights.averageBedtime, isNull);
    expect(insights.averageWake, isNull);
    expect(insights.goalNights, 0);
    expect(insights.shortNights, 1);
    expect(insights.sleepBalance, const Duration(hours: -8));
  });

  test('ignores open and future sessions', () {
    final insights = insightsFor([
      SleepSession(startedAt: DateTime(2026, 10, 21, 9)),
      closed(DateTime(2026, 10, 22, 1), DateTime(2026, 10, 22, 7)),
      nightEnding(daysAgo(0), const Duration(hours: 8)),
    ]);

    expect(insights.recordedDays, 1);
    expect(insights.days.where((day) => day.hasData), hasLength(1));
    expect(insights.bestDay?.date, daysAgo(0));
  });

  test('builds the window for every range', () {
    final sessions = [
      nightEnding(daysAgo(10), const Duration(hours: 7)),
      nightEnding(daysAgo(0), const Duration(hours: 8)),
    ];

    for (final range in [
      SleepHistoryRange.week,
      SleepHistoryRange.month,
      SleepHistoryRange.threeMonths,
      SleepHistoryRange.year,
    ]) {
      final insights = insightsFor(sessions, range: range);
      expect(insights.range, range);
      expect(
        insights.windowStart,
        daysAgo(range.dayCount! - 1),
        reason: 'windowStart for $range',
      );
      expect(insights.windowEndExclusive, DateTime(2026, 10, 22));
      expect(insights.windowDays, range.dayCount);
      expect(insights.days.first.date, daysAgo(0));
      expect(insights.days.last.date, daysAgo(range.dayCount! - 1));
    }

    final all = insightsFor(sessions, range: SleepHistoryRange.all);
    expect(all.windowStart, daysAgo(10));
    expect(all.windowEndExclusive, DateTime(2026, 10, 22));
    expect(all.windowDays, 11);
    expect(all.recordedDays, 2);
    expect(all.coverage, closeTo(2 / 11, 1e-9));
    expect(all.days.first.date, daysAgo(0));
    expect(all.days.last.date, daysAgo(10));
  });

  test('an empty All window is just today', () {
    final insights = insightsFor(const [], range: SleepHistoryRange.all);

    expect(insights.windowStart, daysAgo(0));
    expect(insights.windowEndExclusive, DateTime(2026, 10, 22));
    expect(insights.windowDays, 1);
    expect(insights.recordedDays, 0);
    expect(insights.coverage, 0);
  });

  test('days without data stay in the window and lower the coverage', () {
    final insights = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 8)),
      nightEnding(daysAgo(4), const Duration(hours: 6)),
    ]);

    expect(insights.windowDays, 7);
    expect(insights.recordedDays, 2);
    expect(insights.coverage, closeTo(2 / 7, 1e-9));
    expect(insights.days.where((day) => !day.hasData), hasLength(5));
    expect(insights.goalHitRate, 0.5);
  });

  test('builds daily, weekly and monthly chart buckets', () {
    final week = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 8)),
    ]);
    expect(week.chartBuckets, hasLength(7));
    expect(week.chartBuckets.first.start, daysAgo(6));
    expect(week.chartBuckets.last.start, daysAgo(0));
    expect(week.chartBuckets.last.endExclusive, DateTime(2026, 10, 22));

    final month = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 8)),
    ], range: SleepHistoryRange.month);
    expect(month.chartBuckets, hasLength(30));
    expect(month.chartBuckets.first.start, daysAgo(29));
    expect(month.chartBuckets.last.start, daysAgo(0));

    final threeMonths = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 7)),
      nightEnding(daysAgo(1), const Duration(hours: 9)),
    ], range: SleepHistoryRange.threeMonths);
    expect(threeMonths.chartBuckets, hasLength(13));
    expect(threeMonths.chartBuckets.last.start, daysAgo(5));
    expect(threeMonths.chartBuckets.last.endExclusive, DateTime(2026, 10, 22));
    expect(threeMonths.chartBuckets.last.recordedDays, 2);
    expect(
      threeMonths.chartBuckets.last.averageDuration,
      const Duration(hours: 8),
    );
    expect(
      threeMonths.chartBuckets.fold<int>(
        0,
        (total, bucket) => total + bucket.recordedDays,
      ),
      2,
    );

    final year = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 7)),
      nightEnding(daysAgo(1), const Duration(hours: 9)),
    ], range: SleepHistoryRange.year);
    expect(year.chartBuckets, hasLength(13));
    expect(year.chartBuckets.first.start, daysAgo(364));
    expect(year.chartBuckets.first.endExclusive, DateTime(2025, 11, 1));
    expect(year.chartBuckets.last.start, DateTime(2026, 10, 1));
    expect(year.chartBuckets.last.endExclusive, DateTime(2026, 10, 22));
    expect(year.chartBuckets.last.recordedDays, 2);
    expect(year.chartBuckets.last.averageDuration, const Duration(hours: 8));
  });

  test('weekly buckets aggregate bedtime, wake and their spread', () {
    final insights = insightsFor([
      closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7)),
      closed(DateTime(2026, 10, 19, 22), DateTime(2026, 10, 20, 6)),
    ], range: SleepHistoryRange.threeMonths);

    final bucket = insights.chartBuckets.last;
    expect(bucket.recordedDays, 2);
    expect(bucket.averageDuration, const Duration(hours: 8));
    expect(bucket.averageBedtime, const Duration(hours: 22, minutes: 30));
    expect(bucket.averageWake, const Duration(hours: 6, minutes: 30));
    expect(bucket.earliestBedtime, const Duration(hours: 22));
    expect(bucket.latestBedtime, const Duration(hours: 23));
    expect(bucket.earliestWake, const Duration(hours: 6));
    expect(bucket.latestWake, const Duration(hours: 7));
  });

  test('All uses weekly buckets up to 180 days and monthly after that', () {
    final weekly = insightsFor([
      nightEnding(daysAgo(179), const Duration(hours: 8)),
      nightEnding(daysAgo(0), const Duration(hours: 8)),
    ], range: SleepHistoryRange.all);
    expect(weekly.windowDays, 180);
    expect(weekly.chartBuckets, hasLength(26));
    expect(weekly.chartBuckets.first.start, daysAgo(179));

    final monthly = insightsFor([
      nightEnding(daysAgo(180), const Duration(hours: 8)),
      nightEnding(daysAgo(0), const Duration(hours: 8)),
    ], range: SleepHistoryRange.all);
    expect(monthly.windowDays, 181);
    expect(monthly.chartBuckets, hasLength(7));
    expect(monthly.chartBuckets.first.start, daysAgo(180));
    expect(monthly.chartBuckets.last.start, DateTime(2026, 10, 1));
    expect(monthly.chartBuckets.last.endExclusive, DateTime(2026, 10, 22));
  });

  test('compares with the previous period only when it has enough data', () {
    final current = [
      for (var day = 0; day < 4; day++)
        nightEnding(daysAgo(day), const Duration(hours: 8)),
    ];
    final previous = [
      for (var day = 7; day < 11; day++)
        nightEnding(daysAgo(day), const Duration(hours: 7)),
    ];

    final insights = insightsFor([...current, ...previous]);
    final comparison = insights.comparison;
    expect(comparison, isNotNull);
    expect(comparison!.previousAverage, const Duration(hours: 7));
    expect(comparison.averageDelta, const Duration(hours: 1));
    expect(comparison.previousNights, 4);
    expect(comparison.previousCoverage, closeTo(4 / 7, 1e-9));

    final insufficient = insightsFor([
      ...current,
      nightEnding(daysAgo(7), const Duration(hours: 7)),
      nightEnding(daysAgo(8), const Duration(hours: 7)),
    ]);
    expect(insufficient.comparison, isNull);

    final all = insightsFor([
      ...current,
      ...previous,
    ], range: SleepHistoryRange.all);
    expect(all.comparison, isNull);
  });

  test('weekday stats keep missing weekdays as null', () {
    final monday = DateTime(2026, 10, 19);
    expect(monday.weekday, DateTime.monday);

    final insights = insightsFor([
      closed(DateTime(2026, 10, 18, 23), DateTime(2026, 10, 19, 7)),
    ]);

    final stats = insights.weekdayStats;
    expect(stats, hasLength(7));
    expect(stats[DateTime.monday - 1], isNotNull);
    expect(stats[DateTime.monday - 1]!.weekday, DateTime.monday);
    expect(stats[DateTime.monday - 1]!.nights, 1);
    expect(stats[DateTime.monday - 1]!.average, const Duration(hours: 8));
    for (var index = 0; index < stats.length; index++) {
      if (index != DateTime.monday - 1) {
        expect(stats[index], isNull, reason: 'weekday index $index');
      }
    }
  });

  test('uses the exact duration band boundaries', () {
    final insights = insightsFor([
      nightEnding(daysAgo(0), const Duration(hours: 5, minutes: 59)),
      nightEnding(daysAgo(1), const Duration(hours: 6)),
      nightEnding(daysAgo(2), const Duration(hours: 7)),
      nightEnding(daysAgo(3), const Duration(hours: 8)),
      nightEnding(daysAgo(4), const Duration(hours: 9)),
    ]);

    final buckets = insights.durationBuckets;
    expect(buckets[SleepDurationBand.underSixHours.index].nights, 1);
    expect(buckets[SleepDurationBand.sixToSevenHours.index].nights, 1);
    expect(buckets[SleepDurationBand.sevenToEightHours.index].nights, 1);
    expect(buckets[SleepDurationBand.eightToNineHours.index].nights, 1);
    expect(buckets[SleepDurationBand.nineHoursPlus.index].nights, 1);
  });
}
