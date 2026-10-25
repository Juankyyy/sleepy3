import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/recent_sleep_summary.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  SleepSession closed(DateTime start, DateTime end) {
    return SleepSession(startedAt: start, endedAt: end);
  }

  DateTime day(RecentSleepSummary summary, int daysAgo) =>
      summary.dayBefore(daysAgo).date;

  test('returns three empty days when there are no sessions', () {
    final summary = buildRecentSleepSummary(
      now: DateTime(2026, 10, 21, 10),
      sessions: const [],
    );

    expect(summary.days, hasLength(3));
    expect(summary.hasData, isFalse);
    expect(summary.average, isNull);
    expect(
      summary.days.map((summaryDay) => summaryDay.duration),
      everyElement(isNull),
    );
    expect(day(summary, 0), DateTime(2026, 10, 21));
    expect(day(summary, 1), DateTime(2026, 10, 20));
    expect(day(summary, 2), DateTime(2026, 10, 19));
  });

  test('groups closed sessions by the local day they ended', () {
    final summary = buildRecentSleepSummary(
      now: DateTime(2026, 10, 21, 10),
      sessions: [
        closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 6, 30)),
        closed(DateTime(2026, 10, 20, 1), DateTime(2026, 10, 20, 8)),
        closed(DateTime(2026, 10, 18, 23), DateTime(2026, 10, 19, 7)),
        // An open session has no wake day and no duration yet.
        SleepSession(startedAt: DateTime(2026, 10, 21, 9)),
      ],
    );

    expect(
      summary.dayBefore(0).duration,
      const Duration(hours: 7, minutes: 30),
    );
    expect(summary.dayBefore(1).duration, const Duration(hours: 7));
    expect(summary.dayBefore(2).duration, const Duration(hours: 8));
    expect(summary.average, const Duration(hours: 7, minutes: 30));
    expect(summary.hasData, isTrue);
  });

  test('a session that crosses midnight counts entirely on its wake day', () {
    final summary = buildRecentSleepSummary(
      now: DateTime(2026, 10, 21, 10),
      sessions: [closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7))],
    );

    expect(summary.dayBefore(0).duration, const Duration(hours: 8));
    expect(summary.dayBefore(1).duration, isNull);
    expect(summary.average, const Duration(hours: 8));
  });

  test('sums several sessions that end on the same day', () {
    final summary = buildRecentSleepSummary(
      now: DateTime(2026, 10, 21, 10),
      sessions: [
        closed(DateTime(2026, 10, 21, 1), DateTime(2026, 10, 21, 3)),
        closed(DateTime(2026, 10, 21, 4), DateTime(2026, 10, 21, 9, 30)),
      ],
    );

    expect(
      summary.dayBefore(0).duration,
      const Duration(hours: 7, minutes: 30),
    );
    expect(summary.average, const Duration(hours: 7, minutes: 30));
  });

  test('averages only the days with data', () {
    final summary = buildRecentSleepSummary(
      now: DateTime(2026, 10, 21, 10),
      sessions: [
        closed(DateTime(2026, 10, 21, 1), DateTime(2026, 10, 21, 7)),
        closed(DateTime(2026, 10, 19, 1), DateTime(2026, 10, 19, 9)),
      ],
    );

    expect(summary.dayBefore(1).duration, isNull);
    expect(summary.average, const Duration(hours: 7));
  });

  test('keeps sessions exactly on the window boundaries', () {
    final summary = buildRecentSleepSummary(
      now: DateTime(2026, 10, 21, 10),
      sessions: [
        // Starts the first day of the window at exactly local midnight.
        closed(DateTime(2026, 10, 18, 22), DateTime(2026, 10, 19)),
        closed(DateTime(2026, 10, 21, 9), DateTime(2026, 10, 21, 9, 59)),
      ],
    );

    expect(summary.dayBefore(2).duration, const Duration(hours: 2));
    expect(summary.dayBefore(0).duration, const Duration(minutes: 59));
  });

  test('ignores closed sessions outside the three-day window', () {
    final summary = buildRecentSleepSummary(
      now: DateTime(2026, 10, 21, 10),
      sessions: [
        closed(DateTime(2026, 10, 17, 23), DateTime(2026, 10, 18, 7)),
        closed(DateTime(2026, 10, 22, 1), DateTime(2026, 10, 22, 7)),
      ],
    );

    expect(summary.hasData, isFalse);
    expect(summary.average, isNull);
  });

  test('only contributes in-window sessions from the full history', () {
    final summary = buildRecentSleepSummary(
      now: DateTime(2026, 10, 21, 10),
      sessions: [
        closed(DateTime(2026, 10, 17, 23), DateTime(2026, 10, 18, 7)),
        closed(DateTime(2026, 10, 21, 0), DateTime(2026, 10, 21, 8)),
        closed(DateTime(2026, 10, 19, 0), DateTime(2026, 10, 19, 6)),
        closed(DateTime(2026, 10, 22, 1), DateTime(2026, 10, 22, 7)),
      ],
    );

    expect(summary.hasData, isTrue);
    expect(summary.dayBefore(0).duration, const Duration(hours: 8));
    expect(summary.dayBefore(1).duration, isNull);
    expect(summary.dayBefore(2).duration, const Duration(hours: 6));
    expect(summary.average, const Duration(hours: 7));
  });

  test('moves today to yesterday when the local date changes', () {
    final sessions = [
      closed(DateTime(2026, 10, 19, 23), DateTime(2026, 10, 20, 7)),
      closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7)),
    ];

    final beforeMidnight = buildRecentSleepSummary(
      now: DateTime(2026, 10, 21, 23, 59, 59),
      sessions: sessions,
    );
    final afterMidnight = buildRecentSleepSummary(
      now: DateTime(2026, 10, 22, 0, 0, 1),
      sessions: sessions,
    );

    expect(day(beforeMidnight, 0), DateTime(2026, 10, 21));
    expect(beforeMidnight.dayBefore(0).duration, const Duration(hours: 8));
    expect(beforeMidnight.dayBefore(1).duration, const Duration(hours: 8));
    expect(beforeMidnight.dayBefore(2).duration, isNull);

    expect(day(afterMidnight, 0), DateTime(2026, 10, 22));
    expect(afterMidnight.dayBefore(0).duration, isNull);
    expect(afterMidnight.dayBefore(1).duration, const Duration(hours: 8));
    expect(afterMidnight.dayBefore(2).duration, const Duration(hours: 8));
  });

  test('keeps calendar days consecutive across a DST transition', () {
    // In Europe/Madrid the clocks move forward on 2026-03-29. The test does not
    // assume the host observes DST; it checks that the buckets stay on calendar
    // days and that the whole night lands on the day it ended.
    final summary = buildRecentSleepSummary(
      now: DateTime(2026, 3, 30, 10),
      sessions: [
        closed(DateTime(2026, 3, 28, 23), DateTime(2026, 3, 29, 7)),
        closed(DateTime(2026, 3, 29, 23, 30), DateTime(2026, 3, 30, 7)),
      ],
    );

    expect(day(summary, 2), DateTime(2026, 3, 28));
    expect(day(summary, 1), DateTime(2026, 3, 29));
    expect(day(summary, 0), DateTime(2026, 3, 30));
    expect(summary.dayBefore(2).duration, isNull);
    expect(summary.dayBefore(1).duration, isNotNull);
    expect(summary.dayBefore(0).duration, isNotNull);
  });
}
