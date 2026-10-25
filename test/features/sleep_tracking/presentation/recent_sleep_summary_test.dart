import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/domain/recent_sleep_summary.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/presentation/widgets/recent_sleep_summary.dart';

void main() {
  final now = DateTime(2026, 10, 21, 10);

  RecentSleepSummary summaryWith({
    Duration? today,
    Duration? yesterday,
    Duration? twoDaysAgo,
  }) {
    final sessions = <SleepSession>[];
    void add(Duration? duration, DateTime start) {
      if (duration == null) return;
      sessions.add(
        SleepSession(startedAt: start, endedAt: start.add(duration)),
      );
    }

    add(twoDaysAgo, DateTime(2026, 10, 19, 1));
    add(yesterday, DateTime(2026, 10, 20, 1));
    add(today, DateTime(2026, 10, 21, 1));
    return buildRecentSleepSummary(now: now, sessions: sessions);
  }

  Future<void> pumpSummary(
    WidgetTester tester,
    RecentSleepSummary summary, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      M3EMaterialApp(
        data: data,
        theme: data.toThemeData(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: RecentSleepSummaryCard(summary: summary),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double barValue(WidgetTester tester, int daysAgo) {
    final bar = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byKey(ValueKey('sleep-summary-bar-$daysAgo')),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    return bar.widthFactor!;
  }

  testWidgets('renders an outlined card with the three day columns', (
    tester,
  ) async {
    await pumpSummary(
      tester,
      summaryWith(
        today: const Duration(hours: 8),
        yesterday: const Duration(hours: 7),
        twoDaysAgo: const Duration(hours: 6),
      ),
    );

    final card = tester.widget<M3ECard>(find.byType(M3ECard));
    expect(card.variant, M3ECardVariant.outlined);

    expect(find.text('Last 3 days · 7h 0m avg'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('2 days ago'), findsOneWidget);
    expect(find.text('8h 0m'), findsOneWidget);
    expect(find.text('7h 0m'), findsOneWidget);
    expect(find.text('6h 0m'), findsOneWidget);

    expect(barValue(tester, 0), 1);
    expect(barValue(tester, 1), 0.875);
    expect(barValue(tester, 2), 0.75);
  });

  testWidgets('caps the bar at the 8-hour goal', (tester) async {
    await pumpSummary(tester, summaryWith(today: const Duration(hours: 10)));

    expect(barValue(tester, 0), 1);
    expect(find.text('10h 0m'), findsOneWidget);
  });

  testWidgets('shows em dashes and empty bars without data', (tester) async {
    await pumpSummary(tester, summaryWith());

    expect(find.text('Last 3 days · — avg'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
    expect(barValue(tester, 0), 0);
    expect(barValue(tester, 1), 0);
    expect(barValue(tester, 2), 0);
  });

  testWidgets('describes the summary to screen readers', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpSummary(
      tester,
      summaryWith(
        today: const Duration(hours: 8),
        yesterday: const Duration(hours: 7),
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp('Last 3 days, average 7 hours 30 minutes')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Yesterday: 7 hours 0 minutes')),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('fits a 360dp phone at 200% text without clipping labels', (
    tester,
  ) async {
    await pumpSummary(
      tester,
      summaryWith(
        today: const Duration(hours: 8),
        yesterday: const Duration(hours: 7),
        twoDaysAgo: const Duration(hours: 6),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    final label = tester.renderObject<RenderParagraph>(find.text('2 days ago'));
    expect(label.didExceedMaxLines, isFalse);
    expect(barValue(tester, 0), 1);
  });
}
