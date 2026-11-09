import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_history.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_insights.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_empty_state.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_format.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_scrub_area.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_tooltip.dart';
import 'package:sleepy3/features/stats/presentation/charts/sleep_window_chart.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  test('maps wall-clock times to the 18:00 to 12:00 axis', () {
    expect(sleepWindowAxisMinutes(const Duration(hours: 18)), 18 * 60);
    expect(sleepWindowAxisMinutes(const Duration(hours: 23)), 23 * 60);
    expect(sleepWindowAxisMinutes(Duration.zero), 24 * 60);
    expect(sleepWindowAxisMinutes(const Duration(hours: 30)), 30 * 60);
    expect(sleepWindowAxisMinutes(const Duration(hours: 12)), 36 * 60);
    expect(sleepWindowAxisMinutes(const Duration(hours: 14)), 36 * 60);
    expect(sleepWindowAxisMinutes(null), isNull);
  });

  SleepSession closed(DateTime start, DateTime end) =>
      SleepSession(startedAt: start, endedAt: end);

  final now = DateTime(2026, 10, 21, 10);
  final session = closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7));
  final week = buildSleepInsights(
    now: now,
    sessions: [session],
    range: SleepHistoryRange.week,
  );
  final month = buildSleepInsights(
    now: now,
    sessions: [session],
    range: SleepHistoryRange.month,
  );
  final threeMonths = buildSleepInsights(
    now: now,
    sessions: [session],
    range: SleepHistoryRange.threeMonths,
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
              builder: (context, value, _) => SleepWindowChart(insights: value),
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

  testWidgets('renders the sleep window card and its legend', (tester) async {
    await pumpChart(tester, week);

    expect(find.text('Sleep window'), findsOneWidget);
    expect(find.text('Bedtime to wake · Week'), findsOneWidget);
    expect(find.text('Bedtime to wake'), findsOneWidget);
    expect(find.text('Range'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.byType(SleepWindowChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes one spoken summary for the window', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpChart(tester, week);

    expect(
      find.bySemanticsLabel(
        'Sleep window for Week. Average bedtime 11:00 PM and average wake '
        '7:00 AM. 6 nights have no data.',
      ),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('shows a tooltip for a recorded night', (tester) async {
    await pumpChart(tester, week);

    final area = tester.getRect(find.byType(ChartScrubArea));
    final rowHeight = (area.height - 8 - 24) / 7;
    final lastRow = Offset(area.left + 80, area.top + 8 + 6.5 * rowHeight);

    final gesture = await tester.startGesture(lastRow);
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.text('Wed, Oct 21 · 11:00 PM – 7:00 AM'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Wed, Oct 21 · 11:00 PM – 7:00 AM'), findsNothing);
  });

  testWidgets('marks a missing night in the tooltip', (tester) async {
    await pumpChart(tester, week);

    final area = tester.getRect(find.byType(ChartScrubArea));
    final rowHeight = (area.height - 8 - 24) / 7;
    final firstRow = Offset(area.left + 80, area.top + 8 + 0.5 * rowHeight);

    final gesture = await tester.startGesture(firstRow);
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.text('Thu, Oct 15 · No night recorded'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('uses a rich tooltip for a weekly bucket', (tester) async {
    await pumpChart(tester, threeMonths);

    final index = threeMonths.chartBuckets.indexWhere(
      (bucket) => bucket.hasData,
    );
    expect(index, greaterThanOrEqualTo(0));

    final area = tester.getRect(find.byType(ChartScrubArea));
    final rowHeight = (area.height - 8 - 24) / threeMonths.chartBuckets.length;
    final point = Offset(
      area.left + 80,
      area.top + 8 + (index + 0.5) * rowHeight,
    );
    final gesture = await tester.startGesture(point);
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.byType(ChartTooltip), findsOneWidget);
    expect(find.text('11:00 PM – 7:00 AM'), findsOneWidget);
    expect(find.text('1 night'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('explains an empty range instead of drawing rows', (
    tester,
  ) async {
    final empty = buildSleepInsights(
      now: now,
      sessions: [closed(DateTime(2026, 9, 1, 22), DateTime(2026, 9, 2, 6))],
      range: SleepHistoryRange.week,
    );
    await pumpChart(tester, empty);

    expect(find.text('Sleep window'), findsOneWidget);
    expect(find.text('Bedtime to wake · Week'), findsOneWidget);
    expect(find.text('No nights in this range'), findsOneWidget);
    expect(find.byType(ChartEmptyState), findsOneWidget);
    expect(find.text('Bedtime to wake'), findsNothing);
  });

  testWidgets('morphs when the range changes', (tester) async {
    final notifier = ValueNotifier(week);
    await pumpChart(tester, week, notifier: notifier);
    expect(find.text('Bedtime to wake · Week'), findsOneWidget);

    notifier.value = month;
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Bedtime to wake · Month'), findsOneWidget);
    expect(find.byType(ChartScrubArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draws every Stats range without layout errors', (tester) async {
    for (final range in SleepHistoryRange.values) {
      final insights = buildSleepInsights(
        now: now,
        sessions: [session],
        range: range,
      );
      await pumpChart(tester, insights);

      expect(find.text('Sleep window'), findsOneWidget);
      expect(find.byType(ChartScrubArea), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('fits at 200% text', (tester) async {
    await pumpChart(tester, week, textScale: 2);

    expect(find.text('Sleep window'), findsOneWidget);
    expect(find.byType(ChartScrubArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Spanish', (tester) async {
    await pumpChart(tester, week, locale: const Locale('es'));

    expect(find.text('Ventana de sueño'), findsOneWidget);
    expect(find.text('De acostarse a despertar · Semana'), findsOneWidget);
    expect(find.text('Rango'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('works with reduced motion', (tester) async {
    await pumpChart(tester, week, disableAnimations: true);

    expect(find.text('Sleep window'), findsOneWidget);
    expect(find.byType(ChartScrubArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits on a medium window', (tester) async {
    await pumpChart(tester, week, size: const Size(800, 900));

    expect(find.text('Sleep window'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
