import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_history.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_insights.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_empty_state.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_scrub_area.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_theme.dart';
import 'package:sleepy3/features/stats/presentation/charts/chart_tooltip.dart';
import 'package:sleepy3/features/stats/presentation/charts/weekday_chart.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  SleepSession closed(DateTime start, DateTime end) =>
      SleepSession(startedAt: start, endedAt: end);

  final now = DateTime(2026, 10, 21, 10);
  final sessions = [
    // Tuesday, 9 hours.
    closed(DateTime(2026, 10, 19, 23), DateTime(2026, 10, 20, 8)),
    // Wednesday, 7 hours.
    closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 6)),
    // Sunday, 5 hours.
    closed(DateTime(2026, 10, 17, 23), DateTime(2026, 10, 18, 4)),
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
              builder: (context, value, _) => WeekdayChart(insights: value),
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

  testWidgets('renders the weekday card', (tester) async {
    await pumpChart(tester, week);

    expect(find.text('By weekday'), findsOneWidget);
    expect(find.text('Average by wake day · Week'), findsOneWidget);
    expect(find.byType(WeekdayChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes one spoken summary for the best weekday', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpChart(tester, week);

    expect(
      find.bySemanticsLabel(
        'Average sleep by weekday for Week. Tuesday is the longest average '
        'with 9 hours 0 minutes. 3 of 7 weekdays have data.',
      ),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('shows a rich tooltip for a weekday', (tester) async {
    await pumpChart(tester, week);

    final area = tester.getRect(find.byType(ChartScrubArea));
    final slot =
        (area.width -
            ChartDimensions.axisGutter -
            ChartDimensions.plotRightInset) /
        7;
    // Tuesday is index 1.
    final gesture = await tester.startGesture(
      Offset(
        area.left + ChartDimensions.axisGutter + 1.5 * slot,
        area.top + 80,
      ),
    );
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.byType(ChartTooltip), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
    expect(find.text('9h 0m'), findsOneWidget);
    expect(find.text('1 night'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(ChartTooltip), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(ChartTooltip), findsNothing);
  });

  testWidgets('marks a weekday without data in the tooltip', (tester) async {
    await pumpChart(tester, week);

    final area = tester.getRect(find.byType(ChartScrubArea));
    final slot =
        (area.width -
            ChartDimensions.axisGutter -
            ChartDimensions.plotRightInset) /
        7;
    // Monday is index 0.
    final gesture = await tester.startGesture(
      Offset(
        area.left + ChartDimensions.axisGutter + 0.5 * slot,
        area.top + 80,
      ),
    );
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.text('Monday · No night recorded'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('explains an empty range', (tester) async {
    final empty = buildSleepInsights(
      now: now,
      sessions: [closed(DateTime(2026, 9, 1, 22), DateTime(2026, 9, 2, 6))],
      range: SleepHistoryRange.week,
    );
    await pumpChart(tester, empty);

    expect(find.text('By weekday'), findsOneWidget);
    expect(find.text('Average by wake day · Week'), findsOneWidget);
    expect(find.text('No nights in this range'), findsOneWidget);
    expect(find.byType(ChartEmptyState), findsOneWidget);
  });

  testWidgets('morphs when the range changes', (tester) async {
    final notifier = ValueNotifier(week);
    await pumpChart(tester, week, notifier: notifier);
    expect(find.text('Average by wake day · Week'), findsOneWidget);

    notifier.value = month;
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Average by wake day · Month'), findsOneWidget);
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

      expect(find.text('By weekday'), findsOneWidget);
      expect(find.byType(ChartScrubArea), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('fits at 200% text', (tester) async {
    await pumpChart(tester, week, textScale: 2);

    expect(find.text('By weekday'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Spanish', (tester) async {
    await pumpChart(tester, week, locale: const Locale('es'));

    expect(find.text('Por día de la semana'), findsOneWidget);
    expect(
      find.text('Media según el día de despertar · Semana'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('works with reduced motion', (tester) async {
    await pumpChart(tester, week, disableAnimations: true);

    expect(find.text('By weekday'), findsOneWidget);
    expect(find.byType(ChartScrubArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits on a medium window', (tester) async {
    await pumpChart(tester, week, size: const Size(800, 900));

    expect(find.text('By weekday'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
