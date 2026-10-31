import 'dart:async';

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
import 'package:sleepy3/features/stats/presentation/stats_screen.dart';
import 'package:sleepy3/features/stats/presentation/widgets/stats_summary_card.dart';

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
    FakeSleepSessionStore? store,
    SleepDataSource source = SleepDataSource.local,
    FakeHealthConnectGateway? gateway,
    FakeHealthSyncStore? healthSyncStore,
    bool settle = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final sleepStore = store ?? FakeSleepSessionStore(snapshot: initial);
    final data = Sleepy3Theme.light();
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
              ],
              child: M3EMaterialApp(
                title: 'Sleepy3',
                data: data,
                theme: data.toThemeData(),
                locale: const Locale('en', 'US'),
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                supportedLocales: const [Locale('en', 'US')],
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

  testWidgets('shows an empty state when there is no history', (tester) async {
    await pumpStats(tester, clock: () => DateTime(2026, 10, 21, 10));

    expect(find.text('Stats'), findsOneWidget);
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
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('8h 13m'), findsOneWidget);
    expect(find.text('10:32 PM – 6:45 AM'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Thu, Oct 15'), findsOneWidget);
    expect(find.text('Wed, Oct 14'), findsNothing);

    final card = tester.widget<M3ECard>(
      find.descendant(
        of: find.byType(StatsSummaryCard),
        matching: find.byType(M3ECard),
      ),
    );
    expect(card.variant, M3ECardVariant.outlined);

    final list = tester.widget<M3EList>(find.byType(M3EList));
    expect(list.variant, M3ECardVariant.filled);

    expect(
      find.byWidgetPredicate((widget) => widget is M3EListItem),
      findsNWidgets(3),
    );
    // These fake sessions have no Drift row id, so Local mode treats them as
    // read-only copies.
    expect(find.byIcon(M3EIcons.edit_outlined), findsNothing);
  });

  testWidgets('marks only editable sessions with the edit action', (
    tester,
  ) async {
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

    expect(find.byIcon(M3EIcons.edit_outlined), findsOneWidget);
  });

  testWidgets('switches between 7 days, 30 days and All', (tester) async {
    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: sessions),
    );

    var chips = tester.widgetList<M3EChip>(find.byType(M3EChip)).toList();
    expect(chips.map((chip) => chip.label), ['7 days', '30 days', 'All']);
    expect(chips[0].selected, isTrue);
    expect(chips[1].selected, isFalse);

    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();

    chips = tester.widgetList<M3EChip>(find.byType(M3EChip)).toList();
    expect(chips[1].selected, isTrue);
    expect(find.text('Across 4 nights · 30h 3m total'), findsOneWidget);
    expect(find.text('Wed, Oct 14'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    chips = tester.widgetList<M3EChip>(find.byType(M3EChip)).toList();
    expect(chips[2].selected, isTrue);
    expect(find.text('Across 4 nights · 30h 3m total'), findsOneWidget);
  });

  testWidgets('offers Show all when the range is empty', (tester) async {
    final older = [closed(DateTime(2026, 9, 1, 22), DateTime(2026, 9, 2, 6))];

    await pumpStats(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(closedSessions: older),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('No nights in this range'), findsOneWidget);
    expect(find.text('Show all'), findsOneWidget);
    expect(find.text('History'), findsNothing);

    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();

    expect(find.text('No nights in this range'), findsNothing);
    expect(find.text('Show all'), findsNothing);
    expect(find.text('8h 0m'), findsWidgets);
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
      find.bySemanticsLabel(
        RegExp('Today, 8 hours 13 minutes, 10:32 PM to 6:45 AM'),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Time range'), findsOneWidget);

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
    expect(find.text('7 days'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
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
      expect(find.text('Wed, Sep 2'), findsOneWidget);
      expect(find.text('Across 2 nights · 16h 0m total'), findsOneWidget);
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
      expect(find.text('Wed, Sep 2'), findsOneWidget);
    });
  });
}
