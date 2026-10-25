import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/app/sleepy3_app.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session.dart';
import 'package:sleepy3/features/sleep_tracking/domain/sleep_session_store.dart';

import '../fakes.dart';

void main() {
  Future<FakeSleepSessionStore> pumpHome(
    WidgetTester tester, {
    required DateTime Function() clock,
    SleepSnapshot initial = SleepSnapshot.empty,
    bool use24HourFormat = false,
  }) async {
    final store = FakeSleepSessionStore();
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          // The View's MediaQuery does not rebuild when the test dispatcher's
          // alwaysUse24HourFormatTestValue changes, so override it directly.
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(alwaysUse24HourFormat: use24HourFormat),
            child: ProviderScope(
              overrides: [
                sleepClockProvider.overrideWithValue(clock),
                sleepSessionStoreProvider.overrideWithValue(store),
                initialSleepSnapshotProvider.overrideWithValue(initial),
              ],
              child: const Sleepy3App(),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('the two actions drive the sleep state machine', (tester) async {
    var now = DateTime(2026, 10, 20, 22, 30);
    final store = await pumpHome(tester, clock: () => now);

    expect(find.text('Night · time to rest'), findsOneWidget);
    expect(find.text('10:30:00'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    expect(find.text('Tuesday, October 20'), findsOneWidget);
    expect(find.text('Tap Sleep when you turn off the lights'), findsOneWidget);
    expect(find.text('Last 3 days · — avg'), findsOneWidget);

    var buttons = tester.widgetList<M3EButton>(find.byType(M3EButton)).toList();
    expect(buttons, hasLength(2));
    expect(buttons[0].enabled, isTrue);
    expect(buttons[1].enabled, isFalse);

    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();

    expect(find.text('Sleeping since 10:30 PM'), findsOneWidget);
    expect(store.starts, hasLength(1));
    buttons = tester.widgetList<M3EButton>(find.byType(M3EButton)).toList();
    expect(buttons[0].enabled, isFalse);
    expect(buttons[1].enabled, isTrue);

    now = now.add(const Duration(hours: 7, minutes: 45));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Wake'));
    await tester.pumpAndSettle();

    expect(find.text('Last session: 7h 45m'), findsOneWidget);
    expect(find.text('6:15:00'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('Wednesday, October 21'), findsOneWidget);
    expect(find.text('Last 3 days · 7h 45m avg'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(store.finishes, hasLength(1));
    buttons = tester.widgetList<M3EButton>(find.byType(M3EButton)).toList();
    expect(buttons[0].enabled, isTrue);
    expect(buttons[1].enabled, isFalse);
  });

  testWidgets('restores a sleeping session on launch', (tester) async {
    final now = DateTime(2026, 10, 20, 23, 10);

    await pumpHome(
      tester,
      clock: () => now,
      initial: SleepSnapshot(openSession: SleepSession(startedAt: now)),
    );

    expect(find.text('Night · time to rest'), findsOneWidget);
    expect(find.text('Sleeping since 11:10 PM'), findsOneWidget);
    final buttons = tester
        .widgetList<M3EButton>(find.byType(M3EButton))
        .toList();
    expect(buttons[0].enabled, isFalse);
    expect(buttons[1].enabled, isTrue);
  });

  testWidgets('shows the three-day summary from the startup snapshot', (
    tester,
  ) async {
    final today = DateTime(2026, 10, 21);
    await pumpHome(
      tester,
      clock: () => DateTime(2026, 10, 21, 10),
      initial: SleepSnapshot(
        closedSessions: [
          SleepSession(
            startedAt: today,
            endedAt: today.add(const Duration(hours: 8)),
          ),
          SleepSession(
            startedAt: DateTime(2026, 10, 20),
            endedAt: DateTime(2026, 10, 20, 7),
          ),
        ],
      ),
    );

    expect(find.text('Last 3 days · 7h 30m avg'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('2 days ago'), findsOneWidget);
    expect(find.text('8h 0m'), findsOneWidget);
    expect(find.text('7h 0m'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('shows the day copy and chip during the day', (tester) async {
    await pumpHome(tester, clock: () => DateTime(2026, 10, 20, 10));

    expect(find.text('Day · ready to wake'), findsOneWidget);
    expect(find.text('10:00:00'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('No active session'), findsOneWidget);
  });

  testWidgets('uses the system 24-hour format', (tester) async {
    await pumpHome(
      tester,
      clock: () => DateTime(2026, 10, 20, 22, 30),
      use24HourFormat: true,
    );

    expect(find.text('22:30:00'), findsOneWidget);
    expect(find.text('PM'), findsNothing);

    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();

    expect(find.text('Sleeping since 22:30'), findsOneWidget);
  });

  testWidgets('exposes the clock and the day/night status to screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await pumpHome(tester, clock: () => DateTime(2026, 10, 20, 22, 30));

    expect(find.bySemanticsLabel('Current time 10:30:00 PM'), findsOneWidget);
    expect(find.bySemanticsLabel('Night, time to rest'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Tap Sleep when you turn off the lights'),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('updates the phase and the date as the clock advances', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 20, 18, 59, 59);
    await pumpHome(tester, clock: () => now);

    expect(find.text('Day · ready to wake'), findsOneWidget);
    expect(find.text('No active session'), findsOneWidget);
    expect(find.text('6:59:59'), findsOneWidget);

    now = DateTime(2026, 10, 20, 19);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Night · time to rest'), findsOneWidget);
    expect(find.text('Tap Sleep when you turn off the lights'), findsOneWidget);
    expect(find.text('7:00:00'), findsOneWidget);

    now = DateTime(2026, 10, 20, 23, 59, 59);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('11:59:59'), findsOneWidget);
    expect(find.text('Tuesday, October 20'), findsOneWidget);

    now = DateTime(2026, 10, 21);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Wednesday, October 21'), findsOneWidget);
    expect(find.text('12:00:00'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('Night · time to rest'), findsOneWidget);
  });

  testWidgets('the clock uses emphasized display type and tabular figures', (
    tester,
  ) async {
    await pumpHome(tester, clock: () => DateTime(2026, 10, 20, 22, 30));

    final clock = tester.widget<Text>(find.text('10:30:00'));
    expect(clock.style?.fontSize, 57);
    expect(clock.style?.fontWeight, FontWeight.w500);
    expect(
      clock.style?.fontFeatures?.any(
        (feature) =>
            feature.feature == FontFeature.tabularFigures().feature &&
            feature.value == FontFeature.tabularFigures().value,
      ),
      isTrue,
    );
  });

  testWidgets('fits on a 360dp phone at 200% text', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpHome(tester, clock: () => DateTime(2026, 10, 20, 22, 30));

    expect(tester.takeException(), isNull);
    expect(find.text('10:30:00'), findsOneWidget);
    expect(find.text('Night · time to rest'), findsOneWidget);

    // The clock shrinks to fit, but the rest of the screen keeps the system
    // scale.
    final clockContext = tester.element(find.text('10:30:00'));
    expect(MediaQuery.textScalerOf(clockContext).scale(57), lessThan(114));
    final sessionContext = tester.element(
      find.text('Tap Sleep when you turn off the lights'),
    );
    expect(MediaQuery.textScalerOf(sessionContext).scale(14), 28);
  });
}
