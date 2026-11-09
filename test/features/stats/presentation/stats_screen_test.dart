import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/theme/sleepy3_theme.dart';
import 'package:sleepy3/features/health/application/app_info_provider.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/health_sleep_session.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';
import 'package:sleepy3/features/stats/presentation/advanced_stats_sheet.dart';
import 'package:sleepy3/features/stats/presentation/charts/sleep_duration_chart.dart';
import 'package:sleepy3/features/stats/presentation/charts/sleep_window_chart.dart';
import 'package:sleepy3/features/stats/presentation/charts/weekday_chart.dart';
import 'package:sleepy3/features/stats/presentation/stats_screen.dart';
import 'package:sleepy3/features/stats/presentation/widgets/sleep_history_list.dart';
import 'package:sleepy3/features/stats/presentation/widgets/stats_hero_card.dart';
import 'package:sleepy3/features/stats/presentation/widgets/stats_insights_card.dart';
import 'package:sleepy3/features/stats/presentation/widgets/stats_metrics_card.dart';
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
    required DateTime Function() clock,
    SleepSnapshot initial = SleepSnapshot.empty,
    bool use24HourFormat = false,
    Size size = const Size(360, 800),
    double textScale = 1,
    Locale locale = const Locale('en'),
    FakeSleepSessionStore? store,
    SleepDataSource source = SleepDataSource.local,
    FakeHealthConnectGateway? gateway,
    FakeHealthSyncStore? healthSyncStore,
    FakeAppInfoGateway? appInfo,
    bool dark = false,
    bool settle = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final sleepStore = store ?? FakeSleepSessionStore(snapshot: initial);
    final data = dark ? Sleepy3Theme.dark() : Sleepy3Theme.light();
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(alwaysUse24HourFormat: use24HourFormat),
            child: ProviderScope(
              overrides: [
                sleepClockProvider.overrideWithValue(clock),
                sleepSessionStoreProvider.overrideWithValue(sleepStore),
                initialSleepSnapshotProvider.overrideWithValue(
                  SleepSnapshot(openSession: initial.openSession),
                ),
                initialSleepDataSourceProvider.overrideWithValue(source),
                healthConnectGatewayProvider.overrideWithValue(
                  gateway ?? FakeHealthConnectGateway(),
                ),
                healthSyncStoreProvider.overrideWithValue(
                  healthSyncStore ?? FakeHealthSyncStore(),
                ),
                appInfoGatewayProvider.overrideWithValue(
                  appInfo ?? FakeAppInfoGateway(),
                ),
              ],
              child: M3EMaterialApp(
                title: 'Sleepy3',
                data: data,
                theme: data.toThemeData(),
                locale: locale,
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(body: StatsScreen()),
              ),
            ),
          );
        },
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return sleepStore;
  }

  Future<void> scrollToHistory(WidgetTester tester) async {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToTop(WidgetTester tester) async {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 4000));
    await tester.pumpAndSettle();
  }

  Finder inAdvanced(Finder matching) {
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
    await tester.tap(inAdvanced(find.byIcon(M3EIcons.close)));
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty state when there is no history', (tester) async {
    await pumpStats(tester, clock: () => DateTime(2026, 10, 21, 10));

    expect(find.text('Stats'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Stats'));
    expect(title.style?.fontFamily, Sleepy3Theme.brandFontFamily);
    expect(title.style?.fontVariations!.single.value, 28);
    expect(find.text('No sleep history yet'), findsOneWidget);
    expect(
      find.text('Your nights will appear here after you wake up.'),
      findsOneWidget,
    );
    expect(find.text('Average sleep'), findsNothing);
    expect(find.byType(M3EChip), findsNothing);
  });

  testWidgets('renders the range summary and the seven-day history', (
    tester,
  ) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
    );

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Average sleep'), findsOneWidget);
    expect(find.text('7h 21m'), findsOneWidget);
    expect(find.text('Across 3 nights · 22h 3m total'), findsOneWidget);
    expect(find.text('3 of 7 nights'), findsOneWidget);
    expect(find.text('Goal hit rate'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(find.text('1 of 3 nights'), findsOneWidget);
    expect(find.text('Schedule consistency'), findsNothing);
    expect(find.text('Sleep balance'), findsOneWidget);
    expect(find.text('−1h 57m'), findsOneWidget);
    expect(find.text('debt · vs 8h goal'), findsOneWidget);
    expect(find.text('Best streak'), findsNothing);
    expect(find.text('Sleep duration'), findsNothing);
    expect(find.text('View advanced stats'), findsOneWidget);
    expect(find.textContaining('vs previous'), findsNothing);

    final card = tester.widget<M3ECard>(
      find.descendant(
        of: find.byType(StatsHeroCard),
        matching: find.byType(M3ECard),
      ),
    );
    expect(card.variant, M3ECardVariant.outlined);

    final metricsCard = tester.widget<M3ECard>(
      find.descendant(
        of: find.byType(StatsMetricsCard),
        matching: find.byType(M3ECard),
      ),
    );
    expect(metricsCard.variant, M3ECardVariant.outlined);
    final table = tester.widget<Table>(
      find.descendant(
        of: find.byType(StatsMetricsCard),
        matching: find.byType(Table),
      ),
    );
    expect(table.columnWidths, hasLength(2));

    await openAdvanced(tester);

    expect(inAdvanced(find.text('Schedule consistency')), findsOneWidget);
    expect(inAdvanced(find.text('bedtime')), findsOneWidget);
    expect(inAdvanced(find.text('Best streak')), findsOneWidget);
    expect(inAdvanced(find.text('1 night')), findsOneWidget);
    expect(inAdvanced(find.text('current 1')), findsOneWidget);
    expect(inAdvanced(find.byType(SleepDurationChart)), findsOneWidget);
    expect(
      inAdvanced(find.text('Week · 3 nights recorded · Goal 8h')),
      findsOneWidget,
    );

    await closeAdvanced(tester);
    await scrollToHistory(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SleepHistoryList),
        matching: find.text('8h 13m'),
      ),
      findsOneWidget,
    );
    expect(find.text('10:32 PM – 6:45 AM'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Thu, Oct 15'), findsOneWidget);
    expect(find.text('Wed, Oct 14'), findsNothing);

    final cards = tester
        .widgetList<M3ECard>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3ECard),
          ),
        )
        .toList();
    expect(cards, hasLength(3));
    expect(cards.first.variant, M3ECardVariant.filled);
    expect(cards.first.padding, const EdgeInsets.all(16));
    final scheme = Sleepy3Theme.light().colorScheme;
    final base = scheme.surfaceContainerHighest;
    final accent = scheme.primaryContainer;
    expect(cards[0].color, accent);
    expect(cards[1].color, Color.lerp(base, accent, 2 / 3));
    expect(cards[2].color, Color.lerp(base, accent, 1 / 3));

    final heroPill = tester.widget<Container>(
      find
          .ancestor(of: find.text('Today'), matching: find.byType(Container))
          .first,
    );
    expect(
      (heroPill.decoration! as ShapeDecoration).color,
      scheme.onPrimaryContainer.withValues(alpha: 0.10),
    );
    expect(
      tester.widget<Text>(find.text('Today')).style?.color,
      scheme.onPrimaryContainer,
    );

    final normalPill = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Yesterday'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (normalPill.decoration! as ShapeDecoration).color,
      scheme.onSurface.withValues(alpha: 0.10),
    );
    expect(
      tester.widget<Text>(find.text('Yesterday')).style?.color,
      scheme.onSurface,
    );

    final rings = tester
        .widgetList<M3EProgressIndicator>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3EProgressIndicator),
          ),
        )
        .toList();
    expect(rings, hasLength(2));
    expect(rings.every((ring) => ring.size == 44), isTrue);

    final badges = tester
        .widgetList<M3EShapeContainer>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3EShapeContainer),
          ),
        )
        .toList();
    expect(badges, hasLength(1));
    expect(badges.single.kind, M3EShapeKind.clover8Leaf);
    expect(badges.single.width, 44);
    expect(badges.single.height, 44);

    // These fake sessions have no Drift row id, so Local mode treats them as
    // read-only copies.
    expect(find.byIcon(M3EIcons.edit_outlined), findsNothing);
  });

  testWidgets('renders the sleep window, weekday and insights cards', (
    tester,
  ) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
    );

    await openAdvanced(tester);

    expect(inAdvanced(find.byType(SleepWindowChart)), findsOneWidget);
    expect(inAdvanced(find.text('Sleep window')), findsOneWidget);
    expect(inAdvanced(find.text('Bedtime to wake · Week')), findsOneWidget);
    expect(inAdvanced(find.byType(WeekdayChart)), findsOneWidget);
    expect(inAdvanced(find.text('By weekday')), findsOneWidget);
    expect(inAdvanced(find.text('Average by wake day · Week')), findsOneWidget);
    expect(inAdvanced(find.byType(StatsInsightsCard)), findsOneWidget);
    expect(inAdvanced(find.text('Insights')), findsOneWidget);
    expect(inAdvanced(find.text('Best night')), findsOneWidget);
    expect(inAdvanced(find.text('Distribution')), findsOneWidget);

    await tester.tap(inAdvanced(find.text('Month')));
    await tester.pumpAndSettle();

    expect(inAdvanced(find.text('Bedtime to wake · Month')), findsOneWidget);
    expect(
      inAdvanced(find.text('Average by wake day · Month')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compares the range with the previous period', (tester) async {
    final previous = [
      closed(DateTime(2026, 10, 8, 23), DateTime(2026, 10, 9, 6)),
      closed(DateTime(2026, 10, 9, 23), DateTime(2026, 10, 10, 6)),
      closed(DateTime(2026, 10, 10, 23), DateTime(2026, 10, 11, 6)),
      closed(DateTime(2026, 10, 11, 23), DateTime(2026, 10, 12, 6)),
    ];
    final current = [
      closed(DateTime(2026, 10, 19, 23), DateTime(2026, 10, 20, 7)),
      closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7)),
    ];

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: [...previous, ...current]),
    );

    expect(find.text('vs previous week: +1h'), findsOneWidget);
    expect(find.byIcon(M3EIcons.arrow_upward_rounded), findsOneWidget);
    expect(find.text('2 of 7 nights'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('2 of 2 nights'), findsOneWidget);
    expect(find.text('0m'), findsOneWidget);
    expect(find.text('even · vs 8h goal'), findsOneWidget);

    await openAdvanced(tester);

    expect(inAdvanced(find.text('2 nights')), findsOneWidget);
    expect(inAdvanced(find.text('current 2')), findsOneWidget);
  });

  testWidgets('marks the goal exactly at eight hours', (tester) async {
    final underGoal = closed(
      DateTime(2026, 10, 21, 23, 1),
      DateTime(2026, 10, 22, 7),
    );
    final exactGoal = closed(
      DateTime(2026, 10, 20, 23),
      DateTime(2026, 10, 21, 7),
    );

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 22, 10),
      initial: SleepSnapshot(closedSessions: [underGoal, exactGoal]),
    );

    await scrollToHistory(tester);

    expect(
      find.descendant(
        of: find.byType(SleepHistoryList),
        matching: find.text('7h 59m'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SleepHistoryList),
        matching: find.text('8h 0m'),
      ),
      findsOneWidget,
    );

    final rings = tester
        .widgetList<M3EProgressIndicator>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3EProgressIndicator),
          ),
        )
        .toList();
    final badges = tester
        .widgetList<M3EShapeContainer>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3EShapeContainer),
          ),
        )
        .toList();
    expect(rings, hasLength(1));
    expect(badges, hasLength(1));
    expect(badges.single.kind, M3EShapeKind.clover8Leaf);

    // The visual mark is decorative, so the state also reaches screen readers.
    expect(find.bySemanticsLabel(RegExp('goal met')), findsOneWidget);
  });

  testWidgets('uses the two-line compact cards for Month and All', (
    tester,
  ) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
    );

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    await scrollToHistory(tester);

    final cards = tester
        .widgetList<M3ECard>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3ECard),
          ),
        )
        .toList();
    expect(cards, hasLength(4));
    expect(cards.first.padding, const EdgeInsets.all(12));

    final compactScheme = Sleepy3Theme.light().colorScheme;
    expect(cards[3].color, compactScheme.surfaceContainerHighest);

    final rings = tester
        .widgetList<M3EProgressIndicator>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3EProgressIndicator),
          ),
        )
        .toList();
    expect(rings, hasLength(2));
    expect(rings.every((ring) => ring.size == 36), isTrue);

    final badges = tester
        .widgetList<M3EShapeContainer>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3EShapeContainer),
          ),
        )
        .toList();
    expect(badges, hasLength(2));
    expect(
      badges.every((badge) => badge.kind == M3EShapeKind.clover8Leaf),
      isTrue,
    );
    expect(badges.every((badge) => badge.width == 36), isTrue);

    final duration = tester.widget<Text>(
      find.descendant(
        of: find.byType(SleepHistoryList),
        matching: find.text('8h 13m'),
      ),
    );
    expect(duration.style?.fontSize, 22);

    await scrollToTop(tester);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await scrollToHistory(tester);

    final allCards = tester
        .widgetList<M3ECard>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3ECard),
          ),
        )
        .toList();
    expect(allCards, hasLength(4));
    expect(allCards.first.padding, const EdgeInsets.all(12));
  });

  testWidgets('puts the latest session of the newest day first', (
    tester,
  ) async {
    final night = closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7));
    final nap = closed(DateTime(2026, 10, 21, 13), DateTime(2026, 10, 21, 14));

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 18),
      initial: SleepSnapshot(closedSessions: [night, nap]),
    );

    await scrollToHistory(tester);

    final cards = tester
        .widgetList<M3ECard>(
          find.descendant(
            of: find.byType(SleepHistoryList),
            matching: find.byType(M3ECard),
          ),
        )
        .toList();
    expect(cards, hasLength(2));
    final scheme = Sleepy3Theme.light().colorScheme;
    expect(cards.first.color, scheme.primaryContainer);
    expect(
      cards.last.color,
      Color.lerp(
        scheme.surfaceContainerHighest,
        scheme.primaryContainer,
        2 / 3,
      ),
    );
    final napDuration = find.descendant(
      of: find.byType(SleepHistoryList),
      matching: find.text('1h 0m'),
    );
    final nightDuration = find.descendant(
      of: find.byType(SleepHistoryList),
      matching: find.text('8h 0m'),
    );
    expect(
      tester.getTopLeft(napDuration).dy,
      lessThan(tester.getTopLeft(nightDuration).dy),
    );
  });

  testWidgets('fits the compact history at 200% text', (tester) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
      textScale: 2,
    );

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Today'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rows no longer show the edit action', (tester) async {
    final editable = SleepSession(
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
      localId: 1,
    );
    final readOnly = closed(
      DateTime(2026, 10, 19, 22),
      DateTime(2026, 10, 20, 6),
    );

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: [editable, readOnly]),
    );

    await scrollToHistory(tester);

    expect(find.byIcon(M3EIcons.edit_outlined), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SleepHistoryList),
        matching: find.byType(M3ECard),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('marks only sessions from other apps in Local mode', (
    tester,
  ) async {
    final local = SleepSession(
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
      localId: 1,
    );
    final uploaded = SleepSession(
      startedAt: DateTime(2026, 10, 19, 22),
      endedAt: DateTime(2026, 10, 20, 6),
      localId: 2,
      healthRecordId: 'health-uploaded',
      sourceId: 'com.sleepy3.app',
    );
    final downloadedOther = SleepSession(
      startedAt: DateTime(2026, 10, 18, 22),
      endedAt: DateTime(2026, 10, 19, 6),
      localId: 4,
      isDownloaded: true,
      healthRecordId: 'health-downloaded-other',
      sourceId: 'com.sec.android.app.shealth',
    );

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(
        closedSessions: [local, uploaded, downloadedOther],
      ),
      appInfo: FakeAppInfoGateway({
        'com.sec.android.app.shealth': 'Samsung Health',
      }),
    );

    await scrollToHistory(tester);

    expect(find.text('Samsung Health'), findsOneWidget);
    expect(find.byIcon(M3EIcons.open_in_new_outlined), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(M3EIcons.open_in_new_outlined)).color,
      Sleepy3Theme.light().colorScheme.onSurface,
    );
    expect(find.byIcon(M3EIcons.smartphone), findsNothing);
    expect(find.byIcon(M3EIcons.cloud_outlined), findsNothing);
  });

  testWidgets('marks Google Health records written by another app', (
    tester,
  ) async {
    final own = HealthSleepSession(
      uuid: 'own',
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
      sourceId: 'com.sleepy3.app',
    );
    final other = HealthSleepSession(
      uuid: 'other',
      startedAt: DateTime(2026, 10, 19, 22),
      endedAt: DateTime(2026, 10, 20, 6),
      sourceId: 'com.sec.android.app.shealth',
    );

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      source: SleepDataSource.healthConnect,
      gateway: FakeHealthConnectGateway(sessions: [own, other]),
      appInfo: FakeAppInfoGateway({
        'com.sec.android.app.shealth': 'Samsung Health',
      }),
    );

    await scrollToHistory(tester);

    expect(find.text('Samsung Health'), findsOneWidget);
    expect(find.byIcon(M3EIcons.open_in_new_outlined), findsOneWidget);
    expect(find.byIcon(M3EIcons.smartphone), findsNothing);
    expect(find.byIcon(M3EIcons.cloud_outlined), findsNothing);
  });

  testWidgets('leaves downloaded Sleepy3 copies unmarked in Local mode', (
    tester,
  ) async {
    final downloadedOwn = SleepSession(
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
      localId: 1,
      isDownloaded: true,
      healthRecordId: 'health-downloaded-own',
      sourceId: 'com.sleepy3.app',
    );

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: [downloadedOwn]),
    );

    await scrollToHistory(tester);

    expect(find.byIcon(M3EIcons.open_in_new_outlined), findsNothing);
    expect(find.text('Another app'), findsNothing);
  });

  testWidgets('does not look up the source label for own sessions', (
    tester,
  ) async {
    final appInfo = FakeAppInfoGateway();

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
      appInfo: appInfo,
    );

    expect(appInfo.requests, isEmpty);
  });

  testWidgets('falls back to Another app when the label is missing', (
    tester,
  ) async {
    final downloaded = SleepSession(
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
      localId: 1,
      isDownloaded: true,
      healthRecordId: 'health-downloaded',
      sourceId: 'com.example.uninstalled',
    );

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: [downloaded]),
    );

    await scrollToHistory(tester);

    expect(find.text('Another app'), findsOneWidget);
    expect(find.byIcon(M3EIcons.open_in_new_outlined), findsOneWidget);
  });

  testWidgets('announces the source of a session from another app', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final downloaded = SleepSession(
      startedAt: DateTime(2026, 10, 17, 22),
      endedAt: DateTime(2026, 10, 18, 6),
      localId: 1,
      isDownloaded: true,
      healthRecordId: 'health-downloaded',
      sourceId: 'com.sec.android.app.shealth',
    );

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: [downloaded]),
      appInfo: FakeAppInfoGateway({
        'com.sec.android.app.shealth': 'Samsung Health',
      }),
    );

    await scrollToHistory(tester);

    expect(
      find.bySemanticsLabel(
        RegExp('Read-only, from Samsung Health, Sunday, October 18'),
      ),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('fits the source pill at 200% text', (tester) async {
    final downloaded = SleepSession(
      startedAt: DateTime(2026, 10, 20, 22),
      endedAt: DateTime(2026, 10, 21, 6),
      localId: 1,
      isDownloaded: true,
      healthRecordId: 'health-downloaded',
      sourceId: 'com.sec.android.app.shealth',
    );

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: [downloaded]),
      appInfo: FakeAppInfoGateway({
        'com.sec.android.app.shealth': 'Samsung Health',
      }),
      textScale: 2,
    );

    await tester.scrollUntilVisible(
      find.text('Samsung Health'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Samsung Health'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches between Week, Month, 3 months, Year and All', (
    tester,
  ) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
    );

    var chips = tester.widgetList<M3EChip>(find.byType(M3EChip)).toList();
    expect(chips.map((chip) => chip.label), [
      'Week',
      'Month',
      '3 months',
      'Year',
      'All',
    ]);
    expect(chips[0].selected, isTrue);
    expect(chips[1].selected, isFalse);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    chips = tester.widgetList<M3EChip>(find.byType(M3EChip)).toList();
    expect(chips[1].selected, isTrue);
    expect(find.text('Across 4 nights · 30h 3m total'), findsOneWidget);

    await scrollToHistory(tester);
    expect(find.text('Wed, Oct 14'), findsOneWidget);

    await scrollToTop(tester);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    chips = tester.widgetList<M3EChip>(find.byType(M3EChip)).toList();
    expect(chips[4].selected, isTrue);
    expect(find.text('Across 4 nights · 30h 3m total'), findsOneWidget);
  });

  testWidgets('offers Show all when the range is empty', (tester) async {
    final older = [closed(DateTime(2026, 9, 1, 22), DateTime(2026, 9, 2, 6))];

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: older),
    );

    expect(
      find.descendant(of: find.byType(StatsHeroCard), matching: find.text('—')),
      findsOneWidget,
    );
    expect(find.text('No nights in this range'), findsOneWidget);
    expect(find.text('Show all'), findsOneWidget);
    expect(find.text('History'), findsNothing);

    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();

    expect(find.text('No nights in this range'), findsNothing);
    expect(find.text('Show all'), findsNothing);
    expect(find.text('8h 0m'), findsWidgets);

    await scrollToHistory(tester);
    expect(find.text('Wed, Sep 2'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('does not offer Show all when every session is in the future', (
    tester,
  ) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(
        closedSessions: [
          closed(DateTime(2026, 10, 22, 1), DateTime(2026, 10, 22, 7)),
        ],
      ),
    );

    expect(find.text('No nights in this range'), findsOneWidget);
    expect(find.text('Show all'), findsNothing);
    expect(find.text('History'), findsNothing);
  });

  testWidgets('explains an open session without counting it', (tester) async {
    final open = SleepSession(startedAt: DateTime(2026, 10, 21, 22, 30));
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 23),
      initial: SleepSnapshot(openSession: open),
    );

    expect(
      find.text('Sleeping since 10:30 PM · it will appear when you wake.'),
      findsOneWidget,
    );
    expect(
      find.text('Your first night will appear here when you wake up.'),
      findsOneWidget,
    );
    expect(find.text('Average sleep'), findsNothing);
  });

  testWidgets('shows the open-session line while closed history is visible', (
    tester,
  ) async {
    final open = SleepSession(startedAt: DateTime(2026, 10, 21, 22, 30));
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 23),
      initial: SleepSnapshot(
        openSession: open,
        closedSessions: [sessions.first],
      ),
    );

    expect(
      find.text('Sleeping since 10:30 PM · it will appear when you wake.'),
      findsOneWidget,
    );
    expect(find.text('8h 13m'), findsWidgets);
    expect(find.text('Across 1 night · 8h 13m total'), findsOneWidget);
  });

  testWidgets('uses the system 24-hour format', (tester) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
      use24HourFormat: true,
    );

    await scrollToHistory(tester);

    expect(find.text('22:32 – 06:45'), findsOneWidget);
    expect(find.text('10:32 PM – 6:45 AM'), findsNothing);
  });

  testWidgets('exposes the summary and each row to screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
    );

    expect(
      find.bySemanticsLabel(
        RegExp('Average sleep 7 hours 21 minutes, across 3 nights'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Goal hit rate, 33%, 1 of 3 nights')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Time range'), findsOneWidget);

    await scrollToHistory(tester);

    expect(
      find.bySemanticsLabel(
        RegExp('Today, 8 hours 13 minutes, goal met, 10:32 PM to 6:45 AM'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp('Yesterday, 7 hours 2 minutes, 11:10 PM to 6:12 AM'),
      ),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('fits on a 360dp phone at 200% text', (tester) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Average sleep'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Today'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('updates Today to Yesterday when the local day changes', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 21, 23, 59, 59);
    await pumpStats(
      tester,
      clock: () => now,
      initial: SleepSnapshot(
        closedSessions: [
          closed(DateTime(2026, 10, 20, 23), DateTime(2026, 10, 21, 7)),
        ],
      ),
    );

    await scrollToHistory(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsNothing);

    now = DateTime(2026, 10, 22, 0, 0, 1);
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Today'), findsNothing);
    expect(find.text('Yesterday'), findsOneWidget);
  });

  testWidgets('uses a wider margin on a medium window', (tester) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
      size: const Size(800, 900),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Average sleep'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Stats')).dx, 24);

    final summaryTable = tester.widget<Table>(
      find.descendant(
        of: find.byType(StatsMetricsCard),
        matching: find.byType(Table),
      ),
    );
    expect(summaryTable.columnWidths, hasLength(2));

    await openAdvanced(tester);

    final advancedTable = tester.widget<Table>(inAdvanced(find.byType(Table)));
    expect(advancedTable.columnWidths, hasLength(4));
  });

  testWidgets('renders the dashboard in the dark theme', (tester) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
      dark: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Average sleep'), findsOneWidget);

    await openAdvanced(tester);

    expect(inAdvanced(find.text('Sleep duration')), findsOneWidget);
    expect(inAdvanced(find.text('Sleep window')), findsOneWidget);
    expect(inAdvanced(find.text('By weekday')), findsOneWidget);
  });

  testWidgets('shows a loading card while the history loads', (tester) async {
    final store = FakeSleepSessionStore();
    store.closedLoadGate = Completer<void>();

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      store: store,
      settle: false,
    );

    expect(find.text('Loading sleep history…'), findsOneWidget);
    expect(find.text('Average sleep'), findsNothing);

    store.closedLoadGate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Loading sleep history…'), findsNothing);
    expect(find.text('No sleep history yet'), findsOneWidget);
  });

  testWidgets('shows an error card and Retry reloads the history', (
    tester,
  ) async {
    final store = FakeSleepSessionStore()
      ..closedLoadError = StateError('read failed');

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      store: store,
    );

    expect(find.text("Couldn't load your sleep history"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    store.closedLoadError = null;
    store.snapshot = SleepSnapshot(closedSessions: sessions);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your sleep history"), findsNothing);
    expect(find.text('Average sleep'), findsOneWidget);
    expect(find.text('7h 21m'), findsOneWidget);
  });

  testWidgets('Google Health shows only Health Connect sessions', (
    tester,
  ) async {
    final health = HealthSleepSession(
      uuid: 'health-1',
      startedAt: DateTime(2026, 10, 20, 23),
      endedAt: DateTime(2026, 10, 21, 5),
    );

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
      source: SleepDataSource.healthConnect,
      gateway: FakeHealthConnectGateway(sessions: [health]),
    );

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Across 1 night · 6h 0m total'), findsOneWidget);
    expect(find.text('6h 0m'), findsWidgets);
    expect(find.text('8h 13m'), findsNothing);
  });

  testWidgets('Google Health empty state never falls back to local data', (
    tester,
  ) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
      source: SleepDataSource.healthConnect,
      gateway: FakeHealthConnectGateway(),
    );

    expect(find.text('No sleep history in Google Health'), findsOneWidget);
    expect(
      find.text('Sleep sessions in Health Connect will appear here.'),
      findsOneWidget,
    );
    expect(find.text('Average sleep'), findsNothing);
    expect(find.text('8h 13m'), findsNothing);
  });

  testWidgets('shows pending uploads above the Health Connect history', (
    tester,
  ) async {
    final session = closed(
      DateTime(2026, 10, 20, 22),
      DateTime(2026, 10, 21, 6),
    );
    final gateway = FakeHealthConnectGateway()
      ..writeError = StateError('Health Connect is offline');

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      source: SleepDataSource.healthConnect,
      gateway: gateway,
      healthSyncStore: FakeHealthSyncStore()..addLocal(session),
    );

    expect(find.text('1 session waiting to sync'), findsOneWidget);
    expect(find.text('No sleep history in Google Health'), findsOneWidget);

    gateway.writeError = null;
    await tester.tap(find.widgetWithText(M3EButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.text('1 session waiting to sync'), findsNothing);
    expect(find.text('No sleep history in Google Health'), findsNothing);
    expect(find.text('Average sleep'), findsOneWidget);
    expect(find.text('Across 1 night · 8h 0m total'), findsOneWidget);
  });

  group('pull to refresh', () {
    testWidgets('shows the 48 dp loader while the list stays visible', (
      tester,
    ) async {
      final old = closed(
        DateTime(2026, 10, 20, 22, 32),
        DateTime(2026, 10, 21, 6, 45),
      );
      final fresh = closed(
        DateTime(2026, 10, 20, 23, 10),
        DateTime(2026, 10, 21, 6, 12),
      );
      final store = FakeSleepSessionStore(
        snapshot: SleepSnapshot(closedSessions: [old]),
      );

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        store: store,
      );

      await scrollToHistory(tester);
      expect(find.text('10:32 PM – 6:45 AM'), findsOneWidget);

      await scrollToTop(tester);
      store.snapshot = SleepSnapshot(closedSessions: [fresh]);
      store.closedLoadGate = Completer<void>();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump();

      final loader = tester.widget<M3ELoadingIndicator>(
        find.byType(M3ELoadingIndicator),
      );
      expect(loader.size, 48);
      expect(find.text('Average sleep'), findsOneWidget);

      store.closedLoadGate!.complete();
      await tester.pumpAndSettle();

      await scrollToHistory(tester);
      expect(find.text('10:32 PM – 6:45 AM'), findsNothing);
      expect(find.text('11:10 PM – 6:12 AM'), findsOneWidget);
    });

    testWidgets('pull retries pending uploads before reading Google Health', (
      tester,
    ) async {
      final session = closed(
        DateTime(2026, 10, 20, 22),
        DateTime(2026, 10, 21, 6),
      );
      final gateway = FakeHealthConnectGateway()
        ..writeError = StateError('Health Connect is offline');

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        source: SleepDataSource.healthConnect,
        gateway: gateway,
        healthSyncStore: FakeHealthSyncStore()..addLocal(session),
      );

      expect(find.text('1 session waiting to sync'), findsOneWidget);

      gateway.writeError = null;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(gateway.writes, hasLength(1));
      expect(find.text('1 session waiting to sync'), findsNothing);
      expect(find.text('Across 1 night · 8h 0m total'), findsOneWidget);
    });

    testWidgets('pull in Local never uploads a new local session', (
      tester,
    ) async {
      final session = closed(
        DateTime(2026, 10, 20, 22),
        DateTime(2026, 10, 21, 6),
      );
      final gateway = FakeHealthConnectGateway();

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        store: FakeSleepSessionStore(
          snapshot: SleepSnapshot(closedSessions: [session]),
        ),
        gateway: gateway,
        healthSyncStore: FakeHealthSyncStore()..addLocal(session),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(gateway.writes, isEmpty);
      expect(find.text('8h 0m'), findsWidgets);
    });

    testWidgets('a failed pull keeps the visible rows and explains it', (
      tester,
    ) async {
      final old = closed(
        DateTime(2026, 10, 20, 22, 32),
        DateTime(2026, 10, 21, 6, 45),
      );
      final store = FakeSleepSessionStore(
        snapshot: SleepSnapshot(closedSessions: [old]),
      );

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        store: store,
      );

      await scrollToHistory(tester);
      expect(find.text('10:32 PM – 6:45 AM'), findsOneWidget);

      await scrollToTop(tester);
      store.closedLoadError = StateError('offline');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't refresh your sleep history. Try again."),
        findsOneWidget,
      );

      await scrollToHistory(tester);
      expect(find.text('10:32 PM – 6:45 AM'), findsOneWidget);
    });

    testWidgets('the empty state can pull to refresh', (tester) async {
      final store = FakeSleepSessionStore();
      final fresh = closed(
        DateTime(2026, 10, 20, 22),
        DateTime(2026, 10, 21, 6),
      );

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        store: store,
      );

      expect(find.text('No sleep history yet'), findsOneWidget);
      store.snapshot = SleepSnapshot(closedSessions: [fresh]);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.text('No sleep history yet'), findsNothing);
      expect(find.text('8h 0m'), findsWidgets);
    });

    testWidgets('the empty state fits at 200% text', (tester) async {
      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No sleep history yet'), findsOneWidget);
    });
  });

  group('history permission', () {
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

    testWidgets('All without history access keeps 30 days and explains it', (
      tester,
    ) async {
      final gateway = FakeHealthConnectGateway(
        sessions: [old, recent],
        historyPermission: false,
        grantHistoryOnRequest: false,
      );

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        source: SleepDataSource.healthConnect,
        gateway: gateway,
      );

      // The initial read already stops 30 days back, so the old night is out.
      expect(find.text('Across 1 night · 8h 0m total'), findsOneWidget);
      expect(find.text('Wed, Sep 2'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(gateway.historyPermissionRequestCalls, 1);
      expect(find.text('Only the last 30 days are available'), findsOneWidget);
      expect(find.text('Allow full history'), findsOneWidget);
      expect(find.text('Wed, Sep 2'), findsNothing);
      expect(find.text('Across 1 night · 8h 0m total'), findsOneWidget);
    });

    testWidgets('3 months without history access asks and explains the limit', (
      tester,
    ) async {
      final gateway = FakeHealthConnectGateway(
        sessions: [old, recent],
        historyPermission: false,
        grantHistoryOnRequest: false,
      );

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        source: SleepDataSource.healthConnect,
        gateway: gateway,
      );

      expect(gateway.historyPermissionRequestCalls, 0);

      await tester.tap(find.text('3 months'));
      await tester.pumpAndSettle();

      expect(gateway.historyPermissionRequestCalls, 1);
      expect(find.text('Only the last 30 days are available'), findsOneWidget);
      expect(find.text('Allow full history'), findsOneWidget);

      await openAdvanced(tester);

      expect(find.textContaining('Last 30 days available'), findsNWidgets(3));
      expect(
        find.text('Bedtime to wake · Last 30 days available'),
        findsOneWidget,
      );
      expect(
        find.text('Average by wake day · Last 30 days available'),
        findsOneWidget,
      );
      expect(find.text('Wed, Sep 2'), findsNothing);
    });

    testWidgets('Year without history access asks and explains the limit', (
      tester,
    ) async {
      final gateway = FakeHealthConnectGateway(
        sessions: [old, recent],
        historyPermission: false,
        grantHistoryOnRequest: false,
      );

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        source: SleepDataSource.healthConnect,
        gateway: gateway,
      );

      expect(gateway.historyPermissionRequestCalls, 0);

      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();

      expect(gateway.historyPermissionRequestCalls, 1);
      expect(find.text('Only the last 30 days are available'), findsOneWidget);

      await openAdvanced(tester);

      expect(find.textContaining('Last 30 days available'), findsNWidgets(3));
      expect(find.text('Wed, Sep 2'), findsNothing);
    });

    testWidgets('All requests full history and reveals older sessions', (
      tester,
    ) async {
      final gateway = FakeHealthConnectGateway(
        sessions: [old, recent],
        historyPermission: false,
        grantHistoryOnRequest: true,
      );

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        source: SleepDataSource.healthConnect,
        gateway: gateway,
      );

      expect(find.text('Wed, Sep 2'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(gateway.historyPermissionRequestCalls, 1);
      expect(find.text('Only the last 30 days are available'), findsNothing);
      expect(find.text('Across 2 nights · 16h 0m total'), findsOneWidget);

      await scrollToHistory(tester);
      expect(find.text('Wed, Sep 2'), findsOneWidget);
    });

    testWidgets('Allow full history in the banner reloads after a denial', (
      tester,
    ) async {
      final gateway = FakeHealthConnectGateway(
        sessions: [old, recent],
        historyPermission: false,
        grantHistoryOnRequest: false,
      );

      await pumpStats(
        tester,
        clock: () => DateTime(2026, 10, 21, 10),
        source: SleepDataSource.healthConnect,
        gateway: gateway,
      );

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Only the last 30 days are available'), findsOneWidget);

      gateway.grantHistoryOnRequest = true;
      await tester.tap(find.text('Allow full history'));
      await tester.pumpAndSettle();

      expect(gateway.historyPermissionRequestCalls, 2);
      expect(find.text('Only the last 30 days are available'), findsNothing);
      expect(find.text('Across 2 nights · 16h 0m total'), findsOneWidget);

      await scrollToHistory(tester);
      expect(find.text('Wed, Sep 2'), findsOneWidget);
    });
  });

  testWidgets('renders the history and summary in Spanish', (tester) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
      locale: const Locale('es'),
    );

    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Sueño medio'), findsOneWidget);
    expect(find.text('Semana'), findsOneWidget);
    expect(find.text('3 de 7 noches'), findsOneWidget);
    expect(find.text('Objetivo cumplido'), findsOneWidget);
    expect(find.text('33 %'), findsOneWidget);
    expect(find.text('1 de 3 noches'), findsOneWidget);
    expect(find.text('Consistencia del horario'), findsNothing);
    expect(find.text('Balance de sueño'), findsOneWidget);
    expect(find.text('−1 h 57 min'), findsOneWidget);
    expect(find.text('deuda · frente al objetivo de 8 h'), findsOneWidget);
    expect(find.text('Ver estadísticas avanzadas'), findsOneWidget);

    await openAdvanced(tester);

    expect(inAdvanced(find.text('Estadísticas avanzadas')), findsOneWidget);
    expect(inAdvanced(find.text('Consistencia del horario')), findsOneWidget);
    expect(inAdvanced(find.text('Mejor racha')), findsOneWidget);
    expect(inAdvanced(find.text('1 noche')), findsOneWidget);
    expect(inAdvanced(find.text('actual 1')), findsOneWidget);

    await closeAdvanced(tester);
    await scrollToHistory(tester);
    expect(find.text('Hoy'), findsOneWidget);
  });
}
