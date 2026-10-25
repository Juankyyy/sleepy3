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
      range: SleepHistoryRange.sevenDays,
    );

    expect(history.hasData, isFalse);
    expect(history.days, isEmpty);
    expect(history.entries, isEmpty);
    expect(history.nights, 0);
    expect(history.average, isNull);
    expect(history.total, Duration.zero);
  });

  test('groups by wake day, newest day first and sessions chronologically', () {
    final history = buildSleepHistory(
      now: now,
      sessions: [
        closed(DateTime(2026, 10, 21, 4), DateTime(2026, 10, 21, 9)),
        closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 6, 30)),
        closed(DateTime(2026, 10, 19, 23), DateTime(2026, 10, 20, 7)),
      ],
      range: SleepHistoryRange.sevenDays,
    );

    expect(history.days.map((day) => day.date).toList(), [
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 20),
    ]);
    expect(
      history.days.first.sessions.map((session) => session.startedAt).toList(),
      [DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 4)],
    );
    expect(history.entries.map((entry) => entry.session.startedAt).toList(), [
      DateTime(2026, 10, 20, 23),
      DateTime(2026, 10, 21, 4),
      DateTime(2026, 10, 19, 23),
    ]);
  });

  test('a session that crosses midnight belongs to its wake day', () {
    final history = buildSleepHistory(
      now: now,
      sessions: [closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7))],
      range: SleepHistoryRange.sevenDays,
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
      range: SleepHistoryRange.sevenDays,
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
      range: SleepHistoryRange.sevenDays,
    );

    expect(history.nights, 2);
    expect(history.average, const Duration(hours: 7));
  });

  test('applies the 7-day, 30-day and all boundaries', () {
    final sessions = [
      closed(DateTime(2026, 10, 21, 1), DateTime(2026, 10, 21, 7)),
      // Six days before today: the first day of the 7-day window.
      closed(DateTime(2026, 10, 15, 1), DateTime(2026, 10, 15, 7)),
      // Seven days before today: outside 7, inside 30.
      closed(DateTime(2026, 10, 14, 1), DateTime(2026, 10, 14, 7)),
      // Twenty-nine days before today: the first day of the 30-day window.
      closed(DateTime(2026, 9, 22, 1), DateTime(2026, 9, 22, 7)),
      // Thirty days before today: only in All.
      closed(DateTime(2026, 9, 21, 1), DateTime(2026, 9, 21, 7)),
    ];

    final week = buildSleepHistory(
      now: now,
      sessions: sessions,
      range: SleepHistoryRange.sevenDays,
    );
    expect(week.days.map((day) => day.date).toList(), [
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 15),
    ]);

    final month = buildSleepHistory(
      now: now,
      sessions: sessions,
      range: SleepHistoryRange.thirtyDays,
    );
    expect(month.days.map((day) => day.date).toList(), [
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 15),
      DateTime(2026, 10, 14),
      DateTime(2026, 9, 22),
    ]);

    final all = buildSleepHistory(
      now: now,
      sessions: sessions,
      range: SleepHistoryRange.all,
    );
    expect(all.days, hasLength(5));
    expect(all.days.last.date, DateTime(2026, 9, 21));
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
      range: SleepHistoryRange.sevenDays,
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
      range: SleepHistoryRange.sevenDays,
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
      range: SleepHistoryRange.sevenDays,
    );
    final after = buildSleepHistory(
      now: DateTime(2026, 10, 22, 0, 0, 1),
      sessions: sessions,
      range: SleepHistoryRange.sevenDays,
    );

    expect(before.days.single.date, DateTime(2026, 10, 21));
    expect(after.days.single.date, DateTime(2026, 10, 21));
    expect(after.days.single.total, const Duration(hours: 8));
  });
}
