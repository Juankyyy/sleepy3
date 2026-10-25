import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sleepy3/core/time/clock_format.dart';
import 'package:sleepy3/features/sleep_tracking/application/sleep_tracking_controller.dart';
import 'package:sleepy3/features/sleep_tracking/presentation/widgets/live_clock.dart';

void main() {
  Future<void> pumpClock(WidgetTester tester, DateTime Function() clock) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sleepClockProvider.overrideWithValue(clock)],
        child: MaterialApp(
          home: Scaffold(
            body: LiveClock(
              builder: (context, now) =>
                  Text(formatClockLabel(now, use24HourFormat: true)),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ticks once a second from the injected clock', (tester) async {
    var now = DateTime(2026, 10, 20, 22, 30, 5);
    await pumpClock(tester, () => now);

    expect(find.text('22:30:05'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('22:30:06'), findsOneWidget);
  });

  testWidgets('stops in the background and catches up on resume', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 20, 22, 30, 5);
    await pumpClock(tester, () => now);
    expect(find.text('22:30:05'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    now = DateTime(2026, 10, 21, 7, 15);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('22:30:05'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('07:15:00'), findsOneWidget);
  });

  testWidgets('cancels its timer when removed', (tester) async {
    await pumpClock(tester, () => DateTime(2026, 10, 20, 22, 30, 5));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
