import 'package:flutter_test/flutter_test.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_history.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';

void main() {
  final now = DateTime(2026, 10, 21, 10);

  SleepSession closed(DateTime start, DateTime end) =>
      SleepSession(startedAt: start, endedAt: end);

  test('returns an empty history when there are no closed sessions', () {
    final history = buildSleepHistory(
      now: now,
      sessions: const [],
      range: SleepHistoryRange.week,
    );

    expect(history.hasData, isFalse);
    expect(history.days, isEmpty);
    expect(history.entries, isEmpty);
    expect(history.nights, 0);
    expect(history.average, isNull);
    expect(history.total, Duration.zero);
  });

  test('groups by wake day and sorts every list newest first', () {
    final history = buildSleepHistory(
      now: now,
      sessions: [
        closed(DateTime(2026, 10, 21, 4), DateTime(2026, 10, 21, 9)),
        closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 6, 30)),
        closed(DateTime(2026, 10, 19, 23), DateTime(2026, 10, 20, 7)),
      ],
      range: SleepHistoryRange.week,
    );

    expect(history.days.map((day) => day.date).toList(), [
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 20),
    ]);
    expect(
      history.days.first.sessions.map((session) => session.startedAt).toList(),
      [DateTime(2026, 10, 21, 4), DateTime(2026, 10, 20, 23)],
    );
    expect(history.entries.map((entry) => entry.session.startedAt).toList(), [
      DateTime(2026, 10, 21, 4),
      DateTime(2026, 10, 20, 23),
      DateTime(2026, 10, 19, 23),
    ]);
  });

  test('orders sessions within the same wake day by most recent first', () {
    final night = closed(
      DateTime(2026, 10, 21, 2),
      DateTime(2026, 10, 21, 9, 45),
    );
    final evening = closed(
      DateTime(2026, 10, 21, 21, 31),
      DateTime(2026, 10, 21, 21, 44),
    );

    final history = buildSleepHistory(
      now: DateTime(2026, 10, 21, 22),
      sessions: [night, evening],
      range: SleepHistoryRange.week,
    );

    expect(history.days.single.sessions.map((session) => session.startedAt), [
      DateTime(2026, 10, 21, 21, 31),
      DateTime(2026, 10, 21, 2),
    ]);
    expect(history.entries.map((entry) => entry.session.startedAt), [
      DateTime(2026, 10, 21, 21, 31),
      DateTime(2026, 10, 21, 2),
    ]);
  });

  test('a session that crosses midnight belongs to its wake day', () {
    final history = buildSleepHistory(
      now: now,
      sessions: [closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7))],
      range: SleepHistoryRange.week,
    );

    expect(history.days.single.date, DateTime(2026, 10, 21));
    expect(history.days.single.total, const Duration(hours: 8));
    expect(history.average, const Duration(hours: 8));
    expect(history.entries.single.date, DateTime(2026, 10, 21));
  });

  test('sums several sessions per day but counts one night', () {
    final history = buildSleepHistory(
      now: now,
      sessions: [
        closed(DateTime(2026, 10, 21, 1), DateTime(2026, 10, 21, 3)),
        closed(DateTime(2026, 10, 21, 4), DateTime(2026, 10, 21, 10)),
        closed(DateTime(2026, 10, 20, 1), DateTime(2026, 10, 20, 7)),
      ],
      range: SleepHistoryRange.week,
    );

    expect(history.nights, 2);
    expect(history.days.first.total, const Duration(hours: 8));
    expect(history.days.last.total, const Duration(hours: 6));
    expect(history.total, const Duration(hours: 14));
    expect(history.average, const Duration(hours: 7));
    expect(history.entries, hasLength(3));
  });

  test('averages only the days with data', () {
    final history = buildSleepHistory(
      now: now,
      sessions: [
        closed(DateTime(2026, 10, 21, 1), DateTime(2026, 10, 21, 7)),
        closed(DateTime(2026, 10, 19, 1), DateTime(2026, 10, 19, 9)),
      ],
      range: SleepHistoryRange.week,
    );

    expect(history.nights, 2);
    expect(history.average, const Duration(hours: 7));
  });

  test('applies the week, month, three-month, year and all boundaries', () {
    DateTime daysAgo(int days) => DateTime(now.year, now.month, now.day - days);
    SleepSession nightAgo(int days) =>
        closed(daysAgo(days).subtract(const Duration(hours: 6)), daysAgo(days));

    final sessions = [
      nightAgo(0),
      // Six days before today: the first day of the week window.
      nightAgo(6),
      // Seven days before today: outside week, inside month.
      nightAgo(7),
      // Twenty-nine days before today: the first day of the month window.
      nightAgo(29),
      // Thirty days before today: outside month, inside three months.
      nightAgo(30),
      // Eighty-nine days before today: the first day of three months.
      nightAgo(89),
      // Ninety days before today: outside three months, inside year.
      nightAgo(90),
      // Three hundred sixty-four days before today: the first day of year.
      nightAgo(364),
      // Three hundred sixty-five days before today: only in All.
      nightAgo(365),
    ];

    final week = buildSleepHistory(
      now: now,
      sessions: sessions,
      range: SleepHistoryRange.week,
    );
    expect(week.days.map((day) => day.date).toList(), [daysAgo(0), daysAgo(6)]);

    final month = buildSleepHistory(
      now: now,
      sessions: sessions,
      range: SleepHistoryRange.month,
    );
    expect(month.days.map((day) => day.date).toList(), [
      daysAgo(0),
      daysAgo(6),
      daysAgo(7),
      daysAgo(29),
    ]);

    final threeMonths = buildSleepHistory(
      now: now,
      sessions: sessions,
      range: SleepHistoryRange.threeMonths,
    );
    expect(threeMonths.days.last.date, daysAgo(89));
    expect(threeMonths.days, hasLength(6));

    final year = buildSleepHistory(
      now: now,
      sessions: sessions,
      range: SleepHistoryRange.year,
    );
    expect(year.days.last.date, daysAgo(364));
    expect(year.days, hasLength(8));

    final all = buildSleepHistory(
      now: now,
      sessions: sessions,
      range: SleepHistoryRange.all,
    );
    expect(all.days, hasLength(9));
    expect(all.days.last.date, daysAgo(365));
  });

  test('marks which ranges need the full Health Connect history', () {
    expect(SleepHistoryRange.week.requiresFullHistory, isFalse);
    expect(SleepHistoryRange.month.requiresFullHistory, isFalse);
    expect(SleepHistoryRange.threeMonths.requiresFullHistory, isTrue);
    expect(SleepHistoryRange.year.requiresFullHistory, isTrue);
    expect(SleepHistoryRange.all.requiresFullHistory, isTrue);
  });

  test('ignores open and future sessions', () {
    final history = buildSleepHistory(
      now: now,
      sessions: [
        SleepSession(startedAt: DateTime(2026, 10, 21, 9)),
        closed(DateTime(2026, 10, 22, 1), DateTime(2026, 10, 22, 7)),
        closed(DateTime(2026, 10, 21, 1), DateTime(2026, 10, 21, 7)),
      ],
      range: SleepHistoryRange.all,
    );

    expect(history.days.single.date, DateTime(2026, 10, 21));
    expect(history.entries, hasLength(1));
  });

  test('clamps negative durations but keeps the day as data', () {
    final history = buildSleepHistory(
      now: now,
      sessions: [closed(DateTime(2026, 10, 21, 7), DateTime(2026, 10, 21, 6))],
      range: SleepHistoryRange.week,
    );

    expect(history.hasData, isTrue);
    expect(history.nights, 1);
    expect(history.days.single.total, Duration.zero);
    expect(history.average, Duration.zero);
  });

  test('keeps calendar days across a DST transition', () {
    // In Europe/Madrid the clocks move forward on 2026-03-29. The test checks
    // calendar-day buckets rather than assuming the host observes DST.
    final history = buildSleepHistory(
      now: DateTime(2026, 3, 30, 10),
      sessions: [
        closed(DateTime(2026, 3, 28, 23), DateTime(2026, 3, 29, 7)),
        closed(DateTime(2026, 3, 29, 23, 30), DateTime(2026, 3, 30, 7)),
      ],
      range: SleepHistoryRange.week,
    );

    expect(history.days.map((day) => day.date).toList(), [
      DateTime(2026, 3, 30),
      DateTime(2026, 3, 29),
    ]);
    expect(history.nights, 2);
  });

  test('keeps a night on its wake day after the local date changes', () {
    final sessions = [
      closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7)),
    ];

    final before = buildSleepHistory(
      now: DateTime(2026, 10, 21, 23, 59, 59),
      sessions: sessions,
      range: SleepHistoryRange.week,
    );
    final after = buildSleepHistory(
      now: DateTime(2026, 10, 22, 0, 0, 1),
      sessions: sessions,
      range: SleepHistoryRange.week,
    );

    expect(before.days.single.date, DateTime(2026, 10, 21));
    expect(after.days.single.date, DateTime(2026, 10, 21));
    expect(after.days.single.total, const Duration(hours: 8));
  });
}
