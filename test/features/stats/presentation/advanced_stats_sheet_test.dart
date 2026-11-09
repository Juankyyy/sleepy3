import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';
import 'package:sleepy3/features/stats/presentation/advanced_stats_sheet.dart';
import 'package:sleepy3/features/stats/presentation/stats_screen.dart';
import 'package:sleepy3/features/stats/presentation/widgets/stats_insights_card.dart';
import 'package:sleepy3/l10n/l10n.dart';

import '../../health/fakes.dart';
import '../../sleep_tracking/fakes.dart';

void main() {
  SleepSession closed(DateTime start, DateTime end) =>
      SleepSession(startedAt: start, endedAt: end);

  final sessions = [
    closed(DateTime(2026, 10, 20, 22, 32), DateTime(2026, 10, 21, 6, 45)),
    closed(DateTime(2026, 10, 19, 23, 10), DateTime(2026, 10, 20, 6, 12)),
    closed(DateTime(2026, 10, 14, 22, 55), DateTime(2026, 10, 15, 5, 43)),
    closed(DateTime(2026, 10, 13, 22), DateTime(2026, 10, 14, 6)),
  ];

  Future<FakeSleepSessionStore> pumpStats(
    WidgetTester tester, {
    SleepSnapshot? snapshot,
    SleepDataSource source = SleepDataSource.local,
    FakeHealthConnectGateway? gateway,
    Size size = const Size(360, 800),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final store = FakeSleepSessionStore(
      snapshot: snapshot ?? SleepSnapshot(closedSessions: sessions),
    );
    final data = Sleepy3Theme.light();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sleepClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 21, 10),
          ),
          sleepSessionStoreProvider.overrideWithValue(store),
          initialSleepSnapshotProvider.overrideWithValue(SleepSnapshot.empty),
          initialSleepDataSourceProvider.overrideWithValue(source),
          healthConnectGatewayProvider.overrideWithValue(
            gateway ?? FakeHealthConnectGateway(),
          ),
          healthSyncStoreProvider.overrideWithValue(FakeHealthSyncStore()),
        ],
        child: M3EMaterialApp(
          title: 'Sleepy3',
          data: data,
          theme: data.toThemeData(),
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: StatsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Finder inSheet(Finder matching) {
    return find.descendant(
      of: find.byType(AdvancedStatsSheet),
      matching: matching,
    );
  }

  Future<void> openAdvanced(WidgetTester tester) async {
    final button = find.byKey(const Key('advanced-stats-button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> closeAdvanced(WidgetTester tester) async {
    await tester.tap(inSheet(find.byIcon(M3EIcons.close)));
    await tester.pumpAndSettle();
  }

  testWidgets('opens the dashboard with a fixed header', (tester) async {
    await pumpStats(tester);
    await openAdvanced(tester);

    expect(find.byType(AdvancedStatsSheet), findsOneWidget);
    expect(inSheet(find.text('Advanced stats')), findsOneWidget);
    expect(inSheet(find.text('Week · 3 nights')), findsOneWidget);
    expect(inSheet(find.text('Goal hit rate')), findsOneWidget);
    expect(inSheet(find.text('Schedule consistency')), findsOneWidget);
    expect(inSheet(find.text('Sleep balance')), findsOneWidget);
    expect(inSheet(find.text('Best streak')), findsOneWidget);
    expect(inSheet(find.text('Sleep duration')), findsOneWidget);
    expect(inSheet(find.text('Sleep window')), findsOneWidget);
    expect(inSheet(find.text('By weekday')), findsOneWidget);
    expect(inSheet(find.text('Insights')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('advanced-stats-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Advanced stats')), findsOneWidget);
    expect(inSheet(find.text('Week · 3 nights')), findsOneWidget);
    expect(inSheet(find.byIcon(M3EIcons.close)), findsOneWidget);
  });

  testWidgets('opens at 70 % and drags between full, the snap and close', (
    tester,
  ) async {
    await pumpStats(tester);
    await openAdvanced(tester);

    final surface = find.byKey(const Key('advanced-stats-surface'));
    final header = find.byKey(const Key('advanced-stats-header-content'));
    final snapTop = 800.0 * (1 - 0.70);

    expect(tester.getTopLeft(surface).dy, closeTo(snapTop, 1));

    await tester.timedDrag(
      header,
      const Offset(0, -320),
      const Duration(milliseconds: 700),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(surface).dy, closeTo(72, 1));

    await tester.timedDrag(
      header,
      const Offset(0, 320),
      const Duration(milliseconds: 700),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(surface).dy, closeTo(snapTop, 1));

    await tester.timedDrag(
      header,
      const Offset(0, 500),
      const Duration(milliseconds: 700),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdvancedStatsSheet), findsNothing);
  });

  testWidgets('scrolls from the duration chart to the last insight card', (
    tester,
  ) async {
    await pumpStats(tester);
    await openAdvanced(tester);

    final sheet = find.byType(AdvancedStatsSheet);
    final surface = find.byKey(const Key('advanced-stats-surface'));
    final header = find.byKey(const Key('advanced-stats-header-content'));
    final scrollable = find
        .descendant(of: sheet, matching: find.byType(Scrollable))
        .first;

    // First drag expands the sheet to full height. The test then scrolls the
    // dashboard so the last card has to be reachable at the bottom.
    await tester.timedDrag(
      header,
      const Offset(0, -400),
      const Duration(milliseconds: 700),
    );
    await tester.pumpAndSettle();
    await tester.drag(scrollable, const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sleep window'), findsOneWidget);
    expect(find.text('By weekday'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);

    final card = tester.getRect(find.byType(StatsInsightsCard));
    final sheetRect = tester.getRect(surface);
    expect(card.top, greaterThanOrEqualTo(sheetRect.top));
    expect(card.bottom, lessThanOrEqualTo(sheetRect.bottom + 0.01));
  });

  testWidgets('the close affordance returns to the summary', (tester) async {
    await pumpStats(tester);
    await openAdvanced(tester);

    await closeAdvanced(tester);

    expect(find.byType(AdvancedStatsSheet), findsNothing);
    expect(find.byKey(const Key('advanced-stats-button')), findsOneWidget);
  });

  testWidgets('tapping the scrim dismisses the sheet', (tester) async {
    await pumpStats(tester);
    await openAdvanced(tester);

    await tester.tapAt(const Offset(180, 60));
    await tester.pumpAndSettle();

    expect(find.byType(AdvancedStatsSheet), findsNothing);
  });

  testWidgets('system back dismisses the sheet', (tester) async {
    await pumpStats(tester);
    await openAdvanced(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AdvancedStatsSheet), findsNothing);
  });

  testWidgets('changing the range in the sheet updates the summary', (
    tester,
  ) async {
    await pumpStats(tester);
    await openAdvanced(tester);

    await tester.tap(inSheet(find.text('Month')));
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Month · 4 nights')), findsOneWidget);
    expect(inSheet(find.text('Bedtime to wake · Month')), findsOneWidget);

    await closeAdvanced(tester);

    final chips = tester.widgetList<M3EChip>(find.byType(M3EChip)).toList();
    expect(chips[1].selected, isTrue);
  });

  testWidgets('asks for full history from the sheet', (tester) async {
    final recent = HealthSleepSession(
      uuid: 'recent',
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
    );
    final old = HealthSleepSession(
      uuid: 'old',
      startedAt: DateTime(2026, 9, 1, 22),
      endedAt: DateTime(2026, 9, 2, 6),
    );
    final gateway = FakeHealthConnectGateway(
      sessions: [old, recent],
      historyPermission: false,
      grantHistoryOnRequest: false,
    );

    await pumpStats(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
    );
    await openAdvanced(tester);

    expect(gateway.historyPermissionRequestCalls, 0);

    await tester.tap(inSheet(find.text('All')));
    await tester.pumpAndSettle();

    expect(gateway.historyPermissionRequestCalls, 1);
    expect(
      inSheet(find.text('Only the last 30 days are available')),
      findsOneWidget,
    );
    expect(inSheet(find.text('All · 1 night')), findsOneWidget);
    expect(
      inSheet(find.text('Bedtime to wake · Last 30 days available')),
      findsOneWidget,
    );
  });

  testWidgets('fits at 200% text with the header fixed', (tester) async {
    await pumpStats(tester, textScale: 2);
    await openAdvanced(tester);

    expect(tester.takeException(), isNull);
    expect(inSheet(find.text('Advanced stats')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('advanced-stats-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(inSheet(find.text('Advanced stats')), findsOneWidget);
    expect(inSheet(find.byIcon(M3EIcons.close)), findsOneWidget);
  });
}
