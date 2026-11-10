import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_history.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_insights.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/stats/presentation/widgets/stats_insights_card.dart';
import 'package:sleepy3/l10n/l10n.dart';

void main() {
  SleepSession closed(DateTime start, DateTime end) =>
      SleepSession(startedAt: start, endedAt: end);

  final now = DateTime(2026, 10, 21, 10);
  final insights = buildSleepInsights(
    now: now,
    sessions: [closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7))],
    range: SleepHistoryRange.week,
  );
  final twoNights = buildSleepInsights(
    now: now,
    sessions: [
      closed(DateTime(2026, 10, 19, 22), DateTime(2026, 10, 20, 8)),
      closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 5)),
    ],
    range: SleepHistoryRange.week,
  );
  final empty = buildSleepInsights(
    now: now,
    sessions: const [],
    range: SleepHistoryRange.week,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    SleepInsights value, {
    Size size = const Size(360, 800),
    double textScale = 1,
    Locale locale = const Locale('en'),
    bool use24HourFormat = false,
    bool compact = false,
    bool showTitle = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(alwaysUse24HourFormat: use24HourFormat),
            child: M3EMaterialApp(
              title: 'Sleepy3',
              data: data,
              theme: data.toThemeData(),
              locale: locale,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: StatsInsightsCard(
                    insights: value,
                    compact: compact,
                    showTitle: showTitle,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the factual rows for one night', (tester) async {
    await pumpCard(tester, insights);

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Best night'), findsOneWidget);
    expect(find.text('Shortest night'), findsOneWidget);
    expect(find.text('Oct 21'), findsNWidgets(2));
    expect(find.text('8h 0m'), findsNWidgets(2));
    expect(find.text('Average bedtime'), findsOneWidget);
    expect(find.text('11:00 PM'), findsOneWidget);
    expect(find.text('Average wake'), findsOneWidget);
    expect(find.text('7:00 AM'), findsOneWidget);
    expect(find.text('Bedtime varies by'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Needs 2 nights'), findsOneWidget);
    expect(find.text('Nights with more than one session'), findsOneWidget);
    expect(find.text('0 nights'), findsOneWidget);
    expect(find.text('Distribution'), findsOneWidget);
    expect(find.text('8–9h · 1 night'), findsOneWidget);
    expect(find.text('Under 6h · 0 nights'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ranks the best and shortest night when there are two', (
    tester,
  ) async {
    await pumpCard(tester, twoNights);

    expect(find.text('10h 0m'), findsOneWidget);
    expect(find.text('6h 0m'), findsOneWidget);
    expect(find.text('Oct 20'), findsOneWidget);
    expect(find.text('Oct 21'), findsOneWidget);
  });

  testWidgets('exposes each row to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCard(tester, insights);

    expect(
      find.bySemanticsLabel(RegExp('Best night, 8 hours 0 minutes, Oct 21')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp('Nights with more than one session, 0 nights'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Sleep duration distribution')),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('shows the 24-hour clock when the system asks for it', (
    tester,
  ) async {
    await pumpCard(tester, insights, use24HourFormat: true);

    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
  });

  testWidgets('explains an empty range once', (tester) async {
    await pumpCard(tester, empty);

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('No nights in this range'), findsOneWidget);
    expect(find.text('Best night'), findsNothing);
    expect(find.text('Distribution'), findsNothing);
  });

  testWidgets('fits at 200% text', (tester) async {
    await pumpCard(tester, insights, textScale: 2);

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Nights with more than one session'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Spanish', (tester) async {
    await pumpCard(tester, insights, locale: const Locale('es'));

    expect(find.text('Datos clave'), findsOneWidget);
    expect(find.text('Mejor noche'), findsOneWidget);
    expect(find.text('Hora media de acostarse'), findsOneWidget);
    expect(find.text('Distribución'), findsOneWidget);
    expect(find.text('8–9 h · 1 noche'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits on a medium window', (tester) async {
    await pumpCard(tester, insights, size: const Size(800, 900));

    expect(find.text('Insights'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('compact summary variant', () {
    Table table(WidgetTester tester) {
      return tester.widget<Table>(
        find.descendant(
          of: find.byType(StatsInsightsCard),
          matching: find.byType(Table),
        ),
      );
    }

    testWidgets('uses two columns on a phone', (tester) async {
      await pumpCard(tester, insights, compact: true);

      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Best night'), findsOneWidget);
      expect(table(tester).columnWidths, hasLength(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses three columns from 600dp', (tester) async {
      await pumpCard(
        tester,
        insights,
        compact: true,
        size: const Size(800, 900),
      );

      expect(table(tester).columnWidths, hasLength(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to one column at 200% text', (tester) async {
      await pumpCard(tester, insights, compact: true, textScale: 2);

      expect(table(tester).columnWidths, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('can hide the inline title for the picker preview', (
      tester,
    ) async {
      await pumpCard(tester, insights, compact: true, showTitle: false);

      expect(find.text('Insights'), findsNothing);
      expect(find.text('Best night'), findsOneWidget);
      expect(find.text('Distribution'), findsOneWidget);
    });
  });
}
