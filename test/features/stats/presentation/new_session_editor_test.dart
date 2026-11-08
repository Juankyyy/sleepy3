import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/app/navigation/pill_navigation_bar.dart';
import 'package:sleepy3/app/sleepy3_app.dart';
import 'package:sleepy3/features/health/application/health_connect_gateway_provider.dart';
import 'package:sleepy3/features/health/application/health_sync_store_provider.dart';
import 'package:sleepy3/features/health/application/sleep_data_source_controller.dart';
import 'package:sleepy3/features/health/domain/sleep_data_source.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';

import '../../health/fakes.dart';
import '../../sleep_tracking/fakes.dart';

void main() {
  final now = DateTime(2026, 10, 20, 22, 30);
  final defaultStart = DateTime(2026, 10, 19, 23);
  final defaultEnd = DateTime(2026, 10, 20, 7);

  Future<FakeSleepSessionStore> pumpApp(
    WidgetTester tester, {
    FakeSleepSessionStore? store,
    SleepDataSource source = SleepDataSource.local,
    FakeHealthConnectGateway? gateway,
    FakeHealthSyncStore? healthSyncStore,
    double textScale = 1,
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: disableAnimations);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final sleepStore = store ?? FakeSleepSessionStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sleepClockProvider.overrideWithValue(() => now),
          sleepSessionStoreProvider.overrideWithValue(sleepStore),
          initialSleepDataSourceProvider.overrideWithValue(source),
          healthConnectGatewayProvider.overrideWithValue(
            gateway ?? FakeHealthConnectGateway(),
          ),
          healthSyncStoreProvider.overrideWithValue(
            healthSyncStore ?? FakeHealthSyncStore(),
          ),
        ],
        child: Sleepy3App(splashStartSignal: Future<void>.value()),
      ),
    );
    await tester.pumpAndSettle();
    return sleepStore;
  }

  Future<void> openStats(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('nav-stats')));
    await tester.pumpAndSettle();
  }

  Future<void> openNewSession(WidgetTester tester) async {
    await tester.tap(find.byType(M3EFab));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> pickDay(WidgetTester tester, String day) async {
    await tester.tap(find.text(day).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('shows the FAB only on Stats', (tester) async {
    await pumpApp(tester);

    expect(find.byType(M3EFab), findsNothing);

    await openStats(tester);
    expect(find.byType(M3EFab), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(M3EFab), findsNothing);
  });

  testWidgets('uses the regular filled primary plus FAB', (tester) async {
    await pumpApp(tester);
    await openStats(tester);

    final fab = tester.widget<M3EFab>(find.byType(M3EFab));
    expect(fab.size, M3EFabSize.regular);
    expect(fab.color, M3EFabColor.primaryFilled);
    expect(fab.cornerRadius, 28);
    expect(fab.tooltip, 'Add a sleep session');
    expect(find.byIcon(M3EIcons.add_rounded), findsOneWidget);
  });

  testWidgets('appears at rest when animations are disabled', (tester) async {
    await pumpApp(tester, disableAnimations: true);
    await openStats(tester);

    final rect = tester.getRect(find.byType(M3EFab));
    expect(rect.width, closeTo(56, 0.01));
    expect(rect.height, closeTo(56, 0.01));
    expect(find.byIcon(M3EIcons.add_rounded), findsOneWidget);
  });

  testWidgets('sits beside the dock as one centered group', (tester) async {
    await pumpApp(tester);
    await openStats(tester);

    final glass = tester.getRect(find.byKey(PillNavigationBar.surfaceKey));
    final fab = tester.getRect(find.byType(M3EFab));

    expect(fab.left - glass.right, closeTo(12, 0.01));
    expect(fab.center.dy, closeTo(glass.center.dy, 0.01));
    expect((glass.left + fab.right) / 2, closeTo(180, 0.01));
    expect(
      glass.bottom,
      closeTo(800 - PillNavigationBar.bottomGap, 0.01),
      reason: 'The bar with the trailing FAB stays at the bottom',
    );
  });

  testWidgets('opens with the last night and adds it in Local mode', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    await openStats(tester);
    await openNewSession(tester);

    expect(find.text('New session'), findsOneWidget);
    expect(find.text('Fell asleep'), findsOneWidget);
    expect(find.text('Woke up'), findsOneWidget);
    expect(find.text('Mon, Oct 19'), findsOneWidget);
    expect(find.text('Tue, Oct 20'), findsOneWidget);
    expect(find.text('11:00 PM'), findsOneWidget);
    expect(find.text('7:00 AM'), findsOneWidget);
    expect(find.text('8h 0m'), findsOneWidget);
    expect(find.text('Goal met'), findsOneWidget);
    expect(find.text('Woke Tue, Oct 20, 2026'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('New session'), findsNothing);
    expect(find.text('Session added.'), findsOneWidget);
    expect(store.inserted.single.startedAt, defaultStart);
    expect(store.inserted.single.endedAt, defaultEnd);
    expect(find.text('11:00 PM – 7:00 AM'), findsOneWidget);
    expect(find.text('No sleep history yet'), findsNothing);
  });

  testWidgets('shows the overlap error inline and keeps the form open', (
    tester,
  ) async {
    final existing = SleepSession(startedAt: defaultStart, endedAt: defaultEnd);
    final store = await pumpApp(
      tester,
      store: FakeSleepSessionStore(
        snapshot: SleepSnapshot(closedSessions: [existing]),
      ),
    );
    await openStats(tester);
    await openNewSession(tester);

    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text('This session overlaps another sleep session.'),
      findsOneWidget,
    );
    expect(find.text('New session'), findsOneWidget);
    expect(store.inserted, isEmpty);
  });

  testWidgets('discards a changed date only after confirmation', (
    tester,
  ) async {
    final store = await pumpApp(tester);
    await openStats(tester);
    await openNewSession(tester);

    await tester.tap(find.text('Mon, Oct 19'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await pickDay(tester, '18');

    await tester.tap(find.byIcon(M3EIcons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('New session'), findsNothing);
    expect(store.inserted, isEmpty);
  });

  testWidgets('explains Google Health and reports a successful upload', (
    tester,
  ) async {
    final gateway = FakeHealthConnectGateway();
    final store = await pumpApp(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: gateway,
    );
    await openStats(tester);
    await openNewSession(tester);

    expect(
      find.text('This night will be added to Google Health.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('New session'), findsNothing);
    expect(find.text('Session added to Google Health.'), findsOneWidget);
    expect(gateway.writes.single.startedAt, defaultStart);
    expect(gateway.writes.single.endedAt, defaultEnd);
    expect(store.inserted.single.startedAt, defaultStart);
    expect(find.text('11:00 PM – 7:00 AM'), findsOneWidget);
  });

  testWidgets('reports a failed Google Health upload as pending', (
    tester,
  ) async {
    final store = await pumpApp(
      tester,
      source: SleepDataSource.healthConnect,
      gateway: FakeHealthConnectGateway()..writeSucceeds = false,
    );
    await openStats(tester);
    await openNewSession(tester);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('New session'), findsNothing);
    expect(
      find.text(
        'Session saved locally. Google Health will update when it can.',
      ),
      findsOneWidget,
    );
    expect(store.inserted.single.startedAt, defaultStart);
    expect(find.text('No sleep history in Google Health'), findsOneWidget);
  });

  testWidgets('fits at 200% text', (tester) async {
    await pumpApp(tester, textScale: 2);
    await openStats(tester);
    await openNewSession(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('New session'), findsOneWidget);
    expect(find.text('Fell asleep'), findsOneWidget);
    expect(find.text('Woke up'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });
}
