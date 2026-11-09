import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/session_night_context.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_history.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  final now = DateTime(2026, 10, 21, 10);

  SleepSession closed(DateTime start, DateTime end) =>
      SleepSession(startedAt: start, endedAt: end);

  SleepSession nightEnding(DateTime day, Duration duration) {
    final end = DateTime(day.year, day.month, day.day, 6);
    return closed(end.subtract(duration), end);
  }

  /// Seven 7-hour nights ending October 14 through October 20.
  List<SleepSession> baselineNights() => [
    for (var day = 14; day <= 20; day++)
      nightEnding(DateTime(2026, 10, day), const Duration(hours: 7)),
  ];

  SessionNightContext contextFor(
    SleepSession session, {
    List<SleepSession>? sessions,
    SleepHistoryRange range = SleepHistoryRange.week,
  }) {
    return buildSessionNightContext(
      now: now,
      session: session,
      sessions: sessions ?? [session, ...baselineNights()],
      range: range,
    );
  }

  test('compares the session with the previous seven recorded nights', () {
    final viewed = closed(
      DateTime(2026, 10, 20, 22),
      DateTime(2026, 10, 21, 6),
    );
    final insights = contextFor(viewed);

    expect(insights.baselineNights, 7);
    expect(insights.averageDuration, const Duration(hours: 7));
    expect(insights.durationDelta, const Duration(hours: 1));
    expect(insights.averageBedtime, const Duration(hours: 23));
    expect(insights.bedtimeDelta, const Duration(hours: -1));
    expect(insights.averageWake, const Duration(hours: 6));
    expect(insights.wakeDelta, Duration.zero);
    expect(insights.hasComparison, isTrue);
    expect(insights.rank, 1);
    expect(insights.totalSessions, 7);
    expect(insights.nightSessionCount, 1);
    expect(insights.isSplitNight, isFalse);
  });

  test('does not compare the night with itself', () {
    final viewed = closed(
      DateTime(2026, 10, 20, 22),
      DateTime(2026, 10, 21, 6),
    );
    final insights = contextFor(viewed);

    // If the viewed 8-hour night were included, the average would be 7h 7m.
    expect(insights.averageDuration, const Duration(hours: 7));
  });

  test('needs at least two recorded nights', () {
    final viewed = closed(
      DateTime(2026, 10, 20, 22),
      DateTime(2026, 10, 21, 6),
    );
    final none = contextFor(viewed, sessions: [viewed]);
    expect(none.baselineNights, 0);
    expect(none.averageDuration, isNull);
    expect(none.hasComparison, isFalse);

    final one = contextFor(
      viewed,
      sessions: [
        viewed,
        nightEnding(DateTime(2026, 10, 20), const Duration(hours: 7)),
      ],
    );
    expect(one.baselineNights, 1);
    expect(one.averageDuration, const Duration(hours: 7));
    expect(one.hasComparison, isFalse);
  });

  test('ranks the session by length inside the selected range', () {
    final viewed = closed(
      DateTime(2026, 10, 20, 22),
      DateTime(2026, 10, 21, 6),
    );
    final longer = closed(
      DateTime(2026, 10, 17, 21),
      DateTime(2026, 10, 18, 7),
    );

    final week = contextFor(
      viewed,
      sessions: [viewed, longer, ...baselineNights()],
    );
    expect(week.rank, 2);

    final older = closed(DateTime(2026, 10, 1, 21), DateTime(2026, 10, 2, 7));
    final weekWithOlder = contextFor(
      viewed,
      sessions: [viewed, ...baselineNights(), older],
    );
    expect(weekWithOlder.rank, 1);

    final all = contextFor(
      viewed,
      sessions: [viewed, ...baselineNights(), older],
      range: SleepHistoryRange.all,
    );
    expect(all.rank, 2);
  });

  test('reports a split night and compares the session, not the day total', () {
    final first = closed(DateTime(2026, 10, 20, 22), DateTime(2026, 10, 21, 2));
    final second = closed(DateTime(2026, 10, 21, 3), DateTime(2026, 10, 21, 6));
    final insights = contextFor(
      first,
      sessions: [
        first,
        second,
        nightEnding(DateTime(2026, 10, 20), const Duration(hours: 7)),
        nightEnding(DateTime(2026, 10, 19), const Duration(hours: 7)),
      ],
    );

    expect(insights.nightSessionCount, 2);
    expect(insights.isSplitNight, isTrue);
    expect(insights.baselineNights, 2);
    expect(insights.averageDuration, const Duration(hours: 7));
    expect(insights.durationDelta, const Duration(hours: -3));
    expect(insights.bedtimeDelta, const Duration(hours: -1));
    expect(insights.wakeDelta, const Duration(hours: -4));
  });

  test('uses a circular average around midnight', () {
    final viewed = closed(
      DateTime(2026, 10, 20, 0, 20),
      DateTime(2026, 10, 20, 8, 20),
    );
    final first = closed(
      DateTime(2026, 10, 18, 23, 50),
      DateTime(2026, 10, 19, 7, 50),
    );
    final second = closed(
      DateTime(2026, 10, 18, 0, 10),
      DateTime(2026, 10, 18, 8, 10),
    );

    final insights = contextFor(viewed, sessions: [viewed, first, second]);

    expect(insights.averageBedtime, Duration.zero);
    expect(insights.bedtimeDelta, const Duration(minutes: 20));
    expect(insights.averageWake, const Duration(hours: 8));
    expect(insights.wakeDelta, const Duration(minutes: 20));
  });

  test('skips empty calendar days when counting the last seven nights', () {
    final viewed = closed(
      DateTime(2026, 10, 20, 22),
      DateTime(2026, 10, 21, 6),
    );
    final sparse = [
      for (var index = 0; index < 7; index++)
        nightEnding(
          DateTime(2026, 10, 20 - index * 2),
          const Duration(hours: 7),
        ),
    ];

    final insights = contextFor(viewed, sessions: [viewed, ...sparse]);
    expect(insights.baselineNights, 7);
    expect(insights.averageDuration, const Duration(hours: 7));
  });
}
