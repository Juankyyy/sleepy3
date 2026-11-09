import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_history.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_insights.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_empty_state.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_scrub_area.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_tooltip.dart';
import 'package:sleepy3/features/stats/presentation/charts/sleep_duration_chart.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  SleepSession closed(DateTime start, DateTime end) =>
      SleepSession(startedAt: start, endedAt: end);

  final now = DateTime(2026, 10, 21, 10);
  final sessions = [
    closed(DateTime(2026, 10, 20, 22), DateTime(2026, 10, 21, 6)),
    closed(DateTime(2026, 10, 19, 23), DateTime(2026, 10, 20, 6)),
    closed(DateTime(2026, 10, 18, 23), DateTime(2026, 10, 19, 6)),
  ];
  final week = buildSleepInsights(
    now: now,
    sessions: sessions,
    range: SleepHistoryRange.week,
  );
  final month = buildSleepInsights(
    now: now,
    sessions: sessions,
    range: SleepHistoryRange.month,
  );

  Future<void> pumpChart(
    WidgetTester tester,
    SleepInsights insights, {
    ValueNotifier<SleepInsights>? notifier,
    Size size = const Size(360, 700),
    double textScale = 1,
    Locale locale = const Locale('en'),
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: disableAnimations);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final data = Sleepy3Theme.light();
    final value = notifier ?? ValueNotifier(insights);
    addTearDown(value.dispose);

    await tester.pumpWidget(
      M3EMaterialApp(
        title: 'Sleepy3',
        data: data,
        theme: data.toThemeData(),
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<SleepInsights>(
              valueListenable: value,
              builder: (context, value, _) =>
                  SleepDurationChart(insights: value),
            ),
          ),
        ),
      ),
    );

    if (disableAnimations) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets('renders the duration chart card and its legend', (tester) async {
    await pumpChart(tester, week);

    expect(find.text('Sleep duration'), findsOneWidget);
    expect(find.text('Week · 3 nights recorded · Goal 8h'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Goal 8h'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.byType(SleepDurationChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes one spoken summary for the chart', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpChart(tester, week);

    expect(
      find.bySemanticsLabel(
        RegExp(
          'Sleep duration for Week\\. Average 7 hours 20 minutes\\. '
          'Best night .+\\. Shortest night .+\\. '
          '2 nights under the 8h goal\\. '
          '4 nights with no data\\.',
        ),
      ),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('shows a tooltip while scrubbing and clears it on release', (
    tester,
  ) async {
    await pumpChart(tester, week);

    final area = tester.getRect(find.byType(ChartScrubArea));
    final plotWidth = area.width - 56 - 8;
    final slot = plotWidth / 7;
    final lastDay = Offset(area.left + 56 + 6.5 * slot, area.top + 80);

    final gesture = await tester.startGesture(lastDay);
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.text('Wed, Oct 21 · 8h 0m'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Wed, Oct 21 · 8h 0m'), findsNothing);
  });

  testWidgets('shows the session count when a night has several sessions', (
    tester,
  ) async {
    final insights = buildSleepInsights(
      now: now,
      sessions: [
        closed(DateTime(2026, 10, 20, 22), DateTime(2026, 10, 21, 6)),
        closed(DateTime(2026, 10, 21, 13), DateTime(2026, 10, 21, 14)),
      ],
      range: SleepHistoryRange.week,
    );
    await pumpChart(tester, insights);

    final area = tester.getRect(find.byType(ChartScrubArea));
    final slot = (area.width - 56 - 8) / 7;
    final gesture = await tester.startGesture(
      Offset(area.left + 56 + 6.5 * slot, area.top + 80),
    );
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.text('Wed, Oct 21 · 9h 0m · 2 sessions'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('marks a missing night in the tooltip instead of a zero bar', (
    tester,
  ) async {
    await pumpChart(tester, week);

    final area = tester.getRect(find.byType(ChartScrubArea));
    final slot = (area.width - 56 - 8) / 7;
    // Index 3 is October 18, the oldest recorded night is October 19.
    final gesture = await tester.startGesture(
      Offset(area.left + 56 + 3.5 * slot, area.top + 80),
    );
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.text('Sun, Oct 18 · No night recorded'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('uses a rich tooltip for a weekly bucket', (tester) async {
    final insights = buildSleepInsights(
      now: now,
      sessions: sessions,
      range: SleepHistoryRange.threeMonths,
    );
    await pumpChart(tester, insights);

    final index = insights.chartBuckets.indexWhere((bucket) => bucket.hasData);
    expect(index, greaterThanOrEqualTo(0));

    final area = tester.getRect(find.byType(ChartScrubArea));
    final slot = (area.width - 56 - 8) / insights.chartBuckets.length;
    final gesture = await tester.startGesture(
      Offset(area.left + 56 + (index + 0.5) * slot, area.top + 80),
    );
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.byType(ChartTooltip), findsOneWidget);
    expect(find.text('7h 20m avg'), findsOneWidget);
    expect(find.text('3 nights'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('explains an empty range instead of drawing zero bars', (
    tester,
  ) async {
    final empty = buildSleepInsights(
      now: now,
      sessions: [closed(DateTime(2026, 9, 1, 22), DateTime(2026, 9, 2, 6))],
      range: SleepHistoryRange.week,
    );

    await pumpChart(tester, empty);

    expect(find.text('Sleep duration'), findsOneWidget);
    expect(find.text('Week · 0 nights recorded · Goal 8h'), findsOneWidget);
    expect(find.text('No nights in this range'), findsOneWidget);
    expect(find.text('Sleep'), findsNothing);
    expect(find.byType(ChartEmptyState), findsOneWidget);
  });

  testWidgets('morphs when the range changes', (tester) async {
    final notifier = ValueNotifier(week);
    await pumpChart(tester, week, notifier: notifier);
    expect(find.text('Week · 3 nights recorded · Goal 8h'), findsOneWidget);

    notifier.value = month;
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Month · 3 nights recorded · Goal 8h'), findsOneWidget);
    expect(find.byType(ChartScrubArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draws every Stats range without layout errors', (tester) async {
    for (final range in SleepHistoryRange.values) {
      final insights = buildSleepInsights(
        now: now,
        sessions: sessions,
        range: range,
      );
      await pumpChart(tester, insights);

      expect(find.text('Sleep duration'), findsOneWidget);
      expect(find.byType(ChartScrubArea), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('fits at 200% text', (tester) async {
    await pumpChart(tester, week, textScale: 2);

    expect(find.text('Sleep duration'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Spanish', (tester) async {
    await pumpChart(tester, week, locale: const Locale('es'));

    expect(find.text('Duración del sueño'), findsOneWidget);
    expect(
      find.text('Semana · 3 noches registradas · Objetivo 8 h'),
      findsOneWidget,
    );
    expect(find.text('Sueño'), findsOneWidget);
    expect(find.text('Objetivo 8 h'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
  });

  testWidgets('works with reduced motion', (tester) async {
    await pumpChart(tester, week, disableAnimations: true);

    expect(find.text('Sleep duration'), findsOneWidget);
    expect(find.byType(ChartScrubArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits on a medium window', (tester) async {
    await pumpChart(tester, week, size: const Size(800, 900));

    expect(find.text('Sleep duration'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
